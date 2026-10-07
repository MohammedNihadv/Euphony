import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

/// Opens the GitHub release page in the system browser.
/// Updates on F-Droid are handled by the F-Droid client;
/// for GitHub / direct-install users this opens the release page
/// so they can review release notes and download the update.
class AppUpdater {
  /// Opens [url] in the system browser. Returns `null` on success or a
  /// human-readable error string on failure.
  static Future<String?> openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Invalid URL.';
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? null : 'Could not open the browser.';
    } catch (e) {
      return 'Could not open the browser: $e';
    }
  }

  /// Opens the release page for [info] in the system browser.
  static Future<String?> openReleasePage(UpdateInfo info) {
    return openInBrowser(info.releaseUrl);
  }
}
