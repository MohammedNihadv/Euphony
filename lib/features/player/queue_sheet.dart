import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../playback/player_provider.dart';
import 'player_screen.dart';

/// Opens the play queue.
Future<void> showQueueSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  builder: (_) => const QueueSheet(),
);

/// The play queue: what is coming, in the order it will actually play.
///
/// Lists [QueueState.ordered] rather than the raw queue, so with shuffle on it
/// shows the shuffled sequence instead of the album order the user is not
/// getting. Nothing in the app could show or edit the queue before this.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final queue = ref.watch(queueProvider);
    final entries = queue.ordered;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EuSpace.xl,
              EuSpace.lg,
              EuSpace.md,
              EuSpace.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'QUEUE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  '${entries.length} track${entries.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: EuBrutal.ink.withValues(alpha: 0.7),
                  ),
                ),
                if (entries.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.playlist_remove),
                    tooltip: 'Clear queue',
                    onPressed: () {
                      ref.read(playerControllerProvider).stop();
                      Navigator.of(context).maybePop();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'The queue is empty.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    scrollController: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      EuSpace.md,
                      0,
                      EuSpace.md,
                      EuSpace.xxl,
                    ),
                    itemCount: entries.length,
                    onReorderItem: (oldIndex, newIndex) => ref
                        .read(queueProvider.notifier)
                        .reorder(oldIndex, newIndex),
                    itemBuilder: (context, position) {
                      final (queueIndex, song) = entries[position];
                      final isCurrent = queueIndex == queue.currentIndex;
                      return Padding(
                        // The key must identify the track, not the row: a
                        // reorder changes positions but not identities.
                        key: ValueKey('${song.id}-$queueIndex'),
                        padding: const EdgeInsets.only(bottom: EuSpace.xs),
                        child: _QueueRow(
                          position: position,
                          queueIndex: queueIndex,
                          title: song.title,
                          subtitle: song.artistNames,
                          artworkUrl: song.artwork?.low ?? song.artworkUrl,
                          duration: song.duration,
                          isCurrent: isCurrent,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    required this.position,
    required this.queueIndex,
    required this.title,
    required this.subtitle,
    required this.artworkUrl,
    required this.duration,
    required this.isCurrent,
  });

  final int position;
  final int queueIndex;
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final Duration? duration;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: EuBrutal.boxDecoration(
        color: isCurrent
            ? EuBrutal.highlight
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        shadows: isCurrent ? EuBrutal.smHardShadow : const [],
        border: EuBrutal.thinBorder,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => ref.read(playerControllerProvider).playAt(queueIndex),
          child: Padding(
            padding: const EdgeInsets.all(EuSpace.xs),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: artworkUrl == null
                        ? const ColoredBox(
                            color: EuBrutal.accent,
                            child: Icon(
                              Icons.music_note,
                              color: EuBrutal.onAccent,
                            ),
                          )
                        : Image.network(
                            artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.music_note),
                          ),
                  ),
                ),
                const SizedBox(width: EuSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          // The playing row is marked by fill, an icon and
                          // weight — not colour alone.
                          color: isCurrent ? EuBrutal.onHighlight : null,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? EuBrutal.onHighlight.withValues(alpha: 0.75)
                                : EuBrutal.ink.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: EuSpace.xs),
                    child: Icon(
                      Icons.volume_up,
                      size: 18,
                      color: EuBrutal.onHighlight,
                    ),
                  )
                else if (duration != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: EuSpace.xs),
                    child: Text(
                      formatPlaybackDuration(duration!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EuBrutal.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove from queue',
                  color: isCurrent ? EuBrutal.onHighlight : null,
                  onPressed: () => ref
                      .read(queueProvider.notifier)
                      .removeFromQueue(queueIndex),
                ),
                ReorderableDragStartListener(
                  index: position,
                  child: Icon(
                    Icons.drag_handle,
                    color: isCurrent
                        ? EuBrutal.onHighlight
                        : EuBrutal.ink.withValues(alpha: 0.5),
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
