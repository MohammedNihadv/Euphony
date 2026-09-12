import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/animated_waveform.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import 'player_screen.dart';

/// Mini player — **Neo-Brutalist shell, glass interior**.
///
/// Outer shell keeps the hard offset shadow and the bold 2px border that define
/// the brutalist language. Inside that slab, BackdropFilter frosted-glass fills
/// the surface instead of a flat color — a glass panel behind brutalist bars.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Song? song = ref.watch(activeSongProvider);
    final bool isPlaying = ref.watch(isPlayingProvider);
    final bool isBuffering = ref.watch(isBufferingProvider);
    final AsyncValue<Duration> positionAsync = ref.watch(trackPositionProvider);
    final Duration position = positionAsync.asData?.value ?? Duration.zero;
    final Duration? totalDuration = ref.watch(totalDurationProvider);

    if (song == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final total =
        totalDuration ??
        song.duration ??
        const Duration(minutes: 3, seconds: 30);
    final progress = total.inSeconds > 0
        ? (position.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: const ValueKey('mini-player'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => ref.read(playerControllerProvider).stop(),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(_buildPlayerRoute()),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EuSpace.md,
            0,
            EuSpace.md,
            EuSpace.md,
          ),
          child: _BrutalGlassSlab(
            isPlaying: isPlaying,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                  child: Row(
                    children: [
                      // ── Artwork ─────────────────────────────────────────
                      _MiniArtwork(song: song, isPlaying: isPlaying),
                      const SizedBox(width: EuSpace.md),

                      // ── Track info ──────────────────────────────────────
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: EuMotion.quick,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: child,
                            ),
                          ),
                          child: _TrackInfo(key: ValueKey(song.id), song: song),
                        ),
                      ),

                      // ── Waveform (playing only) ─────────────────────────
                      AnimatedSize(
                        duration: EuMotion.quick,
                        child: isPlaying && !isBuffering
                            ? const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 6),
                                child: AnimatedWaveform(
                                  playing: true,
                                  color: EuBrutal.accent,
                                  height: 20,
                                  width: 18,
                                  barWidth: 2.5,
                                  gap: 1.5,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // ── Play / pause ────────────────────────────────────
                      _SpringPlayButton(
                        isPlaying: isPlaying,
                        isBuffering: isBuffering,
                        onTap: () =>
                            ref.read(playerControllerProvider).togglePlayPause(),
                      ),

                      // ── Skip next ───────────────────────────────────────
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 26),
                        onPressed: () =>
                            ref.read(playerControllerProvider).skipNext(),
                      ),

                      // ── Close ───────────────────────────────────────────
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.eu.ink.withValues(alpha: 0.4),
                        ),
                        tooltip: 'Stop',
                        onPressed: () =>
                            ref.read(playerControllerProvider).stop(),
                      ),
                    ],
                  ),
                ),

                // ── Gradient progress bar (brutalist base, gradient fill) ──
                _GradientProgressBar(
                  progress: progress.toDouble(),
                  primaryColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BrutalGlassSlab — the outer brutalist frame with glass fill
// ---------------------------------------------------------------------------

/// The key hybrid widget: hard offset shadow + 2px border (Neo-Brutalism)
/// wrapping a frosted-glass BackdropFilter fill (Glassmorphism).
class _BrutalGlassSlab extends StatelessWidget {
  const _BrutalGlassSlab({required this.child, required this.isPlaying});

  final Widget child;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // ── Brutalist hard offset shadow ──────────────────────────────────
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Classic Neo-Brutalist hard offset
          const BoxShadow(color: EuBrutal.shadow, offset: Offset(4, 4)),
          // Subtle accent glow when playing (glass layer bonus)
          if (isPlaying)
            BoxShadow(
              color: EuBrutal.accent.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: -4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          // ── Glass layer: blur the content behind the slab ─────────────
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // Semi-transparent fill — the "glass" inside the brutalist frame
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              // ── Bold 2px Neo-Brutalist border ──────────────────────────
              border: Border.all(
                color: context.eu.ink,
                width: 2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MiniArtwork
// ---------------------------------------------------------------------------

class _MiniArtwork extends StatelessWidget {
  const _MiniArtwork({required this.song, required this.isPlaying});

  final Song song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: EuMotion.standard,
      child: Container(
        key: ValueKey(song.id),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          // Brutalist border on the artwork thumbnail
          border: Border.all(color: context.eu.ink, width: 2),
          color: theme.colorScheme.surfaceContainerHighest,
          // Glass-accent glow when playing
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: EuBrutal.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : EuBrutal.smHardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: song.artworkUrl != null
            ? Image.network(
                song.artworkUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.music_note_rounded),
              )
            : const Icon(Icons.music_note_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TrackInfo
// ---------------------------------------------------------------------------

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          song.artistNames.isEmpty ? 'Unknown Artist' : song.artistNames,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.eu.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _SpringPlayButton — Brutalist shape + spring tap animation
// ---------------------------------------------------------------------------

class _SpringPlayButton extends StatefulWidget {
  const _SpringPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  @override
  State<_SpringPlayButton> createState() => _SpringPlayButtonState();
}

class _SpringPlayButtonState extends State<_SpringPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      value: 1.0,
      lowerBound: 0.82,
      upperBound: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.animateTo(0.82,
        curve: Curves.easeIn,
        duration: const Duration(milliseconds: 80));
    widget.onTap();
    await _ctrl.animateTo(1.0,
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            // ── Brutalist accent fill + gradient glass shimmer ─────────
            gradient: const LinearGradient(
              colors: [EuBrutal.accent, EuBrutal.accentDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            // Hard shadow + soft glow — brutalist meets glass
            boxShadow: [
              const BoxShadow(
                color: EuBrutal.shadow,
                offset: Offset(2, 2),
              ),
              BoxShadow(
                color: EuBrutal.accent.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: widget.isBuffering
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
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
                    key: ValueKey(widget.isPlaying),
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GradientProgressBar — Brutalist bottom rail with gradient fill
// ---------------------------------------------------------------------------

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.progress,
    required this.primaryColor,
  });

  final double progress;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                // Track background
                Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                // Gradient fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [EuBrutal.accent, primaryColor.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Route builder
// ---------------------------------------------------------------------------

PageRouteBuilder<void> _buildPlayerRoute() {
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
