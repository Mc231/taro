import 'package:test/test.dart';

import 'logic_support.dart';

void main() {
  final now = DateTime.utc(2026, 9, 26, 10);

  group('CardDrawer.shuffle', () {
    test('is Fisher–Yates: nextInt(n) … nextInt(2), swap i with j', () {
      final rng = ScriptedRandomSource([0, 0]);
      final ids = [
        const CardId('major_00'),
        const CardId('major_01'),
        const CardId('major_02'),
      ];
      // i=2, j=0: [02, 01, 00]; i=1, j=0: [01, 02, 00].
      expect(CardDrawer(rng).shuffle(ids), [
        const CardId('major_01'),
        const CardId('major_02'),
        const CardId('major_00'),
      ]);
      expect(rng.maxes, [3, 2]);
      expect(ids.first, const CardId('major_00'), reason: 'input unchanged');
    });

    test('identity script (j = i) keeps the order', () {
      final rng = ScriptedRandomSource([for (var i = 77; i > 0; i--) i]);
      expect(CardDrawer(rng).shuffle(kCardIds), kCardIds);
      expect(rng.maxes, [for (var n = 78; n >= 2; n--) n]);
    });

    test('rejects an out-of-range nextInt', () {
      final ids = [const CardId('major_00'), const CardId('major_01')];
      expect(
        () => CardDrawer(ScriptedRandomSource([2])).shuffle(ids),
        throwsRangeError,
      );
      expect(
        () => CardDrawer(ScriptedRandomSource([-1])).shuffle(ids),
        throwsRangeError,
      );
    });

    test('an empty or single list uses no randomness', () {
      final rng = ScriptedRandomSource([]);
      expect(CardDrawer(rng).shuffle([]), isEmpty);
      expect(CardDrawer(rng).shuffle([const CardId('major_00')]), [
        const CardId('major_00'),
      ]);
      expect(rng.maxes, isEmpty);
    });
  });

  group('CardDrawer.draw with ScriptedRandomSource (exact order)', () {
    test('position i takes shuffled[i]; reversals drawn per position', () {
      // All j = 0: the shuffle rotates the deck so shuffled starts with
      // kCardIds[1], kCardIds[2], kCardIds[3] …
      final rng = ScriptedRandomSource(
        List.filled(77, 0),
        bools: [true, false, true],
      );
      final draw = CardDrawer(
        rng,
      ).draw(deck, spreadOf(3), reversalsEnabled: true, now: now);
      final expected = CardDrawer(
        ScriptedRandomSource(List.filled(77, 0)),
      ).shuffle(kCardIds);
      expect(draw.cardIds, expected.take(3));
      expect(draw.cardIds, [
        const CardId('major_01'),
        const CardId('major_02'),
        const CardId('major_03'),
      ]);
      expect([for (final c in draw.cards) c.reversed], [true, false, true]);
      expect(
        [for (final c in draw.cards) c.positionId.value],
        [
          'p1',
          'p2',
          'p3',
        ],
      );
      expect(draw.spreadId, const SpreadId('three_ppf'));
      expect(draw.spreadVersion, 2);
      expect(draw.drawnAt, now);
      expect(draw.drawnAt.isUtc, isTrue);
      expect(rng.boolCalls, 3);
      for (final id in draw.cardIds) {
        expect(CardId.isValid(id.value), isTrue);
      }
    });

    test('positions are filled in `order`, not list order', () {
      final rng = ScriptedRandomSource(
        List.filled(77, 0),
        bools: [false, false],
      );
      final draw = CardDrawer(rng).draw(
        deck,
        spreadOf(2, orders: [2, 1]),
        reversalsEnabled: true,
        now: now,
      );
      expect(draw.cards.first.positionId, const PositionId('p2'));
      expect(draw.cards.first.cardId, const CardId('major_01'));
      expect(draw.cards.last.positionId, const PositionId('p1'));
      expect(draw.cards.last.cardId, const CardId('major_02'));
    });

    test('no coin flips when reversals are off or not allowed', () {
      for (final (enabled, allowed) in [(false, true), (true, false)]) {
        final rng = ScriptedRandomSource(List.filled(77, 0));
        final draw = CardDrawer(rng).draw(
          deck,
          spreadOf(3, allowsReversals: allowed),
          reversalsEnabled: enabled,
          now: now,
        );
        expect(draw.cards.every((c) => !c.reversed), isTrue);
        expect(rng.boolCalls, 0);
      }
    });

    test('local now is stored as UTC', () {
      final local = DateTime(2026, 9, 26, 12);
      final draw = CardDrawer(
        ScriptedRandomSource(List.filled(77, 0)),
      ).draw(deck, spreadOf(1), reversalsEnabled: false, now: local);
      expect(draw.drawnAt, local.toUtc());
      expect(draw.drawnAt.isUtc, isTrue);
    });

    test('a spread larger than the deck is rejected', () {
      expect(
        () => CardDrawer(ScriptedRandomSource([])).draw(
          deck,
          spreadOf(79),
          reversalsEnabled: true,
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CardDrawer.draw property tests (SeededRandomSource)', () {
    test('no duplicates, every position filled, valid IDs', () {
      for (var seed = 0; seed < 500; seed++) {
        final size = 1 + seed % 12;
        final spread = spreadOf(size);
        final draw = CardDrawer(
          SeededRandomSource(seed),
        ).draw(deck, spread, reversalsEnabled: true, now: now);
        expect(draw.cards, hasLength(size));
        expect(draw.hasUniqueCards, isTrue, reason: 'seed $seed');
        expect(
          [for (final c in draw.cards) c.positionId],
          [
            for (final p in spread.positionsInOrder) p.id,
          ],
        );
        expect(draw.cardIds.every(deck.contains), isTrue);
      }
    });

    test('a full shuffle is a permutation of the 78 IDs', () {
      for (var seed = 0; seed < 50; seed++) {
        final shuffled = CardDrawer(SeededRandomSource(seed)).shuffle(kCardIds);
        expect(shuffled.toSet(), kCardIds.toSet());
        expect(shuffled, hasLength(78));
      }
    });

    test('the same seed gives the same draw', () {
      Draw drawWith(int seed) => CardDrawer(
        SeededRandomSource(seed),
      ).draw(deck, spreadOf(10), reversalsEnabled: true, now: now);
      expect(drawWith(7), drawWith(7));
      expect(drawWith(7), isNot(drawWith(8)));
    });
  });
}
