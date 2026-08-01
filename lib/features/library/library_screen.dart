import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/artist_ref.dart';
import '../../domain/song.dart';
import '../../playback/download_provider.dart';
import '../../playback/player_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Library',
          style: theme.textTheme.screenTitle?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          indicator: BoxDecoration(
            color: EuBrutal.highlight,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EuBrutal.onHighlight, width: 2),
            boxShadow: EuBrutal.smHardShadow,
          ),
          labelColor: EuBrutal.onHighlight,
          unselectedLabelColor: context.eu.ink,
          tabs: const [
            Tab(
              icon: Icon(Icons.download_done_rounded, size: 20),
              text: 'Downloads',
            ),
            Tab(icon: Icon(Icons.favorite_rounded, size: 20), text: 'Liked'),
            Tab(
              icon: Icon(Icons.queue_music_rounded, size: 20),
              text: 'Playlists',
            ),
            Tab(icon: Icon(Icons.album_rounded, size: 20), text: 'Albums'),
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DownloadsTab(),
          _LikedSongsTab(),
          _SavedPlaylistsTab(),
          _SavedAlbumsTab(),
          _SearchHistoryTab(),
        ],
      ),
    );
  }
}

class _LikedSongsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(likedSongsDaoProvider);

    return StreamBuilder<List<LikedSongEntry>>(
      stream: dao.watchAll(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 56,
                  color: EuBrutal.alert,
                ),
                const SizedBox(height: EuSpace.md),
                Text(
                  'No liked songs yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: EuSpace.xs),
                const Text(
                  'Songs you heart will appear right here',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        final songs = entries
            .map(
              (entry) => Song(
                id: entry.id,
                title: entry.title,
                artists: entry.artists
                    .split(', ')
                    .map((n) => ArtistRef(name: n))
                    .toList(),
                albumTitle: entry.albumTitle,
                artworkUrl: entry.artworkUrl,
                duration: entry.durationSeconds != null
                    ? Duration(seconds: entry.durationSeconds!)
                    : null,
              ),
            )
            .toList();

        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(EuSpace.screenGutter),
          children: [
            // Spotify-style Liked Songs Hero Banner Card
            Container(
              padding: const EdgeInsets.all(EuSpace.lg),
              decoration: EuBrutal.boxDecoration(
                color: EuBrutal.alert,
                borderRadius: BorderRadius.circular(16),
                shadows: EuBrutal.hardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.eu.ink, width: 2),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: EuBrutal.alert,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: EuSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liked Songs',
                          style: TextStyle(
                            color: context.eu.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${songs.length} track${songs.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: context.eu.ink.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (songs.isNotEmpty) {
                        ref.read(playerControllerProvider).playQueue(songs);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EuBrutal.highlight,
                      foregroundColor: EuBrutal.onHighlight,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      side: const BorderSide(
                        color: EuBrutal.onHighlight,
                        width: 2,
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.play_arrow, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EuSpace.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (songs.isNotEmpty) {
                        ref
                            .read(playerControllerProvider)
                            .playQueue(songs, shuffle: true);
                      }
                    },
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: const Text(
                      'SHUFFLE PLAY',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EuBrutal.accent,
                      foregroundColor: context.eu.ink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: context.eu.ink, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: EuSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: EuBrutal.highlight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EuBrutal.onHighlight, width: 2),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sort, size: 18, color: EuBrutal.onHighlight),
                      SizedBox(width: 4),
                      Text(
                        'Recent',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: EuBrutal.onHighlight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EuSpace.lg),

            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: EuSpace.sm),
                child: _LibraryTile(
                  title: entries[i].title,
                  subtitle: entries[i].artists,
                  artworkUrl: entries[i].artworkUrl,
                  onTap: () => ref
                      .read(playerControllerProvider)
                      .playQueue(songs, startIndex: i),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: EuBrutal.alert,
                      size: 20,
                    ),
                    onPressed: () => dao.unlike(entries[i].id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SavedPlaylistsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(savedPlaylistsDaoProvider);

    return StreamBuilder<List<SavedPlaylistEntry>>(
      stream: dao.watchAll(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(EuSpace.screenGutter),
          children: [
            // Create Playlist Action Tile
            Container(
              margin: const EdgeInsets.only(bottom: EuSpace.md),
              decoration: EuBrutal.boxDecoration(
                color: EuBrutal.highlight,
                borderRadius: BorderRadius.circular(12),
                shadows: EuBrutal.smHardShadow,
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => _showCreatePlaylistDialog(context, ref),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: EuBrutal.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.eu.ink, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: EuBrutal.onAccent,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    'Create Playlist',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: context.eu.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Build your personal music collection',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.eu.ink,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: context.eu.ink),
                ),
              ),
            ),

            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(EuSpace.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.playlist_play,
                      size: 48,
                      color: EuBrutal.accent,
                    ),
                    const SizedBox(height: EuSpace.md),
                    Text(
                      'No saved playlists yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: EuSpace.sm),
                  child: _LibraryTile(
                    title: entry.title,
                    subtitle: entry.author ?? '${entry.trackCount ?? 0} tracks',
                    artworkUrl: entry.artworkUrl,
                    leadingIcon: Icons.playlist_play,
                    onTap: () => context.push('/playlist/${entry.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => dao.remove(entry.id),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(savedPlaylistsDaoProvider)
                    .save(
                      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                      title: name,
                      author: 'Custom Playlist',
                      trackCount: 0,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAlbumsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(savedAlbumsDaoProvider);

    return _buildStream<SavedAlbumEntry>(
      stream: dao.watchAll(),
      emptyText: 'No saved albums yet',
      emptyIcon: Icons.album,
      itemBuilder: (entry) => _LibraryTile(
        title: entry.title,
        subtitle: entry.artists,
        artworkUrl: entry.artworkUrl,
        leadingIcon: Icons.album,
        onTap: () => context.push('/album/${entry.browseId}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => dao.remove(entry.browseId),
        ),
      ),
    );
  }
}

class _SearchHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(searchHistoryDaoProvider);

    return _buildStream<SearchHistoryEntry>(
      stream: dao.watchRecent(limit: 50),
      emptyText: 'No search history yet',
      emptyIcon: Icons.history,
      itemBuilder: (entry) => _LibraryTile(
        title: entry.query,
        subtitle: _formatDate(entry.lastUsedAt),
        leadingIcon: Icons.history,
        onTap: () => context.go('/search'),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => dao.remove(entry.query),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

Widget _buildStream<T>({
  required Stream<List<T>> stream,
  required String emptyText,
  required IconData emptyIcon,
  required Widget Function(T entry) itemBuilder,
}) {
  return StreamBuilder<List<T>>(
    stream: stream,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null || data.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 48, color: EuBrutal.accent),
              const SizedBox(height: EuSpace.md),
              Text(
                emptyText,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(EuSpace.screenGutter),
        itemCount: data.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: EuSpace.sm),
          child: itemBuilder(data[index]),
        ),
      );
    },
  );
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.leadingIcon,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? artworkUrl;
  final IconData? leadingIcon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: EuBrutal.boxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        shadows: EuBrutal.smHardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.eu.ink, width: 1.5),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.antiAlias,
            child: artworkUrl != null
                ? Image.network(
                    artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      leadingIcon ?? Icons.music_note,
                      size: 24,
                      color: context.eu.ink,
                    ),
                  )
                : Icon(
                    leadingIcon ?? Icons.music_note,
                    size: 24,
                    color: context.eu.ink,
                  ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: context.eu.ink.withValues(alpha: 0.7),
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadedSongsProvider);
    final progressMap = ref.watch(downloadProgressProvider);
    final theme = Theme.of(context);

    if (downloaded.isEmpty && progressMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_for_offline_outlined,
              size: 64,
              color: EuBrutal.accent,
            ),
            const SizedBox(height: EuSpace.md),
            Text(
              'No Downloaded Songs Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: EuSpace.sm),
            Text(
              'Tap download on any track to listen 100% offline!',
              style: TextStyle(
                color: context.eu.ink.withValues(alpha: 0.35),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EuSpace.screenGutter,
        EuSpace.md,
        EuSpace.screenGutter,
        100,
      ),
      children: [
        if (progressMap.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: EuSpace.md),
            padding: const EdgeInsets.all(EuSpace.md),
            decoration: EuBrutal.boxDecoration(
              color: EuBrutal.highlight,
              borderRadius: BorderRadius.circular(12),
              shadows: EuBrutal.smHardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: EuBrutal.onHighlight,
                      ),
                    ),
                    const SizedBox(width: EuSpace.sm),
                    Expanded(
                      child: Text(
                        'DOWNLOADING (${progressMap.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: EuBrutal.onHighlight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EuSpace.sm),
                for (final entry in progressMap.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Track ...${entry.key.length > 5 ? entry.key.substring(entry.key.length - 5) : entry.key}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: context.eu.ink,
                              ),
                            ),
                            Text(
                              '${(entry.value * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: context.eu.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              EuBrutal.accent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (downloaded.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: EuSpace.sm),
            child: Text(
              'OFFLINE SONGS (${downloaded.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: context.eu.ink.withValues(alpha: 0.7),
              ),
            ),
          ),
        for (var i = 0; i < downloaded.length; i++)
          Builder(
            builder: (context) {
              final song = downloaded[i];
              return Container(
                margin: const EdgeInsets.only(bottom: EuSpace.sm),
                decoration: EuBrutal.boxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  shadows: EuBrutal.smHardShadow,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: EuBrutal.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: EuBrutal.accent,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      song.artists.map((a) => a.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: context.eu.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Remove Download',
                      onPressed: () {
                        ref
                            .read(downloadedSongsProvider.notifier)
                            .removeDownload(song.id);
                      },
                    ),
                    onTap: () {
                      ref
                          .read(playerControllerProvider)
                          .playQueue(downloaded, startIndex: i);
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
