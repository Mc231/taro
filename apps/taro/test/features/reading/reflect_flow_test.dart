import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/question_controller.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

/// R3-03: "Reflect on the cards without a question" (01 §7.5) reads the
/// declined cards themselves, and S08 does not ask to shuffle or pick again.
void main() {
  const args = QuestionArgs(spreadId: SpreadId('three_ppf'));

  for (final canRephrase in [true, false]) {
    test('refuse → reflect (canRephrase: $canRephrase): the Worker gets the '
        'declined cards; S08 goes straight to the reveal', () async {
      final fakes = aiReadyFakes();
      final container = fakes.container();
      final question = StateLog(
        container,
        questionControllerProvider(args),
      );
      await pumpEventQueue();
      final controller = container.read(
        questionControllerProvider(args).notifier,
      );

      fakes.readings.refuseNext(
        safety: SafetyInfo(
          category: RefusalCategory.health,
          messageKey: 'safetyDeclinedHealth',
          canRephrase: canRephrase,
        ),
      );
      controller.updateText('Is this mole serious?');
      await controller.begin();
      expect(question.last, isA<QuestionReady>());

      // The first S08: the full ritual, then the Worker declines.
      final draw = StateLog(container, drawControllerProvider);
      await pumpEventQueue();
      expect(draw.last, isA<DrawShuffling>());
      container.read(drawControllerProvider.notifier).finishShuffle();
      await container.read(drawControllerProvider.notifier).drawForMe();
      await pumpEventQueue();
      await container.read(drawControllerProvider.notifier).revealAll();
      await pumpEventQueue();
      expect(draw.last, isA<DrawReturnedToQuestion>());
      expect(
        question.last,
        canRephrase ? isA<QuestionRephrase>() : isA<QuestionRefused>(),
      );
      final declined = fakes.readings.submitted.single;
      expect(declined.question, 'Is this mole serious?');
      draw.subscription.close();

      // Reflect: no question, the same cards, no shuffle and no pick.
      await controller.reflectWithoutQuestion();
      expect(question.last, isA<QuestionReady>());
      final reflected = StateLog(container, drawControllerProvider);
      await pumpEventQueue();
      expect(
        reflected.states.whereType<DrawShuffling>(),
        isEmpty,
        reason: 'preset cards skip the shuffle',
      );
      expect(
        reflected.states.whereType<DrawPicking>().where(
          (s) => !s.view.allPlaced,
        ),
        isEmpty,
        reason: 'preset cards skip the pick',
      );
      final revealing = reflected.last as DrawRevealing;
      expect(revealing.view.allPlaced, isTrue);
      expect(revealing.view.revealed, 0);
      expect(revealing.view.question, isNull);
      expect(revealing.view.draw.cards, declined.draw.cards);

      await container.read(drawControllerProvider.notifier).revealAll();
      await pumpEventQueue();
      final done = reflected.last as DrawCompleted;
      final sent = fakes.readings.submitted.last;
      expect(fakes.readings.submitted, hasLength(2));
      expect(sent.question, isNull);
      expect(sent.draw.cards, declined.draw.cards);
      expect(done.reading.cards, declined.draw.cards);
      expect(fakes.readings.holds, hasLength(2));
      container.dispose();
    });
  }
}
