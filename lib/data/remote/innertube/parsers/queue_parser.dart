import '../../../../domain/song.dart';
import '../innertube_utils.dart';
import '../json_nav.dart';
import 'song_runs.dart';

/// Parses the `next` (radio) response into a list of related [Song]s.
///
/// YouTube returns the up-next queue as a `playlistPanelRenderer` whose entries
/// are `playlistPanelVideoRenderer`s — a different shape from the list rows
/// elsewhere, with the artist line under `longBylineText` and the duration
/// under `lengthText`. Ported from Harmony's parseWatchPlaylist.
List<Song> parseWatchQueue(Map<String, dynamic> response) {
  final contents = navOrNull<List<dynamic>>(
    response,
    const JsonPath([
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
      'tabs',
      0,
      'tabRenderer',
      'content',
      'musicQueueRenderer',
      'content',
      'playlistPanelRenderer',
      'contents',
    ]),
  );
  if (contents == null) return const [];

  final songs = <Song>[];
  for (final entry in contents) {
    // Some entries are wrapped for A/B video/audio counterparts; unwrap to the
    // primary renderer.
    var renderer = navOrNull<Map<String, dynamic>>(
      entry,
      const JsonPath(['playlistPanelVideoRenderer']),
    );
    renderer ??= navOrNull<Map<String, dynamic>>(
      entry,
      const JsonPath([
        'playlistPanelVideoWrapperRenderer',
        'primaryRenderer',
        'playlistPanelVideoRenderer',
      ]),
    );
    if (renderer == null) continue;

    final song = _parsePanelVideo(renderer);
    if (song != null) songs.add(song);
  }
  return songs;
}

Song? _parsePanelVideo(Map<String, dynamic> data) {
  // Unplayable entries (region-locked, removed) carry an unplayableText field.
  if (data.containsKey('unplayableText')) return null;

  final videoId =
      navOrNull<String>(data, const JsonPath(['videoId'])) ??
      navOrNull<String>(
        data,
        const JsonPath(['navigationEndpoint', 'watchEndpoint', 'videoId']),
      );
  final title = navOrNull<String>(
    data,
    const JsonPath(['title', 'runs', 0, 'text']),
  );
  if (videoId == null || title == null) return null;

  final meta = parseSongRuns(
    navOrNull<List<dynamic>>(
          data,
          const JsonPath(['longBylineText', 'runs']),
        ) ??
        const [],
  );
  final duration =
      meta.duration ??
      parseDuration(
        navOrNull<String>(
          data,
          const JsonPath(['lengthText', 'runs', 0, 'text']),
        ),
      );

  final thumbnails = navOrNull<List<dynamic>>(
    data,
    const JsonPath(['thumbnail', 'thumbnails']),
  );
  String? artworkUrl;
  if (thumbnails != null && thumbnails.isNotEmpty) {
    final last = thumbnails.last;
    if (last is Map<String, dynamic>) artworkUrl = last['url'] as String?;
  }

  final videoType = navOrNull<String>(
    data,
    const JsonPath([
      'navigationEndpoint',
      'watchEndpoint',
      'watchEndpointMusicSupportedConfigs',
      'watchEndpointMusicConfig',
      'musicVideoType',
    ]),
  );

  return Song(
    id: videoId,
    title: title,
    artists: meta.artists,
    kind: videoType == 'MUSIC_VIDEO_TYPE_ATV' ? SongKind.song : SongKind.video,
    albumId: meta.albumId,
    albumTitle: meta.albumTitle,
    artworkUrl: artworkUrl,
    duration: duration,
  );
}
