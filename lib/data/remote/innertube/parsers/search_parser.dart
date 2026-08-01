import '../../../../core/log.dart';
import '../../../../core/result.dart';
import '../../../../domain/album.dart';
import '../../../../domain/artist.dart';
import '../../../../domain/music_item.dart';
import '../../../../domain/playlist.dart';
import '../../../../domain/search_results.dart';
import '../../../../domain/song.dart';
import '../innertube_paths.dart';
import '../innertube_utils.dart';
import '../json_nav.dart';
import 'item_parser.dart';
import 'song_runs.dart';

final _log = logFor('search_parser');

/// Parses a `search` response.
///
/// The shape depends on whether a filter was applied:
///
/// * **unfiltered** — a `musicCardShelfRenderer` holding the top result, then
///   `musicShelfRenderer` shelves for each type, capped at a few rows each;
/// * **filtered** — a single `musicShelfRenderer` with everything, plus a
///   continuation token.
///
/// Harmony handled both in one 200-line method that returned a
/// `Map<String, dynamic>` keyed by display strings, which is why its search
/// broke silently when a shelf title changed. Here the shape is typed and every
/// unparseable row is logged with the path that failed.
Result<SearchResults> parseSearch(
  Map<String, dynamic> response, {
  required String query,
  SearchFilter? filter,
}) {
  // An empty query or a query with no matches has no contents at all — that is
  // a legitimate empty result, not a parse failure.
  if (!response.containsKey('contents')) {
    return Ok(SearchResults(query: query));
  }

  final tabContent = navAny<Map<String, dynamic>>(response, [
    P.tabbedSearchTabs + [0, 'tabRenderer', 'content'],
    const JsonPath(['contents']),
  ]);
  if (tabContent case Err(:final failure)) return Err(failure);

  final content = tabContent.unwrap();

  final sectionsResult = nav<List<dynamic>>(content, P.sectionList);
  if (sectionsResult case Err(:final failure)) return Err(failure);
  final rawSections = sectionsResult.unwrap();

  final filters = filter == null
      ? _parseFilterChips(content)
      : const <String, String>{};

  MusicItem? topResult;
  final sections = <SearchSection>[];
  // Rows that arrive loose, outside any titled shelf. YouTube's current
  // unfiltered search returns the whole result list this way: one
  // `itemSectionRenderer` per row, no shelf and no headings. Older responses
  // (and every filtered one) still use titled `musicShelfRenderer` shelves, so
  // both shapes are handled.
  final looseItems = <MusicItem>[];
  String? didYouMean;

  for (final raw in rawSections) {
    if (raw is! Map<String, dynamic>) continue;

    if (raw[P.cardShelf] case final Map<String, dynamic> card) {
      topResult ??= _parseTopResult(card);
      // The card carries a few related rows of its own beneath the headline.
      looseItems.addAll(
        _parseRows(
          navOrNull<List<dynamic>>(card, const JsonPath(['contents'])),
          hint: null,
          context: 'top result card',
        ),
      );
      continue;
    }

    if (raw[P.shelf] case final Map<String, dynamic> shelf) {
      final section = _parseShelf(shelf, filter: filter);
      if (section != null) sections.add(section);
      continue;
    }

    if (raw['itemSectionRenderer'] case final Map<String, dynamic> section) {
      // "Did you mean …" occupies an item section of its own.
      didYouMean ??= navOrNull<String>(
        section,
        const JsonPath([
          'contents',
          0,
          'didYouMeanRenderer',
          'correctedQuery',
          'runs',
          0,
          'text',
        ]),
      );

      looseItems.addAll(
        _parseRows(
          navOrNull<List<dynamic>>(section, const JsonPath(['contents'])),
          hint: _hintFor(filter, ''),
          context: 'item section',
        ),
      );
    }
  }

  if (looseItems.isNotEmpty) {
    sections.insert(
      0,
      SearchSection(title: _titleFor(filter), items: looseItems),
    );
  }

  return Ok(
    SearchResults(
      query: query,
      topResult: topResult,
      sections: sections,
      filters: filters,
      didYouMean: didYouMean,
    ),
  );
}

