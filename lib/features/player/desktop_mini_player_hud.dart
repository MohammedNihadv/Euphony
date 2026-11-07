import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../playback/desktop_media_controls.dart';
import '../../playback/player_provider.dart';
import 'player_screen.dart';

/// Compact floating Picture-in-Picture mini player for Desktop (Windows/macOS/Linux).
///
/// Displayed when the desktop window is shrunk to floating mini-mode ($380 \times 135\text{px}$).
/// Provides full transport controls, live scrubber, volume scroll, and one-tap restore.
class DesktopMiniPlayerHud extends ConsumerWidget {
  const DesktopMiniPlayerHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(activeSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final controller = ref.read(playerControllerProvider);
    final volumeNotifier = ref.read(playerVolumeProvider.notifier);

    final positionAsync = ref.watch(trackPositionProvider);
    final currentPosition = positionAsync.asData?.value ?? Duration.zero;
    final totalDuration = ref.watch(totalDurationProvider);

    final Duration effectiveDuration =
        totalDuration ?? song?.duration ?? const Duration(minutes: 3, seconds: 30);
    final maxSeconds = effectiveDuration.inMilliseconds / 1000.0;
    final currentSeconds = (currentPosition.inMilliseconds / 1000.0)
        .clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);

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
          onDoubleTap: () => DesktopMediaControls().exitMiniPlayer(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF101018),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: App title & window action buttons
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: EuBrutal.accent,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Euphony Mini',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    // Minimize to tray
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      splashRadius: 14,
                      color: Colors.white60,
                      tooltip: 'Minimize to tray',
                      onPressed: () => DesktopMediaControls().minimizeToTray(),
                    ),
                    const SizedBox(width: 4),
                    // Expand back to full window
                    IconButton(
                      icon: const Icon(Icons.open_in_full_rounded, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      splashRadius: 14,
                      color: Colors.white60,
                      tooltip: 'Expand window',
                      onPressed: () => DesktopMediaControls().exitMiniPlayer(),
                    ),
                  ],
                ),

                // Middle row: Artwork, metadata, transport controls
                Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: (song?.artworkUrl != null && song!.artworkUrl!.isNotEmpty)
                            ? Image.network(
                                song.artworkUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFF1A1A28),
                                  child: const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white30,
                                    size: 22,
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF1A1A28),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white30,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song?.title ?? 'No Track Playing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song?.artistNames ?? 'Euphony Desktop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transport Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          splashRadius: 16,
                          color: song != null ? Colors.white : Colors.white24,
                          tooltip: 'Previous',
                          onPressed: song != null ? controller.skipPrevious : null,
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: EuBrutal.accent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 19,
                            ),
                            padding: EdgeInsets.zero,
                            color: Colors.black,
                            tooltip: isPlaying ? 'Pause' : 'Play',
                            onPressed: song != null
                                ? () => controller.togglePlayPause()
                                : null,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          splashRadius: 16,
                          color: song != null ? Colors.white : Colors.white24,
                          tooltip: 'Next',
                          onPressed: song != null ? controller.skipNext : null,
                        ),
                      ],
                    ),
                  ],
                ),

                // Bottom row: Scrubber progress bar & timestamps
                SizedBox(
                  height: 18,
                  child: Row(
                    children: [
                      Text(
                        formatPlaybackDuration(Duration(seconds: currentSeconds.round())),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 8,
                            ),
                            activeTrackColor: EuBrutal.accent,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: EuBrutal.accent,
                          ),
                          child: Slider(
                            value: currentSeconds.clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0),
                            max: maxSeconds > 0 ? maxSeconds : 1.0,
                            onChanged: song != null
                                ? (val) {
                                    controller.seek(Duration(seconds: val.round()));
                                  }
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatPlaybackDuration(Duration(seconds: maxSeconds.round())),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
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
