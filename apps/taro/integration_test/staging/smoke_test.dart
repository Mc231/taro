import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// `TARO_STAGING_SMOKE=1`: the manual-dispatch switch of this smoke.
const bool _enabled = bool.fromEnvironment('TARO_STAGING_SMOKE');

/// Staging smoke (06 §4, Phase 13 Sprint 13.6): the real composition root
/// of the `staging` flavor against the staging Worker. It registers the
/// install (the debug attestation bypass: `TARO_DEBUG_ATTESTATION_TOKEN`,
/// RC86), syncs the balance, and takes one free reading end to end (hold →
/// CSPRNG draw → `POST /v1/readings` → ack).
///
/// Manual dispatch only; it spends the install's free reading of the day.
/// Run on a simulator with a fresh install:
///
/// ```sh
/// cd apps/taro && flutter test integration_test/staging/smoke_test.dart \
///   --flavor staging --dart-define-from-file=config/staging.json \
///   --dart-define=TARO_STAGING_SMOKE=1 \
///   --dart-define=TARO_DEBUG_ATTESTATION_TOKEN="$TOKEN"
/// ```
///
/// Without both defines every test is skipped, so a plain
/// `flutter test integration_test` never calls staging.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Manual dispatch: TARO_STAGING_SMOKE=1 and the debug token are needed.
  final skip = !_enabled || BuildDefines.debugAttestationToken.isEmpty;

  testWidgets('staging: register, balance, one free reading', skip: skip, (
    tester,
  ) async {
    final env = ProductionEnvironment(Flavor.staging);
    expect(env.flavor.flavor, Flavor.staging);
    final container = (await bootstrap(env))!;
    addTearDown(container.dispose);
    await tester.pump();

    // Register (debug attestation bypass on a simulator).
    final install = await container
        .read(installRepositoryProvider)
        .ensureRegistered();
    expect(install, isA<Ok<InstallIdentity>>(), reason: '$install');
    expect(install.valueOrNull!.isRegistered, isTrue);

    // Balance.
    final synced = await container
        .read(balanceRepositoryProvider)
        .sync(reason: SyncReason.manual);
    expect(synced, isA<Ok<CreditBalance>>(), reason: '$synced');
    final balance = synced.valueOrNull!;
    expect(
      balance.canRead,
      isTrue,
      reason: 'a fresh staging install has its free reading ($balance)',
    );

    // AI consent for the current disclosure version (onboarding is not
    // run: the UMP / ATT dialogs would need native automation).
    final config = container.read(remoteConfigRepositoryProvider).current;
    final clock = container.read(clockProvider);
    await container
        .read(consentStoreProvider)
        .update(
          (s) => s.copyWith(
            ai: AiConsent(
              decision: AiConsentDecision.granted,
              version: config.aiConsentVersion,
              at: clock.now(),
            ),
          ),
        );

    // One free reading: hold → draw → submit (acknowledged on delivery).
    final spreads = (await container.read(contentRepositoryProvider).spreads())
        .valueOrNull!;
    final spread = spreads.firstWhere((s) => s.id.value == 'three_ppf');
    final readings = container.read(requestReadingProvider);
    final hold = await readings.hold(spread, locale: 'en');
    expect(hold, isA<Ok<ReadingHold>>(), reason: '$hold');
    final draw = await container
        .read(drawCardsProvider)
        .call(spread, hold: hold.valueOrNull!);
    expect(draw, isA<Ok<Draw>>(), reason: '$draw');
    final reading = await readings.submit(
      hold: hold.valueOrNull!,
      draw: draw.valueOrNull!,
      locale: 'en',
      question: 'What should I focus on this week?',
    );
    expect(reading, isA<Ok<Reading>>(), reason: '$reading');
    final delivered = reading.valueOrNull!;
    expect(delivered.status, isA<ReadingStatusComplete>());
    final stored =
        (await container.read(readingRepositoryProvider).get(delivered.id))
            .valueOrNull;
    expect(stored?.deliveryAcked, isTrue, reason: 'acknowledged (RC51)');

    final after = container.read(balanceRepositoryProvider).cached!;
    expect(after.free.remaining, lessThan(balance.free.remaining));
  });
}
