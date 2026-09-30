import 'package:taro/common/balance_chip.dart';

import '../support/flow_harness.dart';

/// The rewarded flow (01 §9.4, 04 §9.2; RC33–RC35, RC57): the offer shows
/// only when `rewarded.enabled` and `free.remaining == 0` → the ad is
/// watched to the end → the grant is polled → the balance shows
/// +`rewarded.amount` → the cooldown, then the daily cap, replace the
/// offer. The ad is never shown without a tap (rule 12).
void main() {
  taroFlow('rewarded ad: grant, cooldown, then the daily cap', ($) async {
    final fakes = flowFakes();
    final free = aCreditBalance().build();
    final exhausted = aCreditBalance()
        .withFreeRemaining(0)
        .withLedgerVersion(2)
        .build();
    final cooldownEnds = kTestNow.add(const Duration(minutes: 5));
    final granted = aCreditBalance()
        .withFreeRemaining(0)
        .withBonus(1)
        .withRewarded(grantedToday: 2, cooldownEndsAt: cooldownEnds)
        .withLedgerVersion(3)
        .build();
    fakes
      ..balance = FakeBalanceRepository(cached: free, server: free)
      ..ads.autoResult = RewardedShowResult.earned;
    fakes.rewards
      ..autoGrant = true
      ..grantBalance = granted;

    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s05);

    // A free reading left: no rewarded offer on the store.
    await app.tapFinder(find.byType(BalanceChip));
    await app.waitForScreen(ScreenId.s11);
    expect(find.text(l.rewardedOfferTitle(1)), findsNothing);
    expect(fakes.ads.shown, isEmpty);
    await app.tapFinder(find.bySemanticsLabel(l.commonClose));
    await app.waitForScreen(ScreenId.s05);

    // The free reading is used elsewhere: the next sync brings 0 left.
    // (A resume within `balance.resumeSyncThrottleSec` of the last sync is
    // skipped, so the device is away for a minute.)
    fakes.balance.server = exhausted;
    await app.backgroundAndResume(
      whileAway: () => app.control.advance(const Duration(minutes: 1)),
    );
    await app.waitUntil(() => fakes.balance.cached == exhausted);

    await app.tapFinder(find.byType(BalanceChip));
    await app.waitForScreen(ScreenId.s11);
    await app.tapText(l.rewardedOfferTitle(1));
    await app.waitForScreen(ScreenId.s12);
    await app.waitFor(find.text(l.rewardedGrantedTitle));
    expect(fakes.ads.shown, hasLength(1));
    expect(fakes.rewards.states.values.single, RewardIntentState.granted);
    expect(fakes.balance.cached?.bonus, 1);

    await app.tapButton(l.commonContinue);
    await app.waitForScreen(ScreenId.s11);
    // The cooldown replaces the offer (RC35).
    await app.waitFor(find.textContaining(l.rewardedCoolingDown('').trim()));
    expect(find.text(l.rewardedOfferTitle(1)), findsWidgets);

    // After the cooldown the Worker reports today's cap: the offer is
    // capped (RC34), not shown.
    fakes.balance.server = aCreditBalance()
        .withFreeRemaining(0)
        .withBonus(1)
        .withRewarded(grantedToday: 3)
        .withLedgerVersion(4)
        .build();
    await app.backgroundAndResume(
      whileAway: () => app.control.advance(const Duration(minutes: 6)),
    );
    await app.waitFor(find.text(l.rewardedCapped));
    expect(fakes.ads.shown, hasLength(1));
  });
}
