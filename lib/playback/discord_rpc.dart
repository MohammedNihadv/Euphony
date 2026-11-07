import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../core/log.dart';
import '../domain/song.dart';

final _log = logFor('discord_rpc');

/// Native cross-platform Discord Rich Presence (IPC) client.
///
/// Communicates directly with Discord's local IPC daemon:
/// - Windows: Named pipes (`\\.\pipe\discord-ipc-0` .. `9`) via Win32 `kernel32.dll`
/// - Linux & macOS: UNIX domain sockets (`$XDG_RUNTIME_DIR/discord-ipc-0`, etc.)
///
/// Pure Dart implementation with zero external C library dependencies.
/// Completely non-blocking and safe: silently no-ops when Discord is not running.
class DiscordRpc {
  DiscordRpc({String? clientId})
      : clientId = clientId ?? _defaultClientId;

  static const String _defaultClientId = '1202888258380894208';

  final String clientId;
  bool _enabled = true;
  bool _disposed = false;

  // Windows handle
  int _windowsPipeHandle = -1;
  // Linux / macOS socket
  Socket? _unixSocket;

  bool _isConnected = false;
  DateTime _lastConnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;

  bool get isSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool get isConnected => _isConnected;
  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      clearActivity();
      _disconnect();
    } else if (_currentSong != null) {
      updateActivity(
        song: _currentSong!,
        isPlaying: _isPlaying,
        position: _lastPosition,
        duration: _lastDuration,
      );
    }
  }

  /// Updates or sets the current playing song.
  void updateActivity({
    required Song song,
    required bool isPlaying,
    Duration position = Duration.zero,
    Duration? duration,
  }) {
    if (!isSupported || !_enabled || _disposed) return;

    _currentSong = song;
    _isPlaying = isPlaying;
    _lastPosition = position;
    _lastDuration = duration;

    _sendPresence();
  }

  /// Sets playing/paused state.
  void setPlaying({
    required bool isPlaying,
    Duration position = Duration.zero,
    Duration? duration,
  }) {
    if (!isSupported || !_enabled || _disposed) return;
    _isPlaying = isPlaying;
    _lastPosition = position;
    if (duration != null) _lastDuration = duration;
    _sendPresence();
  }

  /// Clears the active Discord presence.
  void clearActivity() {
    _currentSong = null;
    _isPlaying = false;
    if (!_isConnected) return;

    try {
      final payload = {
        'cmd': 'SET_ACTIVITY',
        'args': {
          'pid': pid,
          'activity': null,
        },
        'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      _sendFrame(1, jsonEncode(payload));
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    clearActivity();
    _disconnect();
  }

  void _sendPresence() {
    if (_currentSong == null) return;

    if (!_isConnected) {
      final now = DateTime.now();
      // Throttle reconnect attempts to once every 10 seconds if disconnected
      if (now.difference(_lastConnectAttempt) < const Duration(seconds: 10)) {
        return;
      }
      _lastConnectAttempt = now;
      if (!_connect()) {
        return;
      }
    }

    final song = _currentSong!;
    final now = DateTime.now();

    Map<String, dynamic>? timestamps;
    if (_isPlaying) {
      final startTime = now.subtract(_lastPosition).millisecondsSinceEpoch;
      timestamps = {
        'start': startTime,
      };
      if (_lastDuration != null && _lastDuration! > Duration.zero) {
        final endTime =
            now.subtract(_lastPosition).add(_lastDuration!).millisecondsSinceEpoch;
        timestamps['end'] = endTime;
      }
    }

    final artworkUrl = song.artworkUrl;
    final albumTitle = song.albumTitle;

    final assets = <String, dynamic>{
      'large_image': (artworkUrl != null && artworkUrl.isNotEmpty)
          ? artworkUrl
          : 'music_logo',
      'large_text': (albumTitle != null && albumTitle.isNotEmpty)
          ? albumTitle
          : 'Euphony',
      'small_image': _isPlaying ? 'play' : 'pause',
      'small_text': _isPlaying ? 'Playing' : 'Paused',
    };

    final buttons = <Map<String, String>>[];
    if (song.id.isNotEmpty) {
      buttons.add({
        'label': 'Listen on YouTube Music',
        'url': 'https://music.youtube.com/watch?v=${song.id}',
      });
    }

    final activity = <String, dynamic>{
      'details': song.title,
      'state': song.artistNames.isNotEmpty ? 'by ${song.artistNames}' : 'Euphony',
      'assets': assets,
    };

    if (timestamps != null) {
      activity['timestamps'] = timestamps;
    }
    if (buttons.isNotEmpty) {
      activity['buttons'] = buttons;
    }

    final payload = {
      'cmd': 'SET_ACTIVITY',
      'args': {
        'pid': pid,
        'activity': activity,
      },
      'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    _sendFrame(1, jsonEncode(payload));
  }

  bool _connect() {
    if (_isConnected) return true;

    try {
      if (Platform.isWindows) {
        return _connectWindows();
      } else {
        return _connectUnix();
      }
    } catch (e) {
      _log.fine('Discord connect failed: $e');
      return false;
    }
  }

  bool _connectWindows() {
    for (var i = 0; i < 10; i++) {
      final pipePath = r'\\.\pipe\discord-ipc-' + i.toString();
      final pathPtr = pipePath.toNativeUtf16();
      final handle = _winCreateFile(
        pathPtr,
        0x40000000 | 0x80000000, // GENERIC_READ | GENERIC_WRITE
        0,
        nullptr,
        3, // OPEN_EXISTING
        0,
        0,
      );
      calloc.free(pathPtr);

      if (handle != -1 &&
          handle != 0xFFFFFFFFFFFFFFFF &&
          handle != 0xFFFFFFFF) {
        _windowsPipeHandle = handle;
        _isConnected = true;
        _log.info('Connected to Discord IPC named pipe ($pipePath)');

        // Send handshake packet (Opcode 0)
        final handshake = jsonEncode({'v': 1, 'client_id': clientId});
        if (_sendFrame(0, handshake)) {
          _drainPipeBuffer();
          return true;
        } else {
          _disconnect();
        }
      }
    }
    return false;
  }

  bool _connectUnix() {
    final possibleDirs = [
      Platform.environment['XDG_RUNTIME_DIR'],
      Platform.environment['TMPDIR'],
      Platform.environment['TMP'],
      Platform.environment['TEMP'],
      '/tmp',
    ];

    for (final dir in possibleDirs) {
      if (dir == null || dir.isEmpty) continue;
      for (var i = 0; i < 10; i++) {
        final path = '$dir/discord-ipc-$i';
        if (File(path).existsSync()) {
          try {
            final socket = Socket.connect(
              InternetAddress(path, type: InternetAddressType.unix),
              0,
              timeout: const Duration(milliseconds: 500),
            );
            socket.then((s) {
              _unixSocket = s;
              _isConnected = true;
              _log.info('Connected to Discord IPC socket ($path)');
              s.listen(
                (_) {},
                onError: (_) => _disconnect(),
                onDone: _disconnect,
              );
              _sendFrame(0, jsonEncode({'v': 1, 'client_id': clientId}));
              _sendPresence();
            }).catchError((_) {});
            return true;
          } catch (_) {}
        }
      }
    }
    return false;
  }

  bool _sendFrame(int opcode, String jsonStr) {
    try {
      final payloadBytes = utf8.encode(jsonStr);
      final byteData = ByteData(8 + payloadBytes.length);
      byteData.setInt32(0, opcode, Endian.little);
      byteData.setInt32(4, payloadBytes.length, Endian.little);

      final fullPacket = byteData.buffer.asUint8List();
      fullPacket.setRange(8, 8 + payloadBytes.length, payloadBytes);

      if (Platform.isWindows && _windowsPipeHandle != -1) {
        final bufferPtr = calloc<Uint8>(fullPacket.length);
        final typedList = bufferPtr.asTypedList(fullPacket.length);
        typedList.setAll(0, fullPacket);

        final bytesWrittenPtr = calloc<Uint32>();
        final res = _winWriteFile(
          _windowsPipeHandle,
          bufferPtr,
          fullPacket.length,
          bytesWrittenPtr,
          nullptr,
        );

        final written = bytesWrittenPtr.value;
        calloc.free(bufferPtr);
        calloc.free(bytesWrittenPtr);

        if (res == 0 || written == 0) {
          _disconnect();
          return false;
        }

        _drainPipeBuffer();
        return true;
      } else if (_unixSocket != null) {
        _unixSocket!.add(fullPacket);
        return true;
      }
    } catch (e) {
      _log.fine('Error sending Discord RPC frame: $e');
      _disconnect();
    }
    return false;
  }

  void _drainPipeBuffer() {
    if (!Platform.isWindows || _windowsPipeHandle == -1) return;
    try {
      final availPtr = calloc<Uint32>();
      if (_winPeekNamedPipe(
            _windowsPipeHandle,
            nullptr,
            0,
            nullptr,
            availPtr,
            nullptr,
          ) !=
          0) {
        final bytesAvail = availPtr.value;
        if (bytesAvail > 0) {
          final readBuf = calloc<Uint8>(bytesAvail);
          final bytesReadPtr = calloc<Uint32>();
          _winReadFile(
            _windowsPipeHandle,
            readBuf,
            bytesAvail,
            bytesReadPtr,
            nullptr,
          );
          calloc.free(readBuf);
          calloc.free(bytesReadPtr);
        }
      }
      calloc.free(availPtr);
    } catch (_) {}
  }

  void _disconnect() {
    _isConnected = false;
    if (Platform.isWindows && _windowsPipeHandle != -1) {
      try {
        _winCloseHandle(_windowsPipeHandle);
      } catch (_) {}
      _windowsPipeHandle = -1;
    }
    if (_unixSocket != null) {
      try {
        _unixSocket!.destroy();
      } catch (_) {}
      _unixSocket = null;
    }
  }

  // Win32 FFI bindings
  static final DynamicLibrary _k32 = DynamicLibrary.open('kernel32.dll');

  static final _winCreateFile = _k32.lookupFunction<
      IntPtr Function(
        Pointer<Utf16>,
        Uint32,
        Uint32,
        Pointer<Void>,
        Uint32,
        Uint32,
        IntPtr,
      ),
      int Function(
        Pointer<Utf16>,
        int,
        int,
        Pointer<Void>,
        int,
        int,
        int,
      )>('CreateFileW');

  static final _winWriteFile = _k32.lookupFunction<
      Int32 Function(
        IntPtr,
        Pointer<Uint8>,
        Uint32,
        Pointer<Uint32>,
        Pointer<Void>,
      ),
      int Function(
        int,
        Pointer<Uint8>,
        int,
        Pointer<Uint32>,
        Pointer<Void>,
      )>('WriteFile');

  static final _winReadFile = _k32.lookupFunction<
      Int32 Function(
        IntPtr,
        Pointer<Uint8>,
        Uint32,
        Pointer<Uint32>,
        Pointer<Void>,
      ),
      int Function(
        int,
        Pointer<Uint8>,
        int,
        Pointer<Uint32>,
        Pointer<Void>,
      )>('ReadFile');

  static final _winPeekNamedPipe = _k32.lookupFunction<
      Int32 Function(
        IntPtr,
        Pointer<Void>,
        Uint32,
        Pointer<Uint32>,
        Pointer<Uint32>,
        Pointer<Uint32>,
      ),
      int Function(
        int,
        Pointer<Void>,
        int,
        Pointer<Uint32>,
        Pointer<Uint32>,
        Pointer<Uint32>,
      )>('PeekNamedPipe');

  static final _winCloseHandle = _k32.lookupFunction<
      Int32 Function(IntPtr),
      int Function(int)>('CloseHandle');
}
