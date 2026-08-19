import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/remote/update_checker.dart';
import '../design/tokens/brutal.dart';
import '../design/tokens/tokens.dart';

/// Surfaces a "new version available" popup shortly after launch.
///
/// Before this, the only place an update was ever checked was the Settings
/// screen — so a user on an old build had no way to learn a fix had shipped
/// unless they went looking. This runs the check once per app session and, if
/// a newer release exists, shows a dismissible dialog with the release notes
/// and a button to grab it.
class UpdatePrompt {
  UpdatePrompt._();

  static bool _checkedThisSession = false;

  /// Checks for an update and shows the popup at most once per app session.
  static Future<void> maybeShowOnLaunch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    // Let the app settle (splash + first real frame) before interrupting.
    await Future<void>.delayed(const Duration(seconds: 3));

    UpdateInfo? info;
    try {
      info = await ref.read(updateCheckerProvider).checkUpdate();
    } catch (_) {
      return; // Offline or API error: stay quiet.
    }

    if (info == null || !info.hasUpdate) return;
    if (!context.mounted) return;
    await showUpdateDialog(context, info);
  }
}

/// The shared "update available" dialog. Opens the release page so the user
/// sees every APK option (and the friendly notes) rather than being handed a
/// single architecture that might be wrong for their device.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.eu.ink, width: 2.5),
      ),
      title: Text(
        'Update available  ·  v${info.latestVersion}',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'A newer version of Euphony is out. Updating keeps all your '
            'downloads, liked songs, playlists and settings.',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: EuSpace.md),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                info.releaseNotes!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Later',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EuBrutal.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            final uri = Uri.tryParse(info.releaseUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text(
            'Get update',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
