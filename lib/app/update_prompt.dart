import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/remote/app_updater.dart';
import '../data/remote/update_checker.dart';
import '../design/tokens/brutal.dart';

/// Shows a "new version available" dialog when the user triggers an update
/// check or when an update is detected.
///
/// Automatic on-launch checking is intentionally removed: on F-Droid the client
/// manages updates; on GitHub users can tap "Check for updates" in Settings.
class UpdatePrompt {
  UpdatePrompt._();
}

/// The shared "update available" dialog. The primary action opens the release
/// page in the system browser so the user can review notes and download the APK.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
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
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
      _receivedBytes = 0;
      _totalBytes = 0;
    });

    final url = await AppUpdater.pickApkUrl(widget.info);
    if (url == null) {
      final error = await AppUpdater.openReleasePage(widget.info);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _downloading = false;
          _error = error;
        });
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    final error = await _updater.downloadAndInstall(
      url,
      onProgress: (p, received, total) {
        if (mounted) {
          setState(() {
            _progress = p;
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _downloading = false;
        _error = error;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openBrowserFallback() async {
    await AppUpdater.openReleasePage(widget.info);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildBulletText(String text, bool isDark) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.82)
                : const Color(0xFF334155),
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white.withValues(alpha: 0.82)
              : const Color(0xFF334155),
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(height: 1.35),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bullets = _extractBullets(info.releaseNotes);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141422) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.65)
                    : const Color(0xFF64748B).withValues(alpha: 0.20),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: EuBrutal.accent.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: EuBrutal.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW UPDATE READY',
                            style: TextStyle(
                              color: EuBrutal.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Euphony v${info.latestVersion}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.3,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Version Comparison Bento
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTALLED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'v${info.currentVersion}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: EuBrutal.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: EuBrutal.accent,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'LATEST BUILD',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: EuBrutal.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'v${info.latestVersion}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: EuBrutal.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Highlights / What's New Box
              Text(
                'HIGHLIGHTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 125),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.30)
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bullets.map((bullet) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: EuBrutal.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: _buildBulletText(bullet, isDark),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Preservation Reassurance
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All playlists, favorites, downloads & settings remain intact.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: EuBrutal.alert.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: EuBrutal.alert.withValues(alpha: 0.3),
                      width: 1,
                    ),
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

              if (_downloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(EuBrutal.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _progress > 0
                          ? 'Downloading... ${(_progress * 100).toInt()}%'
                          : 'Starting download...',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    if (_totalBytes > 0)
                      Text(
                        '${(_receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(_totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _downloading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.14)
                              : Colors.black.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _error != null ? 'Cancel' : 'Later',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Download in browser',
                      onPressed: _openBrowserFallback,
                      icon: const Icon(Icons.open_in_browser_rounded),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _downloading
                          ? null
                          : () async {
                              await HapticFeedback.mediumImpact();
                              await _startUpdate();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EuBrutal.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      icon: _downloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _error != null
                                  ? Icons.refresh_rounded
                                  : Icons.download_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _downloading
                            ? 'Downloading...'
                            : (_error != null ? 'Retry' : 'Get Update'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.2,
                        ),
                      ),
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

List<String> _extractBullets(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [
      'Refreshed features & audio playback improvements',
      'Refined interface alignments and smooth animations',
      'Bug fixes and system reliability updates',
    ];
  }

  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toList();

  final bullets = <String>[];
  for (final line in lines) {
    var cleaned = line;
    if (cleaned.startsWith('- ') || cleaned.startsWith('* ')) {
      cleaned = cleaned.substring(2).trim();
    }
    // Remove markdown links like [Text](url) -> Text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Remove "by @user" suffix
    cleaned = cleaned.replaceAll(RegExp(r'\s+by\s+@[\w-]+.*$'), '');
    if (cleaned.isNotEmpty && !cleaned.toLowerCase().startsWith('full changelog')) {
      bullets.add(cleaned);
    }
  }

  if (bullets.isEmpty) {
    return const [
      'Performance optimizations and playback enhancements',
      'Visual polish and responsive layout fixes',
      'Stability updates and memory improvements',
    ];
  }

  return bullets.take(4).toList();
}
