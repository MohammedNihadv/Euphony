import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';
import '../../playback/download_provider.dart';
import '../../playback/local_playlist_provider.dart';
import '../../playback/player_provider.dart';

void showSongOptionsSheet(BuildContext context, Song song) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: context.eu.ink, width: 2.5),
    ),
    builder: (context) =>
        SingleChildScrollView(child: _SongOptionsSheetBody(song: song)),
  );
}

class _SongOptionsSheetBody extends ConsumerWidget {
  const _SongOptionsSheetBody({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(likedSongsDaoProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(EuSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.eu.ink, width: 2),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                const SizedBox(width: EuSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artistNames.isEmpty
                            ? 'Unknown Artist'
                            : song.artistNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: context.eu.ink, thickness: 2, height: 2),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: EuBrutal.accent),
            title: const Text(
              'Add to Playlist',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, song);
            },
          ),
          ListTile(
            leading: Icon(Icons.playlist_play, color: context.eu.ink),
            title: const Text(
              'Play Next',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () {
              ref.read(playerControllerProvider).addNext(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to play next')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.queue_music, color: context.eu.ink),
            title: const Text(
              'Add to Queue',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () {
              ref.read(playerControllerProvider).addToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Added to queue')));
            },
          ),
          StreamBuilder<bool>(
            stream: dao.watchIsLiked(song.id),
            builder: (context, snapshot) {
              final isLiked = snapshot.data ?? false;
              return ListTile(
                leading: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? EuBrutal.alert : context.eu.ink,
                ),
                title: Text(
                  isLiked ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () {
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
                  Navigator.pop(context);
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final isDownloaded = ref
                  .watch(downloadedSongsProvider)
                  .any((s) => s.id == song.id);
              final progressMap = ref.watch(downloadProgressProvider);
              final progress = progressMap[song.id];

              return ListTile(
                leading: progress != null
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: EuBrutal.accent,
                        ),
                      )
                    : Icon(
                        isDownloaded
                            ? Icons.check_circle
                            : Icons.download_for_offline_outlined,
                        color: isDownloaded ? Colors.green : EuBrutal.accent,
                      ),
                title: Text(
                  isDownloaded
                      ? 'Remove Download'
                      : (progress != null
                            ? 'Downloading ${(progress * 100).toInt()}%...'
                            : 'Download Track'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  isDownloaded
                      ? 'Remove from offline storage'
                      : 'Save track for offline listening',
                ),
                onTap: () {
                  if (progress != null) return;
                  if (isDownloaded) {
                    ref
                        .read(downloadedSongsProvider.notifier)
                        .removeDownload(song.id);
                    Navigator.pop(context);
                  } else {
                    ref
                        .read(downloadedSongsProvider.notifier)
                        .downloadSong(song);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
          if (song.artistNames.isNotEmpty)
            ListTile(
              leading: Icon(
                Icons.person_search_outlined,
                color: context.eu.ink,
              ),
              title: Text(
                'Search "${song.artistNames}"',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go(
                  '/search?q=${Uri.encodeComponent(song.artistNames)}',
                );
              },
            ),
          const SizedBox(height: EuSpace.lg),
        ],
      ),
    );
  }
}

void _showAddToPlaylistSheet(BuildContext context, Song song) {
  final inkColor = context.eu.ink;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: inkColor, width: 2.5),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final dao = ref.watch(savedPlaylistsDaoProvider);
          return StreamBuilder<List<SavedPlaylistEntry>>(
            stream: dao.watchAll(),
            builder: (context, snapshot) {
              final playlists = snapshot.data ?? const [];
              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(EuSpace.lg),
                        child: Text(
                          'ADD TO PLAYLIST',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Divider(
                        color: context.eu.divider,
                        thickness: 2,
                        height: 1,
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: EuBrutal.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: EuBrutal.onAccent,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Create New Playlist',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: EuBrutal.accent,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showNewPlaylistDialog(context, song);
                        },
                      ),
                      if (playlists.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(EuSpace.xl),
                          child: Text(
                            'No playlists created yet',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        for (final playlist in playlists)
                          ListTile(
                            leading: Icon(
                              Icons.playlist_play,
                              color: context.eu.ink,
                            ),
                            title: Text(
                              playlist.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist.trackCount ?? 0} tracks',
                            ),
                            onTap: () async {
                              final notifier = ref.read(
                                localPlaylistTracksProvider.notifier,
                              );
                              await notifier.addSongToPlaylist(
                                playlist.id,
                                song,
                              );
                              final currentTracks = notifier.getPlaylistTracks(
                                playlist.id,
                              );
                              await dao.save(
                                id: playlist.id,
                                title: playlist.title,
                                author: playlist.author ?? 'Custom Playlist',
                                artworkUrl:
                                    song.artworkUrl ?? playlist.artworkUrl,
                                trackCount: currentTracks.length,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added "${song.title}" to ${playlist.title}',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      const SizedBox(height: EuSpace.md),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

void _showNewPlaylistDialog(BuildContext context, Song song) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, child) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.eu.ink, width: 2.5),
        ),
        title: const Text(
          'NEW PLAYLIST',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EuBrutal.accent,
              foregroundColor: EuBrutal.onAccent,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final playlistId =
                    'local_${DateTime.now().millisecondsSinceEpoch}';
                final notifier = ref.read(localPlaylistTracksProvider.notifier);
                final dao = ref.read(savedPlaylistsDaoProvider);
                await notifier.addSongToPlaylist(playlistId, song);
                await dao.save(
                  id: playlistId,
                  title: name,
                  author: 'Custom Playlist',
                  artworkUrl: song.artworkUrl,
                  trackCount: 1,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Created "$name" and added "${song.title}"',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Create & Add',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );
}
