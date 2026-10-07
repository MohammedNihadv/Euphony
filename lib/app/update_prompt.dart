import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/remote/app_updater.dart';
import '../data/remote/update_checker.dart';
import '../design/tokens/brutal.dart';

/// Shows a "new version available" dialog when the user manually triggers an
/// update check from Settings.
///
/// Automatic on-launch checking is intentionally removed: on F-Droid the
/// client manages updates; on GitHub users can tap "Check for updates" in
/// Settings at any time.
class UpdatePrompt {
  UpdatePrompt._();

  // no-op: kept so call-sites that still reference this compile cleanly.
  // Will be removed after callers are cleaned up.
}

/// The shared "update available" dialog.  The primary action opens the release
/// page (or ABI-matched APK) in the system browser; no APK is downloaded
/// inside the app.
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
  bool _opening = false;
  String? _error;

  Future<void> _openRelease() async {
    setState(() {
      _opening = true;
      _error = null;
    });

    final error = await AppUpdater.openReleasePage(widget.info);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _opening = false;
        _error = error;
      });
    } else {
      Navigator.of(context).pop();
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
            color: isDark
                ? const Color(0xF5141424)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.08),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
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

              // Description
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
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

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
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
                children: [
                  TextButton(
                    onPressed: _opening ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white60 : Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EuBrutal.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _opening ? null : _openRelease,
                    icon: _opening
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: Text(
                      _error != null ? 'Retry' : 'View release',
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
  final bullets = lines
      .where((l) => l.startsWith('-') || l.startsWith('*'))
      .toList();
  final listToUse = bullets.isNotEmpty ? bullets : lines;
  return listToUse.take(3).join('\n');
}
