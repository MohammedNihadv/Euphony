import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../design/widgets/animated_waveform.dart';
import '../../playback/player_provider.dart';
import 'player_screen.dart';

/// Opens the play queue with a glassmorphic sheet or centered desktop dialog.
Future<void> showQueueSheet(BuildContext context) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 700;
  if (isDesktop) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: const QueueSheet(isDialog: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => const QueueSheet(),
  );
}

/// The play queue: what is coming, in the order it will actually play.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key, this.isDialog = false});

  final bool isDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final queue = ref.watch(queueProvider);
    final entries = queue.ordered;
    final surfaceColor = isDark ? const Color(0xFF13131E) : const Color(0xFFF8FAFD);

    Widget buildQueueContent({ScrollController? scrollController}) {
      return Material(
        color: surfaceColor,
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: isDialog
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Drag handle (mobile sheet only)
              if (!isDialog)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Header bar
              Padding(
                padding: EdgeInsets.fromLTRB(20, isDialog ? 16 : 8, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: EuBrutal.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.queue_music_rounded,
                        size: 18,
                        color: EuBrutal.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Up Next Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        '${entries.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (entries.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                        tooltip: 'Clear queue',
                        color: isDark ? Colors.white60 : Colors.black54,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(playerControllerProvider).stop();
                          Navigator.of(context).maybePop();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        isDialog ? Icons.close_rounded : Icons.keyboard_arrow_down_rounded,
                        size: isDialog ? 20 : 26,
                      ),
                      tooltip: 'Close',
                      color: isDark ? Colors.white60 : Colors.black54,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // Queue list
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The queue is empty',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        scrollController: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: entries.length,
                        onReorderItem: (oldIndex, newIndex) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(queueProvider.notifier)
                              .reorder(oldIndex, newIndex);
                        },
                        itemBuilder: (context, position) {
                          final (queueIndex, song) = entries[position];
                          final isCurrent = queueIndex == queue.currentIndex;
                          return Padding(
                            key: ValueKey('${song.id}-$queueIndex'),
                            padding: const EdgeInsets.only(bottom: 8),
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
        ),
      );
    }

    if (isDialog) {
      return buildQueueContent();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) =>
          buildQueueContent(scrollController: scrollController),
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
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                colors: [
                  EuBrutal.accent.withValues(alpha: isDark ? 0.28 : 0.20),
                  EuBrutal.accentDeep.withValues(alpha: isDark ? 0.12 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrent
            ? null
            : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? EuBrutal.accent.withValues(alpha: isDark ? 0.65 : 0.45)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06)),
          width: isCurrent ? 1.4 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: EuBrutal.accent.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(playerControllerProvider).playAt(queueIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Artwork thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: artworkUrl == null
                        ? const Icon(
                            Icons.music_note_rounded,
                            size: 22,
                            color: EuBrutal.accent,
                          )
                        : Image.network(
                            artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.music_note_rounded,
                              size: 22,
                              color: EuBrutal.accent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: isCurrent
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black87),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? EuBrutal.accent
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),

                // Live waveform for playing track or duration
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedWaveform(
                      playing: true,
                      color: EuBrutal.accent,
                      height: 18,
                      width: 16,
                      barWidth: 2.5,
                      gap: 1.5,
                    ),
                  )
                else if (duration != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      formatPlaybackDuration(duration!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),

                // Delete button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  tooltip: 'Remove',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(queueProvider.notifier)
                        .removeFromQueue(queueIndex);
                  },
                ),

                // Drag handle
                ReorderableDragStartListener(
                  index: position,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
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
