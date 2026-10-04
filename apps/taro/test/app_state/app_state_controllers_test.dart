import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/app_state/settings_controller.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

void main() {
  late TaroFakes fakes;
  late ProviderContainer container;

  setUp(() {
    fakes = TaroFakes();
    container = fakes.container();
  });

  group('balanceProvider', () {
    test('starts from the cache and follows the repository', () async {
      final cached = fakes.balance.cached;
      expect(container.read(balanceProvider), cached);
      final newer = aCreditBalance().withLedgerVersion(9).withBonus(3).build();
      fakes.balance.seed(newer);
      await pumpEventQueue();
      expect(container.read(balanceProvider), newer);
    });

    test('refresh runs a manual sync pass', () async {
      final status = await container.read(balanceProvider.notifier).refresh();
      expect(status, isA<SyncStatusSynced>());
      expect(fakes.balance.syncReasons, [SyncReason.manual]);
    });
  });

  group('balanceStaleProvider', () {
    test('no balance is stale', () {
      fakes.balance.seed(null);
      expect(fakes.container().read(balanceStaleProvider), isTrue);
    });

    test('a fresh synced balance is not stale', () async {
      await container.read(syncCoordinatorProvider).run(SyncReason.launch);
      container.read(syncStatusProvider);
      await pumpEventQueue();
      expect(container.read(balanceStaleProvider), isFalse);
    });

    test('an older balance than balance.staleAfterSec is stale', () async {
      await container.read(syncCoordinatorProvider).run(SyncReason.launch);
      container.read(syncStatusProvider);
      await pumpEventQueue();
      fakes.clock.advance(const Duration(minutes: 6));
      container.invalidate(balanceStaleProvider);
      expect(container.read(balanceStaleProvider), isTrue);
    });

    test('a failed last sync is stale', () async {
      container.read(syncStatusProvider);
      await pumpEventQueue();
      expect(container.read(balanceStaleProvider), isTrue);
    });
  });

  group('entitlementProvider', () {
    test('starts from the cache and follows store answers', () async {
      fakes.entitlements.entitlement = Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
        verifiedAt: kTestNow,
      );
      final c = fakes.container();
      expect(c.read(entitlementProvider).removesAds, isTrue);
      await c.read(removeAdsEntitlementProvider).refresh();
      await pumpEventQueue();
      expect(c.read(entitlementProvider).removesAds, isFalse);
    });
  });

  group('consentProvider', () {
    test('grants and declines AI consent at ai.consentVersion', () async {
      fakes.config.current = RemoteConfig.defaults.copyWith(
        aiConsentVersion: 2,
      );
      final controller = container.read(consentProvider.notifier);
      expect(container.read(aiConsentValidProvider), isFalse);

      await controller.grantAi();
      await pumpEventQueue();
      final granted = container.read(consentProvider).ai;
      expect(granted.decision, AiConsentDecision.granted);
      expect(granted.version, 2);
      expect(granted.at, kTestNow);
      expect(container.read(aiConsentValidProvider), isTrue);

      fakes.config.current = RemoteConfig.defaults.copyWith(
        aiConsentVersion: 3,
      );
      await pumpEventQueue();
      expect(container.read(aiConsentValidProvider), isFalse);

      await controller.declineAi();
      await pumpEventQueue();
      expect(
        container.read(consentProvider).ai.decision,
        AiConsentDecision.declined,
      );
    });

    test('persists the onboarding step', () async {
      await container
          .read(consentProvider.notifier)
          .setOnboardingStep(OnboardingStep.disclaimer);
      await pumpEventQueue();
      expect(
        container.read(consentProvider).onboardingStep,
        OnboardingStep.disclaimer,
      );
    });

    test('the analytics toggle applies to analytics and crash', () async {
      await container
          .read(consentProvider.notifier)
          .setAnalyticsEnabled(enabled: false);
      expect(fakes.consentStore.current.analyticsEnabled, isFalse);
      expect(fakes.analytics.collectionEnabled, isFalse);
      expect(fakes.crash.calls, contains('setCollectionEnabled'));
    });

    test(
      'runs UMP / ATT and the privacy options through the orchestrator',
      () async {
        final controller = container.read(consentProvider.notifier);
        final outcome = await controller.runAdsConsent();
        expect(outcome, isNotNull);
        expect(fakes.consentService.calls, contains('gather'));
        await controller.showPrivacyOptions();
        expect(fakes.consentService.calls, contains('showPrivacyOptions'));
      },
    );
  });

  group('remoteConfigProvider', () {
    test('follows refreshes', () async {
      expect(container.read(remoteConfigProvider), RemoteConfig.defaults);
      final next = RemoteConfig.defaults.copyWith(readingsEnabled: false);
      fakes.config.current = next;
      await pumpEventQueue();
      expect(container.read(remoteConfigProvider), next);
    });

    test('update required / available compare the installed version', () async {
      expect(container.read(updateRequiredProvider), isFalse);
      expect(container.read(updateAvailableProvider), isFalse);
      fakes.config.current = RemoteConfig.defaults.copyWith(
        appMinVersionIos: '1.0.1',
        appRecommendedVersionIos: '1.2.0',
      );
      await pumpEventQueue();
      expect(container.read(updateRequiredProvider), isTrue);
      expect(container.read(updateAvailableProvider), isTrue);
    });

    test('android reads the android keys', () {
      fakes
        ..appInfo = const FakeAppInfo(
          version: '2.0.0',
          platform: AppPlatform.android,
        )
        ..config.current = RemoteConfig.defaults.copyWith(
          appMinVersionAndroid: '2.0.0',
          appRecommendedVersionAndroid: '2.1',
          appMinVersionIos: '9.0.0',
        );
      final c = fakes.container();
      expect(c.read(updateRequiredProvider), isFalse);
      expect(c.read(updateAvailableProvider), isTrue);
    });

    test(
      'built-in defaults never require an update (regression: 0.1.0 beta)',
      () {
        for (final platform in AppPlatform.values) {
          for (final version in ['0.0.1', '0.1.0', '0.1.0+1', '1.0.0']) {
            fakes
              ..appInfo = FakeAppInfo(version: version, platform: platform)
              ..config.current = RemoteConfig.defaults;
            final c = fakes.container();
            addTearDown(c.dispose);
            expect(
              c.read(updateRequiredProvider),
              isFalse,
              reason: '$platform $version',
            );
            expect(
              c.read(updateAvailableProvider),
              isFalse,
              reason: '$platform $version',
            );
          }
        }
      },
    );

    test('compareVersions', () {
      expect(compareVersions('1.2.3', '1.2.3'), 0);
      expect(compareVersions('1.2.3+45', '1.2.3'), 0);
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.2', '1.2.1'), lessThan(0));
      expect(compareVersions('x.2', '0.2'), 0);
    });
  });

  group('connectivityProvider', () {
    test('is optimistic, then follows the monitor', () async {
      fakes.connectivity.setOnline(online: false);
      final c = fakes.container();
      expect(c.read(connectivityProvider), isTrue);
      await pumpEventQueue();
      expect(c.read(connectivityProvider), isFalse);
      fakes.connectivity.setOnline(online: true);
      await pumpEventQueue();
      expect(c.read(connectivityProvider), isTrue);
    });

    test('a late first answer after dispose is ignored', () async {
      ProviderContainer(overrides: fakes.toOverrides())
        ..read(connectivityProvider)
        ..dispose();
      await pumpEventQueue();
    });
  });

  group('settingsProvider', () {
    test('starts from the store and persists updates', () async {
      expect(container.read(settingsProvider), const UserSettings());
      await container
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(localeOverride: 'uk'));
      await pumpEventQueue();
      expect(container.read(settingsProvider).localeOverride, 'uk');
    });
  });
}
