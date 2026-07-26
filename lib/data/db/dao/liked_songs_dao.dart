import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'liked_songs_dao.g.dart';

@DriftAccessor(tables: [LikedSongs])
class LikedSongsDao extends DatabaseAccessor<EuphonyDatabase>
    with _$LikedSongsDaoMixin {
  LikedSongsDao(super.db);

  Stream<List<LikedSongEntry>> watchAll() =>
      (likedSongs.select()..orderBy([(t) => OrderingTerm.desc(t.likedAt)]))
          .watch();

  Future<bool> isLiked(String id) async {
    final query = likedSongs.select()..where((t) => t.id.equals(id));
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  Stream<bool> watchIsLiked(String id) {
    final query = likedSongs.select()..where((t) => t.id.equals(id));
    return query.watch().map((rows) => rows.isNotEmpty);
  }

  Future<void> like({
    required String id,
    required String title,
    required String artists,
    String? albumTitle,
    String? artworkUrl,
    int? durationSeconds,
    bool isExplicit = false,
  }) async {
    await likedSongs.insertOnConflictUpdate(
      LikedSongsCompanion(
        id: Value(id),
        title: Value(title),
        artists: Value(artists),
        albumTitle: Value(albumTitle),
        artworkUrl: Value(artworkUrl),
        durationSeconds: Value(durationSeconds),
        isExplicit: Value(isExplicit),
        likedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> unlike(String id) async {
    await (likedSongs.delete()..where((t) => t.id.equals(id))).go();
  }
}
