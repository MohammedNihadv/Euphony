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
          _error = failure.message ?? 'Failed to load playlist';
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
          _error = failure.message ?? 'Failed to load album';
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
                  child: Text(
                    _error!,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
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
                            border: Border.all(color: EuBrutal.ink, width: 2.5),
                            color: EuBrutal.highlight,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _artworkUrl != null
                              ? Image.network(_artworkUrl!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.queue_music,
                                  size: 60,
                                  color: EuBrutal.ink,
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
                                side: const BorderSide(
                                  color: EuBrutal.ink,
                                  width: 2,
                                ),
                              ),
                              onPressed: _tracks.isEmpty
                                  ? null
                                  : () {
                                      final shuffled = List<Song>.from(_tracks)
                                        ..shuffle();
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
                      padding: const EdgeInsets.symmetric(vertical: EuSpace.xl),
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
                    for (final song in _tracks)
                      Container(
                        margin: const EdgeInsets.only(bottom: EuSpace.sm),
                        decoration: EuBrutal.boxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          shadows: EuBrutal.smHardShadow,
                        ),
                        child: Material(
                          type: MaterialType.canvas,
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            onTap: () => ref
                                .read(playerControllerProvider)
                                .playSong(song),
                            onLongPress: () =>
                                showSongOptionsSheet(context, song),
                            title: Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(song.artistNames),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: EuBrutal.accent,
                                    size: 32,
                                  ),
                                  onPressed: () => ref
                                      .read(playerControllerProvider)
                                      .playSong(song),
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
                                          .read(savedPlaylistsDaoProvider)
                                          .save(
                                            id: widget.id,
                                            title: _title ?? 'Custom Playlist',
                                            artworkUrl: _artworkUrl,
                                            trackCount: updated.length,
                                          );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
