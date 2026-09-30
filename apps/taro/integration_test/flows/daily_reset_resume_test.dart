import '../support/flow_harness.dart';

/// The daily reset on resume (02 §9.2, rule 6; 06 §2.5 "Resume re-sync"):
/// the free reading is used → the app is backgrounded → the clock passes
/// local midnight → resume runs exactly one balance sync → the free
/// reading is back, shown on Home; a second resume the same day is a
/// no-op.
void main() {
  taroFlow('resume after midnight: the free reading is back, once', ($) async {
    final used = aCreditBalance().withFreeRemaining(0).build();
    final fakes = flowFakes()
      ..balance = FakeBalanceRepository(cached: used, server: used);
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s05);
    await app.waitFor(find.text(l.balanceFreeUsed));
    await app.waitUntil(() => fakes.balance.syncReasons.isNotEmpty);
    expect(fakes.balance.syncReasons, [SyncReason.launch]);

    // Tomorrow (Europe/Kyiv): the Worker has reset the allowance.
    final tomorrow = kTestResetsAt.add(const Duration(minutes: 1));
    app.control.serverBalance = aCreditBalance()
        .withLocalDate('2026-09-27')
        .withResetsAt(kTestResetsAt.add(const Duration(days: 1)))
        .withLedgerVersion(2)
        .syncedAt(tomorrow)
        .build();
    await app.backgroundAndResume(
      whileAway: () => app.control.setNow(tomorrow),
    );
    await app.waitFor(find.text(l.balanceFreeReadings(1)));
    expect(fakes.balance.syncReasons, [SyncReason.launch, SyncReason.resume]);

    // Same day, ten seconds later: idempotent, no second sync.
    await app.backgroundAndResume(
      whileAway: () => app.control.advance(const Duration(seconds: 10)),
    );
    await app.settle();
    expect(fakes.balance.syncReasons, [SyncReason.launch, SyncReason.resume]);
    expect(fakes.balance.cached?.free.remaining, 1);
  });
}
