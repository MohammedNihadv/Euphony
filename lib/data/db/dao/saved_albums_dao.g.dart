// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_albums_dao.dart';

// ignore_for_file: type=lint
mixin _$SavedAlbumsDaoMixin on DatabaseAccessor<EuphonyDatabase> {
  $SavedAlbumsTable get savedAlbums => attachedDatabase.savedAlbums;
  SavedAlbumsDaoManager get managers => SavedAlbumsDaoManager(this);
}

class SavedAlbumsDaoManager {
  final _$SavedAlbumsDaoMixin _db;
  SavedAlbumsDaoManager(this._db);
  $$SavedAlbumsTableTableManager get savedAlbums =>
      $$SavedAlbumsTableTableManager(_db.attachedDatabase, _db.savedAlbums);
}
