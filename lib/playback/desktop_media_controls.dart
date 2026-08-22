import 'package:flutter/foundation.dart';

import '../domain/song.dart';

/// Hook point for desktop OS media controls (Windows SMTC, macOS Now Playing,
/// Linux MPRIS).
///
/// Currently a no-op: the available Windows SMTC package pulls a prebuilt native
/// library at build time that does not bundle reliably, so shipping it would add
/// a dependency that silently does nothing. The player already calls these
/// methods, so a real implementation can be dropped in here later without
/// touching playback code. Everything is a safe no-op today.
class DesktopMediaControls {
  static bool get isSupported => false;

  void init({
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
  }) {}

  void updateSong(Song song) {}

  void setPlaying({required bool playing}) {}

  void setStopped() {}

  void dispose() {}
}
