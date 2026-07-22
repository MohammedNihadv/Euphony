import 'package:meta/meta.dart';

import '../data/remote/innertube/parsers/item_parser.dart';

/// One titled shelf of search results — "Songs", "Albums", "Community
/// playlists".
@immutable
class SearchSection {
  const SearchSection({
    required this.title,
    required this.items,
    this.continuationToken,
  });

  final String title;
  final List<MusicItem> items;

  /// Token for the next page of this shelf, when it has one.
  final String? continuationToken;

  bool get hasMore => continuationToken != null;
}

@immutable
class SearchResults {
  const SearchResults({
    required this.query,
    this.topResult,
    this.sections = const [],
    this.filters = const {},
    this.didYouMean,
  });

  final String query;

  /// The single best match YouTube picked, shown above the shelves.
  final MusicItem? topResult;

  final List<SearchSection> sections;

  /// Filter chip label to its opaque `params` value, e.g.
  /// `{'Songs': 'EgWKAQIIAWoM…'}`. Re-running the search with one of these
  /// scopes the results to that type.
  final Map<String, String> filters;

  /// YouTube's spelling correction, when it offered one.
  final String? didYouMean;

  bool get isEmpty =>
      topResult == null && sections.every((s) => s.items.isEmpty);
}
