import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/album.dart';
import '../../domain/artist.dart';
import '../../domain/playlist.dart';
import '../../playback/player_provider.dart';

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
                            if (section.browseId != null)
                              TextButton(
                                onPressed: () {
                                  context.push('/album/${section.browseId}');
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

                        // 1. Top Songs List
                        if (section.songs.isNotEmpty)
                          for (int i = 0; i < section.songs.length; i++)
                            Builder(
                              builder: (context) {
                                final song = section.songs[i];
                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: EuSpace.sm,
                                  ),
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
                                          .playQueue(
                                            section.songs,
                                            startIndex: i,
                                          ),
                                      title: Text(
                                        song.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      subtitle: Text(song.artistNames),
                                      trailing: const Icon(
                                        Icons.play_circle_fill,
                                        color: EuBrutal.accent,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                        // 2. Albums / Singles Discography
                        if (section.albums.isNotEmpty)
                          SizedBox(
                            height: 215,
                            child: ListView.separated(
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
                            height: 215,
                            child: ListView.separated(
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
    final artistName =
        album.artistNames.isNotEmpty ? album.artistNames : fallbackArtist;
    final yearText = album.year != null ? '${album.year}' : '';
    final subtitle = [
      if (yearText.isNotEmpty) yearText,
      artistName,
    ].join(' • ');

    return GestureDetector(
      onTap: () => context.push('/album/${album.browseId}'),
      child: SizedBox(
        width: 145,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 145,
              height: 145,
              decoration: EuBrutal.boxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                shadows: EuBrutal.smHardShadow,
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
            const SizedBox(height: EuSpace.sm),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
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

    return GestureDetector(
      onTap: () => context.push('/playlist/${playlist.id}'),
      child: SizedBox(
        width: 145,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 145,
              height: 145,
              decoration: EuBrutal.boxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                shadows: EuBrutal.smHardShadow,
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
            const SizedBox(height: EuSpace.sm),
            Text(
              playlist.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              playlist.author ?? 'Playlist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
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

    return GestureDetector(
      onTap: () => context.push('/artist/${artist.browseId}'),
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.eu.ink,
                  width: 2.5,
                ),
                color: EuBrutal.highlight,
              ),
              clipBehavior: Clip.antiAlias,
              child: artist.artworkUrl != null
                  ? Image.network(
                      artist.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        size: 44,
                        color: EuBrutal.onHighlight,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 44,
                      color: EuBrutal.onHighlight,
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
