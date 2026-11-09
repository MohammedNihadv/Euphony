import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/album.dart';
import '../../domain/artist.dart';
import '../../domain/playlist.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import '../player/desktop_player_bar.dart';
import '../player/mini_player.dart';
import 'artist_discography_screen.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  const ArtistScreen({required this.browseId, super.key});

  final String browseId;

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  Artist? _artist;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtist();
  }

  Future<void> _loadArtist() async {
    final repo = ref.read(musicDetailRepositoryProvider);
    final result = await repo.fetchArtist(widget.browseId);

    if (!mounted) return;
    result.fold(
      (artist) => setState(() {
        _artist = artist;
        _loading = false;
      }),
      (failure) => setState(() {
        _error = failure.message ?? 'Failed to load artist';
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          _artist?.name ?? 'Artist',
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
            ? Center(child: Text(_error!, style: theme.textTheme.titleMedium))
            : _artist == null
            ? const Center(child: Text('Artist not found'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.all(EuSpace.screenGutter),
                    children: [
                      // Artist Header Card
                      Container(
                        padding: const EdgeInsets.all(EuSpace.lg),
                        decoration: EuBrutal.boxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          shadows: EuBrutal.hardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.eu.ink,
                                  width: 2.5,
                                ),
                                color: EuBrutal.highlight,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _artist!.artworkUrl != null
                                  ? Image.network(
                                      _artist!.artworkUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: EuBrutal.onHighlight,
                                    ),
                            ),
                            const SizedBox(width: EuSpace.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _artist!.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  if (_artist!.subscribers != null)
                                    Text(
                                      _artist!.subscribers!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.eu.ink.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: EuSpace.xl),

                      // Artist Sections (Top Songs / Albums / Playlists / Related Artists)
                      for (final section in _artist!.sections) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              section.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (section.browseId != null ||
                                section.albums.length > 5 ||
                                section.songs.length > 5)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ArtistDiscographyScreen(
                                        artistName: _artist!.name,
                                        sectionTitle: section.title,
                                        initialAlbums: section.albums,
                                        initialSongs: section.songs,
                                        initialPlaylists: section.playlists,
                                        browseId: section.browseId,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'More',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: EuBrutal.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: EuSpace.md),

                        // 1. Videos / Live Shows or Top Songs
                        Builder(
                          builder: (context) {
                            final titleLower = section.title.toLowerCase();
                            final isVideoSection = titleLower.contains('video') ||
                                titleLower.contains('live') ||
                                titleLower.contains('show') ||
                                titleLower.contains('performance') ||
                                (section.songs.isNotEmpty &&
                                    section.songs.every((s) => s.kind == SongKind.video));

                            if (isVideoSection && section.songs.isNotEmpty) {
                              return SizedBox(
                                height: 205,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: section.songs.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: EuSpace.md),
                                  itemBuilder: (context, i) {
                                    final song = section.songs[i];
                                    return _ArtistVideoCard(
                                      song: song,
                                      onTap: () => ref
                                          .read(playerControllerProvider)
                                          .playQueue(section.songs, startIndex: i),
                                    );
                                  },
                                ),
                              );
                            }

                            if (section.songs.isNotEmpty) {
                              return Column(
                                children: [
                                  for (int i = 0; i < section.songs.length; i++)
                                    Builder(
                                      builder: (context) {
                                        final song = section.songs[i];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(14),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(14),
                                              onTap: () => ref
                                                  .read(playerControllerProvider)
                                                  .playQueue(
                                                    section.songs,
                                                    startIndex: i,
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.04)
                                                      : Colors.black.withValues(alpha: 0.03),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        width: 44,
                                                        height: 44,
                                                        color: isDark
                                                            ? Colors.white10
                                                            : Colors.black12,
                                                        child: song.artworkUrl != null
                                                            ? Image.network(
                                                                song.artworkUrl!,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (_, _, _) =>
                                                                    const Icon(
                                                                  Icons.music_note,
                                                                  size: 22,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons.music_note,
                                                                size: 22,
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 14),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            song.title,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w800,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            song.artistNames,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: theme.colorScheme.onSurface
                                                                  .withValues(alpha: 0.65),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.play_circle_fill,
                                                        color: EuBrutal.accent,
                                                        size: 32,
                                                      ),
                                                      onPressed: () => ref
                                                          .read(playerControllerProvider)
                                                          .playQueue(
                                                            section.songs,
                                                            startIndex: i,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),

                        // 2. Albums / Singles Discography
                        if (section.albums.isNotEmpty)
                          SizedBox(
                            height: 232,
                            child: ListView.separated(
                              clipBehavior: Clip.none,
                              padding: const EdgeInsets.only(bottom: 8, left: 2, right: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: section.albums.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: EuSpace.md),
                              itemBuilder: (context, index) {
                                final album = section.albums[index];
                                return _ArtistAlbumCard(
                                  album: album,
                                  fallbackArtist: _artist!.name,
                                );
                              },
                            ),
                          ),

                        // 3. Playlists (Featured on / By artist)
                        if (section.playlists.isNotEmpty)
                          SizedBox(
                            height: 232,
                            child: ListView.separated(
                              clipBehavior: Clip.none,
                              padding: const EdgeInsets.only(bottom: 8, left: 2, right: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: section.playlists.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: EuSpace.md),
                              itemBuilder: (context, index) {
                                final playlist = section.playlists[index];
                                return _ArtistPlaylistCard(playlist: playlist);
                              },
                            ),
                          ),

                        // 4. Related Artists
                        if (section.relatedArtists.isNotEmpty)
                          SizedBox(
                            height: 165,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: section.relatedArtists.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: EuSpace.md),
                              itemBuilder: (context, index) {
                                final rel = section.relatedArtists[index];
                                return _RelatedArtistCard(artist: rel);
                              },
                            ),
                          ),

                        const SizedBox(height: EuSpace.xl),
                      ],
                    ],
                  ),
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: MiniPlayer(),
            ),
          );
        },
      ),
    );
  }
}

