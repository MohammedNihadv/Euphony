// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_playlists_dao.dart';

// ignore_for_file: type=lint
mixin _$SavedPlaylistsDaoMixin on DatabaseAccessor<EuphonyDatabase> {
  $SavedPlaylistsTable get savedPlaylists => attachedDatabase.savedPlaylists;
  SavedPlaylistsDaoManager get managers => SavedPlaylistsDaoManager(this);
}

class SavedPlaylistsDaoManager {
  final _$SavedPlaylistsDaoMixin _db;
  SavedPlaylistsDaoManager(this._db);
  $$SavedPlaylistsTableTableManager get savedPlaylists =>
      $$SavedPlaylistsTableTableManager(
        _db.attachedDatabase,
        _db.savedPlaylists,
      );
}
