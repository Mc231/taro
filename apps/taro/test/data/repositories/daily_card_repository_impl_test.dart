import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/repositories/daily_card_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';

final class _Harness implements DailyCardRepositoryHarness {
  _Harness({RandomSource? random, UserSettings? settings}) {
    addTearDown(db.close);
    repo = DailyCardRepositoryImpl(
      dao: db.dailyCardsDao,
      content: content,
      settings: FakeSettingsRepository(initial: settings),
      clock: clock,
      random: random ?? SeededRandomSource(),
      logger: logger,
    );
  }

  final JournalDatabase db = memoryJournal();
  final FakeClock clock = FakeClock();
  final FakeContentRepository content = FakeContentRepository();
  final CapturingLogger logger = CapturingLogger();
  late final DailyCardRepositoryImpl repo;

  @override
  DailyCardRepository get subject => repo;

  @override
  void advanceToNextLocalDay() => clock.advance(const Duration(days: 1));

  @override
  void advanceWithinDay() => clock.advance(const Duration(hours: 1));
}

void main() {
  runDailyCardRepositoryContract(_Harness.new);

  test('today is the device-local date, not the UTC date', () async {
    // kTestNow is 09:00Z; at UTC+3, 22:30Z is already the next local day.
    final h = _Harness()..clock.advance(const Duration(hours: 13, minutes: 30));
    final card = expectOk(await h.repo.drawToday());
    expect(card.localDate, '2026-09-27');
    expect(card.drawnAt, h.clock.now());
  });

  test('draws from the random source; reversals follow settings', () async {
    final h = _Harness(
      random: ScriptedRandomSource([5]),
      settings: const UserSettings(reversalsEnabled: false),
    );
    final card = expectOk(await h.repo.drawToday());
    expect(card.cardId, kCardIds[5]);
    expect(card.reversed, isFalse);
    expect(card.localDate, kTestLocalDate);
    final row = await h.db.dailyCardsDao.byDate(kTestLocalDate);
    expect(row!.cardId, kCardIds[5].value);
  });

  test('a card stored for today is returned without drawing', () async {
    final h = _Harness(random: ScriptedRandomSource([]));
    await h.db.dailyCardsDao.insertIfAbsent(
      dailyCardRow(kTestLocalDate, cardId: 'cups_03', note: 'kept'),
    );
    final card = expectOk(await h.repo.drawToday());
    expect(card.cardId.value, 'cups_03');
    expect(card.note, 'kept');
  });

  test('concurrent draws keep one card for the day', () async {
    final h = _Harness();
    final cards = await Future.wait([h.repo.drawToday(), h.repo.drawToday()]);
    expect(expectOk(cards[0]), expectOk(cards[1]));
    expect(await h.db.dailyCardsDao.all(), hasLength(1));
  });

  test('a deck failure is returned and nothing is stored', () async {
    final h = _Harness();
    h.content.failNext(const Failure.storage(), on: 'deck');
    expect(expectErr(await h.repo.drawToday()), isA<StorageFailure>());
    expect(await h.db.dailyCardsDao.all(), isEmpty);
  });

  test('a row with an invalid card ID is a storage failure', () async {
    final h = _Harness();
    await h.db.dailyCardsDao.insertIfAbsent(
      dailyCardRow(kTestLocalDate, cardId: 'nope'),
    );
    expect(expectErr(await h.repo.drawToday()), isA<StorageFailure>());
    expect(await h.repo.watchToday().first, isNull);
    expect(h.logger.logged('invalid card ID'), isTrue);
  });

  test('database errors become storage failures', () async {
    final h = _Harness();
    await h.db.customStatement('DROP TABLE daily_cards');
    expect(expectErr(await h.repo.drawToday()), isA<StorageFailure>());
    expect(
      expectErr(await h.repo.setNote(kTestLocalDate, 'x')),
      isA<StorageFailure>(),
    );
    expect(h.logger.logged('daily card draw failed'), isTrue);
    expect(h.logger.logged('daily card update failed'), isTrue);
    await expectLater(h.repo.watchToday().first, throwsA(anything));
  });

  test('changes to a day without a card are no-ops', () async {
    final h = _Harness();
    expectOk(await h.repo.setFavourite('2020-01-01', favourite: true));
    expect(await h.db.dailyCardsDao.all(), isEmpty);
  });

  test('watchToday re-reads the date on each change', () async {
    final h = _Harness();
    final seen = <DailyCard?>[];
    final sub = h.repo.watchToday().listen(seen.add);
    await pumpEventQueue();
    final first = expectOk(await h.repo.drawToday());
    await pumpEventQueue();
    h.advanceToNextLocalDay();
    final second = expectOk(await h.repo.drawToday());
    await pumpEventQueue();
    await h.repo.setNote(second.localDate, 'evening');
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, isNull);
    expect(seen[1], first);
    expect(seen[2], second);
    expect(seen.last!.note, 'evening');
    expect(seen, hasLength(4));
  });
}
