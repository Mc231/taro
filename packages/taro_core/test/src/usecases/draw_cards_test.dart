import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeContentRepository content;
  late FakeSettingsRepository settings;
  late FakeClock clock;
  final spread = aSpread('celtic_cross').build();

  setUp(() {
    content = FakeContentRepository();
    settings = FakeSettingsRepository();
    clock = FakeClock();
  });

  DrawCards drawCards(RandomSource random) => DrawCards(
    content: content,
    settings: settings,
    random: random,
    clock: clock,
  );

  group('call (AI reading under a hold)', () {
    test('draws every position with unique cards at clock time', () async {
      final draw = expectOk(
        await drawCards(
          SeededRandomSource(),
        ).call(spread, hold: aReadingHold()),
      );
      expect(draw.spreadId, spread.id);
      expect(draw.cards, hasLength(10));
      expect(draw.hasUniqueCards, isTrue);
      expect(
        [for (final c in draw.cards) c.positionId],
        [for (final p in spread.positionsInOrder) p.id],
      );
      expect(draw.drawnAt, kTestNow);
    });

    test('is exact for a scripted source', () async {
      // Every swap picks index 0: the last card ends up first each round.
      final random = ScriptedRandomSource(
        List.filled(77, 0),
        bools: List.filled(3, true),
      );
      final draw = expectOk(
        await drawCards(random).call(
          aSpread().build(),
          hold: aReadingHold(),
        ),
      );
      expect(random.maxes.first, 78);
      expect(random.boolCalls, 3);
      expect(draw.cards.every((c) => c.reversed), isTrue);
      expect(draw.cardIds, hasLength(3));
    });

    test('no card is reversed when the user turned reversals off', () async {
      await settings.update((s) => s.copyWith(reversalsEnabled: false));
      final random = ScriptedRandomSource(List.filled(77, 0));
      final draw = expectOk(
        await drawCards(random).call(spread, hold: aReadingHold()),
      );
      expect(random.boolCalls, 0);
      expect(draw.cards.any((c) => c.reversed), isFalse);
    });

    test('a lapsed hold draws nothing (holdLost)', () async {
      clock.advance(const Duration(minutes: 11));
      final random = ScriptedRandomSource([]);
      expect(
        expectErr(await drawCards(random).call(spread, hold: aReadingHold())),
        const Failure.holdConflict(),
      );
      expect(random.maxes, isEmpty);
      expect(content.calls, isEmpty);
    });

    test('a missing deck is a failure', () async {
      content.failNext(const Failure.storage(), on: 'deck');
      expect(
        expectErr(
          await drawCards(
            SeededRandomSource(),
          ).call(spread, hold: aReadingHold()),
        ),
        const Failure.storage(),
      );
    });
  });

  group('classic', () {
    test('draws without a hold', () async {
      clock.advance(const Duration(days: 30));
      final draw = expectOk(
        await drawCards(SeededRandomSource()).classic(spread),
      );
      expect(draw.cards, hasLength(10));
      expect(draw.drawnAt, kTestNow.add(const Duration(days: 30)));
    });
  });
}