class _ArtistVideoCard extends StatelessWidget {
  const _ArtistVideoCard({
    required this.song,
    required this.onTap,
  });

  final Song song;
  final VoidCallback onTap;

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final artworkUrl = song.artwork?.max ?? song.artworkUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1926) : const Color(0xFFE2E4EB),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (artworkUrl != null)
                      Image.network(
                        artworkUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),
                    // Centered subtle play icon overlay
                    Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (song.duration != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDuration(song.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
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
              song.artistNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistAlbumCard extends StatelessWidget {
  const _ArtistAlbumCard({
    required this.album,
    required this.fallbackArtist,
  });

  final Album album;
  final String fallbackArtist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final artistName =
        album.artistNames.isNotEmpty ? album.artistNames : fallbackArtist;
    final yearText = album.year != null ? '${album.year}' : '';
    final subtitle = [
      if (yearText.isNotEmpty) yearText,
      artistName,
    ].join(' • ');

    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/album/${album.browseId}'),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: album.artworkUrl != null
                        ? Image.network(
                            album.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                              child: const Icon(
                                Icons.album,
                                size: 48,
                                color: EuBrutal.accent,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: const Icon(
                              Icons.album,
                              size: 48,
                              color: EuBrutal.accent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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

class _ArtistPlaylistCard extends StatelessWidget {
  const _ArtistPlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/playlist/${playlist.id}'),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: playlist.artworkUrl != null
                        ? Image.network(
                            playlist.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                              child: const Icon(
                                Icons.queue_music,
                                size: 48,
                                color: EuBrutal.accent,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: const Icon(
                              Icons.queue_music,
                              size: 48,
                              color: EuBrutal.accent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  playlist.author ?? 'Playlist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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

class _RelatedArtistCard extends StatelessWidget {
  const _RelatedArtistCard({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/artist/${artist.browseId}'),
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E1D2A) : const Color(0xFFE2E4EB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: artist.artworkUrl != null
                  ? Image.network(
                      artist.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        size: 44,
                        color: Colors.white54,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 44,
                      color: Colors.white54,
                    ),
            ),
            const SizedBox(height: EuSpace.sm),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
