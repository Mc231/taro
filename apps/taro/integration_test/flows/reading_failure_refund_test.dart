import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';

import '../support/flow_harness.dart';

/// F6 (01 §9.6; RC5, RC49): the Worker answers `503 AI_UNAVAILABLE` → S08
/// `generationFailed` with the cards kept and **Try again** → the balance
/// is unchanged (refunded) → Try again resubmits the same cards with the
/// same `clientReadingId` → the reading arrives.
void main() {
  taroFlow('AI unavailable: cards kept, refunded, retry works', ($) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s08);
    final before = fakes.balance.cached;
    fakes.readings.failNext(const Failure.aiUnavailable(), on: 'submit');
    await app.drawAndRevealAll();

    await app.waitFor(find.text(l.drawGenerationFailedTitle));
    final failed = app.container.read(drawControllerProvider);
    expect(failed, isA<DrawGenerationFailed>());
    final cards = (failed as DrawGenerationFailed).view.draw.cards;
    final first = fakes.readings.submitted.single;
    expect(
      fakes.journal.readings[first.id]?.status,
      isA<ReadingStatusFailed>().having((s) => s.refunded, 'refunded', true),
    );
    expect(fakes.balance.cached, before, reason: 'nothing was charged');
    expect(app.screen(ScreenId.s09), findsNothing);

    await app.tapButton(l.commonRetry);
    await app.waitForScreen(ScreenId.s09);
    final retried = fakes.readings.submitted.last;
    expect(fakes.readings.submitted, hasLength(2));
    expect(retried.id, first.id);
    expect(retried.draw.cards, cards);
    expect(
      fakes.journal.readings[first.id]?.status,
      isA<ReadingStatusComplete>(),
    );
  });
}
