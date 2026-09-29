import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// The `JournalRepository` contract (01 §7.8, 02 §5, §12). [create] returns
/// an empty journal; data is seeded through `replaceAll`.
void runJournalRepositoryContract(JournalRepository Function() create) {
  group('JournalRepository contract', () {
    late JournalRepository journal;

    final older = aReading()
        .withId('11111111-1111-4111-8111-111111111111')
        .createdAt(DateTime.utc(2026, 9, 20, 8), localDate: '2026-09-20')
        .withSpread('single')
        .withQuestion('Is the harbour calm?')
        .build();
    final newer = aReading()
        .withId('22222222-2222-4222-8222-222222222222')
        .createdAt(DateTime.utc(2026, 9, 25, 8), localDate: '2026-09-25')
        .withNote('Remember the lighthouse')
        .favourite()
        .build();
    final classic = aReading()
        .withId('33333333-3333-4333-8333-333333333333')
        .createdAt(DateTime.utc(2026, 9, 22, 8), localDate: '2026-09-22')
        .classic()
        .withQuestion(null)
        .build();
    final daily = aDailyCard()
        .on('2026-09-23')
        .drawnAt(DateTime.utc(2026, 9, 23, 7))
        .withNote('Stars')
        .favourite()
        .build();

    final data = BackupData(
      settings: const UserSettings(themeMode: ThemeMode.dark),
      readings: [older, newer, classic],
      dailyCards: [daily],
    );

    setUp(() => journal = create());

    List<DateTime> times(List<JournalItem> items) => [
      for (final i in items) i.createdAt,
    ];

    test('an empty journal has an empty snapshot', () async {
      final snapshot = expectOk(await journal.snapshot());
      expect(snapshot.readings, isEmpty);
      expect(snapshot.dailyCards, isEmpty);
    });

    test('replaceAll stores exactly the given entries', () async {
      expectOk(await journal.replaceAll(data));
      final snapshot = expectOk(await journal.snapshot());
      expect(snapshot.readings, unorderedEquals([older, newer, classic]));
      expect(snapshot.dailyCards, [daily]);

      final smaller = data.copyWith(readings: [newer], dailyCards: []);
      expectOk(await journal.replaceAll(smaller));
      final after = expectOk(await journal.snapshot());
      expect(after.readings, [newer]);
      expect(after.dailyCards, isEmpty);
    });

    test('watchAll lists readings and daily cards newest first', () async {
      await journal.replaceAll(data);
      final items = await journal.watchAll().first;
      expect(items, hasLength(4));
      expect(times(items), [
        newer.createdAt,
        daily.createdAt,
        classic.createdAt,
        older.createdAt,
      ]);
    });

    test('watchAll filters favourites, spreads and daily cards', () async {
      await journal.replaceAll(data);
      final favourites = await journal
          .watchAll(query: const JournalQuery(favouritesOnly: true))
          .first;
      expect(times(favourites), [newer.createdAt, daily.createdAt]);

      final single = await journal
          .watchAll(query: const JournalQuery(spreadId: SpreadId('single')))
          .first;
      expect(single, [JournalItem.reading(older)]);

      final noDaily = await journal
          .watchAll(query: const JournalQuery(includeDailyCards: false))
          .first;
      expect(noDaily.whereType<JournalDailyCardItem>(), isEmpty);
      expect(noDaily, hasLength(3));
    });

    test('watchAll filters by card: readings and daily cards', () async {
      await journal.replaceAll(data);
      // Only the three-card readings drew their second card.
      final second = newer.cards[1].cardId;
      expect(older.cards.map((c) => c.cardId), isNot(contains(second)));
      final byCard = await journal
          .watchAll(query: JournalQuery(cardId: second))
          .first;
      expect(byCard, [
        JournalItem.reading(newer),
        JournalItem.reading(classic),
      ]);

      final byDaily = await journal
          .watchAll(query: JournalQuery(cardId: daily.cardId))
          .first;
      expect(byDaily, [JournalItem.dailyCard(daily)]);

      final noDaily = await journal
          .watchAll(
            query: JournalQuery(cardId: daily.cardId, includeDailyCards: false),
          )
          .first;
      expect(noDaily, isEmpty);
    });

    test('watchAll emits again after a change', () async {
      final seen = <List<JournalItem>>[];
      final sub = journal.watchAll().listen(seen.add);
      await settle();
      await journal.replaceAll(data);
      await settle();
      await sub.cancel();
      expect(seen.first, isEmpty);
      expect(seen.last, hasLength(4));
    });

    test('search finds questions and notes, case-insensitively', () async {
      await journal.replaceAll(data);
      expect(expectOk(await journal.search('HARBOUR')), [
        JournalItem.reading(older),
      ]);
      expect(expectOk(await journal.search('lighthouse')), [
        JournalItem.reading(newer),
      ]);
      expect(expectOk(await journal.search('stars')), [
        JournalItem.dailyCard(daily),
      ]);
      expect(expectOk(await journal.search('no such text')), isEmpty);
    });

    test('deleteAll empties the journal', () async {
      await journal.replaceAll(data);
      expectOk(await journal.deleteAll());
      final snapshot = expectOk(await journal.snapshot());
      expect(snapshot.readings, isEmpty);
      expect(snapshot.dailyCards, isEmpty);
      expect(await journal.watchAll().first, isEmpty);
    });
  });
}
