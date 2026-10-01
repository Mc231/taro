import 'package:taro/common/disclaimer_footer.dart';

import '../support/flow_harness.dart';

/// F1 + F2 (01 §9.1, §9.2; 06 §4): onboarding → disclaimer → AI consent →
/// Home → spread `three_ppf` → question → Begin (hold) → draw → reading
/// with the disclaimer footer → acknowledged → saved to the Journal. No
/// analytics event reaches the backend before consent resolves (RC68).
void main() {
  taroFlow('first launch: onboarding, then the free reading', ($) async {
    final fakes = flowFakes(consent: const ConsentState())
      ..install = FakeInstallRepository.firstLaunch();
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();

    // F1: onboarding (S02 → S03 → S04), consent not asked yet (RC19).
    await app.waitForScreen(ScreenId.s02);
    await app.tapText(l.welcomeGetStarted);
    await app.waitForScreen(ScreenId.s03);
    await app.tapText(l.disclaimerAcknowledge);
    await app.waitForScreen(ScreenId.s04);
    expect(fakes.consentService.calls, isNot(contains('gather')));
    // RC68: onboarding events are buffered, nothing reached the backend.
    expect(fakes.analytics.events, isEmpty);
    expect(fakes.analytics.consents, [AnalyticsConsent.allDenied()]);

    await app.tapText(l.aiConsentAccept);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(
      () => app.orchestrator.isResolved,
      reason: 'UMP resolved after onboarding',
    );
    expect(fakes.consentService.calls, contains('gather'));
    expect(fakes.consentStore.current.onboardingDone, isTrue);
    expect(
      fakes.consentStore.current.ai.decision,
      AiConsentDecision.granted,
    );
    // Released after resolution: the buffered onboarding events arrive.
    await app.waitUntil(
      () => fakes.analytics.events.isNotEmpty,
      reason: 'buffered events flushed',
    );

    // F2: the free reading. The hold is taken before any card exists.
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s08);
    expect(fakes.readings.holds, hasLength(1));
    expect(fakes.readings.holds.single.$2, const SpreadId('three_ppf'));
    await app.drawAndRevealAll();

    await app.waitForScreen(ScreenId.s09);
    // The footer closes the (lazy) reading list.
    await app.$(DisclaimerFooter).scrollTo();
    expect(find.byType(DisclaimerFooter), findsWidgets);
    await app.waitUntil(
      () => fakes.readings.acked.isNotEmpty,
      reason: 'delivery acknowledged',
    );
    final saved = fakes.journal.readings.values.single;
    expect(saved.status, isA<ReadingStatusComplete>());
    expect(saved.question, kTestQuestion);
    expect(fakes.readings.acked, [saved.id]);

    // Saved to the Journal.
    await app.tapFinder(find.byTooltip(l.readingDone));
    await app.waitForScreen(ScreenId.s05);
    await app.tapText(l.tabJournal);
    await app.waitForScreen(ScreenId.s14);
    await app.waitFor(find.text(kTestQuestion));
  });
}
