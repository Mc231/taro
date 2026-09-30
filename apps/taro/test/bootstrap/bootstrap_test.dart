import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/storage_error_app.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_environment.dart';

const _secret = 'c2VjcmV0LXNlY3JldC1zZWNyZXQ';

/// The screen with the S-ID [wire] (`buildScreen` keys every screen).
Finder _screen(String wire) => find.byKey(
  ValueKey(ScreenId.values.firstWhere((s) => s.wire == wire)),
);

void main() {
  late FakeTaroEnvironment env;

  setUp(() {
    env = FakeTaroEnvironment();
    env.fakes.secureStore.values[SecureKeys.installSecret] = _secret;
    env.fakes.sessionTokens.token = SessionToken(
      token: 'jwt-token-value',
      expiresAt: kTestNow.add(const Duration(days: 7)),
    );
  });

  Future<ProviderContainer> boot(WidgetTester tester) async {
    final container = await bootstrap(env);
    expect(container, isNotNull);
    await tester.pumpWidget(env.app);
    await tester.pumpAndSettle();
    return container!;
  }

  /// Unmounts the app and lets the bounded timers (ownership query) lapse.
  Future<void> shutdown(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(minutes: 1));
  }

  testWidgets('happy path: consent denied first, Home, then the launch sync', (
    tester,
  ) async {
    final container = await boot(tester);
    final fakes = env.fakes;

    expect(env.firebaseInitialized, isTrue);
    expect(env.app, isA<UncontrolledProviderScope>());
    expect(fakes.analytics.consents.first, AnalyticsConsent.allDenied());
    expect(env.errorHandlersFor, same(fakes.crash));
    expect(fakes.install.calls.first, 'getOrCreate');

    final redacted = fakes.redactor.redact(
      'id ${kTestInstallId.value} secret $_secret token jwt-token-value',
    );
    expect(redacted, isNot(contains(kTestInstallId.value)));
    expect(redacted, isNot(contains(_secret)));
    expect(redacted, isNot(contains('jwt-token-value')));

    expect(_screen('S05'), findsOneWidget);
    expect(fakes.balance.syncReasons, [SyncReason.launch]);
    expect(container.read(syncCoordinatorProvider).runs, 1);
    expect(fakes.consentService.calls, contains('gather'));
    expect(fakes.warmUps, 1);
    expect(container.read(purchaseCoordinatorProvider), isNotNull);
    await shutdown(tester, container);
  });

  testWidgets('the neutral ATT pre-prompt comes before the system prompt', (
    tester,
  ) async {
    final container = await boot(tester);
    final fakes = env.fakes;
    final l10n = lookupTaroLocalizations(const Locale('en'));
    expect(find.text(l10n.attPrepromptTitle), findsOneWidget);
    expect(fakes.tracking.prompts, 0);
    await tester.tap(find.text(l10n.attPrepromptContinue));
    await tester.pumpAndSettle();
    expect(find.text(l10n.attPrepromptTitle), findsNothing);
    expect(fakes.tracking.prompts, 1);
    expect(_screen('S05'), findsOneWidget);
    await shutdown(tester, container);
  });

  testWidgets('offline first frame: the cached balance, sync unavailable', (
    tester,
  ) async {
    final fakes = env.fakes;
    final cached = fakes.balance.cached;
    fakes.balance.failNext(const Failure.network(), on: 'sync');
    fakes.connectivity.setOnline(online: false);
    final container = (await bootstrap(env))!;
    expect(container.read(balanceProvider), cached);
    await tester.pumpWidget(env.app);
    expect(_screen('S05'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(container.read(syncStatusProvider), isA<SyncStatusStale>());
    expect(container.read(balanceProvider), cached);
    await shutdown(tester, container);
  });

  testWidgets('first launch starts onboarding', (tester) async {
    await env.fakes.consentStore.update(
      (s) => s.copyWith(onboardingStep: OnboardingStep.welcome),
    );
    final container = await boot(tester);
    expect(_screen('S02'), findsOneWidget);
    expect(env.fakes.consentService.calls, isNot(contains('gather')));
    await shutdown(tester, container);
  });

  testWidgets('a storage failure shows S01 storageError; retry recovers', (
    tester,
  ) async {
    env.failDatabases = true;
    expect(await bootstrap(env), isNull);
    await tester.pumpWidget(env.app);
    expect(find.byType(StorageErrorApp), findsOneWidget);
    expect(find.text('Taro can’t open its storage'), findsOneWidget);
    expect(find.text(env.flavor.supportEmail), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(env.app, isA<UncontrolledProviderScope>());
    final scope = env.app as UncontrolledProviderScope;
    await tester.pumpWidget(env.app);
    await tester.pumpAndSettle();
    expect(_screen('S05'), findsOneWidget);
    await shutdown(tester, scope.container);
  });

  testWidgets('an unreadable install ID is storageError, reported', (
    tester,
  ) async {
    env.fakes.install.failNext(const Failure.storage(), on: 'getOrCreate');
    expect(await bootstrap(env), isNull);
    expect(env.app, isA<StorageErrorApp>());
    expect(env.fakes.crash.errors, hasLength(1));
  });

  testWidgets('without stored secrets only the install ID is registered', (
    tester,
  ) async {
    env.fakes.secureStore.values.clear();
    env.fakes.sessionTokens.token = null;
    final container = await boot(tester);
    expect(container.read(redactorProvider), same(env.fakes.redactor));
    await shutdown(tester, container);
  });

  group('prod assertions (02 §15)', () {
    setUp(() => env.fakes.flavor = testFlavorConfig(Flavor.prod));

    test('a SeededRandomSource is unreachable in prod', () {
      expect(() => bootstrap(env), throwsStateError);
    });

    test('the DebugAttestationService is unreachable in prod', () {
      env.fakes.random = SecureRandomSource();
      env.fakes.attestationPort = DebugAttestationService.forBuild(
        isProd: false,
        token: 'debug',
      );
      expect(() => bootstrap(env), throwsStateError);
    });

    testWidgets('a prod graph with the CSPRNG boots', (tester) async {
      env.fakes.random = SecureRandomSource();
      final container = await boot(tester);
      expect(_screen('S05'), findsOneWidget);
      await shutdown(tester, container);
    });
  });

  test('noProviderRetry never retries', () {
    expect(noProviderRetry(0, StateError('x')), isNull);
  });
}
