import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const EuphonyPageCapsule(
          label: 'Library',
          icon: Icons.my_library_music_rounded,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          indicator: BoxDecoration(
            color: EuBrutal.accent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: EuBrutal.accent.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: const [
            Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Liked'),
            Tab(
              icon: Icon(Icons.download_done_rounded, size: 18),
              text: 'Downloads',
            ),
            Tab(
              icon: Icon(Icons.queue_music_rounded, size: 18),
              text: 'Playlists',
            ),
            Tab(icon: Icon(Icons.album_rounded, size: 18), text: 'Albums'),
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LikedSongsTab(),
          _DownloadsTab(),
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
        final isDark = theme.brightness == Brightness.dark;

        return ListView(
          padding: const EdgeInsets.all(EuSpace.screenGutter),
          children: [
            // Spotify-style Liked Songs Hero Banner Card (Glassmorphic Crimson)
            Container(
              padding: const EdgeInsets.all(EuSpace.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE11D48),
                    Color(0xFFBE123C),
                    Color(0xFF881337),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: EuSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Liked Songs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          '${songs.length} track${songs.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE11D48),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      elevation: 4,
                      shadowColor: Colors.black45,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 28),
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
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text(
                      'SHUFFLE PLAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0x60161626)
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<SavedPlaylistEntry>>(
      stream: dao.watchAll(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(EuSpace.screenGutter),
          children: [
            // Create Playlist Action Tile (Neo-Glassmorphic)
            Container(
              margin: const EdgeInsets.only(bottom: EuSpace.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          EuBrutal.accent.withValues(alpha: 0.22),
                          const Color(0x60161626),
                        ]
                      : [
                          EuBrutal.accent.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EuBrutal.accent.withValues(
                    alpha: isDark ? 0.38 : 0.28,
                  ),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EuBrutal.accent.withValues(
                      alpha: isDark ? 0.18 : 0.08,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => _showCreatePlaylistDialog(context, ref),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    'Create Playlist',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Build your personal music collection',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xF5141424)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EuBrutal.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EuBrutal.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.playlist_add_rounded,
                      color: EuBrutal.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW PLAYLIST',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Create a custom collection for your moods',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Midnight Vibes, Workout Mix',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: EuBrutal.accent,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EuBrutal.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                      'Create Playlist',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x60161626)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : Colors.black.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: artworkUrl != null && artworkUrl!.isNotEmpty
                ? Image.network(
                    artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      leadingIcon ?? Icons.music_note_rounded,
                      size: 24,
                      color: EuBrutal.accent,
                    ),
                  )
                : Icon(
                    leadingIcon ?? Icons.music_note_rounded,
                    size: 24,
                    color: EuBrutal.accent,
                  ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        EuBrutal.accent.withValues(alpha: 0.18),
                        const Color(0x60161626),
                      ]
                    : [
                        EuBrutal.accent.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.95),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: EuBrutal.accent.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: EuBrutal.accent.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EuBrutal.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOWNLOADING (${progressMap.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 0.8,
                              color: EuBrutal.accent,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Saving tracks for instant offline listening',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                              'Track ...${entry.key.length > 6 ? entry.key.substring(entry.key.length - 6) : entry.key}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: EuBrutal.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(entry.value * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: EuBrutal.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: entry.value,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
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
            padding: const EdgeInsets.only(bottom: EuSpace.sm, top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.offline_pin_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  'SAVED OFFLINE (${downloaded.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        for (var i = 0; i < downloaded.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: EuSpace.sm),
            child: _LibraryTile(
              title: downloaded[i].title,
              subtitle: downloaded[i].artistNames,
              artworkUrl: downloaded[i].artworkUrl,
              leadingIcon: Icons.music_note_rounded,
              onTap: () => ref
                  .read(playerControllerProvider)
                  .playQueue(downloaded, startIndex: i),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Colors.redAccent,
                ),
                tooltip: 'Remove Download',
                onPressed: () {
                  ref
                      .read(downloadedSongsProvider.notifier)
                      .removeDownload(downloaded[i].id);
                },
              ),
            ),
          ),
      ],
    );
  }
}
