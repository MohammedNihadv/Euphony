import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/animated_waveform.dart';
import '../../domain/song.dart';
import '../../playback/download_provider.dart';
import '../../playback/player_provider.dart';
import '../../playback/sleep_timer_provider.dart';
import '../common/song_options_sheet.dart';
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
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(activeSongProvider);
    final theme = Theme.of(context);
    final isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: _GlassAppBar(song: song),
      body: song == null
          ? const _NothingPlaying()
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return _WideLayout(song: song, isPlaying: isPlaying);
                  }
                  return _NarrowLayout(song: song, isPlaying: isPlaying);
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
  const _GlassAppBar({required this.song});

  final Song? song;

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
                onPressed: () => showLyricsSheet(context, song!),
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
  const _NarrowLayout({required this.song, required this.isPlaying});

  final Song song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxArtSize = (MediaQuery.sizeOf(context).height * 0.38).clamp(
      150.0,
      360.0,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EuSpace.xl,
            vertical: EuSpace.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Artwork(song: song, artSize: maxArtSize, isPlaying: isPlaying),
              _TrackHeader(song: song),
              const _GlassScrubber(),
              const _TransportControls(),
              _GlassBottomActionBar(song: song),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideLayout extends ConsumerWidget {
  const _WideLayout({required this.song, required this.isPlaying});

  final Song song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artSize = (MediaQuery.sizeOf(context).height * 0.68)
        .clamp(240.0, 520.0)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EuSpace.xxxl,
        EuSpace.lg,
        EuSpace.xxxl,
        EuSpace.lg,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: _Artwork(song: song, artSize: artSize, isPlaying: isPlaying),
            ),
          ),
          const SizedBox(width: EuSpace.xxxl),
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
                    _GlassBottomActionBar(song: song),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              // ── Pulsing glow ring (glass layer) ──────────────────────
              _PulsingGlowRing(
                artSize: artSize,
                isPlaying: isPlaying,
                color: EuBrutal.accent,
              ),

              // ── Artwork slab (brutalist hard shadow + border) ──────────
              AnimatedScale(
                scale: isPlaying ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Container(
                  width: artSize - 12,
                  height: artSize - 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.eu.ink, width: 2),
                    boxShadow: [
                      // Brutalist hard offset
                      const BoxShadow(
                        color: EuBrutal.shadow,
                        offset: Offset(6, 6),
                      ),
                      // Glass accent glow
                      BoxShadow(
                        color: EuBrutal.accent.withValues(
                          alpha: isPlaying ? 0.25 : 0.0,
                        ),
                        blurRadius: 28,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: url == null
                      ? const Icon(Icons.music_note_rounded, size: 80)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.music_note_rounded, size: 80),
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
      duration: const Duration(milliseconds: 2200),
    );
    _glow = Tween<double>(begin: 0.08, end: 0.28).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
          duration: const Duration(milliseconds: 500),
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
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _glow.value),
              blurRadius: 36,
              spreadRadius: 4,
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

