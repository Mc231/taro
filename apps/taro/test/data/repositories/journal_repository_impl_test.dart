import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/repositories/journal_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runJournalRepositoryContract(
    () => JournalRepositoryImpl(
      journal: JournalDatabase(NativeDatabase.memory()),
      logger: CapturingLogger(),
    ),
  );

  group('JournalRepositoryImpl', () {
    late JournalDatabase db;
    late CapturingLogger logger;
    late FakeContentRepository content;
    late JournalRepositoryImpl journal;

    // The default draw holds major_00, major_11 and wands_01.
    final tower = aReading()
        .withId('11111111-1111-4111-8111-111111111111')
        .createdAt(DateTime.utc(2026, 9, 20, 8), localDate: '2026-09-20')
        .withQuestion('Über die Zukunft?')
        .build();
    final plain = aReading()
        .withId('22222222-2222-4222-8222-222222222222')
        .createdAt(DateTime.utc(2026, 9, 21, 8), localDate: '2026-09-21')
        .withSpread('single')
        .withQuestion('Is it ok?')
        .build();
    final star = aDailyCard()
        .on('2026-09-22')
        .withCard('major_11')
        .drawnAt(DateTime.utc(2026, 9, 22, 7))
        .build();
    final moon = aDailyCard()
        .on('2026-09-23')
        .withCard('major_18')
        .drawnAt(DateTime.utc(2026, 9, 23, 7))
        .build();

    setUp(() async {
      db = JournalDatabase(NativeDatabase.memory());
      logger = CapturingLogger();
      content = FakeContentRepository(
        texts: {
          (const CardId('major_11'), 'en'): aCardText(
            const CardId('major_11'),
          ).copyWith(name: 'Justice'),
          (const CardId('major_18'), 'en'): aCardText(
            const CardId('major_18'),
          ).copyWith(name: 'The Moon'),
          (const CardId('major_11'), 'de'): aCardText(
            const CardId('major_11'),
            locale: 'de',
          ).copyWith(name: 'Gerechtigkeit'),
        },
      );
      journal = JournalRepositoryImpl(
        journal: db,
        logger: logger,
        cardNames: JournalRepositoryImpl.contentNames(content, () => 'en'),
      );
      expectOk(
        await journal.replaceAll(
          BackupData(
            settings: const UserSettings(),
            readings: [tower, plain],
            dailyCards: [star, moon],
          ),
        ),
      );
    });
    tearDown(() => db.close());

    List<String> keys(List<JournalItem> items) => [
      for (final i in items)
        switch (i) {
          JournalReadingItem(:final reading) => reading.id.value,
          JournalDailyCardItem(:final card) => card.localDate,
        },
    ];

    test('search is accent- and case-insensitive (FTS5 trigram)', () async {
      expect(keys(expectOk(await journal.search('uber ZUKUNFT'))), [
        tower.id.value,
      ]);
      expect(keys(expectOk(await journal.search('ok'))), [plain.id.value]);
      expect(expectOk(await journal.search('  ')), isEmpty);
    });

    test('search finds readings and daily cards by card name', () async {
      expect(keys(expectOk(await journal.search('justice'))), [
        star.localDate,
        tower.id.value,
      ]);
      expect(keys(expectOk(await journal.search('moon'))), [moon.localDate]);
    });

    test('card names follow the app locale', () async {
      var locale = 'en';
      final localized = JournalRepositoryImpl(
        journal: db,
        logger: logger,
        cardNames: JournalRepositoryImpl.contentNames(content, () => locale),
      );
      expect(expectOk(await localized.search('gerecht')), isEmpty);
      locale = 'de';
      expect(keys(expectOk(await localized.search('gerecht'))), hasLength(2));
    });

    test('without deck content, search covers questions and notes', () async {
      content.failNext(const Failure.storage(), on: 'deck');
      expect(expectOk(await journal.search('justice')), isEmpty);
      final plainJournal = JournalRepositoryImpl(journal: db, logger: logger);
      expect(expectOk(await plainJournal.search('justice')), isEmpty);
    });

    test('watchAll filters by card', () async {
      final items = await journal
          .watchAll(query: const JournalQuery(cardId: CardId('major_11')))
          .first;
      expect(keys(items), [star.localDate, tower.id.value]);
      final none = await journal
          .watchAll(
            query: const JournalQuery(
              includeDailyCards: false,
              cardId: CardId('major_18'),
            ),
          )
          .first;
      expect(none, isEmpty);
    });

    test('watchAll follows edits of readings and daily cards', () async {
      final seen = <List<JournalItem>>[];
      final sub = journal
          .watchAll(query: const JournalQuery(favouritesOnly: true))
          .listen(seen.add);
      await settle();
      await db.dailyCardsDao.patch(
        moon.localDate,
        const DailyCardsCompanion(favourite: Value(true)),
      );
      await settle();
      await sub.cancel();
      expect(seen.first, isEmpty);
      expect(keys(seen.last), [moon.localDate]);
    });

    test('snapshot and replaceAll keep the settings', () async {
      const settings = UserSettings(
        themeMode: ThemeMode.light,
        localeOverride: 'de',
        reduceMotion: true,
      );
      expectOk(
        await journal.replaceAll(
          const BackupData(settings: settings, readings: [], dailyCards: []),
        ),
      );
      final rows = await db.settingsDao.readAll();
      expect(rows['theme'], '"light"');
      expect(rows['localeOverride'], '"de"');
      expectOk(await journal.deleteAll());
      expect(await db.settingsDao.readAll(), isEmpty);
    });

    test('a broken database is a StorageFailure', () async {
      await db.customStatement('DROP TABLE journal_fts');
      expect(expectErr(await journal.search('ok')), isA<StorageFailure>());
      expect(
        logger.records.where((r) => r.level == LogLevel.warning),
        isNotEmpty,
      );
    });

    test('a failing source stream errors the merged stream', () async {
      await db.customStatement('DROP TABLE daily_cards');
      await expectLater(journal.watchAll().first, throwsA(anything));
    });
  });
}
