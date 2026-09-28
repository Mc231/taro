import 'package:test/test.dart';

import 'boundary_zones.dart';
import 'logic_support.dart';

void main() {
  final now = DateTime.utc(2026, 9, 26, 7);

  DailyCard stored(String localDate) => DailyCard(
    localDate: localDate,
    cardId: const CardId('major_17'),
    reversed: true,
    drawnAt: now,
    createdAt: now,
    updatedAt: now,
    note: 'kept',
  );

  group('DailyCardRules.today', () {
    test('no stored card: draws one with nextInt(78) and nextBool()', () {
      final rng = ScriptedRandomSource([17], bools: [true]);
      final pick = DailyCardRules(rng).today(
        today: '2026-09-26',
        stored: null,
        deck: deck,
        reversalsEnabled: true,
        now: now,
      );
      expect(pick.isNew, isTrue);
      expect(pick.card.cardId, const CardId('major_17'));
      expect(pick.card.reversed, isTrue);
      expect(pick.card.localDate, '2026-09-26');
      expect(pick.card.drawnAt, now);
      expect(pick.card.createdAt, now);
      expect(pick.card.updatedAt, now);
      expect(rng.maxes, [78]);
      expect(rng.boolCalls, 1);
    });

    test('the same local day returns the stored card, no randomness', () {
      final rng = ScriptedRandomSource([]);
      final card = stored('2026-09-26');
      final pick = DailyCardRules(rng).today(
        today: '2026-09-26',
        stored: card,
        deck: deck,
        reversalsEnabled: true,
        now: now.add(const Duration(hours: 10)),
      );
      expect(pick, DailyCardPick(card: card, isNew: false));
      expect(rng.maxes, isEmpty);
    });

    test('is idempotent: applying it to its own result changes nothing', () {
      final rules = DailyCardRules(SeededRandomSource(1));
      final first = rules.today(
        today: '2026-09-26',
        stored: null,
        deck: deck,
        reversalsEnabled: true,
        now: now,
      );
      var current = first.card;
      for (var i = 0; i < 5; i++) {
        final again = rules.today(
          today: '2026-09-26',
          stored: current,
          deck: deck,
          reversalsEnabled: true,
          now: now.add(Duration(hours: i)),
        );
        expect(again.isNew, isFalse);
        expect(again.card, first.card);
        current = again.card;
      }
    });

    test('a new local day draws a new card', () {
      final pick = DailyCardRules(ScriptedRandomSource([0])).today(
        today: '2026-09-27',
        stored: stored('2026-09-26'),
        deck: deck,
        reversalsEnabled: false,
        now: now,
      );
      expect(pick.isNew, isTrue);
      expect(pick.card.cardId, const CardId('major_00'));
      expect(pick.card.reversed, isFalse);
      expect(pick.card.note, isNull);
    });

    test('reversals off: no coin flip', () {
      final rng = ScriptedRandomSource([77]);
      final pick = DailyCardRules(rng).today(
        today: '2026-09-26',
        stored: null,
        deck: deck,
        reversalsEnabled: false,
        now: now,
      );
      expect(pick.card.cardId, const CardId('pentacles_14'));
      expect(rng.boolCalls, 0);
    });

    for (final zone in kBoundaryZones) {
      test('${zone.name}: same card until local midnight, new after', () {
        final rules = DailyCardRules(SeededRandomSource(3));
        final start = DateTime.utc(2026, 9, 26, 12);
        final midnight = zone.nextMidnight(start);
        final first = rules.today(
          today: zone.localDate(start),
          stored: null,
          deck: deck,
          reversalsEnabled: true,
          now: start,
        );
        final justBefore = midnight.subtract(const Duration(seconds: 1));
        expect(
          rules
              .today(
                today: zone.localDate(justBefore),
                stored: first.card,
                deck: deck,
                reversalsEnabled: true,
                now: justBefore,
              )
              .isNew,
          isFalse,
        );
        final after = rules.today(
          today: zone.localDate(midnight),
          stored: first.card,
          deck: deck,
          reversalsEnabled: true,
          now: midnight,
        );
        expect(after.isNew, isTrue);
        expect(
          after.card.localDate,
          LocalDates.addDays(first.card.localDate, 1),
        );
      });
    }
  });

  group('LocalDates', () {
    test('toDay / fromDay round trip', () {
      expect(LocalDates.toDay('1970-01-01'), 0);
      expect(LocalDates.toDay('1970-01-02'), 1);
      expect(
        LocalDates.fromDay(LocalDates.toDay('2026-02-28') + 1),
        '2026-03-01',
      );
      expect(LocalDates.addDays('2028-02-28', 1), '2028-02-29');
      expect(LocalDates.addDays('2026-01-01', -1), '2025-12-31');
      expect(LocalDates.fromDay(-1), '1969-12-31');
    });

    test('format uses the wall-clock fields', () {
      expect(LocalDates.format(DateTime(2026, 9, 5, 23, 59)), '2026-09-05');
      expect(LocalDates.format(DateTime.utc(987, 1, 2)), '0987-01-02');
    });

    test('rejects malformed and impossible dates', () {
      for (final bad in ['2026-9-26', '2026-02-30', '2026-13-01', 'x']) {
        expect(() => LocalDates.toDay(bad), throwsFormatException, reason: bad);
      }
    });
  });
}
