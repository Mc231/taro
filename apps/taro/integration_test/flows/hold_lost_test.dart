import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro_ui/taro_ui.dart';

import '../support/flow_harness.dart';

/// Hold lost after the pick (RC48, RC50; 04 §12.1): the hold is too short
/// to reveal, its renewal returns `402` → S10 with every card face-down →
/// a rewarded grant → the same draw (same cards, same `clientReadingId`)
/// is resubmitted, nothing is redrawn.
void main() {
  taroFlow('hold lost: S10 face-down, grant, the same cards', ($) async {
    final fakes = flowFakes();
    // The hold reserved the free reading: 0 left, rewarded available.
    final reserved = aCreditBalance()
        .withFreeRemaining(0)
        .withNextSource(ChargeSource.free)
        .withLedgerVersion(2)
        .build();
    fakes.readings
      ..holdBalance = reserved
      // Under `ReadingHold.minRevealLeft` (120 s): the reveal renews it.
      ..holdTtl = const Duration(seconds: 60);
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards
      ..autoGrant = true
      ..grantBalance = aCreditBalance()
          .withFreeRemaining(0)
          .withBonus(1)
          .withRewarded(grantedToday: 1)
          .withLedgerVersion(3)
          .build();

    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s08);
    final firstHold = fakes.readings.holds.first.$1;

    // The renewal after the pick is refused.
    fakes.readings.failNext(
      const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      on: 'hold',
    );
    await app.tapButton(l.drawShuffleButton);
    await app.tapButton(l.drawForMe);
    await app.waitForScreen(ScreenId.s10);

    final lost = app.container.read(drawControllerProvider);
    expect(lost, isA<DrawHoldLost>());
    final cards = (lost as DrawHoldLost).view.draw.cards;
    expect(find.byType(TaroCardFace), findsNothing, reason: 'face-down');
    expect(fakes.readings.submitted, isEmpty);

    // A rewarded grant makes a reading available again.
    await app.tapText(l.rewardedOfferTitle(1));
    await app.waitForScreen(ScreenId.s12);
    await app.waitFor(find.text(l.rewardedGrantedTitle));
    await app.tapButton(l.commonContinue);

    // S10 closes by itself; the same draw is resubmitted.
    await app.waitUntil(
      () => fakes.readings.submitted.isNotEmpty,
      reason: 'hold re-taken for the same reading',
    );
    expect(fakes.readings.holds.map((h) => h.$1).toSet(), {firstHold});
    await app.tapButton(l.drawRevealAll);
    await app.waitForScreen(ScreenId.s09);
    final submitted = fakes.readings.submitted.single;
    expect(submitted.id, firstHold);
    expect(submitted.draw.cards, cards);
  });
}
