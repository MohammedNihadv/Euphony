import '../../../../domain/artist_ref.dart';
import '../innertube_paths.dart';
import '../innertube_utils.dart';
import '../json_nav.dart';

/// The metadata line under a title, decomposed.
///
/// YouTube renders it as a flat list of runs joined by ` • `, mixing artists,
/// album, year, duration and view count in an order that varies by shelf. There
/// is no field telling you which is which — you infer it from whether the run
/// links somewhere and what its text looks like.
class SongRuns {
  const SongRuns({
    this.artists = const [],
    this.albumId,
    this.albumTitle,
    this.year,
    this.duration,
    this.views,
  });

  final List<ArtistRef> artists;
  final String? albumId;
  final String? albumTitle;
  final int? year;
  final Duration? duration;

  /// As displayed, e.g. `"1.2M"`.
  final String? views;
}

/// Content-type words YouTube puts as the first subtitle run; never artists.
const _typeLabels = {
  'song',
  'video',
  'album',
  'single',
  'ep',
  'playlist',
  'artist',
  'episode',
};

final _viewsPattern = RegExp(r'^\d([^ ])* [^ ]*$');
final _durationPattern = RegExp(r'^(\d+:)*\d+:\d+$');
final _yearPattern = RegExp(r'^\d{4}$');

/// Parses a metadata run list.
///
/// Ported from Harmony's `parseSongRuns`, with the same classification rules —
/// they are the product of watching what YouTube actually sends:
///
/// * odd indices are the ` • ` separators, skipped;
/// * a run with a `navigationEndpoint` is an artist, unless its browse id
///   starts with `MPRE` or contains `release_detail`, which makes it the album;
/// * a bare run is matched against view-count, duration and year shapes, in
///   that order, and is otherwise an artist with no link.
///
/// Order matters: `"2019"` matches the year pattern but would also match a
/// loose view-count pattern, so views are tested with a stricter rule first and
/// only from index 1 onward (a leading number is a title, not a count).
SongRuns parseSongRuns(List<dynamic> runs) {
  final artists = <ArtistRef>[];
  String? albumId;
  String? albumTitle;
  int? year;
  Duration? duration;
  String? views;

  for (var i = 0; i < runs.length; i++) {
    if (i.isOdd) continue;

    final run = runs[i];
    if (run is! Map<String, dynamic>) continue;
    final text = run['text'];
    if (text is! String) continue;

    if (run.containsKey('navigationEndpoint')) {
      final browseId = navOrNull<String>(run, P.navigationBrowseId);
      final isAlbum =
          browseId != null &&
          (browseId.startsWith('MPRE') || browseId.contains('release_detail'));

      if (isAlbum) {
        albumId = browseId;
        albumTitle = text;
      } else {
        artists.add(ArtistRef(name: text, browseId: browseId));
      }
      continue;
    }

    if (_durationPattern.hasMatch(text)) {
      duration = parseDuration(text);
    } else if (_yearPattern.hasMatch(text)) {
      year = int.tryParse(text);
    } else if (i > 0 && _viewsPattern.hasMatch(text)) {
      views = text.split(' ').first;
    } else if (_typeLabels.contains(text.trim().toLowerCase())) {
      // The first subtitle run on an unfiltered-search row is a content-type
      // word ("Song", "Video", "Album"). It is not an artist — dropping it here
      // is what stops rows reading "Song · Song" instead of "Song · Artist".
      continue;
    } else {
      artists.add(ArtistRef(name: text));
    }
  }

  return SongRuns(
    artists: artists,
    albumId: albumId,
    albumTitle: albumTitle,
    year: year,
    duration: duration,
    views: views,
  );
}
