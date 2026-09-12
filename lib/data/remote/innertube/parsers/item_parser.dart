import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../../../domain/album.dart';
import '../../../../domain/artist.dart';
import '../../../../domain/artist_ref.dart';
import '../../../../domain/music_item.dart';
import '../../../../domain/playlist.dart';
import '../../../../domain/song.dart';
import '../innertube_paths.dart';
import '../innertube_utils.dart';
import '../json_nav.dart';
import 'song_runs.dart';

/// What a renderer is expected to produce, when the surrounding shelf knows.
enum ItemHint { song, video, album, artist, playlist, station }

/// Parses a `musicResponsiveListItemRenderer` — the row shape used by search
/// results, album track lists and playlist track lists.
///
/// Returns [Err] rather than `null` so a shelf that suddenly parses to nothing
/// says why. Callers reading a mixed shelf log and drop failures; callers that
/// expect one type treat a failure as a broken parser.
Result<MusicItem> parseListItem(
  Map<String, dynamic> renderer, {
  ItemHint? hint,
}) {
  // The play button's endpoint is the most reliable type signal: it says
  // whether this is an audio track (ATV) or a music video.
  final videoType = navOrNull<String>(
    renderer,
    P.playButton + ['playNavigationEndpoint'] + P.navigationVideoType.steps,
  );

  final resolved =
      hint ??
      switch (videoType) {
        'MUSIC_VIDEO_TYPE_ATV' => ItemHint.song,
        final String _ => ItemHint.video,
        null => _inferFromSubtitle(renderer),
      };

  if (resolved == null) {
    return Err(
      ParseFailure(
        P.responsiveListItem,
        message:
            'unrecognised item type; subtitle was '
            '"${flexColumnText(renderer, 1)}"',
      ),
    );
  }

  return switch (resolved) {
    ItemHint.song || ItemHint.video => _parseSongRow(renderer, resolved),
    ItemHint.album => _parseAlbumRow(renderer),
    ItemHint.artist => _parseArtistRow(renderer),
    ItemHint.playlist => _parsePlaylistRow(renderer),
    ItemHint.station => _parseStationRow(renderer),
  };
}

/// When there is no play button, the second flex column's first run names the
/// type: "Artist", "Album", "Playlist", "Song", "Video", "Single", "EP".
ItemHint? _inferFromSubtitle(Map<String, dynamic> renderer) {
  final text = flexColumnText(renderer, 1)?.toLowerCase();
  return switch (text) {
    'artist' => ItemHint.artist,
    'album' || 'single' || 'ep' => ItemHint.album,
    'playlist' => ItemHint.playlist,
    'song' => ItemHint.song,
    'video' => ItemHint.video,
    'station' || 'radio' => ItemHint.station,
    _ => null,
  };
}

Result<MusicItem> _parseSongRow(Map<String, dynamic> renderer, ItemHint hint) {
  final title = flexColumnText(renderer, 0);
  if (title == null) {
    return const Err(ParseFailure('flexColumns[0].title'));
  }

  final videoId =
      navOrNull<String>(
        renderer,
        P.playButton + ['playNavigationEndpoint', 'watchEndpoint', 'videoId'],
      ) ??
      navOrNull<String>(renderer, P.navigationVideoId);
  if (videoId == null) {
    return const Err(ParseFailure('watchEndpoint.videoId'));
  }

  final meta = parseSongRuns(flexColumnRuns(renderer, 1) ?? const []);

  // Album and playlist track lists put the duration in a fixed column rather
  // than in the subtitle runs.
  final duration = meta.duration ?? parseDuration(fixedColumnText(renderer, 0));

  return Ok(
    SongItem(
      Song(
        id: videoId,
        title: title,
        artists: meta.artists,
        kind: hint == ItemHint.video ? SongKind.video : SongKind.song,
        albumId: meta.albumId,
        albumTitle: meta.albumTitle,
        artworkUrl: _artwork(renderer),
        duration: duration,
        year: meta.year,
        isExplicit: navOrNull<String>(renderer, P.badgeLabel) != null,
        playlistId: navOrNull<String>(renderer, P.navigationPlaylistId),
      ),
    ),
  );
}

