import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// What the `DailyCardRepository` contract needs besides the port.
abstract interface class DailyCardRepositoryHarness {
  /// The repository under test (no card stored yet).
  DailyCardRepository get subject;

  /// Moves the device clock to the next local day.
  void advanceToNextLocalDay();

  /// Moves the device clock forward within the same local day.
  void advanceWithinDay();
}

/// The `DailyCardRepository` contract (01 §7.6, §17.3): one card per local
/// day, idempotent.
void runDailyCardRepositoryContract(
  DailyCardRepositoryHarness Function() create,
) {
  group('DailyCardRepository contract', () {
    late DailyCardRepositoryHarness harness;
    late DailyCardRepository cards;

    setUp(() {
      harness = create();
      cards = harness.subject;
    });

    test('drawToday is idempotent within a local day', () async {
      final first = expectOk(await cards.drawToday());
      harness.advanceWithinDay();
      final again = expectOk(await cards.drawToday());
      expect(again, first);
    });

    test('a new local day draws a new card for that day', () async {
      final first = expectOk(await cards.drawToday());
      harness.advanceToNextLocalDay();
      final next = expectOk(await cards.drawToday());
      expect(next.localDate, isNot(first.localDate));
      expect(
        DateTime.parse(
          next.localDate,
        ).difference(DateTime.parse(first.localDate)),
        const Duration(days: 1),
      );
    });

    test('watchToday emits null, then the drawn card', () async {
      final seen = <DailyCard?>[];
      final sub = cards.watchToday().listen(seen.add);
      await settle();
      final card = expectOk(await cards.drawToday());
      await settle();
      await sub.cancel();
      expect(seen.first, isNull);
      expect(seen.last, card);
    });

    test('setNote and setFavourite change the stored card', () async {
      final card = expectOk(await cards.drawToday());
      harness.advanceWithinDay();
      expectOk(await cards.setNote(card.localDate, 'A calm start'));
      expectOk(await cards.setFavourite(card.localDate, favourite: true));
      final stored = expectOk(await cards.drawToday());
      expect(stored.note, 'A calm start');
      expect(stored.favourite, isTrue);
      expect(stored.cardId, card.cardId);
      expect(stored.updatedAt.isAfter(card.updatedAt), isTrue);

      expectOk(await cards.setNote(card.localDate, null));
      expect(expectOk(await cards.drawToday()).note, isNull);
    });
  });
}
