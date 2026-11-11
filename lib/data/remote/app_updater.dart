import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

class AppUpdater {
  AppUpdater({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Picks the release APK matching this device's CPU architecture.
  /// Prefers standard direct-install builds over F-Droid binaries.
  static Future<String?> pickApkUrl(UpdateInfo info) async {
    if (info.apkAssets.isEmpty) return info.apkUrl;

    // Filter to standard direct-install APKs (excluding F-Droid builds)
    final directAssets = Map<String, String>.fromEntries(
      info.apkAssets.entries.where((e) => !e.key.contains('fdroid')),
    );
    final assetsToSearch =
        directAssets.isNotEmpty ? directAssets : info.apkAssets;

    var abis = <String>[];
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final android = await DeviceInfoPlugin().androidInfo;
        abis = android.supportedAbis.map((a) => a.toLowerCase()).toList();
      } catch (_) {}
    }

    String? match(String token) {
      for (final entry in assetsToSearch.entries) {
        if (entry.key.contains(token)) return entry.value;
      }
      return null;
    }

    for (final abi in abis) {
      if (abi.contains('arm64')) {
        final u = match('arm64');
        if (u != null) return u;
      } else if (abi.contains('armeabi') || abi.contains('v7a')) {
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

    return match('arm64') ?? assetsToSearch.values.first;
  }

  /// Downloads [url] inside the app and triggers the system package installer.
  /// [onProgress] passes current progress (0.0 to 1.0) and bytes transferred.
  Future<String?> downloadAndInstall(
    String url, {
    void Function(double progress, int received, int total)? onProgress,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return openInBrowser(url);
    }

    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/euphony-update.apk');
      if (file.existsSync()) {
        await file.delete();
      }

      await _dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total, received, total);
          }
        },
      );

      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        return 'Could not start installer: ${result.message}';
      }
      return null;
    } catch (e) {
      return 'Failed to download update: $e';
    }
  }

  /// Opens [url] in the system browser. Returns `null` on success or an error string.
  static Future<String?> openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Invalid URL.';
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return null;
      final fallback = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      return fallback ? null : 'Could not open the browser.';
    } catch (e) {
      return 'Could not open the browser: $e';
    }
  }

  /// Opens the release page for [info] in the system browser.
  static Future<String?> openReleasePage(UpdateInfo info) {
    return openInBrowser(info.releaseUrl);
  }
}