Result<MusicItem> _parseAlbumRow(Map<String, dynamic> renderer) {
  final title = flexColumnText(renderer, 0);
  final browseId = navOrNull<String>(renderer, P.navigationBrowseId);
  if (title == null || browseId == null) {
    return const Err(ParseFailure('album row title/browseId'));
  }

  final meta = parseSongRuns(flexColumnRuns(renderer, 1) ?? const []);

  return Ok(
    AlbumItem(
      Album(
        browseId: browseId,
        title: title,
        artists: meta.artists,
        artworkUrl: _artwork(renderer),
        year: meta.year,
        isExplicit: navOrNull<String>(renderer, P.badgeLabel) != null,
        audioPlaylistId: navOrNull<String>(
          renderer,
          P.menuItems +
              [0, 'menuNavigationItemRenderer'] +
              P.navigationWatchPlaylistId.steps,
        ),
      ),
    ),
  );
}

Result<MusicItem> _parseArtistRow(Map<String, dynamic> renderer) {
  final name = flexColumnText(renderer, 0);
  final browseId = navOrNull<String>(renderer, P.navigationBrowseId);
  if (name == null || browseId == null) {
    return const Err(ParseFailure('artist row name/browseId'));
  }

  // Subtitle reads "Artist • 1.2M subscribers": run 0 is the type, run 1 the
  // separator, run 2 the count. Rows that do not show a count have one run.
  final subscribers = flexColumnText(renderer, 1, runIndex: 2);

  return Ok(
    ArtistItem(
      Artist(
        browseId: browseId,
        name: name,
        artworkUrl: _artwork(renderer),
        subscribers: subscribers?.split(' ').first,
      ),
    ),
  );
}

Result<MusicItem> _parsePlaylistRow(Map<String, dynamic> renderer) {
  final title = flexColumnText(renderer, 0);
  final browseId = navOrNull<String>(renderer, P.navigationBrowseId);
  if (title == null || browseId == null) {
    return const Err(ParseFailure('playlist row title/browseId'));
  }

  // Subtitle reads "Playlist • Author • 25 songs", or drops the author. The
  // count is always last; the author is present only with three parts.
  final parts = _runTexts(flexColumnRuns(renderer, 1));

  return Ok(
    PlaylistItem(
      Playlist(
        id: normalisePlaylistId(browseId),
        title: title,
        artworkUrl: _artwork(renderer),
        author: parts.length >= 3 ? parts[1] : null,
        trackCount: parts.isEmpty
            ? null
            : int.tryParse(parts.last.split(' ').first.replaceAll(',', '')),
      ),
    ),
  );
}

Result<MusicItem> _parseStationRow(Map<String, dynamic> renderer) {
  final title = flexColumnText(renderer, 0);
  final playlistId = navOrNull<String>(renderer, P.navigationPlaylistId);
  if (title == null || playlistId == null) {
    return const Err(ParseFailure('station row title/playlistId'));
  }
  return Ok(
    StationItem(
      title: title,
      playlistId: playlistId,
      artworkUrl: _artwork(renderer),
    ),
  );
}

/// The text of every run, with the ` • ` separators removed.
List<String> _runTexts(List<dynamic>? runs) => [
  for (final run in runs ?? const [])
    if (run is Map<String, dynamic> && run['text'] is String)
      run['text'] as String,
].where((text) => text.trim() != '•').toList();

/// Picks the largest thumbnail offered, trying the shapes YouTube uses.
String? _artwork(Map<String, dynamic> renderer) {
  final thumbnails =
      navOrNull<List<dynamic>>(renderer, P.thumbnailNested) ??
      navOrNull<List<dynamic>>(renderer, P.thumbnailRenderer) ??
      navOrNull<List<dynamic>>(renderer, P.thumbnails) ??
      navOrNull<List<dynamic>>(renderer, P.thumbnailCropped);

  if (thumbnails == null || thumbnails.isEmpty) return null;
  final largest = thumbnails.last;
  return largest is Map<String, dynamic> ? largest['url'] as String? : null;
}

