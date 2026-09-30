import '../support/flow_harness.dart';

/// Reinstall (01 §10.4, 02 §6.2; RC75): the Keychain / Block Store keeps
/// the install ID and secret, the app data is gone. The reinstalled app
/// onboards again, keeps the same install ID (no new registration, no
/// second free reading today: the Worker still has today's allowance
/// used), and starts with an empty Journal.
void main() {
  taroFlow('reinstall: same install ID, no second free reading', ($) async {
    // First install: register and use today's free reading.
    final first = flowFakes(consent: const ConsentState())
      ..install = FakeInstallRepository.firstLaunch();
    final app = await FlowApp.launch($, fakes: first);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s02);
    await app.tapText(l.welcomeGetStarted);
    await app.tapText(l.disclaimerAcknowledge);
    await app.tapButton(l.aiConsentAccept);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => first.install.identity?.isRegistered ?? false);
    final identity = first.install.identity!;
    first.readings.holdBalance = aCreditBalance()
        .withFreeRemaining(0)
        .withNextSource(ChargeSource.free)
        .withLedgerVersion(2)
        .build();
    await app.openQuestion();
    await app.begin();
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    await app.shutdown();

    // Reinstall: the secure store (Keychain) survives, nothing else does.
    final used = aCreditBalance()
        .withFreeRemaining(0)
        .withLedgerVersion(3)
        .build();
    final second = flowFakes(consent: const ConsentState())
      ..secureStore = first.secureStore
      ..install = FakeInstallRepository(identity: identity)
      ..balance = FakeBalanceRepository(server: used);
    final again = await FlowApp.launch($, fakes: second);
    await again.waitForScreen(ScreenId.s02);
    await again.tapText(l.welcomeGetStarted);
    await again.tapText(l.disclaimerAcknowledge);
    await again.tapButton(l.aiConsentAccept);
    await again.waitForScreen(ScreenId.s05);
    await again.waitFor(find.text(l.balanceFreeUsed));

    expect(second.install.identity?.installId, identity.installId);
    expect(second.install.identity, identity, reason: 'no new registration');
    expect(
      second.redactor.redact(identity.installId.value),
      isNot(contains(identity.installId.value)),
    );
    expect(second.journal.readings, isEmpty);
    await again.tapText(l.tabJournal);
    await again.waitFor(find.text(l.journalEmptyTitle));
  });
}
