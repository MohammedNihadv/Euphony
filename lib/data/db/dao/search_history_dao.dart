import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'search_history_dao.g.dart';

@DriftAccessor(tables: [SearchHistory])
class SearchHistoryDao extends DatabaseAccessor<EuphonyDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.db);

  /// The [limit] most recently used queries, newest first.
  Stream<List<SearchHistoryEntry>> watchRecent({int limit = 20}) {
    return (select(searchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(limit))
        .watch();
  }

  /// Records [query] as just used, moving it to the top if already present.
  Future<void> record(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return into(searchHistory).insertOnConflictUpdate(
      SearchHistoryCompanion.insert(query: trimmed, lastUsedAt: DateTime.now()),
    );
  }

  Future<void> remove(String query) =>
      (delete(searchHistory)..where((t) => t.query.equals(query))).go();

  Future<void> clear() => delete(searchHistory).go();
}
