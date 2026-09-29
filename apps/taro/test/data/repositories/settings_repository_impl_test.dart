import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/repositories/settings_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';

void main() {
  late JournalDatabase db;
  late CapturingLogger logger;
  late SettingsRepositoryImpl repo;

  Future<SettingsRepositoryImpl> open() async {
    final opened = await SettingsRepositoryImpl.open(
      dao: db.settingsDao,
      logger: logger,
    );
    addTearDown(opened.close);
    return opened;
  }

  setUp(() async {
    db = memoryJournal();
    logger = CapturingLogger();
    addTearDown(db.close);
    repo = await open();
  });

  runSettingsRepositoryContract(() => repo);

  test('settings survive a restart, reduceMotion included', () async {
    const settings = UserSettings(
      themeMode: ThemeMode.light,
      localeOverride: 'ja',
      reversalsEnabled: false,
      hapticsEnabled: false,
      reminder: ReminderSettings(enabled: true, time: '07:15'),
      reduceMotion: true,
    );
    await repo.update((_) => settings);
    expect((await open()).current, settings);
    expect(await db.settingsDao.read('theme'), '"light"');
    expect(await db.settingsDao.read('reduceMotion'), 'true');
  });

  test('rows use the backup keys; null reduceMotion is not stored', () {
    expect(SettingsRepositoryImpl.encode(const UserSettings()).keys, {
      'theme',
      'reversalsEnabled',
      'hapticsEnabled',
      'reminder',
      'localeOverride',
    });
  });

  test('an invalid or unknown key takes its default and is logged', () async {
    final settings = SettingsRepositoryImpl.decode({
      'theme': '"purple"',
      'reminder': '{"enabled": true, "time": "25:00"}',
      'reversalsEnabled': 'false',
      'localeOverride': 'not json',
      'reduceMotion': '"yes"',
      'futureKey': '1',
    }, logger);
    expect(settings, const UserSettings(reversalsEnabled: false));
    expect(logger.logged('settings key "theme" invalid'), isTrue);
    expect(logger.logged('settings key "reminder" invalid'), isTrue);
    expect(logger.logged('settings key "localeOverride" invalid'), isTrue);
    expect(logger.logged('settings key "reduceMotion" invalid'), isTrue);
  });

  test('a wipe outside the repository resets to the defaults', () async {
    await repo.update((s) => s.copyWith(themeMode: ThemeMode.dark));
    final seen = <UserSettings>[];
    final sub = repo.watch().listen(seen.add);
    await settle();
    await db.wipe();
    await pumpEventQueue();
    await sub.cancel();
    expect(repo.current, const UserSettings());
    expect(seen.last, const UserSettings());
  });

  test('a failed write returns a storage failure and keeps current', () async {
    await db.customStatement('DROP TABLE settings');
    final result = await repo.update(
      (s) => s.copyWith(themeMode: ThemeMode.dark),
    );
    expect(expectErr(result), isA<StorageFailure>());
    expect(repo.current, const UserSettings());
    expect(logger.logged('settings update failed'), isTrue);
  });

  test('a failed reload is logged', () async {
    await db.customStatement('DROP TABLE settings');
    await db.customStatement('CREATE TABLE settings (x TEXT)');
    await db.customStatement("INSERT INTO settings VALUES ('x')");
    db.notifyUpdates({const TableUpdate('settings')});
    await pumpEventQueue();
    expect(logger.logged('settings reload failed'), isTrue);
  });
}
