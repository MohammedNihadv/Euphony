import 'package:drift/native.dart';
import 'package:euphony/data/db/dao/saved_albums_dao.dart';
import 'package:euphony/data/db/dao/saved_playlists_dao.dart';
import 'package:euphony/data/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EuphonyDatabase db;
  late SavedAlbumsDao albumsDao;
  late SavedPlaylistsDao playlistsDao;

  setUp(() {
    db = EuphonyDatabase(NativeDatabase.memory());
    albumsDao = SavedAlbumsDao(db);
    playlistsDao = SavedPlaylistsDao(db);
  });

  tearDown(() async => db.close());

  test(
    'album save is reflected in watchIsSaved and watchAll, remove clears it',
    () async {
      expect(await albumsDao.watchIsSaved('MPREb_test').first, isFalse);

      await albumsDao.save(
        browseId: 'MPREb_test',
        title: 'Test Album',
        artists: 'Test Artist',
        artworkUrl: 'https://example.com/a.jpg',
        year: 2024,
      );

      expect(await albumsDao.watchIsSaved('MPREb_test').first, isTrue);
      final saved = await albumsDao.watchAll().first;
      expect(saved, hasLength(1));
      expect(saved.first.title, 'Test Album');
      expect(saved.first.artists, 'Test Artist');
      expect(saved.first.year, 2024);

      await albumsDao.remove('MPREb_test');

      expect(await albumsDao.watchIsSaved('MPREb_test').first, isFalse);
      expect(await albumsDao.watchAll().first, isEmpty);
    },
  );

  test(
    'playlist save is reflected in watchIsSaved and remove clears it',
    () async {
      expect(await playlistsDao.watchIsSaved('PL_test').first, isFalse);

      await playlistsDao.save(
        id: 'PL_test',
        title: 'Test Playlist',
        author: 'Test Author',
        artworkUrl: 'https://example.com/p.jpg',
        trackCount: 12,
      );

      expect(await playlistsDao.watchIsSaved('PL_test').first, isTrue);
      final saved = await playlistsDao.watchAll().first;
      expect(saved, hasLength(1));
      expect(saved.first.author, 'Test Author');
      expect(saved.first.trackCount, 12);

      await playlistsDao.remove('PL_test');

      expect(await playlistsDao.watchIsSaved('PL_test').first, isFalse);
      expect(await playlistsDao.watchAll().first, isEmpty);
    },
  );

  test('saving the same id twice updates it instead of duplicating', () async {
    await playlistsDao.save(id: 'PL_test', title: 'First', trackCount: 1);
    await playlistsDao.save(id: 'PL_test', title: 'Second', trackCount: 2);

    final saved = await playlistsDao.watchAll().first;
    expect(saved, hasLength(1));
    expect(saved.first.title, 'Second');
    expect(saved.first.trackCount, 2);
  });

  test('album rename updates title and is visible via watchAll', () async {
    await albumsDao.save(
      browseId: 'MPREb_test',
      title: 'Old Title',
      artists: 'Artist',
    );

    await albumsDao.rename('MPREb_test', 'New Title');

    final saved = await albumsDao.watchAll().first;
    expect(saved, hasLength(1));
    expect(saved.first.title, 'New Title');
    expect(saved.first.artists, 'Artist');
    expect(await albumsDao.watchIsSaved('MPREb_test').first, isTrue);
  });

  test('playlist rename updates title and keeps other fields', () async {
    await playlistsDao.save(
      id: 'PL_test',
      title: 'Old Title',
      author: 'Author',
      trackCount: 5,
    );

    await playlistsDao.rename('PL_test', 'New Title');

    final saved = await playlistsDao.watchAll().first;
    expect(saved, hasLength(1));
    expect(saved.first.title, 'New Title');
    expect(saved.first.author, 'Author');
    expect(saved.first.trackCount, 5);
  });

  test('renaming a missing id is a no-op', () async {
    await albumsDao.rename('MPREb_missing', 'Ghost');
    expect(await albumsDao.watchAll().first, isEmpty);
  });
}
