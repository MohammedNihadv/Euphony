// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open database. Closed when the provider container is disposed.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The open database. Closed when the provider container is disposed.

final class DatabaseProvider
    extends
        $FunctionalProvider<EuphonyDatabase, EuphonyDatabase, EuphonyDatabase>
    with $Provider<EuphonyDatabase> {
  /// The open database. Closed when the provider container is disposed.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<EuphonyDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EuphonyDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EuphonyDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EuphonyDatabase>(value),
    );
  }
}

String _$databaseHash() => r'17024eb77fc53400534b1dd5b7e1ff192ce505b6';

@ProviderFor(searchHistoryDao)
final searchHistoryDaoProvider = SearchHistoryDaoProvider._();

final class SearchHistoryDaoProvider
    extends
        $FunctionalProvider<
          SearchHistoryDao,
          SearchHistoryDao,
          SearchHistoryDao
        >
    with $Provider<SearchHistoryDao> {
  SearchHistoryDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryDaoHash();

  @$internal
  @override
  $ProviderElement<SearchHistoryDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchHistoryDao create(Ref ref) {
    return searchHistoryDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchHistoryDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchHistoryDao>(value),
    );
  }
}

String _$searchHistoryDaoHash() => r'4fe610d07076f8110c854d3815981b923d8b375f';

@ProviderFor(likedSongsDao)
final likedSongsDaoProvider = LikedSongsDaoProvider._();

final class LikedSongsDaoProvider
    extends $FunctionalProvider<LikedSongsDao, LikedSongsDao, LikedSongsDao>
    with $Provider<LikedSongsDao> {
  LikedSongsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likedSongsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likedSongsDaoHash();

  @$internal
  @override
  $ProviderElement<LikedSongsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LikedSongsDao create(Ref ref) {
    return likedSongsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LikedSongsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LikedSongsDao>(value),
    );
  }
}

String _$likedSongsDaoHash() => r'4321c4d7efdf0af2142647b218b4513b33e1dfce';

@ProviderFor(savedAlbumsDao)
final savedAlbumsDaoProvider = SavedAlbumsDaoProvider._();

final class SavedAlbumsDaoProvider
    extends $FunctionalProvider<SavedAlbumsDao, SavedAlbumsDao, SavedAlbumsDao>
    with $Provider<SavedAlbumsDao> {
  SavedAlbumsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedAlbumsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedAlbumsDaoHash();

  @$internal
  @override
  $ProviderElement<SavedAlbumsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SavedAlbumsDao create(Ref ref) {
    return savedAlbumsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedAlbumsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedAlbumsDao>(value),
    );
  }
}

String _$savedAlbumsDaoHash() => r'b9621305a8d0732e7fe3f4ccd78c9a8e27c02808';

@ProviderFor(savedPlaylistsDao)
final savedPlaylistsDaoProvider = SavedPlaylistsDaoProvider._();

final class SavedPlaylistsDaoProvider
    extends
        $FunctionalProvider<
          SavedPlaylistsDao,
          SavedPlaylistsDao,
          SavedPlaylistsDao
        >
    with $Provider<SavedPlaylistsDao> {
  SavedPlaylistsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPlaylistsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPlaylistsDaoHash();

  @$internal
  @override
  $ProviderElement<SavedPlaylistsDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedPlaylistsDao create(Ref ref) {
    return savedPlaylistsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedPlaylistsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedPlaylistsDao>(value),
    );
  }
}

String _$savedPlaylistsDaoHash() => r'749181f8cba6e82b3dc4384c790c5cbc7d72204d';

/// Overridden in `main()` with the instance loaded before the first frame, so
/// settings are readable synchronously and the app never paints an unthemed
/// frame.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Overridden in `main()` with the instance loaded before the first frame, so
/// settings are readable synchronously and the app never paints an unthemed
/// frame.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// Overridden in `main()` with the instance loaded before the first frame, so
  /// settings are readable synchronously and the app never paints an unthemed
  /// frame.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'70ef90bd70df9f89260fca9b542d9f8d25d8e3cb';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'cb57457244062d3bd9be73a1a3ee43a55e76dd3d';
