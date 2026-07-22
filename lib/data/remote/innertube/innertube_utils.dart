import 'json_nav.dart';

/// Small helpers ported from Harmony's `services/utils.dart`.

/// Parses `"3:45"` or `"1:02:03"` into a [Duration].
///
/// Returns `null` for anything that is not a duration, which is normal — some
/// rows carry a view count in that slot instead.
Duration? parseDuration(String? text) {
  if (text == null || text.isEmpty) return null;

  final parts = text.split(':').reversed.toList();
  if (parts.length > 3) return null;

  // seconds, minutes, hours
  const multipliers = [1, 60, 3600];
  var seconds = 0;
  for (var i = 0; i < parts.length; i++) {
    final value = int.tryParse(parts[i].trim());
    if (value == null || value < 0) return null;
    seconds += value * multipliers[i];
  }
  return Duration(seconds: seconds);
}

/// Strips the `VL` prefix YouTube puts on playlist browse ids.
String normalisePlaylistId(String playlistId) =>
    playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId;

/// Whether a stream URL (or a raw [epoch] second) is at or near expiry.
///
/// Treats anything expiring within 30 minutes as already expired, so a track
/// queued now still has a usable URL when it starts playing.
bool isExpired({String? url, int? epoch, DateTime Function()? clock}) {
  var deadline = epoch;

  if (url != null) {
    final match = RegExp(r'[?&]expire=([0-9]+)').firstMatch(url);
    if (match != null) deadline = int.tryParse(match.group(1)!);
  }

  if (deadline == null) return true;
  final nowSeconds = (clock ?? DateTime.now)().millisecondsSinceEpoch ~/ 1000;
  return nowSeconds + 1800 >= deadline;
}

/// Reads the text out of flex column [index] of a `musicResponsiveListItem`.
///
/// Flex columns are how YouTube lays out a list row: column 0 is the title,
/// column 1 the artist line, column 2 the album. Which column holds what varies
/// by shelf, so callers check.
String? flexColumnText(
  Map<String, dynamic> item,
  int index, {
  int runIndex = 0,
}) => navOrNull<String>(
  item,
  JsonPath([
    'flexColumns',
    index,
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
    runIndex,
    'text',
  ]),
);

/// The whole run list of flex column [index], for rows where the artist line is
/// several linked runs.
List<dynamic>? flexColumnRuns(Map<String, dynamic> item, int index) =>
    navOrNull<List<dynamic>>(
      item,
      JsonPath([
        'flexColumns',
        index,
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
      ]),
    );

/// Reads fixed column [index] — where a track's duration sits in album and
/// playlist listings.
String? fixedColumnText(Map<String, dynamic> item, int index) =>
    navOrNull<String>(
      item,
      JsonPath([
        'fixedColumns',
        index,
        'musicResponsiveListItemFixedColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]),
    );

/// The index of the ` • ` separator in a run list, or -1.
///
/// YouTube joins metadata with that exact string; everything before it is
/// artists, everything after is album/year/duration.
int dotSeparatorIndex(List<dynamic> runs) => runs.indexWhere(
  (run) => run is Map && run.length == 1 && run['text'] == ' • ',
);

/// Which search filters the API accepts.
enum SearchFilter {
  songs,
  videos,
  albums,
  artists,
  playlists,
  communityPlaylists,
  featuredPlaylists,
}

/// Builds the opaque `params` value that scopes a search to one result type.
///
/// These are protobuf fragments YouTube's own client sends; they are copied
/// from Harmony, which copied them from ytmusicapi. Nobody derives them — they
/// are observed.
String? searchParams({SearchFilter? filter, bool ignoreSpelling = false}) {
  if (filter == null) {
    return ignoreSpelling ? 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D' : null;
  }

  if (filter == SearchFilter.playlists) {
    return ignoreSpelling
        ? 'Eg-KAQwIABAAGAAgACgBMABCAggBagoQBBADEAkQBRAK'
        : 'Eg-KAQwIABAAGAAgACgBMABqChAEEAMQCRAFEAo%3D';
  }

  if (filter == SearchFilter.communityPlaylists ||
      filter == SearchFilter.featuredPlaylists) {
    const prefix = 'EgeKAQQoA';
    final middle = filter == SearchFilter.featuredPlaylists ? 'Dg' : 'EA';
    final suffix = ignoreSpelling
        ? 'BQgIIAWoMEA4QChADEAQQCRAF'
        : 'BagwQDhAKEAMQBBAJEAU%3D';
    return '$prefix$middle$suffix';
  }

  const prefix = 'EgWKAQI';
  final middle = switch (filter) {
    SearchFilter.songs => 'I',
    SearchFilter.videos => 'Q',
    SearchFilter.albums => 'Y',
    SearchFilter.artists => 'g',
    // Handled above.
    SearchFilter.playlists ||
    SearchFilter.communityPlaylists ||
    SearchFilter.featuredPlaylists => 'o',
  };
  final suffix = ignoreSpelling
      ? 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D'
      : 'AWoMEA4QChADEAQQCRAF';
  return '$prefix$middle$suffix';
}
