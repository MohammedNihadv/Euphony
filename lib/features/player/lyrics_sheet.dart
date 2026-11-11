import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import 'lyrics_service.dart';
import 'romanizer.dart';

/// Shows a Frosted Neo-Glassmorphic synchronized lyrics modal sheet or desktop dialog for the given [song].
void showLyricsSheet(BuildContext context, Song song) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isDesktop = MediaQuery.sizeOf(context).width >= 700;

  if (isDesktop) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
          child: _LyricsSheet(song: song, isDialog: true),
        ),
      ),
    );
    return;
  }

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

class _LyricsSheet extends ConsumerStatefulWidget {
  const _LyricsSheet({required this.song, this.isDialog = false});

  final Song song;
  final bool isDialog;

  @override
  ConsumerState<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<_LyricsSheet> {
  SongLyrics? _lyrics;
  bool _loading = true;
  String? _error;
  bool _viewPlain = false;
  bool _showRomanization = false;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;
  bool _userIsScrolling = false;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await LyricsService.instance.getLyrics(widget.song);
      if (mounted) {
        if (result != null) {
          setState(() {
            _lyrics = result;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Lyrics not available for this track';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load lyrics';
          _loading = false;
        });
      }
    }
  }

  void _searchLyricsOnline() async {
    final clean = LyricsService.cleanTrackTitle(widget.song.title);
    final query = Uri.encodeComponent(
      '$clean ${widget.song.artistNames} lyrics',
    );
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _scrollToActive(int activeIndex) {
    if (!_scrollController.hasClients || _userIsScrolling || activeIndex < 0) {
      return;
    }
    const estimatedItemHeight = 56.0;
    final viewportHeight = _scrollController.position.hasViewportDimension
        ? _scrollController.position.viewportDimension
        : 400.0;
    final viewportCenter = viewportHeight / 2;
    final targetOffset =
        (activeIndex * estimatedItemHeight) + 24.0 - (viewportCenter - estimatedItemHeight / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionAsync = ref.watch(trackPositionProvider);
    final currentPosition = positionAsync.asData?.value ?? Duration.zero;

    final lyrics = _lyrics;
    int activeIndex = -1;

    if (lyrics != null && lyrics.isSynced && lyrics.syncedLines.isNotEmpty) {
      for (int i = 0; i < lyrics.syncedLines.length; i++) {
        if (currentPosition >= lyrics.syncedLines[i].timestamp) {
          activeIndex = i;
        } else {
          break;
        }
      }

      if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
        _lastActiveIndex = activeIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActive(activeIndex);
        });
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final sheetHeight = isWide
            ? MediaQuery.sizeOf(context).height * 0.82
            : MediaQuery.sizeOf(context).height * 0.88;

        final surfaceColor = isDark ? const Color(0xFF10101A) : const Color(0xFFF8FAFD);
        final borderRadius = widget.isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(28));

        return Align(
          alignment: widget.isDialog ? Alignment.center : Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.isDialog ? 680 : (isWide ? 780 : double.infinity),
              maxHeight: sheetHeight,
            ),
            child: Material(
              color: surfaceColor,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    // Drag Handle (mobile sheet only)
                    if (!widget.isDialog)
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
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
                                  ),
                                  if (lyrics != null && lyrics.isSynced) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EuBrutal.accent.withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: EuBrutal.accent.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'SYNCED',
                                        style: TextStyle(
                                          color: EuBrutal.accent,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Romanization Toggle (Romaji / Phonetic)
                        if (lyrics != null &&
                            (Romanizer.hasAsianScript(lyrics.plainLyrics ?? '') ||
                                lyrics.syncedLines
                                    .any((l) => Romanizer.hasAsianScript(l.text))))
                          IconButton(
                            tooltip: _showRomanization
                                ? 'Original Script'
                                : 'Phonetic Romanization (Romaji)',
                            icon: Icon(
                              _showRomanization
                                  ? Icons.translate_rounded
                                  : Icons.translate_outlined,
                              color: _showRomanization
                                  ? EuBrutal.accent
                                  : (isDark ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _showRomanization = !_showRomanization);
                            },
                          ),

                        // Toggle between Synced & Plain mode
                        if (lyrics != null && lyrics.isSynced)
                          IconButton(
                            tooltip: _viewPlain ? 'Karaoke View' : 'Full Plain Text',
                            icon: Icon(
                              _viewPlain
                                  ? Icons.format_align_left_rounded
                                  : Icons.sync_alt_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _viewPlain = !_viewPlain);
                            },
                          ),

                        // Copy Lyrics
                        if (lyrics != null && lyrics.plainLyrics != null)
                          IconButton(
                            tooltip: 'Copy Lyrics',
                            icon: Icon(
                              Icons.copy_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: lyrics.plainLyrics!),
                              );
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
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.70)
                                        : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Try Again'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
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
                                            icon: const Icon(
                                              Icons.travel_explore_rounded,
                                              size: 16,
                                            ),
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
                            : lyrics != null && lyrics.isSynced && !_viewPlain
                                ? NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification.depth == 0) {
                                        if (notification is ScrollStartNotification &&
                                            notification.dragDetails != null) {
                                          _userIsScrolling = true;
                                        } else if (notification is ScrollEndNotification &&
                                            notification.dragDetails != null) {
                                          Future.delayed(
                                            const Duration(milliseconds: 1800),
                                            () {
                                              if (mounted) {
                                                _userIsScrolling = false;
                                              }
                                            },
                                          );
                                        }
                                      }
                                      return false;
                                    },
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.fromLTRB(
                                        EuSpace.xl,
                                        EuSpace.xl,
                                        EuSpace.xl,
                                        EuSpace.xl + MediaQuery.of(context).viewPadding.bottom,
                                      ),
                                      itemCount: lyrics.syncedLines.length,
                                      itemBuilder: (context, index) {
                                        final line = lyrics.syncedLines[index];
                                        final isActive = index == activeIndex;

                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            ref
                                                .read(playerControllerProvider)
                                                .seek(line.timestamp);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeOutCubic,
                                            margin: const EdgeInsets.symmetric(vertical: 7),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? EuBrutal.accent.withValues(alpha: isDark ? 0.22 : 0.12)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              border: isActive
                                                  ? Border.all(
                                                      color: EuBrutal.accent.withValues(alpha: 0.5),
                                                      width: 1.2,
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  line.text.isEmpty ? '♪' : line.text,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: isActive ? 21.0 : 16.5,
                                                    fontWeight: isActive
                                                        ? FontWeight.w900
                                                        : FontWeight.w600,
                                                    letterSpacing: isActive ? 0.3 : 0.1,
                                                    color: isActive
                                                        ? (isDark
                                                            ? Colors.white
                                                            : EuBrutal.accent)
                                                        : (isDark
                                                            ? Colors.white.withValues(alpha: 0.35)
                                                            : Colors.black.withValues(alpha: 0.35)),
                                                    height: 1.45,
                                                  ),
                                                ),
                                                if (_showRomanization &&
                                                    Romanizer.hasAsianScript(line.text)) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    Romanizer.romanize(line.text),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: isActive ? 14.0 : 11.5,
                                                      fontWeight: isActive
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      fontStyle: FontStyle.italic,
                                                      color: isActive
                                                          ? (isDark
                                                              ? EuBrutal.accent
                                                              : const Color(0xFF6D28D9))
                                                          : (isDark
                                                              ? Colors.white.withValues(alpha: 0.45)
                                                              : Colors.black45),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: EuSpace.xl,
                                      vertical: EuSpace.lg,
                                    ),
                                    child: SelectableText(
                                      _showRomanization
                                          ? Romanizer.romanize(
                                              lyrics?.plainLyrics ?? '',
                                            )
                                          : (lyrics?.plainLyrics ?? ''),
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
            ),
          ),
        ),
      );
    },
  );
}
}