/// The chip row above the results — "Songs", "Videos", "Albums" — each carrying
/// the `params` value that re-runs the search scoped to it.
Map<String, String> _parseFilterChips(Map<String, dynamic> content) {
  final chips = navOrNull<List<dynamic>>(content, P.searchChips);
  if (chips == null) return const {};

  final filters = <String, String>{};
  for (final chip in chips) {
    final renderer = navOrNull<Map<String, dynamic>>(
      chip,
      const JsonPath(['chipCloudChipRenderer']),
    );
    if (renderer == null) continue;

    final label = navOrNull<String>(renderer, P.textRunText);
    final params = navOrNull<String>(
      renderer,
      const JsonPath(['navigationEndpoint', 'searchEndpoint', 'params']),
    );
    if (label != null && params != null) filters[label] = params;
  }
  return filters;
}

/// The top result is a `musicCardShelfRenderer`, a different shape from every
/// other row: its title is a run list, its type is the first subtitle run, and
/// its endpoint hangs off `title.runs[0]` or `onTap`.
MusicItem? _parseTopResult(Map<String, dynamic> card) {
  final title = navOrNull<String>(card, P.titleText);
  if (title == null) return null;

  final subtitleRuns = navOrNull<List<dynamic>>(
    card,
    const JsonPath(['subtitle', 'runs']),
  );
  final kind = navOrNull<String>(card, P.subtitle)?.toLowerCase();
  final artworkUrl = _largestThumbnail(card);

  // Everything after the type run is the usual artist/album/year line.
  final meta = parseSongRuns(
    subtitleRuns == null || subtitleRuns.length < 2
        ? const []
        : subtitleRuns.sublist(2),
  );

  final browseId =
      navOrNull<String>(
        card,
        const JsonPath(['title', 'runs', 0]) + P.navigationBrowseId.steps,
      ) ??
      navOrNull<String>(
        card,
        const JsonPath(['onTap', 'browseEndpoint', 'browseId']),
      ) ??
      navOrNull<String>(card, P.navigationBrowseId) ??
      navOrNull<String>(
        card,
        const JsonPath([
          'buttons',
          0,
          'buttonRenderer',
          'command',
          'browseEndpoint',
          'browseId',
        ]),
      ) ??
      navOrNull<String>(
        card,
        const JsonPath([
          'buttons',
          0,
          'buttonRenderer',
          'navigationEndpoint',
          'browseEndpoint',
          'browseId',
        ]),
      );
  final videoId =
      navOrNull<String>(
        card,
        const JsonPath(['onTap', 'watchEndpoint', 'videoId']),
      ) ??
      navOrNull<String>(
        card,
        const JsonPath([
          'title',
          'runs',
          0,
          'navigationEndpoint',
          'watchEndpoint',
          'videoId',
        ]),
      ) ??
      navOrNull<String>(
        card,
        const JsonPath([
          'buttons',
          0,
          'buttonRenderer',
          'command',
          'watchEndpoint',
          'videoId',
        ]),
      ) ??
      navOrNull<String>(
        card,
        const JsonPath([
          'buttons',
          0,
          'buttonRenderer',
          'navigationEndpoint',
          'watchEndpoint',
          'videoId',
        ]),
      ) ??
      navOrNull<String>(card, P.navigationVideoId);

  switch (kind) {
    case 'artist':
      if (browseId == null) return null;
      return ArtistItem(
        Artist(browseId: browseId, name: title, artworkUrl: artworkUrl),
      );

    case 'album' || 'single' || 'ep':
      if (browseId == null) return null;
      return AlbumItem(
        Album(
          browseId: browseId,
          title: title,
          artists: meta.artists,
          artworkUrl: artworkUrl,
          year: meta.year,
        ),
      );

    case 'playlist':
      if (browseId == null) return null;
      return PlaylistItem(
        Playlist(
          id: normalisePlaylistId(browseId),
          title: title,
          artworkUrl: artworkUrl,
        ),
      );

    case 'song' || 'video':
      if (videoId == null) return null;
      return SongItem(
        Song(
          id: videoId,
          title: title,
          artists: meta.artists,
          kind: kind == 'video' ? SongKind.video : SongKind.song,
          albumId: meta.albumId,
          albumTitle: meta.albumTitle,
          artworkUrl: artworkUrl,
          duration: meta.duration,
          year: meta.year,
        ),
      );

    default:
      _log.fine('top result had an unrecognised subtitle "$kind"');
      return null;
  }
}

