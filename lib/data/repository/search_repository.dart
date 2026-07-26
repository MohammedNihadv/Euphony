import '../../core/result.dart';
import '../../domain/search_results.dart';
import '../remote/innertube/innertube_client.dart';
import '../remote/innertube/innertube_constants.dart';
import '../remote/innertube/innertube_utils.dart';
import '../remote/innertube/parsers/search_parser.dart';

class SearchRepository {
  SearchRepository(this._client);

  final InnertubeClient _client;

  Future<Result<SearchResults>> search(
    String query, {
    SearchFilter? filter,
    String? params,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Ok(SearchResults(query: trimmed));

    final response = await _client.post(Innertube.search, {
      ..._client.context,
      'query': trimmed,
      if (params ?? searchParams(filter: filter) case final String params)
        'params': params,
    });

    return response.flatMap(
      (json) => parseSearch(json, query: trimmed, filter: filter),
    );
  }

  Future<Result<List<String>>> suggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const Ok([]);

    final response = await _client.post(Innertube.searchSuggestions, {
      ..._client.context,
      'input': trimmed,
    });

    return response.flatMap(parseSearchSuggestions);
  }
}
