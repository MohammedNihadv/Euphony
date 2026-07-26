import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'saved_playlists_dao.g.dart';

@DriftAccessor(tables: [SavedPlaylists])
class SavedPlaylistsDao extends DatabaseAccessor<EuphonyDatabase>
    with _$SavedPlaylistsDaoMixin {
  SavedPlaylistsDao(super.db);

  Stream<List<SavedPlaylistEntry>> watchAll() =>
      (savedPlaylists.select()..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
          .watch();

  Future<bool> isSaved(String id) async {
    final query = savedPlaylists.select()..where((t) => t.id.equals(id));
    final rows = await query.get();
    return rows.isNotEmpty;
  }

  Future<void> save({
    required String id,
    required String title,
    String? author,
    String? artworkUrl,
    int? trackCount,
  }) async {
    await savedPlaylists.insertOnConflictUpdate(
      SavedPlaylistsCompanion(
        id: Value(id),
        title: Value(title),
        author: Value(author),
        artworkUrl: Value(artworkUrl),
        trackCount: Value(trackCount),
        savedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> remove(String id) async {
    await (savedPlaylists.delete()..where((t) => t.id.equals(id))).go();
  }
}
