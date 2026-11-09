import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/animated_waveform.dart';
import '../../domain/song.dart';
import '../../domain/song_details.dart';
import '../../playback/download_provider.dart';
import '../../playback/player_provider.dart';
import '../../playback/sleep_timer_provider.dart';
import '../common/song_options_sheet.dart';
import 'lyrics_service.dart';
import 'lyrics_sheet.dart';
import 'queue_sheet.dart';

/// Formats a duration as `m:ss`, or `h:mm:ss` past an hour.
String formatPlaybackDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// The full-screen player.
///
/// Visual language: **Neo-Brutalist shell, glass interior** — same hybrid as
/// the mini-player but with more room to breathe. Artwork gets a pulsing glow
/// ring when playing. Controls keep their brutalist hard shadows + bold borders.
/// Glass BackdropFilter fills the bottom action bar and the scrubber area.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLyrics() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final target = _scrollController.position.viewportDimension;
    if (currentOffset < target * 0.4) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(activeSongProvider);
    final theme = Theme.of(context);
    final isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: _GlassAppBar(
        song: song,
        onLyricsTap: _scrollToLyrics,
      ),
      body: song == null
          ? const _NothingPlaying()
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return _WideLayout(
                      song: song,
                      isPlaying: isPlaying,
                      scrollController: _scrollController,
                      onLyricsTap: _scrollToLyrics,
                      viewportHeight: constraints.maxHeight,
                    );
                  }
                  return _NarrowLayout(
                    song: song,
                    isPlaying: isPlaying,
                    scrollController: _scrollController,
                    onLyricsTap: _scrollToLyrics,
                    viewportHeight: constraints.maxHeight,
                  );
                },
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass AppBar
// ---------------------------------------------------------------------------

