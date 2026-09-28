import 'package:test/test.dart';

import 'logic_support.dart';

Reading _reading(String localDate, List<(String, bool)> cards) {
  final at = DateTime.parse('${localDate}T08:00:00Z');
  return Reading(
    id: ReadingId('r-$localDate-${cards.first.$1}'),
    createdAt: at,
    updatedAt: at,
    localDate: localDate,
    draw: Draw(
      spreadId: const SpreadId('three_ppf'),
      spreadVersion: 1,
      cards: [
        for (var i = 0; i < cards.length; i++)
          DrawnCard(
            positionId: PositionId('p$i'),
            cardId: CardId(cards[i].$1),
            reversed: cards[i].$2,
          ),
      ],
      drawnAt: at,
    ),
    status: const ReadingStatus.complete(),
    contentLocale: 'en',
  );
}

DailyCard _daily(String localDate, String card, {bool reversed = false}) {
  final at = DateTime.parse('${localDate}T07:00:00Z');
  return DailyCard(
    localDate: localDate,
    cardId: CardId(card),
    reversed: reversed,
    drawnAt: at,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  const today = '2026-09-26';

  group('JournalPatterns.compute (01 §7.8)', () {
    test('hidden below 5 entries, shown from 5', () {
      final four = [
        for (var i = 0; i < 4; i++) _daily('2026-09-2$i', 'major_00'),
      ];
      expect(
        JournalPatterns.compute(
          readings: [],
          dailyCards: four,
          today: today,
        ).visible,
        isFalse,
      );
      final five = [...four, _daily('2026-09-25', 'major_01')];
      final p = JournalPatterns.compute(
        readings: [],
        dailyCards: five,
        today: today,
      );
      expect(p.visible, isTrue);
      expect(p.totalEntries, 5);
    });

    test('windows, most-drawn ranking, suits, ratios', () {
      final readings = [
        _reading('2026-09-26', [
          ('major_16', false),
          ('cups_03', true),
          ('pentacles_14', false),
        ]),
        _reading('2026-09-10', [
          ('cups_03', false),
          ('major_16', true),
          ('swords_01', false),
        ]),
        // 60 days ago: only in the 90-day window.
        _reading('2026-07-28', [('wands_05', true), ('wands_05', false)]),
        // Future and too old: in no window.
        _reading('2026-09-27', [('major_00', false)]),
        _reading('2026-06-01', [('major_00', false)]),
      ];
      final daily = [
        _daily('2026-09-25', 'cups_03'),
        _daily('2026-08-28', 'major_16', reversed: true), // day 29 back
        _daily('2026-08-27', 'major_16'), // day 30 back: outside 30
      ];
      final p = JournalPatterns.compute(
        readings: readings,
        dailyCards: daily,
        today: today,
      );
      expect(p.totalEntries, 8);

      final w30 = p.last30;
      expect(w30.days, 30);
      expect(w30.entries, 4);
      expect(w30.cards, 8);
      expect(w30.mostDrawn, const [
        CardCount(cardId: CardId('major_16'), count: 3),
        CardCount(cardId: CardId('cups_03'), count: 3),
      ]);
      expect(w30.major, 3);
      expect(w30.minor, 5);
      expect(w30.suits, {
        Suit.wands: 0,
        Suit.cups: 3,
        Suit.swords: 1,
        Suit.pentacles: 1,
      });
      expect(w30.reversed, 3);
      expect(w30.majorRatio, closeTo(3 / 8, 1e-9));
      expect(w30.reversedRatio, closeTo(3 / 8, 1e-9));

      final w90 = p.last90;
      expect(w90.entries, 6);
      expect(w90.cards, 11);
      expect(w90.mostDrawn.map((c) => c.cardId.value), [
        'major_16',
        'cups_03',
        'wands_05',
      ]);
      expect(w90.mostDrawn.first.count, 4);
      expect(w90.suits[Suit.wands], 2);
    });

    test('ties rank in canonical card order; at most 3; singles dropped', () {
      final daily = [
        for (final c in ['swords_02', 'major_05', 'cups_01', 'wands_09'])
          for (var i = 0; i < 2; i++) _daily('2026-09-${10 + i}', c),
        _daily('2026-09-20', 'major_21'),
      ];
      final w = JournalPatterns.compute(
        readings: [],
        dailyCards: daily,
        today: today,
      ).last30;
      expect(w.mostDrawn.map((c) => c.cardId.value), [
        'major_05',
        'wands_09',
        'cups_01',
      ]);
      expect(w.mostDrawn.length, JournalPatterns.topCards);
    });

    test('an empty journal has zero ratios', () {
      final p = JournalPatterns.compute(
        readings: [],
        dailyCards: [],
        today: today,
      );
      expect(p.visible, isFalse);
      expect(p.last30.cards, 0);
      expect(p.last30.majorRatio, 0);
      expect(p.last30.reversedRatio, 0);
      expect(p.last30.mostDrawn, isEmpty);
    });

    test('suitOf', () {
      expect(JournalPatterns.suitOf(const CardId('major_00')), isNull);
      expect(
        JournalPatterns.suitOf(const CardId('pentacles_14')),
        Suit.pentacles,
      );
    });
  });

  group('JournalPatterns.streakDays (analytics only, Q10)', () {
    test('consecutive days ending today', () {
      expect(
        JournalPatterns.streakDays(
          ['2026-09-24', '2026-09-25', '2026-09-26', '2026-09-20'],
          today,
        ),
        3,
      );
    });

    test('0 without an entry today; duplicates count once', () {
      expect(JournalPatterns.streakDays(['2026-09-25'], today), 0);
      expect(JournalPatterns.streakDays([], today), 0);
      expect(
        JournalPatterns.streakDays(['2026-09-26', '2026-09-26'], today),
        1,
      );
    });

    test('crosses month and year boundaries', () {
      expect(
        JournalPatterns.streakDays(['2025-12-31', '2026-01-01'], '2026-01-01'),
        2,
      );
    });
  });
}
