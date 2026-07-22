import 'package:drift/drift.dart';

/// Queries the user has typed into search, most recent first.
///
/// Replaces Harmony's `searchQuery` Hive box.
@DataClassName('SearchHistoryEntry')
class SearchHistory extends Table {
  TextColumn get query => text()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {query};
}
