import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../core/log.dart';
import '../domain/song.dart';

final _log = logFor('desktop_media_controls');

/// Native desktop OS media controls (Windows SystemMediaTransportControls (SMTC),
/// lock screen integration, hardware media keys, Bluetooth AVRCP, and taskbar tray).
class DesktopMediaControls {
  static const MethodChannel _channel =
      MethodChannel('com.mhdni.euphony/desktop_media');

  static bool get isSupported => !kIsWeb && Platform.isWindows;

  static final ValueNotifier<bool> isMiniPlayer = ValueNotifier<bool>(false);

  SMTCWindows? _smtc;
  StreamSubscription<PressedButton>? _smtcSub;

  VoidCallback? _onPlay;
  VoidCallback? _onPause;
  VoidCallback? _onPlayPause;
  VoidCallback? _onNext;
  VoidCallback? _onPrevious;
  VoidCallback? _onStop;
  bool _isPlaying = false;
  int? _lastPositionSec;

  void toggleMiniPlayer() {
    if (!isSupported) return;
    final next = !isMiniPlayer.value;
    isMiniPlayer.value = next;
    _channel
        .invokeMethod(next ? 'enterMiniPlayer' : 'exitMiniPlayer')
        .ignore();
  }

  void enterMiniPlayer() {
    if (!isSupported) return;
    isMiniPlayer.value = true;
    _channel.invokeMethod('enterMiniPlayer').ignore();
  }

  void exitMiniPlayer() {
    if (!isSupported) return;
    isMiniPlayer.value = false;
    _channel.invokeMethod('exitMiniPlayer').ignore();
  }

  void closeMiniPlayer() {
    if (!isSupported) return;
    isMiniPlayer.value = false;
    _channel.invokeMethod('closeMiniPlayer').ignore();
  }

  void startDragging() {
    if (!isSupported) return;
    _channel.invokeMethod('startDragging').ignore();
  }

  void minimizeToTray() {
    if (!isSupported) return;
    _channel.invokeMethod('minimizeToTray').ignore();
  }

  void restoreFromTray() {
    if (!isSupported) return;
    _channel.invokeMethod('restoreFromTray').ignore();
  }

  void setCloseToTray({required bool enabled}) {
    if (!isSupported) return;
    _channel.invokeMethod('setCloseToTray', {'enabled': enabled}).ignore();
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
    _initSmtc();
    _log.info('Windows native desktop media controls initialized');
  }

  void _initSmtc() {
    try {
      _smtc = SMTCWindows(
        enabled: false,
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      );

      _smtcSub = _smtc!.buttonPressStream.listen((event) {
        _log.fine('SMTC event received: $event');
        switch (event) {
          case PressedButton.play:
            _onPlay?.call();
            _smtc?.setPlaybackStatus(PlaybackStatus.Playing);
          case PressedButton.pause:
            _onPause?.call();
            _smtc?.setPlaybackStatus(PlaybackStatus.Paused);
          case PressedButton.next:
            _onNext?.call();
          case PressedButton.previous:
            _onPrevious?.call();
          case PressedButton.stop:
            _onStop?.call();
            _smtc?.setPlaybackStatus(PlaybackStatus.Stopped);
          default:
            break;
        }
      });
      _log.info('SMTC listener registered successfully');
    } catch (e, st) {
      _log.warning('Could not initialize SMTC: $e\n$st');
    }
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
    _lastPositionSec = null;

    _channel.invokeMethod('updateMetadata', {
      'title': song.title,
      'artist': song.artistNames,
      'album': song.albumTitle,
    }).ignore();

    try {
      if (_smtc != null) {
        if (!_smtc!.enabled) {
          unawaited(_smtc!.enableSmtc());
        }

        String? validThumbnail;
        if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
          final uri = Uri.tryParse(song.artworkUrl!);
          if (uri != null && uri.hasScheme) {
            validThumbnail = song.artworkUrl;
          }
        }

        unawaited(_smtc!.updateMetadata(
          MusicMetadata(
            title: song.title,
            artist: song.artistNames,
            album: song.albumTitle,
            albumArtist: song.artistNames,
            thumbnail: validThumbnail,
          ),
        ));

        if (song.duration != null && song.duration! > Duration.zero) {
          unawaited(_smtc!.setEndTime(song.duration!));
          unawaited(_smtc!.setPosition(Duration.zero));
        }
      }
    } catch (e) {
      _log.warning('Failed to update SMTC song metadata: $e');
    }
  }

  void setPlaying({required bool playing}) {
    _isPlaying = playing;
    if (!isSupported) return;
    _channel.invokeMethod('setPlaybackStatus', {'playing': playing}).ignore();

    try {
      _smtc?.setPlaybackStatus(
        playing ? PlaybackStatus.Playing : PlaybackStatus.Paused,
      );
    } catch (e) {
      _log.warning('Failed to update SMTC playback status: $e');
    }
  }

  void setStopped() {
    _isPlaying = false;
    _lastPositionSec = null;
    if (!isSupported) return;
    _channel
        .invokeMethod('setPlaybackStatus', {'playing': false, 'stopped': true})
        .ignore();

    try {
      _smtc?.setPlaybackStatus(PlaybackStatus.Stopped);
      _smtc?.clearMetadata();
      _smtc?.disableSmtc();
    } catch (e) {
      _log.warning('Failed to stop SMTC: $e');
    }
  }

  void updatePosition(Duration position) {
    if (!isSupported || _smtc == null || !_smtc!.enabled) return;
    if (position.inSeconds == _lastPositionSec) return;
    _lastPositionSec = position.inSeconds;
    try {
      _smtc?.setPosition(position);
    } catch (_) {}
  }

  void updateDuration(Duration duration) {
    if (!isSupported || _smtc == null || !_smtc!.enabled) return;
    try {
      _smtc?.setEndTime(duration);
    } catch (_) {}
  }

  void dispose() {
    if (!isSupported) return;
    _channel.setMethodCallHandler(null);
    try {
      unawaited(_smtcSub?.cancel());
      _smtcSub = null;
      if (_smtc != null) {
        unawaited(_smtc!.clearMetadata());
        unawaited(_smtc!.disableSmtc());
        unawaited(_smtc!.dispose());
        _smtc = null;
      }
    } catch (e) {
      _log.warning('Failed to dispose SMTC: $e');
    }
  }
}
