import 'package:taro/common/banner_slot.dart';

import '../support/flow_harness.dart';

/// Store-review evidence flows (05 §1; `docs/compliance/APPLE_MATRIX.md`):
///
/// * 3.2.2: the free daily reading never shows an ad, rewarded or banner;
/// * 5.1.2(i): nothing of the question leaves the device before AI consent:
///   with consent declined, Begin takes no hold and submits no reading;
///   both happen only after the user allows AI readings;
/// * 5.1.1(iv): UMP denied on its own (AI allowed) keeps the app usable:
///   ATT skipped, the ads SDK off, and the AI reading still works.
void main() {
  taroFlow('3.2.2: the free reading never shows an ad', ($) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => app.orchestrator.isResolved);

    await app.openQuestion();
    expect(find.byType(BannerSlot), findsNothing, reason: 'S07');
    await app.begin();
    await app.waitForScreen(ScreenId.s08);
    expect(find.byType(BannerSlot), findsNothing, reason: 'S08');
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    expect(find.byType(BannerSlot), findsNothing, reason: 'S09');

    expect(fakes.readings.submitted, hasLength(1));
    expect(fakes.ads.shown, isEmpty, reason: 'no rewarded ad (RC34)');
    expect(fakes.ads.callCount('showRewarded'), 0);
    expect(app.screen(ScreenId.s10), findsNothing);
  });

  taroFlow('5.1.2(i): no reading request before AI consent', ($) async {
    final fakes = flowFakes(consent: onboardedConsent(aiGranted: false));
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s05);

    await app.openQuestion();
    await app.begin();
    // The gate re-asks (RC21) instead of calling the Worker.
    await app.waitForScreen(ScreenId.s04);
    expect(fakes.readings.holds, isEmpty);
    expect(fakes.readings.submitted, isEmpty);
    expect(fakes.readings.callCount('hold'), 0);
    expect(fakes.readings.callCount('submit'), 0);

    await app.tapButton(l.aiConsentReentryAllow);
    await app.waitForScreen(ScreenId.s08);
    expect(
      fakes.consentStore.current.ai.decision,
      AiConsentDecision.granted,
    );
    expect(fakes.readings.holds, hasLength(1));
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    expect(fakes.readings.submitted, hasLength(1));
    expect(fakes.readings.submitted.single.question, kTestQuestion);
  });

  taroFlow('5.1.1(iv): UMP denied alone, the AI reading still works', (
    $,
  ) async {
    final fakes = flowFakes()
      ..consentService = FakeConsentService(
        status: AdsConsentStatus.required,
        afterForm: const AdsConsent(status: AdsConsentStatus.obtained),
      )
      ..tracking = FakeTrackingAuthorization();
    final app = await FlowApp.launch($, fakes: fakes);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => app.orchestrator.outcome != null);

    expect(app.orchestrator.outcome!.ads.canRequestAds, isFalse);
    expect(fakes.tracking.calls, isEmpty, reason: 'ATT skipped (RC19)');
    expect(fakes.ads.isInitialized, isFalse);

    await app.openQuestion();
    await app.begin();
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    expect(
      fakes.journal.readings.values.single.status,
      isA<ReadingStatusComplete>(),
    );
  });
}
