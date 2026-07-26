// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  SearchHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryEntry(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryEntry extends DataClass
    implements Insertable<SearchHistoryEntry> {
  final String query;
  final DateTime lastUsedAt;
  const SearchHistoryEntry({required this.query, required this.lastUsedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      query: Value(query),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory SearchHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryEntry(
      query: serializer.fromJson<String>(json['query']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  SearchHistoryEntry copyWith({String? query, DateTime? lastUsedAt}) =>
      SearchHistoryEntry(
        query: query ?? this.query,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );
  SearchHistoryEntry copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryEntry(
      query: data.query.present ? data.query.value : this.query,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryEntry(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryEntry &&
          other.query == this.query &&
          other.lastUsedAt == this.lastUsedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryEntry> {
  final Value<String> query;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const SearchHistoryCompanion({
    this.query = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    required String query,
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<SearchHistoryEntry> custom({
    Expression<String>? query,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryCompanion copyWith({
    Value<String>? query,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return SearchHistoryCompanion(
      query: query ?? this.query,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LikedSongsTable extends LikedSongs
    with TableInfo<$LikedSongsTable, LikedSongEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LikedSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistsMeta = const VerificationMeta(
    'artists',
  );
  @override
  late final GeneratedColumn<String> artists = GeneratedColumn<String>(
    'artists',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumTitleMeta = const VerificationMeta(
    'albumTitle',
  );
  @override
  late final GeneratedColumn<String> albumTitle = GeneratedColumn<String>(
    'album_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isExplicitMeta = const VerificationMeta(
    'isExplicit',
  );
  @override
  late final GeneratedColumn<bool> isExplicit = GeneratedColumn<bool>(
    'is_explicit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_explicit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _likedAtMeta = const VerificationMeta(
    'likedAt',
  );
  @override
  late final GeneratedColumn<DateTime> likedAt = GeneratedColumn<DateTime>(
    'liked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artists,
    albumTitle,
    artworkUrl,
    durationSeconds,
    isExplicit,
    likedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liked_songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LikedSongEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists')) {
      context.handle(
        _artistsMeta,
        artists.isAcceptableOrUnknown(data['artists']!, _artistsMeta),
      );
    } else if (isInserting) {
      context.missing(_artistsMeta);
    }
    if (data.containsKey('album_title')) {
      context.handle(
        _albumTitleMeta,
        albumTitle.isAcceptableOrUnknown(data['album_title']!, _albumTitleMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_explicit')) {
      context.handle(
        _isExplicitMeta,
        isExplicit.isAcceptableOrUnknown(data['is_explicit']!, _isExplicitMeta),
      );
    }
    if (data.containsKey('liked_at')) {
      context.handle(
        _likedAtMeta,
        likedAt.isAcceptableOrUnknown(data['liked_at']!, _likedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_likedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LikedSongEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LikedSongEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artists: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artists'],
      )!,
      albumTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_title'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      isExplicit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_explicit'],
      )!,
      likedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}liked_at'],
      )!,
    );
  }

  @override
  $LikedSongsTable createAlias(String alias) {
    return $LikedSongsTable(attachedDatabase, alias);
  }
}

class LikedSongEntry extends DataClass implements Insertable<LikedSongEntry> {
  final String id;
  final String title;
  final String artists;
  final String? albumTitle;
  final String? artworkUrl;
  final int? durationSeconds;
  final bool isExplicit;
  final DateTime likedAt;
  const LikedSongEntry({
    required this.id,
    required this.title,
    required this.artists,
    this.albumTitle,
    this.artworkUrl,
    this.durationSeconds,
    required this.isExplicit,
    required this.likedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artists'] = Variable<String>(artists);
    if (!nullToAbsent || albumTitle != null) {
      map['album_title'] = Variable<String>(albumTitle);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['is_explicit'] = Variable<bool>(isExplicit);
    map['liked_at'] = Variable<DateTime>(likedAt);
    return map;
  }

  LikedSongsCompanion toCompanion(bool nullToAbsent) {
    return LikedSongsCompanion(
      id: Value(id),
      title: Value(title),
      artists: Value(artists),
      albumTitle: albumTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(albumTitle),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      isExplicit: Value(isExplicit),
      likedAt: Value(likedAt),
    );
  }

  factory LikedSongEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LikedSongEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artists: serializer.fromJson<String>(json['artists']),
      albumTitle: serializer.fromJson<String?>(json['albumTitle']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      isExplicit: serializer.fromJson<bool>(json['isExplicit']),
      likedAt: serializer.fromJson<DateTime>(json['likedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artists': serializer.toJson<String>(artists),
      'albumTitle': serializer.toJson<String?>(albumTitle),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'isExplicit': serializer.toJson<bool>(isExplicit),
      'likedAt': serializer.toJson<DateTime>(likedAt),
    };
  }

  LikedSongEntry copyWith({
    String? id,
    String? title,
    String? artists,
    Value<String?> albumTitle = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    bool? isExplicit,
    DateTime? likedAt,
  }) => LikedSongEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    artists: artists ?? this.artists,
    albumTitle: albumTitle.present ? albumTitle.value : this.albumTitle,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    isExplicit: isExplicit ?? this.isExplicit,
    likedAt: likedAt ?? this.likedAt,
  );
  LikedSongEntry copyWithCompanion(LikedSongsCompanion data) {
    return LikedSongEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artists: data.artists.present ? data.artists.value : this.artists,
      albumTitle: data.albumTitle.present
          ? data.albumTitle.value
          : this.albumTitle,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      isExplicit: data.isExplicit.present
          ? data.isExplicit.value
          : this.isExplicit,
      likedAt: data.likedAt.present ? data.likedAt.value : this.likedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LikedSongEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isExplicit: $isExplicit, ')
          ..write('likedAt: $likedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artists,
    albumTitle,
    artworkUrl,
    durationSeconds,
    isExplicit,
    likedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LikedSongEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.artists == this.artists &&
          other.albumTitle == this.albumTitle &&
          other.artworkUrl == this.artworkUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.isExplicit == this.isExplicit &&
          other.likedAt == this.likedAt);
}

class LikedSongsCompanion extends UpdateCompanion<LikedSongEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artists;
  final Value<String?> albumTitle;
  final Value<String?> artworkUrl;
  final Value<int?> durationSeconds;
  final Value<bool> isExplicit;
  final Value<DateTime> likedAt;
  final Value<int> rowid;
  const LikedSongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artists = const Value.absent(),
    this.albumTitle = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isExplicit = const Value.absent(),
    this.likedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LikedSongsCompanion.insert({
    required String id,
    required String title,
    required String artists,
    this.albumTitle = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isExplicit = const Value.absent(),
    required DateTime likedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artists = Value(artists),
       likedAt = Value(likedAt);
  static Insertable<LikedSongEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artists,
    Expression<String>? albumTitle,
    Expression<String>? artworkUrl,
    Expression<int>? durationSeconds,
    Expression<bool>? isExplicit,
    Expression<DateTime>? likedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artists != null) 'artists': artists,
      if (albumTitle != null) 'album_title': albumTitle,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isExplicit != null) 'is_explicit': isExplicit,
      if (likedAt != null) 'liked_at': likedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LikedSongsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artists,
    Value<String?>? albumTitle,
    Value<String?>? artworkUrl,
    Value<int?>? durationSeconds,
    Value<bool>? isExplicit,
    Value<DateTime>? likedAt,
    Value<int>? rowid,
  }) {
    return LikedSongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      albumTitle: albumTitle ?? this.albumTitle,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isExplicit: isExplicit ?? this.isExplicit,
      likedAt: likedAt ?? this.likedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artists.present) {
      map['artists'] = Variable<String>(artists.value);
    }
    if (albumTitle.present) {
      map['album_title'] = Variable<String>(albumTitle.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (isExplicit.present) {
      map['is_explicit'] = Variable<bool>(isExplicit.value);
    }
    if (likedAt.present) {
      map['liked_at'] = Variable<DateTime>(likedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LikedSongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isExplicit: $isExplicit, ')
          ..write('likedAt: $likedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedAlbumsTable extends SavedAlbums
    with TableInfo<$SavedAlbumsTable, SavedAlbumEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _browseIdMeta = const VerificationMeta(
    'browseId',
  );
  @override
  late final GeneratedColumn<String> browseId = GeneratedColumn<String>(
    'browse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistsMeta = const VerificationMeta(
    'artists',
  );
  @override
  late final GeneratedColumn<String> artists = GeneratedColumn<String>(
    'artists',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    browseId,
    title,
    artists,
    artworkUrl,
    year,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedAlbumEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('browse_id')) {
      context.handle(
        _browseIdMeta,
        browseId.isAcceptableOrUnknown(data['browse_id']!, _browseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_browseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists')) {
      context.handle(
        _artistsMeta,
        artists.isAcceptableOrUnknown(data['artists']!, _artistsMeta),
      );
    } else if (isInserting) {
      context.missing(_artistsMeta);
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {browseId};
  @override
  SavedAlbumEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedAlbumEntry(
      browseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}browse_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artists: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artists'],
      )!,
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedAlbumsTable createAlias(String alias) {
    return $SavedAlbumsTable(attachedDatabase, alias);
  }
}

class SavedAlbumEntry extends DataClass implements Insertable<SavedAlbumEntry> {
  final String browseId;
  final String title;
  final String artists;
  final String? artworkUrl;
  final int? year;
  final DateTime savedAt;
  const SavedAlbumEntry({
    required this.browseId,
    required this.title,
    required this.artists,
    this.artworkUrl,
    this.year,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['browse_id'] = Variable<String>(browseId);
    map['title'] = Variable<String>(title);
    map['artists'] = Variable<String>(artists);
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedAlbumsCompanion toCompanion(bool nullToAbsent) {
    return SavedAlbumsCompanion(
      browseId: Value(browseId),
      title: Value(title),
      artists: Value(artists),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      savedAt: Value(savedAt),
    );
  }

  factory SavedAlbumEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedAlbumEntry(
      browseId: serializer.fromJson<String>(json['browseId']),
      title: serializer.fromJson<String>(json['title']),
      artists: serializer.fromJson<String>(json['artists']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      year: serializer.fromJson<int?>(json['year']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'browseId': serializer.toJson<String>(browseId),
      'title': serializer.toJson<String>(title),
      'artists': serializer.toJson<String>(artists),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'year': serializer.toJson<int?>(year),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedAlbumEntry copyWith({
    String? browseId,
    String? title,
    String? artists,
    Value<String?> artworkUrl = const Value.absent(),
    Value<int?> year = const Value.absent(),
    DateTime? savedAt,
  }) => SavedAlbumEntry(
    browseId: browseId ?? this.browseId,
    title: title ?? this.title,
    artists: artists ?? this.artists,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    year: year.present ? year.value : this.year,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedAlbumEntry copyWithCompanion(SavedAlbumsCompanion data) {
    return SavedAlbumEntry(
      browseId: data.browseId.present ? data.browseId.value : this.browseId,
      title: data.title.present ? data.title.value : this.title,
      artists: data.artists.present ? data.artists.value : this.artists,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      year: data.year.present ? data.year.value : this.year,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbumEntry(')
          ..write('browseId: $browseId, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('year: $year, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(browseId, title, artists, artworkUrl, year, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedAlbumEntry &&
          other.browseId == this.browseId &&
          other.title == this.title &&
          other.artists == this.artists &&
          other.artworkUrl == this.artworkUrl &&
          other.year == this.year &&
          other.savedAt == this.savedAt);
}

class SavedAlbumsCompanion extends UpdateCompanion<SavedAlbumEntry> {
  final Value<String> browseId;
  final Value<String> title;
  final Value<String> artists;
  final Value<String?> artworkUrl;
  final Value<int?> year;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedAlbumsCompanion({
    this.browseId = const Value.absent(),
    this.title = const Value.absent(),
    this.artists = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedAlbumsCompanion.insert({
    required String browseId,
    required String title,
    required String artists,
    this.artworkUrl = const Value.absent(),
    this.year = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : browseId = Value(browseId),
       title = Value(title),
       artists = Value(artists),
       savedAt = Value(savedAt);
  static Insertable<SavedAlbumEntry> custom({
    Expression<String>? browseId,
    Expression<String>? title,
    Expression<String>? artists,
    Expression<String>? artworkUrl,
    Expression<int>? year,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (browseId != null) 'browse_id': browseId,
      if (title != null) 'title': title,
      if (artists != null) 'artists': artists,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (year != null) 'year': year,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedAlbumsCompanion copyWith({
    Value<String>? browseId,
    Value<String>? title,
    Value<String>? artists,
    Value<String?>? artworkUrl,
    Value<int?>? year,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedAlbumsCompanion(
      browseId: browseId ?? this.browseId,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      year: year ?? this.year,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (browseId.present) {
      map['browse_id'] = Variable<String>(browseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artists.present) {
      map['artists'] = Variable<String>(artists.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbumsCompanion(')
          ..write('browseId: $browseId, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('year: $year, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedPlaylistsTable extends SavedPlaylists
    with TableInfo<$SavedPlaylistsTable, SavedPlaylistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackCountMeta = const VerificationMeta(
    'trackCount',
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    artworkUrl,
    trackCount,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedPlaylistEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('track_count')) {
      context.handle(
        _trackCountMeta,
        trackCount.isAcceptableOrUnknown(data['track_count']!, _trackCountMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedPlaylistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlaylistEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedPlaylistsTable createAlias(String alias) {
    return $SavedPlaylistsTable(attachedDatabase, alias);
  }
}

class SavedPlaylistEntry extends DataClass
    implements Insertable<SavedPlaylistEntry> {
  final String id;
  final String title;
  final String? author;
  final String? artworkUrl;
  final int? trackCount;
  final DateTime savedAt;
  const SavedPlaylistEntry({
    required this.id,
    required this.title,
    this.author,
    this.artworkUrl,
    this.trackCount,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || trackCount != null) {
      map['track_count'] = Variable<int>(trackCount);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SavedPlaylistsCompanion(
      id: Value(id),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      trackCount: trackCount == null && nullToAbsent
          ? const Value.absent()
          : Value(trackCount),
      savedAt: Value(savedAt),
    );
  }

  factory SavedPlaylistEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlaylistEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      trackCount: serializer.fromJson<int?>(json['trackCount']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'trackCount': serializer.toJson<int?>(trackCount),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedPlaylistEntry copyWith({
    String? id,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<int?> trackCount = const Value.absent(),
    DateTime? savedAt,
  }) => SavedPlaylistEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    trackCount: trackCount.present ? trackCount.value : this.trackCount,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedPlaylistEntry copyWithCompanion(SavedPlaylistsCompanion data) {
    return SavedPlaylistEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylistEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('trackCount: $trackCount, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, author, artworkUrl, trackCount, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlaylistEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.artworkUrl == this.artworkUrl &&
          other.trackCount == this.trackCount &&
          other.savedAt == this.savedAt);
}

class SavedPlaylistsCompanion extends UpdateCompanion<SavedPlaylistEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> artworkUrl;
  final Value<int?> trackCount;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedPlaylistsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedPlaylistsCompanion.insert({
    required String id,
    required String title,
    this.author = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.trackCount = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       savedAt = Value(savedAt);
  static Insertable<SavedPlaylistEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? artworkUrl,
    Expression<int>? trackCount,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (trackCount != null) 'track_count': trackCount,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedPlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? artworkUrl,
    Value<int?>? trackCount,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedPlaylistsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackCount: trackCount ?? this.trackCount,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('trackCount: $trackCount, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EuphonyDatabase extends GeneratedDatabase {
  _$EuphonyDatabase(QueryExecutor e) : super(e);
  $EuphonyDatabaseManager get managers => $EuphonyDatabaseManager(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final $LikedSongsTable likedSongs = $LikedSongsTable(this);
  late final $SavedAlbumsTable savedAlbums = $SavedAlbumsTable(this);
  late final $SavedPlaylistsTable savedPlaylists = $SavedPlaylistsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    searchHistory,
    likedSongs,
    savedAlbums,
    savedPlaylists,
  ];
}

typedef $$SearchHistoryTableCreateCompanionBuilder =
    SearchHistoryCompanion Function({
      required String query,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$SearchHistoryTableUpdateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<String> query,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

class $$SearchHistoryTableFilterComposer
    extends Composer<_$EuphonyDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$EuphonyDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$EuphonyDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$EuphonyDatabase,
          $SearchHistoryTable,
          SearchHistoryEntry,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryEntry,
            BaseReferences<
              _$EuphonyDatabase,
              $SearchHistoryTable,
              SearchHistoryEntry
            >,
          ),
          SearchHistoryEntry,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(
    _$EuphonyDatabase db,
    $SearchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion.insert(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$EuphonyDatabase,
      $SearchHistoryTable,
      SearchHistoryEntry,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryEntry,
        BaseReferences<
          _$EuphonyDatabase,
          $SearchHistoryTable,
          SearchHistoryEntry
        >,
      ),
      SearchHistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$LikedSongsTableCreateCompanionBuilder =
    LikedSongsCompanion Function({
      required String id,
      required String title,
      required String artists,
      Value<String?> albumTitle,
      Value<String?> artworkUrl,
      Value<int?> durationSeconds,
      Value<bool> isExplicit,
      required DateTime likedAt,
      Value<int> rowid,
    });
typedef $$LikedSongsTableUpdateCompanionBuilder =
    LikedSongsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> artists,
      Value<String?> albumTitle,
      Value<String?> artworkUrl,
      Value<int?> durationSeconds,
      Value<bool> isExplicit,
      Value<DateTime> likedAt,
      Value<int> rowid,
    });

class $$LikedSongsTableFilterComposer
    extends Composer<_$EuphonyDatabase, $LikedSongsTable> {
  $$LikedSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExplicit => $composableBuilder(
    column: $table.isExplicit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get likedAt => $composableBuilder(
    column: $table.likedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LikedSongsTableOrderingComposer
    extends Composer<_$EuphonyDatabase, $LikedSongsTable> {
  $$LikedSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExplicit => $composableBuilder(
    column: $table.isExplicit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get likedAt => $composableBuilder(
    column: $table.likedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LikedSongsTableAnnotationComposer
    extends Composer<_$EuphonyDatabase, $LikedSongsTable> {
  $$LikedSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artists =>
      $composableBuilder(column: $table.artists, builder: (column) => column);

  GeneratedColumn<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExplicit => $composableBuilder(
    column: $table.isExplicit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get likedAt =>
      $composableBuilder(column: $table.likedAt, builder: (column) => column);
}

class $$LikedSongsTableTableManager
    extends
        RootTableManager<
          _$EuphonyDatabase,
          $LikedSongsTable,
          LikedSongEntry,
          $$LikedSongsTableFilterComposer,
          $$LikedSongsTableOrderingComposer,
          $$LikedSongsTableAnnotationComposer,
          $$LikedSongsTableCreateCompanionBuilder,
          $$LikedSongsTableUpdateCompanionBuilder,
          (
            LikedSongEntry,
            BaseReferences<_$EuphonyDatabase, $LikedSongsTable, LikedSongEntry>,
          ),
          LikedSongEntry,
          PrefetchHooks Function()
        > {
  $$LikedSongsTableTableManager(_$EuphonyDatabase db, $LikedSongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LikedSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LikedSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LikedSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artists = const Value.absent(),
                Value<String?> albumTitle = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isExplicit = const Value.absent(),
                Value<DateTime> likedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LikedSongsCompanion(
                id: id,
                title: title,
                artists: artists,
                albumTitle: albumTitle,
                artworkUrl: artworkUrl,
                durationSeconds: durationSeconds,
                isExplicit: isExplicit,
                likedAt: likedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artists,
                Value<String?> albumTitle = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isExplicit = const Value.absent(),
                required DateTime likedAt,
                Value<int> rowid = const Value.absent(),
              }) => LikedSongsCompanion.insert(
                id: id,
                title: title,
                artists: artists,
                albumTitle: albumTitle,
                artworkUrl: artworkUrl,
                durationSeconds: durationSeconds,
                isExplicit: isExplicit,
                likedAt: likedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LikedSongsTableProcessedTableManager =
    ProcessedTableManager<
      _$EuphonyDatabase,
      $LikedSongsTable,
      LikedSongEntry,
      $$LikedSongsTableFilterComposer,
      $$LikedSongsTableOrderingComposer,
      $$LikedSongsTableAnnotationComposer,
      $$LikedSongsTableCreateCompanionBuilder,
      $$LikedSongsTableUpdateCompanionBuilder,
      (
        LikedSongEntry,
        BaseReferences<_$EuphonyDatabase, $LikedSongsTable, LikedSongEntry>,
      ),
      LikedSongEntry,
      PrefetchHooks Function()
    >;
typedef $$SavedAlbumsTableCreateCompanionBuilder =
    SavedAlbumsCompanion Function({
      required String browseId,
      required String title,
      required String artists,
      Value<String?> artworkUrl,
      Value<int?> year,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$SavedAlbumsTableUpdateCompanionBuilder =
    SavedAlbumsCompanion Function({
      Value<String> browseId,
      Value<String> title,
      Value<String> artists,
      Value<String?> artworkUrl,
      Value<int?> year,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$SavedAlbumsTableFilterComposer
    extends Composer<_$EuphonyDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get browseId => $composableBuilder(
    column: $table.browseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedAlbumsTableOrderingComposer
    extends Composer<_$EuphonyDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get browseId => $composableBuilder(
    column: $table.browseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedAlbumsTableAnnotationComposer
    extends Composer<_$EuphonyDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get browseId =>
      $composableBuilder(column: $table.browseId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artists =>
      $composableBuilder(column: $table.artists, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedAlbumsTableTableManager
    extends
        RootTableManager<
          _$EuphonyDatabase,
          $SavedAlbumsTable,
          SavedAlbumEntry,
          $$SavedAlbumsTableFilterComposer,
          $$SavedAlbumsTableOrderingComposer,
          $$SavedAlbumsTableAnnotationComposer,
          $$SavedAlbumsTableCreateCompanionBuilder,
          $$SavedAlbumsTableUpdateCompanionBuilder,
          (
            SavedAlbumEntry,
            BaseReferences<
              _$EuphonyDatabase,
              $SavedAlbumsTable,
              SavedAlbumEntry
            >,
          ),
          SavedAlbumEntry,
          PrefetchHooks Function()
        > {
  $$SavedAlbumsTableTableManager(_$EuphonyDatabase db, $SavedAlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> browseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artists = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedAlbumsCompanion(
                browseId: browseId,
                title: title,
                artists: artists,
                artworkUrl: artworkUrl,
                year: year,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String browseId,
                required String title,
                required String artists,
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedAlbumsCompanion.insert(
                browseId: browseId,
                title: title,
                artists: artists,
                artworkUrl: artworkUrl,
                year: year,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$EuphonyDatabase,
      $SavedAlbumsTable,
      SavedAlbumEntry,
      $$SavedAlbumsTableFilterComposer,
      $$SavedAlbumsTableOrderingComposer,
      $$SavedAlbumsTableAnnotationComposer,
      $$SavedAlbumsTableCreateCompanionBuilder,
      $$SavedAlbumsTableUpdateCompanionBuilder,
      (
        SavedAlbumEntry,
        BaseReferences<_$EuphonyDatabase, $SavedAlbumsTable, SavedAlbumEntry>,
      ),
      SavedAlbumEntry,
      PrefetchHooks Function()
    >;
typedef $$SavedPlaylistsTableCreateCompanionBuilder =
    SavedPlaylistsCompanion Function({
      required String id,
      required String title,
      Value<String?> author,
      Value<String?> artworkUrl,
      Value<int?> trackCount,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$SavedPlaylistsTableUpdateCompanionBuilder =
    SavedPlaylistsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> author,
      Value<String?> artworkUrl,
      Value<int?> trackCount,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$SavedPlaylistsTableFilterComposer
    extends Composer<_$EuphonyDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedPlaylistsTableOrderingComposer
    extends Composer<_$EuphonyDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedPlaylistsTableAnnotationComposer
    extends Composer<_$EuphonyDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedPlaylistsTableTableManager
    extends
        RootTableManager<
          _$EuphonyDatabase,
          $SavedPlaylistsTable,
          SavedPlaylistEntry,
          $$SavedPlaylistsTableFilterComposer,
          $$SavedPlaylistsTableOrderingComposer,
          $$SavedPlaylistsTableAnnotationComposer,
          $$SavedPlaylistsTableCreateCompanionBuilder,
          $$SavedPlaylistsTableUpdateCompanionBuilder,
          (
            SavedPlaylistEntry,
            BaseReferences<
              _$EuphonyDatabase,
              $SavedPlaylistsTable,
              SavedPlaylistEntry
            >,
          ),
          SavedPlaylistEntry,
          PrefetchHooks Function()
        > {
  $$SavedPlaylistsTableTableManager(
    _$EuphonyDatabase db,
    $SavedPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion(
                id: id,
                title: title,
                author: author,
                artworkUrl: artworkUrl,
                trackCount: trackCount,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedPlaylistsCompanion.insert(
                id: id,
                title: title,
                author: author,
                artworkUrl: artworkUrl,
                trackCount: trackCount,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$EuphonyDatabase,
      $SavedPlaylistsTable,
      SavedPlaylistEntry,
      $$SavedPlaylistsTableFilterComposer,
      $$SavedPlaylistsTableOrderingComposer,
      $$SavedPlaylistsTableAnnotationComposer,
      $$SavedPlaylistsTableCreateCompanionBuilder,
      $$SavedPlaylistsTableUpdateCompanionBuilder,
      (
        SavedPlaylistEntry,
        BaseReferences<
          _$EuphonyDatabase,
          $SavedPlaylistsTable,
          SavedPlaylistEntry
        >,
      ),
      SavedPlaylistEntry,
      PrefetchHooks Function()
    >;

class $EuphonyDatabaseManager {
  final _$EuphonyDatabase _db;
  $EuphonyDatabaseManager(this._db);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
  $$LikedSongsTableTableManager get likedSongs =>
      $$LikedSongsTableTableManager(_db, _db.likedSongs);
  $$SavedAlbumsTableTableManager get savedAlbums =>
      $$SavedAlbumsTableTableManager(_db, _db.savedAlbums);
  $$SavedPlaylistsTableTableManager get savedPlaylists =>
      $$SavedPlaylistsTableTableManager(_db, _db.savedPlaylists);
}
