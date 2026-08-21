import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/euphony_app.dart';
import 'core/log.dart';
import 'data/providers.dart';
import 'playback/audio_handler.dart';

/// True on the desktop OSes where just_audio has no native player and needs the
/// media_kit (libmpv) backend. Guarded by [kIsWeb] because `dart:io`'s
/// [Platform] throws on the web.
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

  // On Windows and Linux just_audio ships no native player, so route it through
  // media_kit (libmpv). Android, iOS and macOS keep their built-in backend.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: true);
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    debugPrint('SharedPreferences failed to load: $e\n$st');
  }

  // Built by hand rather than letting `ProviderScope` create one, so the audio
  // handler can attach to the same container the widgets read from.
  final container = ProviderContainer(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Launch the UI immediately so the app starts up without delay.
  // AudioService initializes asynchronously in the background.
  unawaited(_startAudioService(container));

  runApp(
    UncontrolledProviderScope(container: container, child: const EuphonyApp()),
  );
}

/// Registers the media session that keeps audio alive in the background.
///
/// Failure here is not fatal: the app still plays in the foreground, which
/// beats refusing to start. Only Android and iOS have an `audio_service`
/// backend; web and desktop have no media session to register, so it is
/// skipped there and playback runs in the foreground.
Future<void> _startAudioService(ProviderContainer container) async {
  if (kIsWeb || _isDesktop) return;
  try {
    await AudioService.init(
      builder: () => EuphonyAudioHandler(container),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mhdni.euphony.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationIcon: 'drawable/ic_stat_music_note',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (error, stack) {
    debugPrint('audio service failed to start: $error\n$stack');
  }
}
