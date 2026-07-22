import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// Euphony's local database.
///
/// Replaces Harmony's Hive boxes — most importantly its one-box-per-playlist
/// layout, where track order was a manual list rewrite (developer guide 7.2).
/// Here relationships are rows and ordering is a column.
@DriftDatabase(tables: [SearchHistory])
class EuphonyDatabase extends _$EuphonyDatabase {
  EuphonyDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  /// Bump this for every schema change and add a step to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'euphony', native: const DriftNativeOptions());
}
