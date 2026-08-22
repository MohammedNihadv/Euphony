import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../core/log.dart';
import '../domain/song.dart';

final _log = logFor('media_controls');

/// Windows System Media Transport Controls (SMTC).
///
/// Puts the current track in Windows' media flyout (the panel over the volume
/// keys) and wires the keyboard media keys — play/pause/next/previous — back to
/// the player. Everything is a no-op off Windows, so callers don't have to
/// guard the platform themselves. macOS "Now Playing" and Linux MPRIS are not
/// covered here yet.
class DesktopMediaControls {
  SMTCWindows? _smtc;

  static bool get isSupported => !kIsWeb && Platform.isWindows;

  /// Starts SMTC and routes its buttons to the given callbacks. Safe to call on
  /// any platform.
  void init({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
  }) {
    if (!isSupported || _smtc != null) return;
    try {
      final smtc = SMTCWindows(enabled: true);
      _smtc = smtc;
      smtc.buttonPressStream.listen((button) {
        switch (button) {
          case PressedButton.play:
            onPlay();
          case PressedButton.pause:
            onPause();
          case PressedButton.next:
            onNext();
          case PressedButton.previous:
            onPrevious();
          default:
            break;
        }
      });
      _log.info('Windows SMTC media controls enabled');
    } catch (e) {
      _log.warning('failed to start SMTC: $e');
    }
  }

  void updateSong(Song song) {
    final smtc = _smtc;
    if (smtc == null) return;
    try {
      smtc.updateMetadata(
        MusicMetadata(
          title: song.title,
          artist: song.artistNames.isEmpty ? 'Unknown Artist' : song.artistNames,
          album: song.albumTitle,
          thumbnail: song.artworkUrl,
        ),
      );
    } catch (_) {}
  }

  void setPlaying({required bool playing}) {
    final smtc = _smtc;
    if (smtc == null) return;
    try {
      smtc.setPlaybackStatus(
        playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      );
    } catch (_) {}
  }

  void setStopped() {
    final smtc = _smtc;
    if (smtc == null) return;
    try {
      smtc.setPlaybackStatus(PlaybackStatus.stopped);
    } catch (_) {}
  }

  void dispose() {
    try {
      _smtc?.dispose();
    } catch (_) {}
    _smtc = null;
  }
}
