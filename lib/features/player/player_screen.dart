import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
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
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(activeSongProvider);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
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
              onPressed: () => showLyricsSheet(context, song),
            ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Queue',
            onPressed: () => showQueueSheet(context),
          ),
        ],
      ),
      body: song == null
          ? const _NothingPlaying()
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Dynamically scale artwork so controls always fit on any screen ratio
                  // without overflow or requiring scrolling.
                  final maxArtSize = (constraints.maxHeight * 0.40).clamp(150.0, 360.0);

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
                            _Artwork(song: song, artSize: maxArtSize),
                            _TrackHeader(song: song),
                            const _Scrubber(),
                            const _TransportControls(),
                            _BottomActionBar(song: song),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

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
              Icons.music_note,
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
                  song.artistNames.isEmpty ? 'Unknown Artist' : song.artistNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: EuBrutal.ink.withValues(alpha: 0.7),
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
        return IconButton(
          iconSize: 32,
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? EuBrutal.alert : null,
          ),
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

class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded = ref.watch(downloadedSongsProvider).any((s) => s.id == song.id);
    final progressMap = ref.watch(downloadProgressProvider);
    final progress = progressMap[song.id];

    if (progress != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              color: EuBrutal.accent,
            ),
            Text(
              '${(progress * 100).toInt()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      iconSize: 32,
      icon: Icon(
        isDownloaded ? Icons.check_circle : Icons.download_for_offline_outlined,
        color: isDownloaded ? Colors.green : null,
      ),
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

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepTimer = ref.watch(sleepTimerProvider);
    final currentSpeed = ref.watch(playbackSpeedProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EuBrutal.ink, width: 2),
          boxShadow: EuBrutal.smHardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomIconButton(
              icon: Icons.playlist_add,
              tooltip: 'Add to Playlist',
              onPressed: () => showSongOptionsSheet(context, song),
            ),
            _BottomIconButton(
              icon: Icons.timer_outlined,
              tooltip: 'Sleep Timer',
              isActive: sleepTimer.isActive,
              badgeText: sleepTimer.isActive ? 'ON' : null,
              onPressed: () => _showSleepTimerSheet(context, ref),
            ),
            _SpeedButton(
              speed: currentSpeed,
              onPressed: () => _showSpeedSheet(context, ref),
            ),
            _BottomIconButton(
              icon: Icons.lyrics_outlined,
              tooltip: 'Lyrics',
              onPressed: () => showLyricsSheet(context, song),
            ),
            _BottomIconButton(
              icon: Icons.queue_music,
              tooltip: 'Queue',
              onPressed: () => showQueueSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  const _BottomIconButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.badgeText,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final String? badgeText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isActive ? EuBrutal.accent : themeData.iconTheme.color,
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

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.speed,
    required this.onPressed,
  });

  final double speed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isCustom = speed != 1.0;
    return Tooltip(
      message: 'Playback Speed',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCustom
                ? EuBrutal.highlight
                : themeData.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EuBrutal.ink, width: isCustom ? 1.5 : 1),
          ),
          child: Text(
            '${speed}x',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: isCustom
                  ? EuBrutal.ink
                  : themeData.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}

void _showSpeedSheet(BuildContext context, WidgetRef ref) {
  final currentSpeed = ref.read(playbackSpeedProvider);
  final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: EuBrutal.ink, width: 2.5),
    ),
    builder: (context) {
      return SafeArea(
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
                      ? const Icon(Icons.check, color: EuBrutal.accent)
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
      );
    },
  );
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final currentPreset = ref.read(sleepTimerProvider).preset;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: EuBrutal.ink, width: 2.5),
    ),
    builder: (context) {
      return SafeArea(
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
                      ? const Icon(Icons.check, color: EuBrutal.accent)
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
      );
    },
  );
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.song, required this.artSize});

  final Song song;
  final double artSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = song.artwork?.max ?? song.artworkUrl;

    return Center(
      child: AnimatedSwitcher(
        duration: EuMotion.standard,
        child: SizedBox(
          key: ValueKey(url ?? song.id),
          width: artSize,
          height: artSize,
          child: Container(
            decoration: EuBrutal.boxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              shadows: EuBrutal.lgHardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? const Icon(Icons.music_note, size: 80)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.music_note, size: 80),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Scrubber extends ConsumerStatefulWidget {
  const _Scrubber();

  @override
  ConsumerState<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends ConsumerState<_Scrubber> {
  /// Where the thumb sits while the user drags it.
  ///
  /// Without this the slider snaps back on every position tick, because the
  /// stream keeps reporting the old position until the seek completes.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = ref.watch(trackPositionProvider).value ?? Duration.zero;
    final total = ref.watch(totalDurationProvider);

    // A track whose length is not known yet cannot be scrubbed meaningfully.
    final totalSeconds = (total?.inSeconds ?? 0).toDouble();
    final hasDuration = totalSeconds > 0;
    final value = (_dragValue ?? position.inSeconds.toDouble()).clamp(
      0.0,
      hasDuration ? totalSeconds : 1.0,
    );

    return Column(
      children: [
        Slider(
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: EuSpace.sm),
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
    );
  }
}

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
        // Shuffle and repeat had providers but no control anywhere in the UI,
        // so neither setting could be reached.
        _ToggleButton(
          icon: Icons.shuffle,
          active: shuffle,
          tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
          onPressed: () => ref.read(shuffleModeProvider.notifier).toggle(),
        ),
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Previous',
          onPressed: controller.skipPrevious,
        ),
        _PlayButton(isPlaying: isPlaying, isBuffering: isBuffering),
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Next',
          onPressed: controller.skipNext,
        ),
        _ToggleButton(
          icon: repeat == LoopMode.one ? Icons.repeat_one : Icons.repeat,
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

class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.isPlaying, required this.isBuffering});

  final bool isPlaying;
  final bool isBuffering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: ref.read(playerControllerProvider).togglePlayPause,
        child: Container(
          width: 72,
          height: 72,
          decoration: EuBrutal.boxDecoration(
            color: EuBrutal.accent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: isBuffering
              // A resolving track can take a moment; without this the button
              // looks unresponsive and invites a second tap.
              ? const Padding(
                  padding: EdgeInsets.all(EuSpace.lg),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: EuBrutal.onAccent,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: EuBrutal.onAccent,
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
      // State is carried by fill as well as colour, because PRODUCT.md rules
      // out communicating state by colour alone.
      style: IconButton.styleFrom(
        backgroundColor: active ? EuBrutal.accent : Colors.transparent,
        foregroundColor: active
            ? EuBrutal.onAccent
            : EuBrutal.ink.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: active ? EuBrutal.thinSide : BorderSide.none,
        ),
      ),
      icon: Icon(icon),
    );
  }
}
