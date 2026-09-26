import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';
import '../../playback/local_playlist_provider.dart';
import '../../playback/player_provider.dart';
import '../common/song_options_sheet.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({required this.id, this.isPlaylist = false, super.key});

  final String id;
  final bool isPlaylist;

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  String? _title;
  String? _artworkUrl;
  List<Song> _tracks = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final isLocalPlaylist =
        widget.isPlaylist &&
        (widget.id.startsWith('local_') ||
            widget.id.startsWith('LIB') ||
            ref.read(localPlaylistTracksProvider).containsKey(widget.id));

    if (isLocalPlaylist) {
      final dao = ref.read(savedPlaylistsDaoProvider);
      final localNotifier = ref.read(localPlaylistTracksProvider.notifier);
      final playlists = await dao.watchAll().first;
      final match = playlists.where((p) => p.id == widget.id).firstOrNull;
      final localTracks = localNotifier.getPlaylistTracks(widget.id);

      if (!mounted) return;
      setState(() {
        _title = match?.title ?? 'Custom Playlist';
        _artworkUrl =
            match?.artworkUrl ??
            (localTracks.isNotEmpty ? localTracks.first.artworkUrl : null);
        _tracks = localTracks;
        _loading = false;
        _error = null;
      });
      return;
    }

    final repo = ref.read(musicDetailRepositoryProvider);
    if (widget.isPlaylist) {
      final result = await repo.fetchPlaylist(widget.id);
      if (!mounted) return;
      result.fold(
        (details) => setState(() {
          _title = details.playlist.title;
          _artworkUrl = details.playlist.artworkUrl;
          _tracks = details.tracks;
          _loading = false;
        }),
        (failure) => setState(() {
          _error = failure.userMessage;
          _loading = false;
        }),
      );
    } else {
      final result = await repo.fetchAlbum(widget.id);
      if (!mounted) return;
      result.fold(
        (details) => setState(() {
          _title = details.album.title;
          _artworkUrl = details.album.artworkUrl;
          _tracks = details.tracks;
          _loading = false;
        }),
        (failure) => setState(() {
          _error = failure.userMessage;
          _loading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal =
        widget.isPlaylist &&
        (widget.id.startsWith('local_') ||
            widget.id.startsWith('LIB') ||
            ref.watch(localPlaylistTracksProvider).containsKey(widget.id));

    // Reactively update local playlist tracks
    if (isLocal) {
      final allLocalMap = ref.watch(localPlaylistTracksProvider);
      _tracks = allLocalMap[widget.id] ?? const [];
      if (_artworkUrl == null && _tracks.isNotEmpty) {
        _artworkUrl = _tracks.first.artworkUrl;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _title ?? (widget.isPlaylist ? 'Playlist' : 'Album'),
          style: theme.textTheme.screenTitle?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: EuBrutal.accent),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(EuSpace.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: EuBrutal.alert,
                      ),
                      const SizedBox(height: EuSpace.md),
                      Text(
                        _error!,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: EuSpace.lg),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: EuBrutal.accent,
                          foregroundColor: EuBrutal.onAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadDetails();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.all(EuSpace.screenGutter),
                    children: [
                      // Cover & Actions Card
                      Container(
                        padding: const EdgeInsets.all(EuSpace.lg),
                        decoration: EuBrutal.boxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          shadows: EuBrutal.hardShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.eu.ink,
                                  width: 2.5,
                                ),
                                color: EuBrutal.highlight,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _artworkUrl != null
                                  ? Image.network(
                                      _artworkUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.queue_music,
                                      size: 60,
                                      color: EuBrutal.onHighlight,
                                    ),
                            ),
                            const SizedBox(height: EuSpace.md),
                            Text(
                              _title ?? '',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: EuSpace.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilledButton.icon(
                                  onPressed: _tracks.isEmpty
                                      ? null
                                      : () {
                                          ref
                                              .read(playerControllerProvider)
                                              .playQueue(_tracks);
                                        },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Play All'),
                                ),
                                const SizedBox(width: EuSpace.md),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: context.eu.ink,
                                      width: 2,
                                    ),
                                  ),
                                  onPressed: _tracks.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<Song>.from(
                                            _tracks,
                                          )..shuffle();
                                          ref
                                              .read(playerControllerProvider)
                                              .playQueue(shuffled);
                                        },
                                  icon: const Icon(Icons.shuffle),
                                  label: const Text('Shuffle'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EuSpace.xl),

                      // Tracks Header
                      Text(
                        'Tracks (${_tracks.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: EuSpace.md),

                      if (_tracks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: EuSpace.xl,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.music_off_outlined,
                                size: 48,
                                color: EuBrutal.accent,
                              ),
                              const SizedBox(height: EuSpace.md),
                              Text(
                                'No songs in this playlist yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: EuSpace.xs),
                              Text(
                                'Tap "Add to Playlist" on any song to add tracks here.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        for (int i = 0; i < _tracks.length; i++)
                          Builder(
                            builder: (context) {
                              final song = _tracks[i];
                              final activeSong = ref.watch(activeSongProvider);
                              final isPlaying = ref.watch(isPlayingProvider);
                              final isCurrentSong = activeSong?.id == song.id;

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: EuSpace.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentSong
                                      ? EuBrutal.accent.withValues(alpha: 0.12)
                                      : theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrentSong
                                        ? EuBrutal.accent.withValues(alpha: 0.5)
                                        : theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.15),
                                    width: isCurrentSong ? 1.4 : 1.0,
                                  ),
                                  boxShadow: isCurrentSong
                                      ? [
                                          BoxShadow(
                                            color: EuBrutal.accent.withValues(
                                              alpha: 0.22,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  type: MaterialType.transparency,
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListTile(
                                    onTap: () {
                                      if (isCurrentSong) {
                                        if (isPlaying) {
                                          ref
                                              .read(playerControllerProvider)
                                              .pause();
                                        } else {
                                          ref
                                              .read(playerControllerProvider)
                                              .play();
                                        }
                                      } else {
                                        ref
                                            .read(playerControllerProvider)
                                            .playQueue(_tracks, startIndex: i);
                                      }
                                    },
                                    onLongPress: () =>
                                        showSongOptionsSheet(context, song),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isCurrentSong
                                            ? EuBrutal.accent.withValues(
                                                alpha: 0.18,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: isCurrentSong
                                          ? (isPlaying
                                                ? const _AlbumEqualizerBars()
                                                : const Icon(
                                                    Icons.volume_up_rounded,
                                                    color: EuBrutal.accent,
                                                    size: 18,
                                                  ))
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                              color: isCurrentSong
                                                  ? EuBrutal.accent
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (isCurrentSong) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: EuBrutal.accent.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isPlaying ? 'PLAYING' : 'PAUSED',
                                              style: const TextStyle(
                                                color: EuBrutal.accent,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      song.artistNames,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isCurrentSong
                                                ? (isPlaying
                                                      ? Icons
                                                            .pause_circle_filled_rounded
                                                      : Icons
                                                            .play_circle_fill_rounded)
                                                : Icons
                                                      .play_circle_outline_rounded,
                                            color: isCurrentSong
                                                ? EuBrutal.accent
                                                : theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.55),
                                            size: isCurrentSong ? 34 : 28,
                                          ),
                                          onPressed: () {
                                            if (isCurrentSong) {
                                              if (isPlaying) {
                                                ref
                                                    .read(
                                                      playerControllerProvider,
                                                    )
                                                    .pause();
                                              } else {
                                                ref
                                                    .read(
                                                      playerControllerProvider,
                                                    )
                                                    .play();
                                              }
                                            } else {
                                              ref
                                                  .read(
                                                    playerControllerProvider,
                                                  )
                                                  .playQueue(
                                                    _tracks,
                                                    startIndex: i,
                                                  );
                                            }
                                          },
                                        ),
                                        if (isLocal)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 22,
                                              color: EuBrutal.alert,
                                            ),
                                            tooltip: 'Remove from playlist',
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    localPlaylistTracksProvider
                                                        .notifier,
                                                  )
                                                  .removeSongFromPlaylist(
                                                    widget.id,
                                                    song.id,
                                                  );
                                              final updated = ref
                                                  .read(
                                                    localPlaylistTracksProvider
                                                        .notifier,
                                                  )
                                                  .getPlaylistTracks(widget.id);
                                              await ref
                                                  .read(
                                                    savedPlaylistsDaoProvider,
                                                  )
                                                  .save(
                                                    id: widget.id,
                                                    title:
                                                        _title ??
                                                        'Custom Playlist',
                                                    artworkUrl: _artworkUrl,
                                                    trackCount: updated.length,
                                                  );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _AlbumEqualizerBars extends StatefulWidget {
  const _AlbumEqualizerBars();

  @override
  State<_AlbumEqualizerBars> createState() => _AlbumEqualizerBarsState();
}

class _AlbumEqualizerBarsState extends State<_AlbumEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final h1 = 5.0 + 9.0 * (0.3 + 0.7 * (t - 0.2).abs());
        final h2 = 5.0 + 11.0 * t;
        final h3 = 5.0 + 9.0 * (1.0 - t);
        return SizedBox(
          width: 16,
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(h1),
              const SizedBox(width: 2),
              _bar(h2),
              const SizedBox(width: 2),
              _bar(h3),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3.0,
      height: height.clamp(4.0, 16.0),
      decoration: BoxDecoration(
        color: EuBrutal.accent,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
