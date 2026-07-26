import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [SearchHistory, LikedSongs, SavedAlbums, SavedPlaylists])
class EuphonyDatabase extends _$EuphonyDatabase {
  EuphonyDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      if (!kIsWeb) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
  );
}

QueryExecutor _openConnection() {
  if (kIsWeb) {
    return driftDatabase(name: 'euphony');
  }
  return driftDatabase(name: 'euphony', native: const DriftNativeOptions());
}
