import '../../core/result.dart';
import '../../domain/search_results.dart';
import '../remote/innertube/innertube_client.dart';
import '../remote/innertube/innertube_constants.dart';
import '../remote/innertube/innertube_utils.dart';
import '../remote/innertube/parsers/search_parser.dart';

/// A cached search result entry with a creation timestamp for TTL checks.
class _CacheEntry<T> {
  _CacheEntry(this.value) : createdAt = DateTime.now();
  final T value;
  final DateTime createdAt;

  bool get isStale =>
      DateTime.now().difference(createdAt) > const Duration(minutes: 5);
}

class SearchRepository {
  SearchRepository(this._client);

  final InnertubeClient _client;

  /// LRU-style in-memory cache for full search results (max 20 entries, 5 min TTL).
  final _searchCache = <String, _CacheEntry<SearchResults>>{};
  static const _maxSearchCacheSize = 20;

  /// LRU-style in-memory cache for search suggestions (max 50 entries, 5 min TTL).
  final _suggestionCache = <String, _CacheEntry<List<String>>>{};
  static const _maxSuggestionCacheSize = 50;

  Future<Result<SearchResults>> search(
    String query, {
    SearchFilter? filter,
    String? params,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Ok(SearchResults(query: trimmed));

    // Build cache key including the filter so different filters are cached separately.
    final cacheKey = '${filter?.name ?? "all"}:$trimmed';
    final cached = _searchCache[cacheKey];
    if (cached != null && !cached.isStale) {
      // Move to end (most-recently-used) by re-inserting.
      _searchCache.remove(cacheKey);
      _searchCache[cacheKey] = cached;
      return Ok(cached.value);
    }

    final response = await _client.post(Innertube.search, {
      ..._client.context,
      'query': trimmed,
      if (params ?? searchParams(filter: filter) case final String p)
        'params': p,
    });

    return response.flatMap((json) {
      final result = parseSearch(json, query: trimmed, filter: filter);
      if (result case Ok(:final value)) {
        // Evict oldest entry when at capacity.
        if (_searchCache.length >= _maxSearchCacheSize) {
          _searchCache.remove(_searchCache.keys.first);
        }
        _searchCache[cacheKey] = _CacheEntry(value);
      }
      return result;
    });
  }

  Future<Result<List<String>>> suggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const Ok([]);

    final cached = _suggestionCache[trimmed];
    if (cached != null && !cached.isStale) {
      _suggestionCache.remove(trimmed);
      _suggestionCache[trimmed] = cached;
      return Ok(cached.value);
    }

    final response = await _client.post(Innertube.searchSuggestions, {
      ..._client.context,
      'input': trimmed,
    });

    return response.flatMap((json) {
      final result = parseSearchSuggestions(json);
      if (result case Ok(:final value)) {
        if (_suggestionCache.length >= _maxSuggestionCacheSize) {
          _suggestionCache.remove(_suggestionCache.keys.first);
        }
        _suggestionCache[trimmed] = _CacheEntry(value);
      }
      return result;
    });
  }
}
