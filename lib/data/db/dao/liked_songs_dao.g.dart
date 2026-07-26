// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked_songs_dao.dart';

// ignore_for_file: type=lint
mixin _$LikedSongsDaoMixin on DatabaseAccessor<EuphonyDatabase> {
  $LikedSongsTable get likedSongs => attachedDatabase.likedSongs;
  LikedSongsDaoManager get managers => LikedSongsDaoManager(this);
}

class LikedSongsDaoManager {
  final _$LikedSongsDaoMixin _db;
  LikedSongsDaoManager(this._db);
  $$LikedSongsTableTableManager get likedSongs =>
      $$LikedSongsTableTableManager(_db.attachedDatabase, _db.likedSongs);
}
