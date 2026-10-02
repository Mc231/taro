import '../support/flow_harness.dart';

/// Kill switches (Phase 19.3; 03 §8.2, §10; RC8, RC47, RC64): a stop is
/// never a paywall. `readings.enabled = false` → S31 "readings are
/// resting" on S07 with the Classic offer, no hold, no S10; the budget hard
/// stop (the balance says `readingsPaused`, or the hold answers `503
/// AI_BUDGET_EXHAUSTED tier=hard`) → the same S31 state, no S10, no draw.
void main() {
  taroFlow('readings.enabled=false: S31 + Classic offer, no paywall', (
    $,
  ) async {
    final fakes = flowFakes()
      ..config = FakeRemoteConfigRepository(
        aRemoteConfig().withReadingsEnabled(false).build(),
      );
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();

    await app.waitFor(find.text(l.pausedTitle));
    expect(app.screen(ScreenId.s10), findsNothing);
    expect(app.screen(ScreenId.s08), findsNothing);
    expect(fakes.readings.holds, isEmpty, reason: 'no hold while paused');

    await app.tapButton(l.questionTryClassic);
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s32);
    expect(
      fakes.journal.readings.values.single.status,
      isA<ReadingStatusClassic>(),
    );
    expect(fakes.readings.holds, isEmpty);
    expect(fakes.readings.submitted, isEmpty);
  });

  taroFlow('budget hard stop with no credits: S31, never the paywall', (
    $,
  ) async {
    final stopped = aCreditBalance()
        .withFreeRemaining(0)
        .withReadingsPaused()
        .build();
    final fakes = flowFakes()
      ..balance = FakeBalanceRepository(cached: stopped, server: stopped);
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();

    await app.waitFor(find.text(l.pausedTitle));
    expect(app.screen(ScreenId.s10), findsNothing);
    expect(app.screen(ScreenId.s11), findsNothing);
    expect(app.screen(ScreenId.s08), findsNothing);
    expect(fakes.readings.holds, isEmpty);
    expect(find.text(l.questionTryClassic), findsWidgets);
  });

  taroFlow('budget hard stop at the hold (503 tier=hard): S31, no draw', (
    $,
  ) async {
    final fakes = flowFakes();
    fakes.readings.failNext(
      const Failure.readingsPaused(reason: PausedReason.budgetHard),
      on: 'hold',
    );
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    final before = fakes.balance.cached;
    await app.openQuestion();
    await app.begin();

    await app.waitFor(find.text(l.pausedTitle));
    expect(app.screen(ScreenId.s10), findsNothing);
    expect(app.screen(ScreenId.s08), findsNothing);
    expect(fakes.readings.holds, hasLength(1), reason: 'one refused hold');
    expect(fakes.readings.submitted, isEmpty);
    expect(fakes.balance.cached, before, reason: 'nothing was charged');
  });
}
