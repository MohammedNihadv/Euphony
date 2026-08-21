import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/log.dart';
import 'update_checker.dart';

final _log = logFor('app_updater');

/// Downloads a release APK inside the app and hands it to the system installer,
/// so updating never has to bounce out to a browser or the website.
class AppUpdater {
  AppUpdater({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Picks the APK that matches this device's CPU architecture.
  ///
  /// The release ships split APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
  /// Installing the wrong one fails, so the device's own supported ABIs decide
  /// — falling back to arm64 (virtually every modern phone) and then to any
  /// available APK.
  static Future<String?> pickApkUrl(UpdateInfo info) async {
    if (info.apkAssets.isEmpty) return info.apkUrl;

    var abis = <String>[];
    try {
      final android = await DeviceInfoPlugin().androidInfo;
      abis = android.supportedAbis.map((a) => a.toLowerCase()).toList();
    } catch (_) {}

    String? match(String token) {
      for (final entry in info.apkAssets.entries) {
        if (entry.key.contains(token)) return entry.value;
      }
      return null;
    }

    for (final abi in abis) {
      if (abi.contains('arm64')) {
        final u = match('arm64');
        if (u != null) return u;
      } else if (abi.contains('armeabi') || abi.contains('armv7')) {
        final u = match('armeabi') ?? match('v7a');
        if (u != null) return u;
      } else if (abi.contains('x86_64')) {
        final u = match('x86_64');
        if (u != null) return u;
      } else if (abi.contains('x86')) {
        final u = match('x86');
        if (u != null) return u;
      }
    }

    return match('arm64') ?? info.apkAssets.values.first;
  }

  /// Downloads [url] to a private file and opens it, which triggers Android's
  /// "install app" prompt. [onProgress] is called with 0.0–1.0.
  ///
  /// Returns `null` on success, or a human-readable error message.
  Future<String?> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // getExternalStorageDirectory is Android-only (it throws elsewhere), so
      // only reach for it on Android; every other platform uses the support dir.
      Directory? dir;
      if (!kIsWeb && Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationSupportDirectory();
      final file = File('${dir.path}/euphony-update.apk');
      if (file.existsSync()) {
        await file.delete();
      }

      await _dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );

      _log.info('update downloaded to ${file.path}');
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        _log.warning('open installer failed: ${result.message}');
        return 'Could not open the installer: ${result.message}';
      }
      return null;
    } catch (error) {
      _log.severe('update download/install failed: $error');
      return 'Update failed to download. Please try again.';
    }
  }
}
