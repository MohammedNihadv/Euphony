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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
    builder: (context) => _SongOptionsSheetBody(song: song),
  );
}

class _SongOptionsSheetBody extends ConsumerWidget {
  const _SongOptionsSheetBody({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(likedSongsDaoProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.68,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10101A) : const Color(0xFFF8FAFD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EuSpace.lg,
              EuSpace.xs,
              EuSpace.lg,
              EuSpace.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: song.artworkUrl != null
                      ? Image.network(
                          song.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.music_note_rounded,
                            color: EuBrutal.accent,
                          ),
                        )
                      : const Icon(
                          Icons.music_note_rounded,
                          color: EuBrutal.accent,
                        ),
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.2,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            thickness: 1,
            height: 1,
          ),
          ListTile(
            leading: const Icon(
              Icons.playlist_add_rounded,
              color: EuBrutal.accent,
            ),
            title: Text(
              'Add to Playlist',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, song);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.playlist_play_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            title: Text(
              'Play Next',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
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
            leading: Icon(
              Icons.queue_music_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            title: Text(
              'Add to Queue',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
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
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isLiked
                      ? EuBrutal.alert
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
                title: Text(
                  isLiked ? 'Remove from Favorites' : 'Add to Favorites',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
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
                            ? Icons.check_circle_rounded
                            : Icons.download_for_offline_outlined,
                        color: isDownloaded
                            ? Colors.green
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                title: Text(
                  isDownloaded
                      ? 'Remove Download'
                      : (progress != null
                            ? 'Downloading ${(progress * 100).toInt()}%...'
                            : 'Download Track'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  isDownloaded
                      ? 'Remove from offline storage'
                      : 'Save track for offline listening',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
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
          if (song.albumId != null &&
              song.albumTitle != null &&
              song.albumTitle!.isNotEmpty)
            ListTile(
              leading: Icon(
                Icons.album_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                'Go to Album "${song.albumTitle}"',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/album/${song.albumId}');
              },
            ),
          if (song.artists.isNotEmpty) ...[
            for (final artist in song.artists)
              ListTile(
                leading: Icon(
                  artist.isNavigable
                      ? Icons.person_outline_rounded
                      : Icons.person_search_outlined,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  artist.isNavigable
                      ? 'Go to ${artist.name}'
                      : 'Search "${artist.name}"',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (artist.isNavigable) {
                    context.push('/artist/${artist.browseId}');
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    context.go('/search?q=${Uri.encodeComponent(artist.name)}');
                  }
                },
              ),
          ] else if (song.artistNames.isNotEmpty)
            ListTile(
              leading: Icon(
                Icons.person_search_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                'Search "${song.artistNames}"',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.70 : 0.40),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final dao = ref.watch(savedPlaylistsDaoProvider);
          return StreamBuilder<List<SavedPlaylistEntry>>(
            stream: dao.watchAll(),
            builder: (context, snapshot) {
              final playlists = snapshot.data ?? const [];
              return Container(
                height: MediaQuery.sizeOf(context).height * 0.65,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF10101A)
                      : const Color(0xFFF8FAFD),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.white.withValues(alpha: 0.90),
                      width: 1.2,
                    ),
                    left: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1.0,
                    ),
                    right: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1.0,
                    ),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EuSpace.lg,
                        vertical: EuSpace.sm,
                      ),
                      child: Text(
                        'ADD TO PLAYLIST',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      thickness: 1,
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
                          Icons.add_rounded,
                          color: EuBrutal.onAccent,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Create New Playlist',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: EuBrutal.accent,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showNewPlaylistDialog(context, song);
                      },
                    ),
                    if (playlists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(EuSpace.xl),
                        child: Text(
                          'No playlists created yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      )
                    else
                      for (final playlist in playlists)
                        ListTile(
                          leading: Icon(
                            Icons.playlist_play_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          title: Text(
                            playlist.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${playlist.trackCount ?? 0} tracks',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () async {
                            final notifier = ref.read(
                              localPlaylistTracksProvider.notifier,
                            );
                            await notifier.addSongToPlaylist(playlist.id, song);
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
              );
            },
          );
        },
      );
    },
  );
}

void _showNewPlaylistDialog(BuildContext context, Song song) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, child) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161626) : Colors.white,
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.10),
            width: 1.0,
          ),
        ),
        title: Text(
          'NEW PLAYLIST',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Playlist Title',
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.40),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: EuBrutal.accent, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EuBrutal.accent,
              foregroundColor: EuBrutal.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