/// Parses a `musicTwoRowItemRenderer` — the card shape used by home-page
/// carousels, new-release shelves, and "recommended for you" grids.
///
/// These cards always have:
///   title.runs[0].text   → display title
///   subtitle.runs[*].text → artist / album / type label
///   thumbnailRenderer.musicThumbnailRenderer.thumbnail.thumbnails → artwork
///   navigationEndpoint → either watchEndpoint (song/video) or browseEndpoint
///     (album / playlist / artist / station depending on pageType).
Result<MusicItem> parseTwoRowItem(Map<String, dynamic> renderer) {
  final title = navOrNull<String>(renderer, P.titleText);
  if (title == null) {
    return const Err(ParseFailure('twoRowItem.title'));
  }

  final artworkUrl = _artwork(renderer);

  // --- Navigation endpoint ---------------------------------------------------
  final navEndpoint =
      renderer['navigationEndpoint'] as Map<String, dynamic>? ?? {};

  // 1. watchEndpoint → treat as song/video.
  final watchEndpoint =
      navEndpoint['watchEndpoint'] as Map<String, dynamic>?;
  if (watchEndpoint != null) {
    final videoId = watchEndpoint['videoId'] as String?;
    if (videoId == null) {
      return const Err(ParseFailure('twoRowItem.watchEndpoint.videoId'));
    }
    final subtitleRuns =
        (renderer['subtitle'] as Map<String, dynamic>?)?['runs']
            as List<dynamic>? ??
        const [];
    final artistName = subtitleRuns
        .whereType<Map<String, dynamic>>()
        .map((r) => r['text'] as String? ?? '')
        .where((t) => t.trim().isNotEmpty && t.trim() != '•')
        .join(', ');

    return Ok(
      SongItem(
        Song(
          id: videoId,
          title: title,
          artists: artistName.isNotEmpty
              ? [ArtistRef(name: artistName)]
              : const [],
          artworkUrl: artworkUrl,
          kind: SongKind.song,
        ),
      ),
    );
  }

  // 2. browseEndpoint → album / playlist / artist / station.
  final browseEndpoint =
      navEndpoint['browseEndpoint'] as Map<String, dynamic>?;
  if (browseEndpoint != null) {
    final browseId = browseEndpoint['browseId'] as String?;
    if (browseId == null) {
      return const Err(ParseFailure('twoRowItem.browseEndpoint.browseId'));
    }

    // pageType is nested inside browseEndpointContextSupportedConfigs.
    final pageType = navOrNull<String>(browseEndpoint, P.pageType);

    final subtitleRuns =
        (renderer['subtitle'] as Map<String, dynamic>?)?['runs']
            as List<dynamic>? ??
        const [];
    final subtitleText = subtitleRuns
        .whereType<Map<String, dynamic>>()
        .map((r) => r['text'] as String? ?? '')
        .where((t) => t.trim().isNotEmpty && t.trim() != '•')
        .join(' ');

    switch (pageType) {
      case 'MUSIC_PAGE_TYPE_ALBUM' ||
            'MUSIC_PAGE_TYPE_SINGLE' ||
            'MUSIC_PAGE_TYPE_EP':
        return Ok(
          AlbumItem(
            Album(
              browseId: browseId,
              title: title,
              artworkUrl: artworkUrl,
            ),
          ),
        );

      case 'MUSIC_PAGE_TYPE_ARTIST':
        return Ok(
          ArtistItem(
            Artist(browseId: browseId, name: title, artworkUrl: artworkUrl),
          ),
        );

      case 'MUSIC_PAGE_TYPE_PLAYLIST' || 'MUSIC_PAGE_TYPE_PODCAST' || null:
        // null pageType falls back to playlist / station.
        if (browseId.startsWith('MPREb') || browseId.startsWith('FEmusic')) {
          // Treat as a radio/station.
          return Ok(
            StationItem(
              title: title,
              playlistId: browseId,
              artworkUrl: artworkUrl,
            ),
          );
        }
        return Ok(
          PlaylistItem(
            Playlist(
              id: normalisePlaylistId(browseId),
              title: title,
              artworkUrl: artworkUrl,
              author: subtitleText.isNotEmpty ? subtitleText : null,
            ),
          ),
        );

      default:
        return Ok(
          PlaylistItem(
            Playlist(
              id: normalisePlaylistId(browseId),
              title: title,
              artworkUrl: artworkUrl,
            ),
          ),
        );
    }
  }

  // No recognised endpoint.
  return Err(
    ParseFailure(
      'twoRowItem.navigationEndpoint',
      message: 'neither watchEndpoint nor browseEndpoint found; '
          'keys: ${_runTexts(null)}',
    ),
  );
}