String? _largestThumbnail(Map<String, dynamic> card) {
  final thumbnails =
      navOrNull<List<dynamic>>(card, P.thumbnailNested) ??
      navOrNull<List<dynamic>>(card, P.thumbnails);
  if (thumbnails == null || thumbnails.isEmpty) return null;
  final largest = thumbnails.last;
  return largest is Map<String, dynamic> ? largest['url'] as String? : null;
}

SearchSection? _parseShelf(Map<String, dynamic> shelf, {SearchFilter? filter}) {
  final title = navOrNull<String>(shelf, P.titleText) ?? _titleFor(filter);
  final contents = navOrNull<List<dynamic>>(
    shelf,
    const JsonPath(['contents']),
  );
  if (contents == null) return null;

  return SearchSection(
    title: title,
    items: _parseRows(contents, hint: _hintFor(filter, title), context: title),
    continuationToken: navOrNull<String>(
      shelf,
      const JsonPath([
        'continuations',
        0,
        'nextContinuationData',
        'continuation',
      ]),
    ),
  );
}

/// Parses a list of `musicResponsiveListItemRenderer` wrappers.
///
/// A row that fails is logged with the path that broke and dropped — one bad
/// row must not empty the whole list, but it must never disappear silently.
/// [context] names the shelf in that log line.
List<MusicItem> _parseRows(
  List<dynamic>? entries, {
  required ItemHint? hint,
  required String context,
}) {
  final items = <MusicItem>[];
  for (final entry in entries ?? const []) {
    final renderer = navOrNull<Map<String, dynamic>>(
      entry,
      const JsonPath([P.responsiveListItem]),
    );
    if (renderer == null) continue;

    switch (parseListItem(renderer, hint: hint)) {
      case Ok(:final value):
        items.add(value);
      case Err(:final failure):
        _log.warning('dropped a row in "$context": $failure');
    }
  }
  return items;
}

/// A filtered search's shelf carries no title of its own.
String _titleFor(SearchFilter? filter) => switch (filter) {
  SearchFilter.songs => 'Songs',
  SearchFilter.videos => 'Videos',
  SearchFilter.albums => 'Albums',
  SearchFilter.artists => 'Artists',
  SearchFilter.playlists => 'Playlists',
  SearchFilter.communityPlaylists => 'Community playlists',
  SearchFilter.featuredPlaylists => 'Featured playlists',
  null => 'Results',
};

/// A filtered search knows what its rows are; an unfiltered one falls back to
/// the shelf title, and failing that lets the item parser infer per row.
ItemHint? _hintFor(SearchFilter? filter, String title) {
  final fromFilter = switch (filter) {
    SearchFilter.songs => ItemHint.song,
    SearchFilter.videos => ItemHint.video,
    SearchFilter.albums => ItemHint.album,
    SearchFilter.artists => ItemHint.artist,
    SearchFilter.playlists ||
    SearchFilter.communityPlaylists ||
    SearchFilter.featuredPlaylists => ItemHint.playlist,
    null => null,
  };
  if (fromFilter != null) return fromFilter;

  return switch (title.toLowerCase()) {
    'songs' => ItemHint.song,
    'videos' => ItemHint.video,
    'albums' => ItemHint.album,
    'artists' => ItemHint.artist,
    'playlists' ||
    'community playlists' ||
    'featured playlists' => ItemHint.playlist,
    _ => null,
  };
}

/// Parses a `music/get_search_suggestions` response into plain query strings.
Result<List<String>> parseSearchSuggestions(Map<String, dynamic> response) {
  final contents = nav<List<dynamic>>(response, P.searchSuggestions);
  // No suggestions is a valid answer for a query nothing matches.
  if (contents case Err()) return const Ok([]);

  return Ok([
    for (final entry in contents.unwrap())
      if (navOrNull<String>(entry, P.searchSuggestionQuery)
          case final String query)
        query,
  ]);
}
