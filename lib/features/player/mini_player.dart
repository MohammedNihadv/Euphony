import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import 'player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Song? song = ref.watch(activeSongProvider);
    final bool isPlaying = ref.watch(isPlayingProvider);
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
      onDismissed: (_) {
        ref.read(playerControllerProvider).stop();
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(_buildPlayerRoute()),
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            EuSpace.md,
            0,
            EuSpace.md,
            EuSpace.md,
          ),
          decoration: EuBrutal.boxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            shadows: EuBrutal.hardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(EuSpace.sm),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: EuMotion.quick,
                      child: Container(
                        key: ValueKey(song.id),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.eu.ink, width: 2),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: song.artworkUrl != null
                            ? Image.network(
                                song.artworkUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.music_note),
                              )
                            : const Icon(Icons.music_note),
                      ),
                    ),
                    const SizedBox(width: EuSpace.md),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: EuMotion.quick,
                        child: Column(
                          key: ValueKey(song.id),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artistNames.isEmpty
                                  ? 'Unknown Artist'
                                  : song.artistNames,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.eu.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 36,
                        color: EuBrutal.accent,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider).togglePlayPause();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      onPressed: () {
                        ref.read(playerControllerProvider).skipNext();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: context.eu.ink.withValues(alpha: 0.5),
                      ),
                      tooltip: 'Stop',
                      onPressed: () {
                        ref.read(playerControllerProvider).stop();
                      },
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
              ),
              ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: EuBrutal.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
