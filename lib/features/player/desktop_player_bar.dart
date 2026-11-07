import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import 'lyrics_sheet.dart';
import 'player_screen.dart';
import 'queue_sheet.dart';

/// A full-featured desktop player bar that spans the bottom of the window.
///
/// Designed with Neo-Brutalism + Frosted Glass aesthetics:
/// - Left: Track artwork with hover zoom, title, artist, and reactive Like heart.
/// - Center: Full transport controls (Shuffle, Prev, Play/Pause, Next, Repeat)
///   plus an interactive scrubbable timeline with numeric timestamps.
/// - Right: Lyrics, Queue, and Fullscreen shortcuts, alongside a volume slider
///   with instant Mute toggle and mouse-wheel scrolling support.
class DesktopPlayerBar extends ConsumerStatefulWidget {
  const DesktopPlayerBar({super.key});

  @override
  ConsumerState<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends ConsumerState<DesktopPlayerBar> {
  double? _dragPositionSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Song? song = ref.watch(activeSongProvider);
    final bool isPlaying = ref.watch(isPlayingProvider);
    final bool isBuffering = ref.watch(isBufferingProvider);
    final AsyncValue<Duration> positionAsync = ref.watch(trackPositionProvider);
    final Duration currentPosition = positionAsync.asData?.value ?? Duration.zero;
    final Duration? totalDuration = ref.watch(totalDurationProvider);
    final bool shuffleEnabled = ref.watch(shuffleModeProvider);
    final LoopMode repeatMode = ref.watch(repeatModeProvider);
    final double volume = ref.watch(playerVolumeProvider);

    final Duration effectiveDuration =
        totalDuration ?? song?.duration ?? const Duration(minutes: 3, seconds: 30);
    final double maxSeconds = effectiveDuration.inMilliseconds / 1000.0;

    final double displayedSeconds = _dragPositionSeconds ??
        (currentPosition.inMilliseconds / 1000.0).clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: context.eu.divider, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: song == null
              ? _buildEmptyState(context)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Left: Track info & Like button ──────────────────────
                    SizedBox(
                      width: 280,
                      child: _LeftTrackSection(song: song),
                    ),

                    const SizedBox(width: 16),

                    // ── Center: Transport controls & scrubber ───────────────
                    Expanded(
                      child: _CenterTransportSection(
                        song: song,
                        isPlaying: isPlaying,
                        isBuffering: isBuffering,
                        shuffleEnabled: shuffleEnabled,
                        repeatMode: repeatMode,
                        displayedSeconds: displayedSeconds,
                        maxSeconds: maxSeconds,
                        onSeekChanged: (val) {
                          setState(() => _dragPositionSeconds = val);
                        },
                        onSeekEnded: (val) {
                          setState(() => _dragPositionSeconds = null);
                          ref
                              .read(playerControllerProvider)
                              .seek(Duration(milliseconds: (val * 1000).round()));
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ── Right: Volume, Queue, Lyrics, Fullscreen ────────────
                    SizedBox(
                      width: 290,
                      child: _RightUtilitySection(
                        song: song,
                        volume: volume,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 20,
            color: context.eu.ink.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            'Select a song or album to begin playing',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.eu.ink.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left: Artwork, Track Title, Artist, and Like Button
// ---------------------------------------------------------------------------

class _LeftTrackSection extends ConsumerStatefulWidget {
  const _LeftTrackSection({required this.song});

  final Song song;

  @override
  ConsumerState<_LeftTrackSection> createState() => _LeftTrackSectionState();
}

class _LeftTrackSectionState extends ConsumerState<_LeftTrackSection> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final dao = ref.watch(likedSongsDaoProvider);

    return Row(
      children: [
        // Artwork thumbnail
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(buildPlayerRoute()),
            child: Tooltip(
              message: 'Expand player (F)',
              child: AnimatedContainer(
                duration: EuMotion.quick,
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.eu.ink, width: 1.5),
                  boxShadow: _isHovered ? EuBrutal.smHardShadow : null,
                  color: Colors.black12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty)
                        Image.network(
                          song.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.music_note_rounded),
                        )
                      else
                        const Icon(Icons.music_note_rounded),
                      if (_isHovered)
                        Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Text title & artist
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: song.title,
                waitDuration: const Duration(milliseconds: 600),
                child: InkWell(
                  onTap: () => Navigator.of(context, rootNavigator: true).push(buildPlayerRoute()),
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                song.artistNames,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.eu.ink.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Reactive Like Button
        StreamBuilder<bool>(
          stream: dao.watchIsLiked(song.id),
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;
            return IconButton(
              icon: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
              ),
              color: isLiked ? EuBrutal.alert : context.eu.ink.withValues(alpha: 0.7),
              tooltip: isLiked ? 'Unlike' : 'Like',
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
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Center: Transport Controls & Scrubber Slider
// ---------------------------------------------------------------------------

class _CenterTransportSection extends ConsumerWidget {
  const _CenterTransportSection({
    required this.song,
    required this.isPlaying,
    required this.isBuffering,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.displayedSeconds,
    required this.maxSeconds,
    required this.onSeekChanged,
    required this.onSeekEnded,
  });

  final Song song;
  final bool isPlaying;
  final bool isBuffering;
  final bool shuffleEnabled;
  final LoopMode repeatMode;
  final double displayedSeconds;
  final double maxSeconds;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Controls row ───────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              iconSize: 19,
              color: shuffleEnabled ? EuBrutal.accent : context.eu.ink.withValues(alpha: 0.6),
              tooltip: 'Shuffle (S)',
              onPressed: () => ref.read(shuffleModeProvider.notifier).toggle(),
            ),

            const SizedBox(width: 4),

            // Previous
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 26,
              color: context.eu.ink,
              tooltip: 'Previous (Ctrl+Left)',
              onPressed: controller.skipPrevious,
            ),

            const SizedBox(width: 8),

            // Play / Pause (Circular Neo-Brutalist button)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: controller.togglePlayPause,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EuBrutal.accent,
                    border: Border.all(color: context.eu.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EuBrutal.onAccent,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 24,
                            color: EuBrutal.onAccent,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Next
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 26,
              color: context.eu.ink,
              tooltip: 'Next (Ctrl+Right)',
              onPressed: controller.skipNext,
            ),

            const SizedBox(width: 4),

            // Repeat
            IconButton(
              icon: Icon(
                repeatMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              ),
              iconSize: 19,
              color: repeatMode != LoopMode.off
                  ? EuBrutal.accent
                  : context.eu.ink.withValues(alpha: 0.6),
              tooltip: 'Repeat (R)',
              onPressed: () => ref.read(repeatModeProvider.notifier).cycle(),
            ),
          ],
        ),

        // ── Scrubber slider row ─────────────────────────────────────────────
        SizedBox(
          height: 24,
          child: Row(
            children: [
              // Elapsed time
              SizedBox(
                width: 42,
                child: Text(
                  formatPlaybackDuration(Duration(seconds: displayedSeconds.round())),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w700,
                    color: context.eu.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Progress slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                      elevation: 2,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: EuBrutal.accent,
                    inactiveTrackColor: context.eu.ink.withValues(alpha: 0.16),
                    thumbColor: EuBrutal.accent,
                    overlayColor: EuBrutal.accent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: displayedSeconds.clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0),
                    max: maxSeconds > 0 ? maxSeconds : 1.0,
                    onChanged: onSeekChanged,
                    onChangeEnd: onSeekEnded,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Total duration
              SizedBox(
                width: 42,
                child: Text(
                  formatPlaybackDuration(Duration(seconds: maxSeconds.round())),
                  style: TextStyle(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w700,
                    color: context.eu.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Right: Volume Slider, Queue, Lyrics, Fullscreen
// ---------------------------------------------------------------------------

class _RightUtilitySection extends ConsumerWidget {
  const _RightUtilitySection({
    required this.song,
    required this.volume,
  });

  final Song song;
  final double volume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeNotifier = ref.read(playerVolumeProvider.notifier);

    final IconData volumeIcon = volume <= 0
        ? Icons.volume_off_rounded
        : volume < 0.4
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Lyrics toggle
        IconButton(
          icon: const Icon(Icons.lyrics_outlined),
          iconSize: 20,
          color: context.eu.ink.withValues(alpha: 0.75),
          tooltip: 'Lyrics (L)',
          onPressed: () => showLyricsSheet(context, song),
        ),

        // Queue toggle
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          iconSize: 20,
          color: context.eu.ink.withValues(alpha: 0.75),
          tooltip: 'Queue (Q)',
          onPressed: () => showQueueSheet(context),
        ),

        // Fullscreen player toggle
        IconButton(
          icon: const Icon(Icons.open_in_full_rounded),
          iconSize: 18,
          color: context.eu.ink.withValues(alpha: 0.75),
          tooltip: 'Full Player (F)',
          onPressed: () => Navigator.of(context, rootNavigator: true).push(buildPlayerRoute()),
        ),

        const SizedBox(width: 6),

        // Volume controller with Mouse Wheel support
        Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy < 0) {
                volumeNotifier.stepUp(0.04);
              } else if (pointerSignal.scrollDelta.dy > 0) {
                volumeNotifier.stepDown(0.04);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(volumeIcon),
                iconSize: 20,
                color: context.eu.ink.withValues(alpha: 0.8),
                tooltip: volume <= 0 ? 'Unmute (M)' : 'Mute (M)',
                onPressed: volumeNotifier.toggleMute,
              ),
              SizedBox(
                width: 95,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5.5,
                      elevation: 1,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: context.eu.ink.withValues(alpha: 0.85),
                    inactiveTrackColor: context.eu.ink.withValues(alpha: 0.18),
                    thumbColor: context.eu.ink,
                  ),
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: (v) => volumeNotifier.setVolume(v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
