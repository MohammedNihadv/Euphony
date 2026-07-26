import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/dao/liked_songs_dao.dart';
import 'db/dao/saved_albums_dao.dart';
import 'db/dao/saved_playlists_dao.dart';
import 'db/dao/search_history_dao.dart';
import 'db/database.dart';
import 'remote/innertube/innertube_client.dart';
import 'repository/home_repository.dart';
import 'repository/music_detail_repository.dart';
import 'repository/search_repository.dart';
import 'repository/settings_repository.dart';

part 'providers.g.dart';

/// The open database. Closed when the provider container is disposed.
@Riverpod(keepAlive: true)
EuphonyDatabase database(Ref ref) {
  final db = EuphonyDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
SearchHistoryDao searchHistoryDao(Ref ref) =>
    SearchHistoryDao(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
LikedSongsDao likedSongsDao(Ref ref) =>
    LikedSongsDao(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
SavedAlbumsDao savedAlbumsDao(Ref ref) =>
    SavedAlbumsDao(ref.watch(databaseProvider));

@Riverpod(keepAlive: true)
SavedPlaylistsDao savedPlaylistsDao(Ref ref) =>
    SavedPlaylistsDao(ref.watch(databaseProvider));

/// Overridden in `main()` with the instance loaded before the first frame, so
/// settings are readable synchronously and the app never paints an unthemed
/// frame.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(sharedPreferencesProvider));

final innertubeClientProvider = riverpod.Provider<InnertubeClient>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  // Extract country code from format "US - United States"
  final regionCode = settings.contentRegion.split(' ').first;
  final client = InnertubeClient(region: regionCode);
  ref.onDispose(client.close);
  return client;
});

final searchRepositoryProvider = riverpod.Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(innertubeClientProvider)),
);

final homeRepositoryProvider = riverpod.Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(innertubeClientProvider)),
);

final musicDetailRepositoryProvider = riverpod.Provider<MusicDetailRepository>(
  (ref) => MusicDetailRepository(ref.watch(innertubeClientProvider)),
);
