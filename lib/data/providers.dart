import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/dao/search_history_dao.dart';
import 'db/database.dart';
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

/// Overridden in `main()` with the instance loaded before the first frame, so
/// settings are readable synchronously and the app never paints an unthemed
/// frame.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(sharedPreferencesProvider));
