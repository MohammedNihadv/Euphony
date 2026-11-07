import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/log.dart';
import '../domain/song.dart';

final _log = logFor('desktop_media_controls');

/// Native desktop OS media controls (Windows hardware media keys, Bluetooth AVRCP,
/// and background transport events).
///
/// Communicates with `windows/runner/flutter_window.cpp` via a platform method channel
/// using native Win32 `WM_APPCOMMAND` and `RegisterHotKey` for zero-dependency,
/// guaranteed bundling in production releases.
class DesktopMediaControls {
  static const MethodChannel _channel =
      MethodChannel('com.mhdni.euphony/desktop_media');

  static bool get isSupported => !kIsWeb && Platform.isWindows;

  static final ValueNotifier<bool> isMiniPlayer = ValueNotifier<bool>(false);

  VoidCallback? _onPlay;
  VoidCallback? _onPause;
  VoidCallback? _onPlayPause;
  VoidCallback? _onNext;
  VoidCallback? _onPrevious;
  VoidCallback? _onStop;
  bool _isPlaying = false;

  void toggleMiniPlayer() {
    if (!isSupported) return;
    final next = !isMiniPlayer.value;
    isMiniPlayer.value = next;
    try {
      _channel.invokeMethod(next ? 'enterMiniPlayer' : 'exitMiniPlayer');
    } catch (_) {}
  }

  void enterMiniPlayer() {
    if (!isSupported) return;
    isMiniPlayer.value = true;
    try {
      _channel.invokeMethod('enterMiniPlayer');
    } catch (_) {}
  }

  void exitMiniPlayer() {
    if (!isSupported) return;
    isMiniPlayer.value = false;
    try {
      _channel.invokeMethod('exitMiniPlayer');
    } catch (_) {}
  }

  void minimizeToTray() {
    if (!isSupported) return;
    try {
      _channel.invokeMethod('minimizeToTray');
    } catch (_) {}
  }

  void restoreFromTray() {
    if (!isSupported) return;
    try {
      _channel.invokeMethod('restoreFromTray');
    } catch (_) {}
  }

  void setCloseToTray({required bool enabled}) {
    if (!isSupported) return;
    try {
      _channel.invokeMethod('setCloseToTray', {'enabled': enabled});
    } catch (_) {}
  }

  void init({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    VoidCallback? onPlayPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
    VoidCallback? onStop,
  }) {
    if (!isSupported) return;

    _onPlay = onPlay;
    _onPause = onPause;
    _onPlayPause = onPlayPause;
    _onNext = onNext;
    _onPrevious = onPrevious;
    _onStop = onStop;

    _channel.setMethodCallHandler(_handleNativeMethod);
    _log.info('Windows native desktop media controls initialized');
  }

  Future<dynamic> _handleNativeMethod(MethodCall call) async {
    switch (call.method) {
      case 'playPause':
        if (_onPlayPause != null) {
          _onPlayPause!();
        } else if (_isPlaying) {
          _onPause?.call();
        } else {
          _onPlay?.call();
        }
      case 'play':
        _onPlay?.call();
      case 'pause':
        _onPause?.call();
      case 'next':
        _onNext?.call();
      case 'previous':
        _onPrevious?.call();
      case 'stop':
        _onStop?.call();
    }
  }

  void updateSong(Song song) {
    if (!isSupported) return;
    try {
      _channel.invokeMethod('updateMetadata', {
        'title': song.title,
        'artist': song.artistNames,
        'album': song.albumTitle,
      });
    } catch (_) {}
  }

  void setPlaying({required bool playing}) {
    _isPlaying = playing;
    if (!isSupported) return;
    try {
      _channel.invokeMethod('setPlaybackStatus', {'playing': playing});
    } catch (_) {}
  }

  void setStopped() {
    _isPlaying = false;
    if (!isSupported) return;
    try {
      _channel.invokeMethod(
        'setPlaybackStatus',
        {'playing': false, 'stopped': true},
      );
    } catch (_) {}
  }

  void dispose() {
    if (!isSupported) return;
    _channel.setMethodCallHandler(null);
  }
}
