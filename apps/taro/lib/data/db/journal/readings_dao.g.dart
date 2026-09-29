// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readings_dao.dart';

// ignore_for_file: type=lint
mixin _$ReadingsDaoMixin on DatabaseAccessor<JournalDatabase> {
  Readings get readings => attachedDatabase.readings;
  ReadingCards get readingCards => attachedDatabase.readingCards;
  DailyCards get dailyCards => attachedDatabase.dailyCards;
  Settings get settings => attachedDatabase.settings;
  JournalSearchRefs get journalSearchRefs => attachedDatabase.journalSearchRefs;
  JournalFts get journalFts => attachedDatabase.journalFts;
  ReadingsDaoManager get managers => ReadingsDaoManager(this);
}

class ReadingsDaoManager {
  final _$ReadingsDaoMixin _db;
  ReadingsDaoManager(this._db);
  $ReadingsTableManager get readings =>
      $ReadingsTableManager(_db.attachedDatabase, _db.readings);
  $ReadingCardsTableManager get readingCards =>
      $ReadingCardsTableManager(_db.attachedDatabase, _db.readingCards);
  $DailyCardsTableManager get dailyCards =>
      $DailyCardsTableManager(_db.attachedDatabase, _db.dailyCards);
  $SettingsTableManager get settings =>
      $SettingsTableManager(_db.attachedDatabase, _db.settings);
  $JournalSearchRefsTableManager get journalSearchRefs =>
      $JournalSearchRefsTableManager(
        _db.attachedDatabase,
        _db.journalSearchRefs,
      );
  $JournalFtsTableManager get journalFts =>
      $JournalFtsTableManager(_db.attachedDatabase, _db.journalFts);
}
