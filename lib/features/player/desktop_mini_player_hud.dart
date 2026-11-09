import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../playback/desktop_media_controls.dart';
import '../../playback/player_provider.dart';

/// Compact floating Picture-in-Picture mini player for Desktop (Windows/macOS/Linux).
///
/// Displayed as a sleek, borderless floating bar inspired by modern mini player designs.
/// Features artwork, track details, favorite toggle, transport controls, volume mute/scroll,
/// and an edge-to-edge interactive progress bar. Double-click or expand icon restores the full window.
class DesktopMiniPlayerHud extends ConsumerWidget {
  const DesktopMiniPlayerHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(activeSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final controller = ref.read(playerControllerProvider);
    final volume = ref.watch(playerVolumeProvider);
    final volumeNotifier = ref.read(playerVolumeProvider.notifier);

    final positionAsync = ref.watch(trackPositionProvider);
    final currentPosition = positionAsync.asData?.value ?? Duration.zero;
    final totalDuration = ref.watch(totalDurationProvider);

    final Duration effectiveDuration =
        totalDuration ?? song?.duration ?? const Duration(minutes: 3, seconds: 30);
    final maxSeconds = effectiveDuration.inMilliseconds / 1000.0;
    final currentSeconds = (currentPosition.inMilliseconds / 1000.0)
        .clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);
    final progressFraction = maxSeconds > 0 ? (currentSeconds / maxSeconds).clamp(0.0, 1.0) : 0.0;

    final isLiked = song != null
        ? (ref.watch(isSongLikedProvider(song.id)).value ?? false)
        : false;
    final dao = ref.watch(likedSongsDaoProvider);

    return Material(
      color: Colors.transparent,
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            if (pointerSignal.scrollDelta.dy < 0) {
              volumeNotifier.stepUp(0.04);
            } else if (pointerSignal.scrollDelta.dy > 0) {
              volumeNotifier.stepDown(0.04);
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => DesktopMediaControls().startDragging(),
          onDoubleTap: () => DesktopMediaControls().exitMiniPlayer(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Main Transport & Info Bar
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 2, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Artwork thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: (song?.artworkUrl != null && song!.artworkUrl!.isNotEmpty)
                                ? Image.network(
                                    song.artworkUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFF1A1A28),
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        color: Colors.white30,
                                        size: 18,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF1A1A28),
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      color: Colors.white30,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Song Title & Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song?.title ?? 'No Track Playing',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                song?.artistNames ?? 'Euphony',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.65),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                      // Heart / Favorite Button
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        color: isLiked ? EuBrutal.alert : Colors.white60,
                        tooltip: isLiked ? 'Unlike' : 'Like',
                        onPressed: song != null
                            ? () async {
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
                              }
                            : null,
                      ),

                      // Skip Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 21),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        color: song != null ? Colors.white70 : Colors.white24,
                        tooltip: 'Previous',
                        onPressed: song != null ? controller.skipPrevious : null,
                      ),
                      const SizedBox(width: 2),

                      // Big Play / Pause Button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: EuBrutal.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: EuBrutal.accent.withValues(alpha: 0.40),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          tooltip: isPlaying ? 'Pause' : 'Play',
                          onPressed: song != null
                              ? () => controller.togglePlayPause()
                              : null,
                        ),
                      ),
                      const SizedBox(width: 2),

                      // Skip Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 21),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        color: song != null ? Colors.white70 : Colors.white24,
                        tooltip: 'Next',
                        onPressed: song != null ? controller.skipNext : null,
                      ),

                      // Volume / Mute
                      IconButton(
                        icon: Icon(
                          volume <= 0.01
                              ? Icons.volume_off_rounded
                              : (volume < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        color: Colors.white60,
                        tooltip: volume <= 0.01 ? 'Unmute' : 'Mute',
                        onPressed: () {
                          if (volume <= 0.01) {
                            volumeNotifier.setVolume(0.7);
                          } else {
                            volumeNotifier.setVolume(0.0);
                          }
                        },
                      ),

                      // Expand / Restore Window
                      IconButton(
                        icon: const Icon(Icons.open_in_full_rounded, size: 14),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        color: Colors.white60,
                        tooltip: 'Restore window',
                        onPressed: () => DesktopMediaControls().exitMiniPlayer(),
                      ),
                      const SizedBox(width: 2),

                      // In-built Close ('X') button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 17),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        color: Colors.white60,
                        tooltip: 'Close mini player',
                        onPressed: () => DesktopMediaControls().closeMiniPlayer(),
                      ),
                    ],
                  ),
                ),
              ),

                // Bottom Edge Interactive Progress Scrubber
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          if (song != null && maxSeconds > 0) {
                            final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                            controller.seek(Duration(seconds: (fraction * maxSeconds).round()));
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          if (song != null && maxSeconds > 0) {
                            final fraction = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                            controller.seek(Duration(seconds: (fraction * maxSeconds).round()));
                          }
                        },
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 2.5,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progressFraction,
                                child: Container(
                                  color: EuBrutal.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
