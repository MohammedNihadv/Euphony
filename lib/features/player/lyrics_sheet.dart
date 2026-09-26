import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';

/// Shows a Frosted Neo-Glassmorphic lyrics modal sheet for the given [song].
void showLyricsSheet(BuildContext context, Song song) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
    builder: (context) => _LyricsSheet(song: song),
  );
}

class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({required this.song});

  final Song song;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  String? _plainLyrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  String? _extractLyricsText(dynamic data) {
    if (data is! Map) return null;
    final plain = data['plainLyrics']?.toString();
    if (plain != null && plain.trim().isNotEmpty) {
      return plain.trim();
    }
    final synced = data['syncedLyrics']?.toString();
    if (synced != null && synced.trim().isNotEmpty) {
      return synced.replaceAll(RegExp(r'\[\d+:\d+(?:\.\d+)?\]\s*'), '').trim();
    }
    return null;
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final rawTitle = widget.song.title;
    // Strip common YouTube/InnerTube noise from title
    final cleanTitle = rawTitle
        .replaceAll(
          RegExp(
            r'\s*[\(\[](official\s*(music)?\s*(video|audio)?|lyric\s*(video)?|audio|remastered|hd|4k|from\s+[^)\]]+)[\)\]]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s*\(feat\..*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\[feat\..*?\]', caseSensitive: false), '')
        .trim();

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 7),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // 1. First attempt: exact match with duration
    try {
      final artist = Uri.encodeComponent(widget.song.artistNames);
      final title = Uri.encodeComponent(
        cleanTitle.isNotEmpty ? cleanTitle : rawTitle,
      );
      final dur = widget.song.duration?.inSeconds ?? 200;
      final url =
          'https://lrclib.net/api/get?artist_name=$artist&track_name=$title&duration=$dur';

      final response = await dio.get<dynamic>(url);
      if (response.statusCode == 200 && response.data != null) {
        final extracted = _extractLyricsText(response.data);
        if (extracted != null && extracted.isNotEmpty) {
          if (mounted) {
            setState(() {
              _plainLyrics = extracted;
              _loading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // 2. Second attempt: search by query (track + artist)
    try {
      final queryTitle = cleanTitle.isNotEmpty ? cleanTitle : rawTitle;
      final query = Uri.encodeComponent('$queryTitle ${widget.song.artistNames}'.trim());
      final searchUrl = 'https://lrclib.net/api/search?q=$query';
      final response = await dio.get<dynamic>(searchUrl);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        for (final item in list) {
          final extracted = _extractLyricsText(item);
          if (extracted != null && extracted.isNotEmpty) {
            if (mounted) {
              setState(() {
                _plainLyrics = extracted;
                _loading = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Third attempt: search by clean title & primary artist
    try {
      final firstArtist = widget.song.artistNames.split(',').first.trim();
      final track = Uri.encodeComponent(
        cleanTitle.isNotEmpty ? cleanTitle : rawTitle,
      );
      final artistEnc = Uri.encodeComponent(firstArtist);
      final searchUrl =
          'https://lrclib.net/api/search?track_name=$track&artist_name=$artistEnc';
      final response = await dio.get<dynamic>(searchUrl);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        for (final item in list) {
          final extracted = _extractLyricsText(item);
          if (extracted != null && extracted.isNotEmpty) {
            if (mounted) {
              setState(() {
                _plainLyrics = extracted;
                _loading = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    // 4. Fourth attempt: search by track name only
    try {
      final track = Uri.encodeComponent(cleanTitle.isNotEmpty ? cleanTitle : rawTitle);
      final searchUrl = 'https://lrclib.net/api/search?q=$track';
      final response = await dio.get<dynamic>(searchUrl);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        for (final item in list) {
          final extracted = _extractLyricsText(item);
          if (extracted != null && extracted.isNotEmpty) {
            if (mounted) {
              setState(() {
                _plainLyrics = extracted;
                _loading = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _error = 'Lyrics not available for this track';
        _loading = false;
      });
    }
  }

  void _searchLyricsOnline() async {
    final query = Uri.encodeComponent(
      '${widget.song.title} ${widget.song.artistNames} lyrics',
    );
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10101A)
            : const Color(0xFFF8FAFD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EuSpace.lg,
                  EuSpace.xs,
                  EuSpace.lg,
                  EuSpace.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [EuBrutal.accent, Color(0xFF9060FA)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: EuBrutal.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lyrics_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: EuSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.song.artistNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_plainLyrics != null)
                      IconButton(
                        tooltip: 'Copy Lyrics',
                        icon: Icon(
                          Icons.copy_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _plainLyrics!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lyrics copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                thickness: 1.0,
              ),

              // Lyrics Content
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: EuBrutal.accent),
                            const SizedBox(height: 16),
                            Text(
                              'Finding synchronized lyrics...',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lyrics_outlined,
                                  size: 42,
                                  color: EuBrutal.accent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Lyrics Unavailable',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No synced lyrics found in database for\n"${widget.song.title}"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _fetchLyrics,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Try Again'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : Colors.black87,
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : Colors.black.withValues(alpha: 0.15),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _searchLyricsOnline,
                                    icon: const Icon(Icons.travel_explore_rounded, size: 16),
                                    label: const Text('Search Online'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EuBrutal.accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EuSpace.xl,
                          vertical: EuSpace.lg,
                        ),
                        child: SelectableText(
                          _plainLyrics!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.8,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.92)
                                : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
  }
}
