import 'package:drift/drift.dart';
import 'package:taro/data/db/database_location.dart';
import 'package:taro/data/db/instant_converter.dart';
import 'package:taro/data/db/journal/daily_cards_dao.dart';
import 'package:taro/data/db/journal/readings_dao.dart';
import 'package:taro/data/db/journal/settings_dao.dart';

part 'journal_database.g.dart';

/// `taro_journal.db` (02 AR7, §6.1, RC75): readings, daily cards, user
/// settings and the journal search index. User content; it may be included
/// in iCloud and Android cloud backups, and after an OS restore it is the
/// only local state present.
@DriftDatabase(
  daos: [ReadingsDao, DailyCardsDao, SettingsDao],
  include: {'journal.drift'},
)
class JournalDatabase extends _$JournalDatabase {
  /// A database over the executor [e] (`NativeDatabase.memory()` in tests).
  JournalDatabase(super.e);

  /// Opens `taro_journal.db` at [location].
  factory JournalDatabase.open({
    DatabaseLocation location = const DatabaseLocation(),
  }) => JournalDatabase(location.open(name));

  /// The drift name; the file is `taro_journal.db`.
  static const name = 'taro_journal';

  /// Bump with a `drift_dev make-migrations` dump and a step test
  /// (docs/TESTING.md "drift migrations").
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) => configureConnection(this),
  );

  /// Deletes every reading (cards cascade), daily card and setting in one
  /// transaction (Delete all data, RC37; backup Replace). The search index
  /// follows through its triggers.
  Future<void> wipe() => transaction(() async {
    await delete(readings).go();
    await delete(dailyCards).go();
    await delete(settings).go();
  });
}
