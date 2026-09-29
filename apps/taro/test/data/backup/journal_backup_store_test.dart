import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/backup/journal_backup_store.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/readings_dao.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';

void main() {
  late JournalDatabase db;
  late JournalBackupStore store;
  late CapturingLogger logger;

  setUp(() {
    db = memoryJournal();
    logger = CapturingLogger();
    store = JournalBackupStore(db, logger: logger);
  });
  tearDown(() => db.close());

  DateTime day(int d, [int h = 8]) => DateTime.utc(2026, 9, d, h);

  final older = aReading()
      .withId('11111111-1111-4111-8111-111111111111')
      .createdAt(day(20), localDate: '2026-09-20')
      .withNote('short')
      .build();
  final newer = aReading()
      .withId('22222222-2222-4222-8222-222222222222')
      .createdAt(day(25), localDate: '2026-09-25')
      .favourite()
      .build();
  final pending = aReading()
      .withId('33333333-3333-4333-8333-333333333333')
      .createdAt(day(26))
      .pending()
      .build();
  final daily = aDailyCard()
      .on('2026-09-23')
      .drawnAt(day(23, 7))
      .withNote('stars')
      .build();
  const localSettings = UserSettings(
    themeMode: ThemeMode.dark,
    reduceMotion: true,
  );

  Future<void> seed() async {
    expectOk(
      await store.replaceAll(
        BackupData(
          settings: localSettings,
          readings: [older, newer, pending],
          dailyCards: [daily],
        ),
      ),
    );
  }

  test('an empty journal: empty snapshot, default settings', () async {
    final snapshot = expectOk(await store.snapshot());
    expect(snapshot.readings, isEmpty);
    expect(snapshot.dailyCards, isEmpty);
    expect(expectOk(await store.settings()), const UserSettings());
  });

  test(
    'replaceAll stores exactly the given journal, then shrinks it',
    () async {
      await seed();
      final snapshot = expectOk(await store.snapshot());
      expect(snapshot.readings, [pending, newer, older]);
      expect(snapshot.dailyCards, [daily]);
      expect(expectOk(await store.settings()), localSettings);

      expectOk(
        await store.replaceAll(
          BackupData(
            settings: const UserSettings(),
            readings: [newer],
            dailyCards: const [],
          ),
        ),
      );
      final after = expectOk(await store.snapshot());
      expect(after.readings, [newer]);
      expect(after.dailyCards, isEmpty);
      expect(expectOk(await store.settings()), const UserSettings());
      expect(await db.readingsDao.search('short'), isEmpty);
    },
  );

  test('exportData keeps only exportable readings', () async {
    await seed();
    final data = expectOk(await store.exportData());
    expect(data.readings, [newer, older]);
    expect(data.dailyCards, [daily]);
    expect(data.settings, localSettings);
  });

  group('importBackup (one drift transaction)', () {
    final incomingOlder = older.copyWith(
      updatedAt: day(28),
      note: 'a much longer note from the other device',
      favourite: true,
      modelId: null,
      chargeSource: null,
    );
    final stale = newer.copyWith(updatedAt: day(1), note: 'longer stale note');
    final added = aReading()
        .withId('44444444-4444-4444-8444-444444444444')
        .createdAt(day(10), localDate: '2026-09-10')
        .classic()
        .build();
    final addedDaily = aDailyCard().on('2026-09-10').build();
    final incoming = BackupData(
      settings: const UserSettings(themeMode: ThemeMode.light),
      readings: [incomingOlder, stale, added],
      dailyCards: [daily, addedDaily],
    );

    test('merge: union, newer updatedAt wins, longer note kept, '
        'settings stay local', () async {
      await seed();
      final report = expectOk(await store.importBackup(incoming));
      expect(report, const MergeReport(added: 2, updated: 2, skipped: 1));

      final snapshot = expectOk(await store.snapshot());
      final byId = {for (final r in snapshot.readings) r.id: r};
      expect(byId.keys, hasLength(4));
      expect(byId[older.id]!.note, incomingOlder.note);
      expect(byId[older.id]!.favourite, isTrue);
      // A backup does not carry device fields; the local ones are kept.
      expect(byId[older.id]!.chargeSource, older.chargeSource);
      expect(byId[newer.id]!.updatedAt, newer.updatedAt);
      expect(byId[newer.id]!.note, 'longer stale note');
      expect(byId[pending.id], pending);
      expect(byId[added.id], added);
      expect(snapshot.dailyCards, [daily, addedDaily]);
      expect(expectOk(await store.settings()), localSettings);
      // The search index follows the written rows.
      expect(await db.readingsDao.search('other device'), [
        (kind: JournalSearchKind.reading, ref: older.id.value),
      ]);
    });

    test('importing the same file twice changes nothing more', () async {
      await seed();
      expectOk(await store.importBackup(incoming));
      final first = expectOk(await store.snapshot());
      final report = expectOk(await store.importBackup(incoming));
      expect(report.added, 0);
      expect(report.updated, 0);
      expect(expectOk(await store.snapshot()), first);
    });

    test(
      'replace: the file wins, pending reading and reduceMotion stay',
      () async {
        await seed();
        final report = expectOk(
          await store.importBackup(incoming, mode: MergeMode.replace),
        );
        expect(report, const MergeReport(added: 5, removed: 3));
        final snapshot = expectOk(await store.snapshot());
        expect(
          snapshot.readings.map((r) => r.id),
          unorderedEquals([pending.id, older.id, newer.id, added.id]),
        );
        expect(
          snapshot.readings.firstWhere((r) => r.id == newer.id).note,
          'longer stale note',
        );
        expect(snapshot.dailyCards, [daily, addedDaily]);
        expect(
          expectOk(await store.settings()),
          const UserSettings(themeMode: ThemeMode.light, reduceMotion: true),
        );
      },
    );

    test('a failure rolls the whole import back', () async {
      await seed();
      final before = expectOk(await store.snapshot());
      // Readings are written first; the daily-card write then fails.
      await db.customStatement(
        'CREATE TRIGGER fail_daily BEFORE INSERT ON daily_cards '
        "BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      final result = await store.importBackup(
        incoming.copyWith(dailyCards: [addedDaily], settings: localSettings),
        mode: MergeMode.replace,
      );
      expect(expectErr(result), const Failure.storage());
      await db.customStatement('DROP TRIGGER fail_daily');
      final after = expectOk(await store.snapshot());
      expect(after, before);
      // Only the error type is logged, never journal text.
      expect(logger.logged('import failed', level: LogLevel.severe), isTrue);
      for (final m in logger.messages) {
        expect(m, isNot(contains('short')));
        expect(m, isNot(contains(kTestQuestion)));
      }
    });
  });

  test('a malformed row is a storage failure for every read', () async {
    await db.readingsDao.upsert(readingRow('broken'), threeCards('broken'));
    await db.readingsDao.patch(
      'broken',
      const ReadingsCompanion(chargeSource: Value('gold')),
    );
    expect(expectErr(await store.snapshot()), const Failure.storage());
    expect(expectErr(await store.settings()), const Failure.storage());
    expect(expectErr(await store.exportData()), const Failure.storage());
    expect(
      expectErr(
        await store.replaceAll(
          const BackupData(
            settings: UserSettings(),
            readings: [],
            dailyCards: [],
          ),
        ),
      ),
      const Failure.storage(),
    );
    expect(
      expectErr(
        await store.importBackup(
          const BackupData(
            settings: UserSettings(),
            readings: [],
            dailyCards: [],
          ),
        ),
      ),
      const Failure.storage(),
    );
  });
}
