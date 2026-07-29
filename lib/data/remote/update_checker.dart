import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.apkUrl,
    this.releaseNotes,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String? apkUrl;
  final String? releaseNotes;
  final bool hasUpdate;
}

class UpdateChecker {
  UpdateChecker({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String currentVersion = '0.2.0';
  static const String repoUrl =
      'https://api.github.com/repos/MohammedNihadv/Euphony/releases/latest';

  Future<UpdateInfo?> checkUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        repoUrl,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.data == null) return null;
      final data = response.data!;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final latestTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseUrl =
          data['html_url'] as String? ??
          'https://github.com/MohammedNihadv/Euphony/releases';
      final releaseNotes = data['body'] as String?;

      String? apkUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final asset in assets) {
          if (asset is Map<String, dynamic>) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }
      }

      final hasUpdate = _isVersionGreater(latestTag, currentVersion);

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestTag.isNotEmpty ? latestTag : currentVersion,
        releaseUrl: releaseUrl,
        apkUrl: apkUrl,
        releaseNotes: releaseNotes,
        hasUpdate: hasUpdate,
      );
    } catch (_) {
      // If offline or release not created yet, return no update
      return null;
    }
  }

  bool _isVersionGreater(String latest, String current) {
    if (latest.isEmpty) return false;
    final latestParts = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (var i = 0; i < latestParts.length || i < currentParts.length; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}

final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  return UpdateChecker();
});

final updateCheckFutureProvider = FutureProvider<UpdateInfo?>((ref) async {
  final checker = ref.watch(updateCheckerProvider);
  return checker.checkUpdate();
});
