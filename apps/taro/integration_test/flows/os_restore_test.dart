import '../support/flow_harness.dart';

/// OS backup restore onto a new device (RC75; 02 §6.1): `taro_journal.db`
/// came back, `taro_device.db` and the secure store did not. The app
/// registers a new install, asks for consent again (onboarding), shows
/// the restored Journal, and replays no purchase outbox (it was never
/// restored).
void main() {
  taroFlow('OS restore: journal kept, new install, consent re-asked', (
    $,
  ) async {
    final fakes = flowFakes(consent: const ConsentState())
      ..install = FakeInstallRepository.firstLaunch();
    const questions = ['Restored question one', 'Restored question two'];
    for (final (i, q) in questions.indexed) {
      fakes.journal.putReading(
        aReading()
            .withId('0c6e2b1e-1111-4222-8333-44445555667$i')
            .withQuestion(q)
            .build(),
      );
    }
    expect(fakes.secureStore.values, isEmpty);
    expect(fakes.outbox.rows, isEmpty);

    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    // Consent state lived in the device DB: onboarding and consent again.
    await app.waitForScreen(ScreenId.s02);
    await app.tapText(l.welcomeGetStarted);
    await app.tapText(l.disclaimerAcknowledge);
    await app.waitForScreen(ScreenId.s04);
    expect(fakes.consentService.calls, isNot(contains('gather')));
    await app.tapButton(l.aiConsentAccept);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => app.orchestrator.isResolved);
    expect(fakes.consentService.calls, contains('gather'));

    // A new registration.
    await app.waitUntil(() => fakes.install.identity?.isRegistered ?? false);
    expect(fakes.install.calls, containsAllInOrder(['getOrCreate']));
    expect(fakes.install.calls, contains('ensureRegistered'));

    // No outbox replay: nothing verified, nothing finished.
    expect(fakes.verifier.verifications, isEmpty);
    expect(fakes.iap.finished, isEmpty);

    // The restored Journal.
    await app.tapText(l.tabJournal);
    await app.waitForScreen(ScreenId.s14);
    for (final q in questions) {
      await app.waitFor(find.text(q));
    }
  });
}
