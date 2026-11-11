import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/remote/innertube/innertube_paths.dart';
import '../../data/remote/innertube/json_nav.dart';
import '../../data/remote/innertube/parsers/item_parser.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
import '../../domain/album.dart';
import '../../domain/music_item.dart';
import '../../domain/playlist.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import '../common/song_options_sheet.dart';
import '../player/desktop_player_bar.dart';
import '../player/mini_player.dart';

/// Full discography view for an artist section (e.g. all Albums, Singles & EPs).
class ArtistDiscographyScreen extends ConsumerStatefulWidget {
  const ArtistDiscographyScreen({
    required this.artistName,
    required this.sectionTitle,
    this.initialAlbums = const [],
    this.initialSongs = const [],
    this.initialPlaylists = const [],
    this.browseId,
    super.key,
  });

  final String artistName;
  final String sectionTitle;
  final List<Album> initialAlbums;
  final List<Song> initialSongs;
  final List<Playlist> initialPlaylists;
  final String? browseId;

  @override
  ConsumerState<ArtistDiscographyScreen> createState() =>
      _ArtistDiscographyScreenState();
}

class _ArtistDiscographyScreenState
    extends ConsumerState<ArtistDiscographyScreen> {
  final List<Album> _albums = [];
  final List<Song> _songs = [];
  final List<Playlist> _playlists = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _albums.addAll(widget.initialAlbums);
    _songs.addAll(widget.initialSongs);
    _playlists.addAll(widget.initialPlaylists);
    _fetchMoreIfAvailable();
  }

  Future<void> _fetchMoreIfAvailable() async {
    final browseId = widget.browseId;
    if (browseId == null || browseId.isEmpty) return;

    setState(() => _isLoadingMore = true);
    try {
      final client = ref.read(innertubeClientProvider);
      final result = await client.browse(browseId);

      if (!mounted) return;
      final value = result.valueOrNull;
      if (value != null) {
        final contentMap =
            navOrNull<Map<String, dynamic>>(value, P.singleColumnTab) ??
            navOrNull<Map<String, dynamic>>(value, P.singleColumn);

        final sectionList =
            contentMap != null
                ? navOrNull<List<dynamic>>(contentMap, P.sectionList)
                : null;

        final newAlbums = <Album>[];
        final newSongs = <Song>[];
        final newPlaylists = <Playlist>[];

        void parseItem(dynamic raw) {
          if (raw is! Map<String, dynamic>) return;
          final renderer =
              raw['musicTwoRowItemRenderer'] as Map<String, dynamic>? ??
              raw['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
          if (renderer == null) return;
          final parsed = parseTwoRowItem(renderer);
          final item = parsed.valueOrNull;
          if (item != null) {
            switch (item) {
              case AlbumItem(:final album):
                newAlbums.add(album);
              case SongItem(:final song):
                newSongs.add(song);
              case PlaylistItem(:final playlist):
                newPlaylists.add(playlist);
              default:
                break;
            }
          }
        }

        if (sectionList != null) {
          for (final section in sectionList) {
            if (section is! Map<String, dynamic>) continue;
            final grid = section['gridRenderer'] as Map<String, dynamic>?;
            final shelf =
                section['musicCarouselShelfRenderer']
                    as Map<String, dynamic>? ??
                section['musicShelfRenderer'] as Map<String, dynamic>?;

            final items =
                grid?['items'] as List<dynamic>? ??
                shelf?['contents'] as List<dynamic>? ??
                const [];

            for (final raw in items) {
              parseItem(raw);
            }
          }
        }

        // Merge without duplicates
        final existingAlbumIds = _albums.map((a) => a.browseId).toSet();
        for (final a in newAlbums) {
          if (!existingAlbumIds.contains(a.browseId)) {
            _albums.add(a);
            existingAlbumIds.add(a.browseId);
          }
        }

        final existingSongIds = _songs.map((s) => s.id).toSet();
        for (final s in newSongs) {
          if (!existingSongIds.contains(s.id)) {
            _songs.add(s);
            existingSongIds.add(s.id);
          }
        }

        final existingPlaylistIds = _playlists.map((p) => p.id).toSet();
        for (final p in newPlaylists) {
          if (!existingPlaylistIds.contains(p.id)) {
            _playlists.add(p);
            existingPlaylistIds.add(p.id);
          }
        }
      }
    } catch (_) {
      // Best-effort load; initial items remain visible
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasAlbums = _albums.isNotEmpty;
    final hasSongs = _songs.isNotEmpty;
    final hasPlaylists = _playlists.isNotEmpty;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: EuphonySubpageAppBar(
        categoryLabel: widget.sectionTitle,
        icon: Icons.library_music_rounded,
        title: widget.artistName,
      ),
      body: SafeArea(
        top: false,
        child: hasAlbums
            ? _buildAlbumsGrid(context, isDark)
            : hasSongs
            ? _buildSongsList(context, theme)
            : hasPlaylists
            ? _buildPlaylistsGrid(context, isDark)
            : _isLoadingMore
            ? const Center(
                child: CircularProgressIndicator(color: EuBrutal.accent),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.album_outlined,
                      size: 48,
                      color: EuBrutal.accent,
                    ),
                    const SizedBox(height: EuSpace.md),
                    Text(
                      'No ${widget.sectionTitle.toLowerCase()} available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final activeSong = ref.watch(activeSongProvider);
          if (activeSong == null) return const SizedBox.shrink();
          final isDesktop = MediaQuery.sizeOf(context).width >= 900;
          if (isDesktop) {
            return const DesktopPlayerBar();
          }
          return const SafeArea(
            top: false,
            child: MiniPlayer(),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsGrid(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 175).floor().clamp(2, 6);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            EuSpace.lg,
            MediaQuery.of(context).padding.top + kToolbarHeight + EuSpace.sm,
            EuSpace.lg,
            EuSpace.lg + 100,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: _albums.length,
          itemBuilder: (context, index) {
            final album = _albums[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/album/${album.browseId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.08,
                              ),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: album.artworkUrl != null
                              ? Image.network(
                                  album.artworkUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: EuBrutal.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: const Icon(
                                      Icons.album_rounded,
                                      size: 40,
                                      color: EuBrutal.accent,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: EuBrutal.accent.withValues(alpha: 0.2),
                                  child: const Icon(
                                    Icons.album_rounded,
                                    size: 40,
                                    color: EuBrutal.accent,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.year != null
                          ? '${album.year} • ${widget.artistName}'
                          : widget.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongsList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + kToolbarHeight + 8,
        16,
        190,
      ),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return ListTile(
          onTap: () => ref
              .read(playerControllerProvider)
              .playQueue(_songs, startIndex: index),
          onLongPress: () => showSongOptionsSheet(context, song),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          subtitle: Text(
            song.artistNames,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          trailing: const Icon(
            Icons.play_circle_fill_rounded,
            color: EuBrutal.accent,
            size: 30,
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsGrid(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 175).floor().clamp(2, 6);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            EuSpace.lg,
            MediaQuery.of(context).padding.top + kToolbarHeight + EuSpace.sm,
            EuSpace.lg,
            EuSpace.lg + 100,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: _playlists.length,
          itemBuilder: (context, index) {
            final playlist = _playlists[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/playlist/${playlist.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: playlist.artworkUrl != null
                            ? Image.network(
                                playlist.artworkUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: EuBrutal.accent.withValues(alpha: 0.2),
                                child: const Icon(Icons.queue_music_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
