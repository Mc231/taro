import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

SpreadDefinition threePpf() => const SpreadDefinition(
  id: SpreadId('three_ppf'),
  version: 1,
  positions: [
    SpreadPosition(id: PositionId('future'), order: 3, x: 0.8, y: 0.5),
    SpreadPosition(id: PositionId('past'), order: 1, x: 0.2, y: 0.5),
    SpreadPosition(id: PositionId('present'), order: 2, x: 0.5, y: 0.5),
  ],
);

void main() {
  group('kSpreadIds', () {
    test('is the six 01 §10.3 spreads', () {
      expect(kSpreadIds.map((s) => s.value), [
        'single',
        'three_ppf',
        'three_sao',
        'relationship',
        'two_paths',
        'celtic_cross',
      ]);
    });
  });

  group('SpreadDefinition', () {
    test('defaults, count and order', () {
      final spread = threePpf();
      expect(spread.cardCount, 3);
      expect(spread.allowsReversals, isTrue);
      expect(spread.enabled, isTrue);
      expect(spread.questionSuggestionKeys, isEmpty);
      expect(spread.positionsInOrder.map((p) => p.id.value), [
        'past',
        'present',
        'future',
      ]);
      expect(spread.problems, isEmpty);
      expect(spread.position(const PositionId('past'))!.order, 1);
      expect(spread.position(const PositionId('nope')), isNull);
      expect(spread.positions.first.rotationDeg, 0);
    });

    test('value equality and copyWith', () {
      expect(threePpf(), threePpf());
      expect(threePpf().copyWith(enabled: false), isNot(threePpf()));
      const p = SpreadPosition(id: PositionId('a'), order: 1, x: 0, y: 0);
      expect(p.copyWith(rotationDeg: 90).rotationDeg, 90);
    });

    test('reports broken invariants', () {
      const empty = SpreadDefinition(
        id: SpreadId('single'),
        version: 1,
        positions: [],
      );
      expect(empty.problems, ['single: no positions']);

      const broken = SpreadDefinition(
        id: SpreadId('x'),
        version: 1,
        positions: [
          SpreadPosition(id: PositionId('a'), order: 1, x: 1.5, y: 0),
          SpreadPosition(id: PositionId('a'), order: 3, x: 0, y: -1),
        ],
      );
      expect(broken.problems, [
        'x: duplicate position IDs',
        'x: orders must be 1..2',
        'x/a: layout outside 0..1',
        'x/a: layout outside 0..1',
      ]);
    });
  });

  group('DrawnCard', () {
    test('JSON round trip', () {
      const card = DrawnCard(
        positionId: PositionId('past'),
        cardId: CardId('cups_03'),
        reversed: true,
      );
      final json = card.toJson();
      expect(json, {
        'positionId': 'past',
        'cardId': 'cups_03',
        'reversed': true,
      });
      expect(DrawnCard.fromJson(json), card);
      expect(card.copyWith(reversed: false).reversed, isFalse);
    });

    test('rejects an invalid card ID', () {
      expect(
        () => DrawnCard.fromJson({
          'positionId': 'past',
          'cardId': 'major_22',
          'reversed': false,
        }),
        throwsFormatException,
      );
    });
  });

  group('Draw', () {
    test('accessors', () {
      final draw = threeCardDraw();
      expect(draw.cardIds.map((c) => c.value), [
        'major_16',
        'cups_03',
        'pentacles_14',
      ]);
      expect(draw.at(const PositionId('present'))!.reversed, isTrue);
      expect(draw.at(const PositionId('nope')), isNull);
      expect(draw.hasUniqueCards, isTrue);
    });

    test('detects duplicates', () {
      final draw = threeCardDraw();
      final dup = draw.copyWith(cards: [draw.cards[0], draw.cards[0]]);
      expect(dup.hasUniqueCards, isFalse);
      expect(dup, isNot(draw));
      expect(threeCardDraw(), draw);
    });
  });
}
