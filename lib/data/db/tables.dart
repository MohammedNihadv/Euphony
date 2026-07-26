import 'package:drift/drift.dart';

@DataClassName('SearchHistoryEntry')
class SearchHistory extends Table {
  TextColumn get query => text()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {query};
}

@DataClassName('LikedSongEntry')
class LikedSongs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artists => text()();
  TextColumn get albumTitle => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get isExplicit => boolean().withDefault(const Constant(false))();
  DateTimeColumn get likedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SavedAlbumEntry')
class SavedAlbums extends Table {
  TextColumn get browseId => text()();
  TextColumn get title => text()();
  TextColumn get artists => text()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {browseId};
}

@DataClassName('SavedPlaylistEntry')
class SavedPlaylists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get trackCount => integer().nullable()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
