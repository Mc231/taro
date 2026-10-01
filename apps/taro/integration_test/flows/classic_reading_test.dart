import '../support/flow_harness.dart';

/// F8 (01 §7.4, §9.9; RC20, RC71): AI consent declined → Begin asks for
/// consent (S04 re-entry) → Back → "Try a classic reading" → cards and
/// static meanings, no hold and no Worker reading call → saved to the
/// Journal as `classic`; no rate-app credit.
void main() {
  taroFlow('AI declined: a Classic reading, no Worker call', ($) async {
    final fakes = flowFakes(consent: onboardedConsent(aiGranted: false));
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();

    await app.openQuestion();
    await app.begin();
    // The gate re-asks (reading-gate origin); the user keeps declining.
    await app.waitForScreen(ScreenId.s04);
    await app.tapButton(l.aiConsentReentryBack);
    await app.waitForScreen(ScreenId.s07);
    await app.tapButton(l.questionTryClassic);

    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s32);
    await app.waitFor(find.text(l.classicLabel));

    final saved = fakes.journal.readings.values.single;
    expect(saved.status, isA<ReadingStatusClassic>());
    expect(fakes.readings.holds, isEmpty);
    expect(fakes.readings.submitted, isEmpty);
    expect(fakes.readings.calls, isNot(contains('submit')));
    expect(fakes.review.triggers, isEmpty);
    await app.waitUntil(
      () => fakes.analytics.eventNames.contains('classic_reading_completed'),
      reason: 'classic_reading_completed logged',
    );
    expect(fakes.analytics.eventNames, contains('classic_reading_started'));

    await app.tapFinder(find.byTooltip(l.readingDone));
    await app.waitForScreen(ScreenId.s05);
    await app.tapText(l.tabJournal);
    await app.waitFor(find.text(kTestQuestion));
  });
}
