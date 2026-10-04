import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeInstallRepository install;
  late FakeBalanceRepository balance;
  late FakeRemoteConfigRepository config;
  late FakeConsentStore consent;
  late FakeConnectivityMonitor connectivity;
  late FakeClock clock;
  late ResolveReadingGate gate;

  final spread = aSpread().build();
  final aiGranted = ConsentState(
    ai: AiConsent(
      decision: AiConsentDecision.granted,
      version: 2,
      at: kTestNow,
    ),
  );
  final fresh = aCreditBalance().withFreeRemaining(0).withPaid(3).build();

  setUp(() {
    install = FakeInstallRepository();
    balance = FakeBalanceRepository(cached: fresh, server: fresh);
    config = FakeRemoteConfigRepository();
    consent = FakeConsentStore(aiGranted);
    connectivity = FakeConnectivityMonitor();
    clock = FakeClock();
    gate = ResolveReadingGate(
      install: install,
      balance: balance,
      config: config,
      consent: consent,
      connectivity: connectivity,
      clock: clock,
    );
  });

  test('a fresh balance is used as is', () async {
    expect(
      expectOk(await gate(spread)),
      const GateDecision.allowed(ChargeSource.paid),
    );
    expect(balance.syncReasons, isEmpty);
  });

  test('a missing balance is synced first (preReading)', () async {
    balance.seed(null);
    expect(
      expectOk(await gate(spread)),
      const GateDecision.allowed(ChargeSource.paid),
    );
    expect(balance.syncReasons, [SyncReason.preReading]);
  });

  test('a stale balance is synced first (resume path)', () async {
    clock.advance(const Duration(minutes: 6));
    balance.server = aCreditBalance()
        .withFreeRemaining(0)
        .withLedgerVersion(2)
        .syncedAt(clock.now())
        .build();
    final decision = expectOk(await gate(spread));
    expect(decision, isA<GateNeedsCredits>());
    expect(balance.syncReasons, [SyncReason.preReading]);
  });

  test('a network failure during the sync means offline', () async {
    balance
      ..seed(null)
      ..failNext(const Failure.network(), on: 'sync');
    expect(expectOk(await gate(spread)), const GateDecision.offline());
  });

  test('another sync failure falls back to the cache', () async {
    clock.advance(const Duration(minutes: 6));
    balance.failNext(const Failure.server(status: 500), on: 'sync');
    // The stale cache still needs a sync.
    expect(expectOk(await gate(spread)), const GateDecision.needsSync());
  });

  test('offline skips the sync', () async {
    connectivity.setOnline(online: false);
    balance.seed(null);
    expect(expectOk(await gate(spread)), const GateDecision.offline());
    expect(balance.syncReasons, isEmpty);
  });

  test('the gate order still applies (consent first)', () async {
    consent.seed(const ConsentState());
    expect(expectOk(await gate(spread)), const GateDecision.needsAiConsent());
  });

  test('an unregistered install registers first, then reads', () async {
    install.identity = anInstallIdentity(registered: false);
    expect(
      expectOk(await gate(spread)),
      const GateDecision.allowed(ChargeSource.paid),
    );
    expect(install.calls, ['getOrCreate', 'ensureRegistered']);
  });

  test('an unregistered install whose registration fails is unverified, '
      'and Begin tries again', () async {
    install
      ..identity = anInstallIdentity(registered: false)
      ..failNext(const Failure.network(), on: 'ensureRegistered');
    expect(expectOk(await gate(spread)), const GateDecision.deviceUnverified());
    expect(
      expectOk(await gate(spread)),
      const GateDecision.allowed(ChargeSource.paid),
    );
  });

  test('offline, an unregistered install stays unverified without a '
      'registration call', () async {
    connectivity.setOnline(online: false);
    install.identity = anInstallIdentity(registered: false);
    expect(expectOk(await gate(spread)), const GateDecision.deviceUnverified());
    expect(install.calls, ['getOrCreate']);
  });

  test('an unreadable identity is a failure (S01 storageError)', () async {
    install.failNext(const Failure.storage(), on: 'getOrCreate');
    expect(expectErr(await gate(spread)), const Failure.storage());
    expect(balance.calls, isEmpty);
  });
}
