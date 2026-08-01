import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../log.dart';

final _log = logFor('permissions');

/// Requests notification permission on Android 13+ (API 33+) so foreground
/// playback notifications and lock screen media controls are not blocked by the OS.
Future<void> ensureNotificationPermission() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      _log.info('requesting Android notification permission for media controls');
      final result = await Permission.notification.request();
      _log.info('notification permission status: $result');
    }
  } catch (e, st) {
    _log.warning('failed to request notification permission: $e\n$st');
  }
}