class _TrackHeader extends ConsumerWidget {
  const _TrackHeader({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: EuMotion.quick,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(song.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: EuSpace.xs),
                Text(
                  song.artistNames.isEmpty
                      ? 'Unknown Artist'
                      : song.artistNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.eu.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
        _DownloadButton(song: song),
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

    return StreamBuilder<bool>(
      stream: dao.watchIsLiked(song.id),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return _AnimatedIconButton(
          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isLiked ? EuBrutal.alert : null,
          onPressed: () {
            if (isLiked) {
              dao.unlike(song.id);
            } else {
              dao.like(
                id: song.id,
                title: song.title,
                artists: song.artistNames,
                albumTitle: song.albumTitle,
                artworkUrl: song.artworkUrl,
                durationSeconds: song.duration?.inSeconds,
              );
            }
          },
        );
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
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            Text(
              '${(progress * 100).toInt()}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
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
          iconSize: 30,
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
                  trackHeight: 6,
                  activeTrackColor: EuBrutal.accent,
                  inactiveTrackColor:
                      theme.colorScheme.surfaceContainerHighest,
                  thumbColor: EuBrutal.accent,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ToggleButton(
          icon: Icons.shuffle_rounded,
          active: shuffle,
          tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
          onPressed: () => ref.read(shuffleModeProvider.notifier).toggle(),
        ),
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous',
          onPressed: controller.skipPrevious,
        ),
        _LargePlayButton(isPlaying: isPlaying, isBuffering: isBuffering),
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next',
          onPressed: controller.skipNext,
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
    );
  }
}

/// The big central play/pause — brutalist circle with glass-accent glow.
class _LargePlayButton extends ConsumerWidget {
  const _LargePlayButton({
    required this.isPlaying,
    required this.isBuffering,
  });

  final bool isPlaying;
  final bool isBuffering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: ref.read(playerControllerProvider).togglePlayPause,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            // Brutalist: gradient accent fill
            gradient: const LinearGradient(
              colors: [EuBrutal.accent, EuBrutal.accentDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            // Hard shadow (brutalist) + soft glow (glass)
            boxShadow: [
              const BoxShadow(color: EuBrutal.shadow, offset: Offset(4, 4)),
              BoxShadow(
                color: EuBrutal.accent.withValues(
                  alpha: isPlaying ? 0.45 : 0.15,
                ),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: isBuffering
              ? const Padding(
                  padding: EdgeInsets.all(EuSpace.lg),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: EuBrutal.onAccent,
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
                    size: 40,
                    color: EuBrutal.onAccent,
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: active ? EuBrutal.accent : Colors.transparent,
        foregroundColor: active
            ? EuBrutal.onAccent
            : context.eu.ink.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: active ? context.eu.thinSide : BorderSide.none,
        ),
        // Brutalist hard shadow when active
        shadowColor: active ? EuBrutal.shadow : Colors.transparent,
        elevation: active ? 0 : 0,
      ),
      icon: Icon(icon),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass Bottom Action Bar — glass panel + brutalist border
// ---------------------------------------------------------------------------

class _GlassBottomActionBar extends ConsumerWidget {
  const _GlassBottomActionBar({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepTimer = ref.watch(sleepTimerProvider);
    final currentSpeed = ref.watch(playbackSpeedProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            // Glass fill
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            // Brutalist 2px border
            border: Border.all(color: context.eu.ink, width: 2),
            // Hard shadow (brutalist) + soft glow
            boxShadow: [
              const BoxShadow(color: EuBrutal.shadow, offset: Offset(3, 3)),
            ],
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
                onPressed: () => _showSpeedSheet(context, ref),
              ),
              _BarButton(
                icon: Icons.lyrics_outlined,
                tooltip: 'Lyrics',
                onPressed: () => showLyricsSheet(context, song),
              ),
              // Live waveform badge or queue button
              isPlaying
                  ? GestureDetector(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isActive ? EuBrutal.accent : Theme.of(context).iconTheme.color,
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
  const _SpeedBadge({required this.speed, required this.onPressed});

  final double speed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isCustom = speed != 1.0;
    return Tooltip(
      message: 'Playback Speed',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isCustom
                ? EuBrutal.highlight
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCustom ? EuBrutal.onHighlight : context.eu.ink,
              width: isCustom ? 1.5 : 1,
            ),
            boxShadow: isCustom ? EuBrutal.smHardShadow : null,
          ),
          child: Text(
            '${speed}x',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isCustom
                  ? EuBrutal.onHighlight
                  : Theme.of(context).textTheme.bodyMedium?.color,
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
  final currentSpeed = ref.read(playbackSpeedProvider);
  final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  final inkColor = context.eu.ink;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: inkColor, width: 2.5),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(EuSpace.lg),
              child: Text(
                'PLAYBACK SPEED',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            for (final speed in speeds)
              ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    fontWeight: speed == currentSpeed
                        ? FontWeight.w900
                        : FontWeight.w700,
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
            const SizedBox(height: EuSpace.md),
          ],
        ),
      ),
    ),
  );
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final currentPreset = ref.read(sleepTimerProvider).preset;
  final inkColor = context.eu.ink;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: inkColor, width: 2.5),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(EuSpace.lg),
              child: Text(
                'SLEEP TIMER',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            for (final preset in SleepTimerPreset.values)
              ListTile(
                title: Text(
                  preset.label,
                  style: TextStyle(
                    fontWeight: preset == currentPreset
                        ? FontWeight.w900
                        : FontWeight.w700,
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
            const SizedBox(height: EuSpace.md),
          ],
        ),
      ),
    ),
  );
}
