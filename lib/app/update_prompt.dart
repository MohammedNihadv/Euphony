import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/remote/app_updater.dart';
import '../data/remote/update_checker.dart';
import '../design/tokens/brutal.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF5141424) : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [EuBrutal.accent, Color(0xFF9060FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: EuBrutal.accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'UPDATE AVAILABLE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                letterSpacing: 0.8,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: EuBrutal.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${info.latestVersion}',
                                style: const TextStyle(
                                  color: EuBrutal.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A fresh release of Euphony is ready',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Concise Description
              Text(
                'Upgrading preserves all your liked songs, playlists, downloads, and app settings.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              // Release notes if available
              if (_cleanNotes(info.releaseNotes).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 90),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _cleanNotes(info.releaseNotes),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],

              // Downloading Progress Bar & Percentage
              if (_downloading) ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EuBrutal.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _progress > 0 ? 'Downloading update…' : 'Connecting to server…',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: EuBrutal.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: EuBrutal.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(EuBrutal.accent),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: EuBrutal.alert.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: EuBrutal.alert,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _downloading
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Please wait for installer…',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ]
                    : [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white60 : Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: const Text(
                            'Later',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: _openInBrowser,
                            style: TextButton.styleFrom(
                              foregroundColor: EuBrutal.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: const Text(
                              'In browser',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EuBrutal.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _startUpdate,
                          child: Text(
                            _error != null ? 'Retry' : 'Update now',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cleanNotes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('##') && !l.startsWith('#'))
      .toList();
  final bullets =
      lines.where((l) => l.startsWith('-') || l.startsWith('*')).toList();
  final listToUse = bullets.isNotEmpty ? bullets : lines;
  return listToUse.take(3).join('\n');
}
