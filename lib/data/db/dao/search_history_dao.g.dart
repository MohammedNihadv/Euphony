// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_dao.dart';

// ignore_for_file: type=lint
mixin _$SearchHistoryDaoMixin on DatabaseAccessor<EuphonyDatabase> {
  $SearchHistoryTable get searchHistory => attachedDatabase.searchHistory;
  SearchHistoryDaoManager get managers => SearchHistoryDaoManager(this);
}

class SearchHistoryDaoManager {
  final _$SearchHistoryDaoMixin _db;
  SearchHistoryDaoManager(this._db);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db.attachedDatabase, _db.searchHistory);
}
