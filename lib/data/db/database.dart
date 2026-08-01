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
    onUpgrade: (m, from, to) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      if (!kIsWeb) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
      try {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS search_history (query TEXT NOT NULL PRIMARY KEY, last_used_at INTEGER NOT NULL);',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS liked_songs (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, artists TEXT NOT NULL, album_title TEXT, artwork_url TEXT, duration_seconds INTEGER, is_explicit INTEGER NOT NULL DEFAULT 0, liked_at INTEGER NOT NULL);',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS saved_albums (browse_id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, artists TEXT NOT NULL, artwork_url TEXT, year INTEGER, saved_at INTEGER NOT NULL);',
        );
        await customStatement(
          'CREATE TABLE IF NOT EXISTS saved_playlists (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, author TEXT, artwork_url TEXT, track_count INTEGER, saved_at INTEGER NOT NULL);',
        );
      } catch (_) {}
    },
  );
}

QueryExecutor _openConnection() {
  if (kIsWeb) {
    return driftDatabase(name: 'euphony');
  }
  return driftDatabase(name: 'euphony', native: const DriftNativeOptions());
}
