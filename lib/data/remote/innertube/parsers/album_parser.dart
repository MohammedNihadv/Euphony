import '../../../../core/result.dart';
import '../../../../domain/album.dart';
import '../../../../domain/music_item.dart';
import '../../../../domain/playlist.dart';
import '../../../../domain/song.dart';
import '../innertube_paths.dart';
import '../json_nav.dart';
import 'item_parser.dart';

/// Parsed album details with tracks.
class AlbumDetails {
  const AlbumDetails({required this.album, required this.tracks});

  final Album album;
  final List<Song> tracks;
}

/// Parsed playlist details with tracks.
class PlaylistDetails {
  const PlaylistDetails({required this.playlist, required this.tracks});

  final Playlist playlist;
  final List<Song> tracks;
}

/// Parses an album browse endpoint response (`MPRE...`).
Result<AlbumDetails> parseAlbumDetails(
  Map<String, dynamic> root,
  String browseId,
) {
  final title = navOrNull<String>(root, P.titleText) ?? 'Album';
  final artworkUrl = navOrNull<String>(root, P.thumbnails + [0, 'url']);

  final secondary = navOrNull<List<dynamic>>(root, P.twoColumnSecondary);
  final contentsList =
      secondary ?? navOrNull<List<dynamic>>(root, P.sectionList) ?? const [];

  final tracks = <Song>[];

  for (final item in contentsList) {
    if (item is! Map<String, dynamic>) continue;
    final shelf =
        item['musicPlaylistShelfRenderer'] as Map<String, dynamic>? ??
        item['musicShelfRenderer'] as Map<String, dynamic>?;
    if (shelf == null) continue;

    final contents = shelf['contents'] as List<dynamic>? ?? const [];
    for (final rawTrack in contents) {
      if (rawTrack is! Map<String, dynamic>) continue;
      final renderer =
          rawTrack['musicResponsiveListItemRenderer']
              as Map<String, dynamic>? ??
          rawTrack;
      final parsed = parseListItem(renderer, hint: ItemHint.song);
      if (parsed case Ok(value: SongItem(:final song))) {
        tracks.add(song);
      }
    }
  }

  return Ok(
    AlbumDetails(
      album: Album(browseId: browseId, title: title, artworkUrl: artworkUrl),
      tracks: tracks,
    ),
  );
}

/// Parses a playlist browse endpoint response (`VL...`).
Result<PlaylistDetails> parsePlaylistDetails(
  Map<String, dynamic> root,
  String playlistId,
) {
  final title = navOrNull<String>(root, P.titleText) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicDetailHeaderRenderer', 'title', 'runs', 0, 'text'])) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicResponsiveHeaderRenderer', 'title', 'runs', 0, 'text'])) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicEditablePlaylistDetailHeaderRenderer', 'header', 'musicResponsiveHeaderRenderer', 'title', 'runs', 0, 'text'])) ??
      'Playlist';
  final artworkUrl = navOrNull<String>(root, P.thumbnails + [0, 'url']) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicDetailHeaderRenderer', 'thumbnail', 'croppedSquareThumbnailRenderer', 'thumbnail', 'thumbnails', 0, 'url'])) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicResponsiveHeaderRenderer', 'thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails', 0, 'url'])) ??
      navOrNull<String>(root, const JsonPath(['header', 'musicEditablePlaylistDetailHeaderRenderer', 'header', 'musicResponsiveHeaderRenderer', 'thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails', 0, 'url']));

  final secondary = navOrNull<List<dynamic>>(root, P.twoColumnSecondary);
  final singleColumn = navOrNull<List<dynamic>>(
    root,
    const JsonPath([
      'contents',
      'singleColumnBrowseResultsRenderer',
      'tabs',
      0,
      'tabRenderer',
      'content',
      'sectionListRenderer',
      'contents',
    ]),
  );
  final contentsList =
      secondary ??
      singleColumn ??
      navOrNull<List<dynamic>>(root, P.sectionList) ??
      const [];

  final tracks = <Song>[];

  for (final item in contentsList) {
    if (item is! Map<String, dynamic>) continue;
    final shelf =
        item['musicPlaylistShelfRenderer'] as Map<String, dynamic>? ??
        item['musicShelfRenderer'] as Map<String, dynamic>?;
    if (shelf == null) continue;

    final contents = shelf['contents'] as List<dynamic>? ?? const [];
    for (final rawTrack in contents) {
      if (rawTrack is! Map<String, dynamic>) continue;
      final renderer =
          rawTrack['musicResponsiveListItemRenderer']
              as Map<String, dynamic>? ??
          rawTrack;
      final parsed = parseListItem(renderer, hint: ItemHint.song);
      if (parsed case Ok(value: SongItem(:final song))) {
        tracks.add(song);
      }
    }
  }

  return Ok(
    PlaylistDetails(
      playlist: Playlist(
        id: playlistId,
        title: title,
        artworkUrl: artworkUrl,
        trackCount: tracks.length,
      ),
      tracks: tracks,
    ),
  );
}
