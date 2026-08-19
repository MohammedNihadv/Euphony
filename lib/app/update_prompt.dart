import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/remote/app_updater.dart';
import '../data/remote/update_checker.dart';
import '../design/tokens/brutal.dart';
import '../design/tokens/tokens.dart';

/// Surfaces a "new version available" popup shortly after launch.
///
/// Before this, the only place an update was ever checked was the Settings
/// screen — so a user on an old build had no way to learn a fix had shipped
/// unless they went looking. This runs the check once per app session and, if
/// a newer release exists, shows a dismissible dialog that downloads and
/// installs the update in-app.
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

/// The shared "update available" dialog. Downloads the matching APK inside the
/// app and hands it to the system installer — no trip to the browser or the
/// website — with a progress bar and a "download in browser" fallback.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info});

  final UpdateInfo info;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  final _updater = AppUpdater();
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    final url = await AppUpdater.pickApkUrl(widget.info);
    if (url == null) {
      setState(() {
        _downloading = false;
        _error = 'No download is available for this release.';
      });
      return;
    }

    final error = await _updater.downloadAndInstall(
      url,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _downloading = false;
        _error = error;
      });
    } else {
      // The system installer is now in front; close our dialog.
      Navigator.of(context).pop();
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.info.releaseUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return AlertDialog(
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_downloading) ...[
            const SizedBox(height: EuSpace.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 10,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(EuBrutal.accent),
              ),
            ),
            const SizedBox(height: EuSpace.xs),
            Text(
              _progress > 0
                  ? 'Downloading… ${(_progress * 100).round()}%'
                  : 'Starting download…',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: EuSpace.md),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EuBrutal.alert,
              ),
            ),
          ],
        ],
      ),
      actions: _downloading
          ? const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Please wait…',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Later',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_error != null)
                TextButton(
                  onPressed: _openInBrowser,
                  child: const Text(
                    'In browser',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EuBrutal.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _startUpdate,
                child: Text(
                  _error != null ? 'Retry' : 'Update now',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
    );
  }
}
