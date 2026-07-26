import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/euphony_app.dart';
import 'core/log.dart';
import 'data/providers.dart';
import 'playback/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

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
/// beats refusing to start. The web build has no media session to register, so
/// it is skipped there.
Future<void> _startAudioService(ProviderContainer container) async {
  if (kIsWeb) return;
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

