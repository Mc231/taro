import '../support/flow_harness.dart';

/// F7 and the consent sequence (01 §9.7; 02 §9.7; RC19, RC20, RC68):
///
/// * onboarding with AI consent declined and UMP denied (`canRequestAds`
///   false): ATT is skipped, the ads SDK stays off, no analytics event is
///   delivered, and Begin offers a Classic reading that works;
/// * UMP granted, then ATT denied: the app is fully usable and the ad
///   requests are non-personalized.
void main() {
  taroFlow('AI declined + UMP denied: no ATT, a Classic reading', ($) async {
    final fakes = flowFakes(consent: const ConsentState())
      ..install = FakeInstallRepository.firstLaunch()
      ..consentService = FakeConsentService(
        status: AdsConsentStatus.required,
        afterForm: const AdsConsent(status: AdsConsentStatus.obtained),
      );
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();

    await app.waitForScreen(ScreenId.s02);
    await app.tapText(l.welcomeGetStarted);
    await app.waitForScreen(ScreenId.s03);
    await app.tapText(l.disclaimerAcknowledge);
    await app.waitForScreen(ScreenId.s04);
    await app.tapButton(l.aiConsentDecline);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => app.orchestrator.outcome != null);

    expect(fakes.consentService.formsShown, 1);
    expect(fakes.tracking.calls, isEmpty, reason: 'ATT skipped (RC19)');
    expect(fakes.ads.isInitialized, isFalse);
    expect(app.orchestrator.outcome!.analytics, AnalyticsConsent.allDenied());
    expect(
      fakes.consentStore.current.ai.decision,
      AiConsentDecision.declined,
    );

    // F7: Begin → consent re-asked → "Back" → Classic reading (RC20).
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s04);
    await app.tapButton(l.aiConsentReentryBack);
    await app.waitForScreen(ScreenId.s07);
    await app.tapButton(l.questionTryClassic);
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s32);
    expect(
      fakes.journal.readings.values.single.status,
      isA<ReadingStatusClassic>(),
    );
    expect(fakes.readings.holds, isEmpty);
    // Analytics storage denied: the buffer was dropped, nothing delivered.
    expect(fakes.analytics.events, isEmpty);
  });

  taroFlow('UMP granted, ATT denied: usable, non-personalized ads', (
    $,
  ) async {
    final fakes = flowFakes()
      ..consentService = FakeConsentService(status: AdsConsentStatus.required)
      ..tracking = FakeTrackingAuthorization(answer: TrackingStatus.denied);
    final app = await FlowApp.launch($, fakes: fakes);
    await app.waitForScreen(ScreenId.s05);
    // The neutral pre-prompt comes after UMP and before the system prompt
    // (RC19, 05 CS14): one Continue, no incentive.
    await app.waitFor(find.text(app.l10n().attPrepromptTitle));
    expect(fakes.tracking.prompts, 0);
    await app.tapText(app.l10n().attPrepromptContinue);
    await app.waitUntil(() => app.orchestrator.outcome != null);
    expect(find.text(app.l10n().attPrepromptTitle), findsNothing);

    final outcome = app.orchestrator.outcome!;
    expect(outcome.ads.canRequestAds, isTrue);
    expect(fakes.tracking.prompts, 1, reason: 'ATT after UMP (RC19)');
    expect(outcome.tracking, TrackingStatus.denied);
    expect(fakes.consentStore.current.tracking, TrackingStatus.denied);
    expect(fakes.ads.isInitialized, isTrue);
    // No TCF purposes read: consent mode denies ad personalization, so
    // every ad request is non-personalized (NPA).
    expect(outcome.analytics.adPersonalization, isFalse);

    // Fully usable: the free reading still works.
    await app.openQuestion();
    await app.begin();
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
  });
}