class _GlassAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _GlassAppBar({required this.song, this.onLyricsTap});

  final Song? song;
  final VoidCallback? onLyricsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
            tooltip: 'Close player',
          ),
          title: Text(
            'NOW PLAYING',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          actions: [
            if (song != null)
              IconButton(
                icon: const Icon(Icons.lyrics_outlined),
                tooltip: 'Lyrics',
                onPressed: onLyricsTap ?? () => showLyricsSheet(context, song!),
              ),
            IconButton(
              icon: const Icon(Icons.queue_music_rounded),
              tooltip: 'Queue',
              onPressed: () => showQueueSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout variants
// ---------------------------------------------------------------------------

class _NarrowLayout extends ConsumerWidget {
  const _NarrowLayout({
    required this.song,
    required this.isPlaying,
    required this.scrollController,
    required this.onLyricsTap,
    required this.viewportHeight,
  });

  final Song song;
  final bool isPlaying;
  final ScrollController scrollController;
  final VoidCallback onLyricsTap;
  final double viewportHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxArtSize = (viewportHeight * 0.36).clamp(180.0, 350.0);
    final minContentHeight = maxArtSize + 360.0;
    final foldHeight = viewportHeight < minContentHeight ? minContentHeight : viewportHeight;
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: EuSpace.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FOLD 1: Full-viewport Now Playing view
              SizedBox(
                height: foldHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: EuSpace.xs),
                    Center(
                      child: _Artwork(
                        song: song,
                        artSize: maxArtSize,
                        isPlaying: isPlaying,
                      ),
                    ),
                    const SizedBox(height: EuSpace.md),
                    _TrackHeader(song: song),
                    const SizedBox(height: EuSpace.md),
                    const _GlassScrubber(),
                    const SizedBox(height: EuSpace.sm),
                    const _TransportControls(),
                    const SizedBox(height: EuSpace.md),
                    _GlassBottomActionBar(
                      song: song,
                      onLyricsTap: onLyricsTap,
                    ),
                    const SizedBox(height: EuSpace.xs),
                    _ScrollToLyricsPrompt(
                      onTap: onLyricsTap,
                      label: 'Scroll to Lyrics & Info',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // FOLD 2: Below-the-fold content: Lyrics, Artist info, Song Details
              const SizedBox(height: EuSpace.lg),
              _EmbeddedLyricsCard(song: song, isFullHeight: false),
              const SizedBox(height: EuSpace.lg),
              _ArtistInfoCard(song: song),
              const SizedBox(height: EuSpace.lg),
              _SongDetailsCard(song: song),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideLayout extends ConsumerWidget {
  const _WideLayout({
    required this.song,
    required this.isPlaying,
    required this.scrollController,
    required this.onLyricsTap,
    required this.viewportHeight,
  });

  final Song song;
  final bool isPlaying;
  final ScrollController scrollController;
  final VoidCallback onLyricsTap;
  final double viewportHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldHeight = viewportHeight < 560.0 ? 560.0 : viewportHeight;
    final artSize = (foldHeight * 0.50).clamp(300.0, 440.0).toDouble();

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: EuSpace.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FOLD 1: Full-viewport Now Playing view on Desktop
              SizedBox(
                height: foldHeight,
                child: Column(
                  children: [
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Artwork with pulsing glow
                        Center(
                          child: _Artwork(
                            song: song,
                            artSize: artSize,
                            isPlaying: isPlaying,
                          ),
                        ),
                        const SizedBox(width: EuSpace.xxxl),
                        // Right: Track info, scrubber, transport controls, action bar
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TrackHeader(song: song),
                              const SizedBox(height: EuSpace.xl),
                              const _GlassScrubber(),
                              const SizedBox(height: EuSpace.lg),
                              const _TransportControls(),
                              const SizedBox(height: EuSpace.xl),
                              _GlassBottomActionBar(
                                song: song,
                                onLyricsTap: onLyricsTap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _ScrollToLyricsPrompt(
                      onTap: onLyricsTap,
                      label: 'Scroll to Lyrics & Info',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // FOLD 2: Below-the-fold content: Lyrics, Artist info, and Track Details
              const SizedBox(height: EuSpace.lg),
              _EmbeddedLyricsCard(song: song, isFullHeight: false),
              const SizedBox(height: EuSpace.xl),
              _ArtistInfoCard(song: song),
              const SizedBox(height: EuSpace.lg),
              _SongDetailsCard(song: song),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nothing playing
// ---------------------------------------------------------------------------

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(EuSpace.lg),
            decoration: EuBrutal.boxDecoration(
              color: EuBrutal.highlight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 48,
              color: EuBrutal.onHighlight,
            ),
          ),
          const SizedBox(height: EuSpace.lg),
          Text(
            'Nothing playing',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artwork — pulsing glow ring when playing, brutalist border slab
// ---------------------------------------------------------------------------

class _Artwork extends ConsumerWidget {
  const _Artwork({
    required this.song,
    required this.artSize,
    required this.isPlaying,
  });

  final Song song;
  final double artSize;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final url = song.artwork?.max ?? song.artworkUrl;

    return Center(
      child: AnimatedSwitcher(
        duration: EuMotion.standard,
        child: SizedBox(
          key: ValueKey(url ?? song.id),
          width: artSize,
          height: artSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Pulsing ambient aura behind artwork ───────────────────
              _PulsingGlowRing(
                artSize: artSize - 16,
                isPlaying: isPlaying,
                color: EuBrutal.accent,
              ),

              // ── Glassmorphic Artwork Slab ────────────────────────────
              AnimatedScale(
                scale: isPlaying ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: Container(
                  width: artSize - 16,
                  height: artSize - 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.80),
                      width: 1.2,
                    ),
                    boxShadow: [
                      // Smooth deep diffusion shadow
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.50 : 0.16,
                        ),
                        blurRadius: 32,
                        spreadRadius: -4,
                        offset: const Offset(0, 16),
                      ),
                      // Ambient accent illumination
                      BoxShadow(
                        color: EuBrutal.accent.withValues(
                          alpha: isPlaying ? 0.35 : 0.10,
                        ),
                        blurRadius: 40,
                        spreadRadius: -6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      url == null
                          ? Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: EuBrutal.accent.withValues(alpha: 0.6),
                              ),
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 80,
                                  color: EuBrutal.accent.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                      // Diagonal glass gloss sheen overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.35, 1.0],
                              colors: [
                                Colors.white.withValues(
                                  alpha: isDark ? 0.15 : 0.25,
                                ),
                                Colors.white.withValues(alpha: 0.02),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingGlowRing extends StatefulWidget {
  const _PulsingGlowRing({
    required this.artSize,
    required this.isPlaying,
    required this.color,
  });

  final double artSize;
  final bool isPlaying;
  final Color color;

  @override
  State<_PulsingGlowRing> createState() => _PulsingGlowRingState();
}

class _PulsingGlowRingState extends State<_PulsingGlowRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _glow = Tween<double>(
      begin: 0.10,
      end: 0.38,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingGlowRing old) {
    super.didUpdateWidget(old);
    if (old.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => Container(
        width: widget.artSize,
        height: widget.artSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(
                alpha: widget.isPlaying ? _glow.value : 0.08,
              ),
              blurRadius: 52,
              spreadRadius: 8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track Header
// ---------------------------------------------------------------------------

void _openArtist(BuildContext context, WidgetRef ref, Song song) {
  final details = ref.read(songDetailsProvider(song)).asData?.value;
  final artistId = details?.artistId ??
      (song.artists.isNotEmpty && song.artists.first.browseId != null
          ? song.artists.first.browseId
          : null);
  final artistName = song.artists.isNotEmpty
      ? song.artists.first.name
      : (song.artistNames.isNotEmpty ? song.artistNames : 'Artist');

  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  if (artistId != null && artistId.isNotEmpty) {
    context.push('/artist/$artistId');
  } else {
    context.push('/search?q=${Uri.encodeComponent(artistName)}');
  }
}

class _TrackHeader extends ConsumerWidget {
  const _TrackHeader({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: EuMotion.quick,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  ...previousChildren,
                  ?currentChild,
                ],
              );
            },
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey(song.id),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Authors / Artists Chip with avatar — clickable to open artist page
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openArtist(context, ref, song),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.14)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                song.artistNames.isEmpty
                                    ? 'Unknown Artist'
                                    : song.artistNames,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _DownloadButton(song: song),
        const SizedBox(width: 4),
        _LikeButton(song: song),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Like Button
// ---------------------------------------------------------------------------

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(likedSongsDaoProvider);
    final isLikedAsync = ref.watch(isSongLikedProvider(song.id));
    final isLiked = isLikedAsync.value ?? false;

    return _AnimatedIconButton(
      icon: isLiked
          ? Icons.favorite_rounded
          : Icons.favorite_border_rounded,
      color: isLiked ? EuBrutal.alert : null,
      onPressed: () async {
        try {
          if (isLiked) {
            await dao.unlike(song.id);
          } else {
            await dao.like(
              id: song.id,
              title: song.title,
              artists: song.artistNames,
              albumTitle: song.albumTitle,
              artworkUrl: song.artworkUrl,
              durationSeconds: song.duration?.inSeconds,
            );
          }
        } catch (_) {}
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Download Button
// ---------------------------------------------------------------------------

class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref
        .watch(downloadedSongsProvider)
        .any((s) => s.id == song.id);
    final progressMap = ref.watch(downloadProgressProvider);
    final progress = progressMap[song.id];

    if (progress != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: EuBrutal.accent,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            Text(
              '${(progress * 100).toInt()}',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    return _AnimatedIconButton(
      icon: isDownloaded
          ? Icons.check_circle_rounded
          : Icons.download_for_offline_outlined,
      color: isDownloaded ? Colors.green : null,
      onPressed: () {
        if (isDownloaded) {
          ref.read(downloadedSongsProvider.notifier).removeDownload(song.id);
        } else {
          ref.read(downloadedSongsProvider.notifier).downloadSong(song);
        }
      },
    );
  }
}

/// An icon button with a subtle scale-bounce on tap.
class _AnimatedIconButton extends StatefulWidget {
  const _AnimatedIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      value: 1.0,
      lowerBound: 0.78,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.animateTo(0.78, curve: Curves.easeIn);
    widget.onPressed();
    await _ctrl.animateTo(
      1.0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _ctrl,
        child: IconButton(
          iconSize: 24,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(widget.icon, color: widget.color),
          onPressed: _tap,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass Scrubber — glass panel wrapping the slider + timestamps
// ---------------------------------------------------------------------------

class _GlassScrubber extends ConsumerStatefulWidget {
  const _GlassScrubber();

  @override
  ConsumerState<_GlassScrubber> createState() => _GlassScrubberState();
}

class _GlassScrubberState extends ConsumerState<_GlassScrubber> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = ref.watch(trackPositionProvider).value ?? Duration.zero;
    final total = ref.watch(totalDurationProvider);

    final totalSeconds = (total?.inSeconds ?? 0).toDouble();
    final hasDuration = totalSeconds > 0;
    final value = (_dragValue ?? position.inSeconds.toDouble()).clamp(
      0.0,
      hasDuration ? totalSeconds : 1.0,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.eu.ink.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: EuBrutal.accent,
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    elevation: 3,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value,
                  max: hasDuration ? totalSeconds : 1.0,
                  onChanged: hasDuration
                      ? (next) => setState(() => _dragValue = next)
                      : null,
                  onChangeEnd: hasDuration
                      ? (next) {
                          ref
                              .read(playerControllerProvider)
                              .seek(Duration(seconds: next.round()));
                          setState(() => _dragValue = null);
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: EuSpace.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatPlaybackDuration(Duration(seconds: value.round())),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hasDuration ? formatPlaybackDuration(total!) : '--:--',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transport Controls — brutalist toggle buttons + large play button
// ---------------------------------------------------------------------------

class _TransportControls extends ConsumerWidget {
  const _TransportControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isBuffering = ref.watch(isBufferingProvider);
    final shuffle = ref.watch(shuffleModeProvider);
    final repeat = ref.watch(repeatModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ToggleButton(
            icon: Icons.shuffle_rounded,
            active: shuffle,
            tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
            onPressed: () => ref.read(shuffleModeProvider.notifier).toggle(),
          ),
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.skip_previous_rounded),
            tooltip: 'Previous',
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.skipPrevious();
            },
          ),
          _LargePlayButton(isPlaying: isPlaying, isBuffering: isBuffering),
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.skip_next_rounded),
            tooltip: 'Next',
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.skipNext();
            },
          ),
          _ToggleButton(
            icon: repeat == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            active: repeat != LoopMode.off,
            tooltip: switch (repeat) {
              LoopMode.off => 'Repeat off',
              LoopMode.all => 'Repeat queue',
              LoopMode.one => 'Repeat track',
            },
            onPressed: () => ref.read(repeatModeProvider.notifier).cycle(),
          ),
        ],
      ),
    );
  }
}

/// The big central play/pause — glowing glassmorphic button with ambient aura.
class _LargePlayButton extends ConsumerWidget {
  const _LargePlayButton({required this.isPlaying, required this.isBuffering});

  final bool isPlaying;
  final bool isBuffering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(playerControllerProvider).togglePlayPause();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: EuBrutal.accent.withValues(
                  alpha: isPlaying ? 0.45 : 0.18,
                ),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isBuffering
              ? const Padding(
                  padding: EdgeInsets.all(EuSpace.md),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    key: ValueKey(isPlaying),
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active
                ? EuBrutal.accent.withValues(alpha: 0.22)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? EuBrutal.accent.withValues(alpha: 0.8)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              width: 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: EuBrutal.accent.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: active
                ? EuBrutal.accent
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass Bottom Action Bar — glass panel + brutalist border
// ---------------------------------------------------------------------------

class _GlassBottomActionBar extends ConsumerWidget {
  const _GlassBottomActionBar({required this.song, this.onLyricsTap});

  final Song song;
  final VoidCallback? onLyricsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepTimer = ref.watch(sleepTimerProvider);
    final currentSpeed = ref.watch(playbackSpeedProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: isDark ? 0.05 : 0.02,
            ),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              // Translucent frosted glass
              color: isDark
                  ? const Color(0x80141422)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              // Specular rim border
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.90),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BarButton(
                  icon: Icons.playlist_add_rounded,
                  tooltip: 'Add to Playlist',
                  onPressed: () => showSongOptionsSheet(context, song),
                ),
                _BarButton(
                  icon: Icons.timer_outlined,
                  tooltip: 'Sleep Timer',
                  isActive: sleepTimer.isActive,
                  badgeText: sleepTimer.isActive ? 'ON' : null,
                  onPressed: () => _showSleepTimerSheet(context, ref),
                ),
                _SpeedBadge(
                  speed: currentSpeed,
                  isDark: isDark,
                  onPressed: () => _showSpeedSheet(context, ref),
                ),
                _BarButton(
                  icon: Icons.lyrics_outlined,
                  tooltip: 'Lyrics',
                  onPressed: onLyricsTap ?? () => showLyricsSheet(context, song),
                ),
                // Live waveform badge or queue button
                isPlaying
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showQueueSheet(context),
                        child: const Tooltip(
                          message: 'Queue',
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: AnimatedWaveform(
                              playing: true,
                              color: EuBrutal.accent,
                              height: 22,
                              width: 22,
                              barWidth: 3,
                              gap: 2,
                            ),
                          ),
                        ),
                      )
                    : _BarButton(
                        icon: Icons.queue_music_rounded,
                        tooltip: 'Queue',
                        onPressed: () => showQueueSheet(context),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.badgeText,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final String? badgeText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? EuBrutal.accent
                    : context.eu.ink.withValues(alpha: 0.75),
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 2),
                Text(
                  badgeText!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: EuBrutal.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({
    required this.speed,
    required this.isDark,
    required this.onPressed,
  });

  final double speed;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCustom = speed != 1.0;
    return Tooltip(
      message: 'Playback Speed',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isCustom
                ? EuBrutal.accent.withValues(alpha: isDark ? 0.35 : 0.18)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : context.eu.ink.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCustom
                  ? EuBrutal.accent
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : context.eu.ink.withValues(alpha: 0.10)),
              width: 1,
            ),
          ),
          child: Text(
            '${speed == speed.roundToDouble() ? speed.toInt() : speed}x',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: isCustom
                  ? EuBrutal.accent
                  : context.eu.ink.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheets — Speed & Sleep Timer
// ---------------------------------------------------------------------------

void _showSpeedSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final currentSpeed = ref.read(playbackSpeedProvider);
  final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  final isDesktop = MediaQuery.sizeOf(context).width >= 700;

  Widget buildContent() => Material(
    color: isDark ? const Color(0xFF141422) : Colors.white,
    borderRadius: isDesktop
        ? BorderRadius.circular(24)
        : const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EuSpace.lg,
              EuSpace.md,
              EuSpace.md,
              EuSpace.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded, size: 22, color: EuBrutal.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PLAYBACK SPEED',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: isDark ? Colors.white60 : Colors.black45,
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            thickness: 1,
            height: 1,
          ),
          for (final speed in speeds)
            ListTile(
              title: Text(
                '${speed}x',
                style: TextStyle(
                  fontWeight: speed == currentSpeed
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: speed == currentSpeed
                      ? EuBrutal.accent
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              trailing: speed == currentSpeed
                  ? const Icon(Icons.check_rounded, color: EuBrutal.accent)
                  : null,
              onTap: () {
                ref.read(playbackSpeedProvider.notifier).setSpeed(speed);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: EuSpace.sm),
        ],
      ),
    ),
  );

  if (isDesktop) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: buildContent(),
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
      builder: (_) => buildContent(),
    );
  }
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final currentPreset = ref.read(sleepTimerProvider).preset;
  final isDesktop = MediaQuery.sizeOf(context).width >= 700;

  Widget buildContent() => Material(
    color: isDark ? const Color(0xFF141422) : Colors.white,
    borderRadius: isDesktop
        ? BorderRadius.circular(24)
        : const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EuSpace.lg,
              EuSpace.md,
              EuSpace.md,
              EuSpace.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.bedtime_rounded, size: 22, color: EuBrutal.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SLEEP TIMER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isDesktop)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: isDark ? Colors.white60 : Colors.black45,
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            thickness: 1,
            height: 1,
          ),
          for (final preset in SleepTimerPreset.values)
            ListTile(
              title: Text(
                preset.label,
                style: TextStyle(
                  fontWeight: preset == currentPreset
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: preset == currentPreset
                      ? EuBrutal.accent
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              trailing: preset == currentPreset
                  ? const Icon(Icons.check_rounded, color: EuBrutal.accent)
                  : null,
              onTap: () {
                ref.read(sleepTimerProvider.notifier).setPreset(preset);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: EuSpace.sm),
        ],
      ),
    ),
  );

  if (isDesktop) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.40),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: buildContent(),
        ),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
      builder: (_) => buildContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Below-the-fold Embedded Cards: Lyrics, Artist, Song Details
// ---------------------------------------------------------------------------

class _ScrollToLyricsPrompt extends StatelessWidget {
  const _ScrollToLyricsPrompt({
    required this.onTap,
    this.label = 'Lyrics & Details',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : context.eu.ink.withValues(alpha: 0.65);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : context.eu.ink.withValues(alpha: 0.85);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmbeddedLyricsCard extends ConsumerStatefulWidget {
  const _EmbeddedLyricsCard({
    required this.song,
    this.isFullHeight = false,
  });

  final Song song;
  final bool isFullHeight;

  @override
  ConsumerState<_EmbeddedLyricsCard> createState() => _EmbeddedLyricsCardState();
}

class _EmbeddedLyricsCardState extends ConsumerState<_EmbeddedLyricsCard> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;
  bool _isUserScrolledAway = false;
  Timer? _resumeSyncTimer;

  @override
  void dispose() {
    _resumeSyncTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserScrollStart() {
    _resumeSyncTimer?.cancel();
    if (!_isUserScrolledAway) {
      setState(() => _isUserScrolledAway = true);
    }
  }

  void _onUserScrollEnd() {
    _resumeSyncTimer?.cancel();
    // After 2.5s of no scroll interaction, automatically re-center active playing line
    _resumeSyncTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _isUserScrolledAway) {
        setState(() => _isUserScrolledAway = false);
        _scrollToActive(_lastActiveIndex, force: true);
      }
    });
  }

  void _scrollToActive(int activeIndex, {bool force = false}) {
    if (!_scrollController.hasClients || activeIndex < 0) {
      return;
    }
    if (_isUserScrolledAway && !force) {
      return;
    }

    const itemHeight = 64.0;
    const topPadding = 120.0;
    final viewportHeight = _scrollController.position.hasViewportDimension
        ? _scrollController.position.viewportDimension
        : (widget.isFullHeight ? 520.0 : 380.0);
    final viewportCenter = viewportHeight / 2;
    final targetOffset =
        (activeIndex * itemHeight) + topPadding - (viewportCenter - itemHeight / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lyricsAsync = ref.watch(songLyricsProvider(widget.song));
    final position = ref.watch(trackPositionProvider).value ?? Duration.zero;

    return Container(
      width: double.infinity,
      height: widget.isFullHeight ? double.infinity : null,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF14121F).withValues(alpha: 0.88)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            offset: const Offset(0, 10),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EuBrutal.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lyrics_rounded,
                  size: 18,
                  color: EuBrutal.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Live Lyrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : context.eu.ink,
                  letterSpacing: -0.2,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // Share button
              IconButton(
                iconSize: 20,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.share_outlined,
                  color: isDark ? Colors.white70 : context.eu.ink.withValues(alpha: 0.70),
                ),
                tooltip: 'Copy lyrics',
                onPressed: () {
                  final SongLyrics? lyrics = lyricsAsync.asData?.value;
                  final textToShare = lyrics?.plainLyrics ??
                      lyrics?.syncedLines.map((LyricLine l) => l.text).join('\n');
                  if (textToShare != null && textToShare.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: textToShare));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lyrics copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              if (!widget.isFullHeight) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => showLyricsSheet(context, widget.song),
                  child: Text(
                    'Full Sheet',
                    style: TextStyle(
                      color: isDark ? Colors.white : context.eu.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Lyrics Body
          Expanded(
            flex: widget.isFullHeight ? 1 : 0,
            child: SizedBox(
              height: widget.isFullHeight ? null : 380.0,
              child: lyricsAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: EuBrutal.accent,
                    ),
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Lyrics not available for this track',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : context.eu.ink.withValues(alpha: 0.50),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                data: (lyrics) {
                  if (lyrics == null ||
                      (!lyrics.isSynced && (lyrics.plainLyrics == null || lyrics.plainLyrics!.isEmpty))) {
                    return Center(
                      child: Text(
                        'Lyrics not available for this track',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : context.eu.ink.withValues(alpha: 0.50),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Synced lyrics view
                  if (lyrics.isSynced && lyrics.syncedLines.isNotEmpty) {
                    int activeIndex = -1;
                    for (int i = 0; i < lyrics.syncedLines.length; i++) {
                      if (position >= lyrics.syncedLines[i].timestamp) {
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

                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              _onUserScrollStart();
                            } else if (notification is ScrollEndNotification) {
                              _onUserScrollEnd();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: 120,
                              horizontal: 4,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: lyrics.syncedLines.length,
                            itemBuilder: (context, index) {
                              final line = lyrics.syncedLines[index];
                              final isActive = index == activeIndex;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isUserScrolledAway = false);
                                      ref
                                          .read(playerControllerProvider)
                                          .seek(line.timestamp);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? (isDark
                                                ? Colors.white.withValues(alpha: 0.14)
                                                : EuBrutal.accent.withValues(alpha: 0.12))
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        border: isActive
                                            ? Border.all(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.24)
                                                    : EuBrutal.accent.withValues(alpha: 0.35),
                                                width: 1.2,
                                              )
                                            : null,
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: EuBrutal.accent.withValues(alpha: isDark ? 0.30 : 0.15),
                                                  blurRadius: 20,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 220),
                                        style: TextStyle(
                                          color: isActive
                                              ? (isDark ? Colors.white : Colors.black)
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.36)
                                                  : context.eu.ink.withValues(alpha: 0.36)),
                                          fontSize: isActive ? 24.0 : 19.0,
                                          fontWeight: isActive
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          letterSpacing: -0.2,
                                          height: 1.35,
                                          shadows: isActive
                                              ? [
                                                  Shadow(
                                                    color: EuBrutal.accent.withValues(
                                                      alpha: isDark ? 0.60 : 0.25,
                                                    ),
                                                    blurRadius: 18,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(line.text),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Floating sync button when user scrolls away
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          bottom: (_isUserScrolledAway && activeIndex >= 0) ? 16 : -70,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isUserScrolledAway = false);
                                _scrollToActive(activeIndex, force: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: EuBrutal.accent.withValues(alpha: 0.30),
                                      blurRadius: 14,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sync with playback',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Plain lyrics view — split into clean, bold, spaced rows like authentic lyrics
                  final lines = (lyrics.plainLyrics ?? '')
                      .split('\n')
                      .map((l) => l.trim())
                      .where((l) => l.isNotEmpty)
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Text(
                          lines[index],
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : context.eu.ink.withValues(alpha: 0.85),
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.45,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Footer
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lyricsAsync.asData?.value?.isSynced == true ? 'Line-synced' : 'Unsynced',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : context.eu.ink.withValues(alpha: 0.54),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : context.eu.ink.withValues(alpha: 0.24),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Provided by LRCLIB',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : context.eu.ink.withValues(alpha: 0.38),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistInfoCard extends ConsumerWidget {
  const _ArtistInfoCard({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailsAsync = ref.watch(songDetailsProvider(song));
    final SongDetails? details = detailsAsync.asData?.value;

    final artistName = details?.artistName ??
        (song.artistNames.isEmpty ? 'Artist' : song.artistNames);
    final subscribers = details?.artistSubscribers ?? 'Artist';
    final artworkUrl = details?.artistThumbnailUrl ??
        song.artwork?.max ??
        song.artworkUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141320).withValues(alpha: 0.88)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openArtist(context, ref, song),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Artwork with Scrim and Tag
                SizedBox(
                  height: 180,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (artworkUrl != null && artworkUrl.isNotEmpty)
                        Image.network(
                          artworkUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.black26,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: Colors.white38,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: Colors.white38,
                          ),
                        ),
                      // Scrim behind the Artists label
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // "ARTIST" label in top-left
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'ARTIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom artist name & subscribers
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : context.eu.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subscribers,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : context.eu.ink.withValues(alpha: 0.65),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : Colors.black.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: isDark ? Colors.white : context.eu.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: isDark ? Colors.white70 : context.eu.ink.withValues(alpha: 0.70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SongDetailsCard extends ConsumerStatefulWidget {
  const _SongDetailsCard({required this.song});

  final Song song;

  @override
  ConsumerState<_SongDetailsCard> createState() => _SongDetailsCardState();
}

class _SongDetailsCardState extends ConsumerState<_SongDetailsCard> {
  bool _expanded = false;

  String _formatCompactNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Duration? _parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) {
        return Duration(minutes: m, seconds: s);
      }
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    return null;
  }

  List<InlineSpan> _buildDescriptionSpans(String text, bool isDark, Color ink) {
    final spans = <InlineSpan>[];
    final combinedRegex = RegExp(
      r'((?:(?:\d{1,2}:)?\d{1,2}:\d{2})|https?://[^\s()]+(?:\([^\s()]+\)|[^\s`!()\[\]{};:\x27",<>?«»“”‘’]))',
    );

    final regularColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : ink.withValues(alpha: 0.85);
    final linkColor = isDark ? const Color(0xFF38BDF8) : EuBrutal.accent;

    int currentIndex = 0;
    for (final match in combinedRegex.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: TextStyle(
              color: regularColor,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        );
      }

      final matchText = match.group(0)!;
      final isUrl = matchText.startsWith('http://') || matchText.startsWith('https://');

      if (isUrl) {
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: linkColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
              height: 1.45,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final uri = Uri.tryParse(matchText);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
          ),
        );
      } else {
        // Timestamp
        spans.add(
          TextSpan(
            text: matchText,
            style: TextStyle(
              color: linkColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
              height: 1.45,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final dur = _parseTimestamp(matchText);
                if (dur != null) {
                  ref.read(playerControllerProvider).seek(dur);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seeking to $matchText'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
          ),
        );
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            color: regularColor,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color ink,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EuBrutal.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = context.eu.ink;
    final detailsAsync = ref.watch(songDetailsProvider(widget.song));
    final SongDetails? details = detailsAsync.asData?.value;

    final uploadDate = details?.uploadDate;
    final dateStr = uploadDate != null
        ? _formatDate(uploadDate)
        : (widget.song.year != null ? '${widget.song.year}' : null);

    final viewCount = details?.viewCount;
    final likeCount = details?.likeCount;

    final description = (details?.description ?? '').trim();
    final hasDescription = description.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141320).withValues(alpha: 0.88)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDark ? Colors.white : ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Track Details & Stats',
                style: TextStyle(
                  color: isDark ? Colors.white : ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stat Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (viewCount != null)
                _buildStatChip(
                  icon: Icons.play_arrow_rounded,
                  label: '${_formatCompactNumber(viewCount)} views',
                  isDark: isDark,
                  ink: ink,
                ),
              if (likeCount != null)
                _buildStatChip(
                  icon: Icons.thumb_up_rounded,
                  label: '${_formatCompactNumber(likeCount)} likes',
                  isDark: isDark,
                  ink: ink,
                ),
              if (dateStr != null)
                _buildStatChip(
                  icon: Icons.calendar_today_rounded,
                  label: dateStr,
                  isDark: isDark,
                  ink: ink,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Description content
          if (hasDescription) ...[
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text.rich(
                TextSpan(children: _buildDescriptionSpans(description, isDark, ink)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text.rich(
                TextSpan(children: _buildDescriptionSpans(description, isDark, ink)),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    color: EuBrutal.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ] else
            Text(
              detailsAsync.isLoading
                  ? 'Loading track description...'
                  : (widget.song.albumTitle != null
                      ? 'Album: ${widget.song.albumTitle}'
                      : 'No additional description for this track.'),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.60)
                    : ink.withValues(alpha: 0.60),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

PageRouteBuilder<void> buildPlayerRoute() {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const PlayerScreen(),
    transitionDuration: EuMotion.standard,
    reverseTransitionDuration: EuMotion.quick,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: EuMotion.emphasized,
        reverseCurve: EuMotion.emphasizedIn,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}
