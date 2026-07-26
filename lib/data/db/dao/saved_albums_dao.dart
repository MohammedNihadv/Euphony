import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'saved_albums_dao.g.dart';

@DriftAccessor(tables: [SavedAlbums])
class SavedAlbumsDao extends DatabaseAccessor<EuphonyDatabase>
    with _$SavedAlbumsDaoMixin {
  SavedAlbumsDao(super.db);

  Stream<List<SavedAlbumEntry>> watchAll() =>
      (savedAlbums.select()..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
          .watch();

  Future<bool> isSaved(String browseId) async {
    final query = savedAlbums.select()
      ..where((t) => t.browseId.equals(browseId));
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  Future<void> save({
    required String browseId,
    required String title,
    required String artists,
    String? artworkUrl,
    int? year,
  }) async {
    await savedAlbums.insertOnConflictUpdate(
      SavedAlbumsCompanion(
        browseId: Value(browseId),
        title: Value(title),
        artists: Value(artists),
        artworkUrl: Value(artworkUrl),
        year: Value(year),
        savedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> remove(String browseId) async {
    await (savedAlbums.delete()..where((t) => t.browseId.equals(browseId)))
        .go();
  }
}
