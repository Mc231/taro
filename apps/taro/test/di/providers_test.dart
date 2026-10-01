import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/analytics_consent_tap.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/di/reminder_copy_l10n.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro/services/notifications/reminder_copy.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';
import '../services/analytics/recording_backend.dart';

void main() {
  group('port providers throw until overridden (02 §7)', () {
    final ports = <String, ProviderBase<Object?>>{
      'flavorConfigProvider': flavorConfigProvider,
      'appLocaleProvider': appLocaleProvider,
      'clockProvider': clockProvider,
      'randomSourceProvider': randomSourceProvider,
      'idGeneratorProvider': idGeneratorProvider,
      'loggerProvider': loggerProvider,
      'timezoneProvider': timezoneProvider,
      'appInfoProvider': appInfoProvider,
      'secureStoreProvider': secureStoreProvider,
      'sessionTokenStoreProvider': sessionTokenStoreProvider,
      'installRepositoryProvider': installRepositoryProvider,
      'balanceRepositoryProvider': balanceRepositoryProvider,
      'readingRepositoryProvider': readingRepositoryProvider,
      'journalRepositoryProvider': journalRepositoryProvider,
      'dailyCardRepositoryProvider': dailyCardRepositoryProvider,
      'contentRepositoryProvider': contentRepositoryProvider,
      'crisisResourcesRepositoryProvider': crisisResourcesRepositoryProvider,
      'remoteConfigRepositoryProvider': remoteConfigRepositoryProvider,
      'settingsRepositoryProvider': settingsRepositoryProvider,
      'consentStoreProvider': consentStoreProvider,
      'purchaseVerifierProvider': purchaseVerifierProvider,
      'purchaseOutboxProvider': purchaseOutboxProvider,
      'entitlementCacheProvider': entitlementCacheProvider,
      'rewardGatewayProvider': rewardGatewayProvider,
      'reportGatewayProvider': reportGatewayProvider,
      'dataDeletionGatewayProvider': dataDeletionGatewayProvider,
      'iapServiceProvider': iapServiceProvider,
      'storeOwnershipProvider': storeOwnershipProvider,
      'adsServiceProvider': adsServiceProvider,
      'bannerSlotViewProvider': bannerSlotViewProvider,
      'consentServiceProvider': consentServiceProvider,
      'trackingAuthorizationProvider': trackingAuthorizationProvider,
      'analyticsServiceProvider': analyticsServiceProvider,
      'crashReporterProvider': crashReporterProvider,
      'reminderSchedulerProvider': reminderSchedulerProvider,
      'attestationServiceProvider': attestationServiceProvider,
      'fileTransferProvider': fileTransferProvider,
      'connectivityMonitorProvider': connectivityMonitorProvider,
      'reviewPrompterProvider': reviewPrompterProvider,
      'backupExclusionProvider': backupExclusionProvider,
      'urlLauncherProvider': urlLauncherProvider,
      'consentOrchestratorProvider': consentOrchestratorProvider,
    };
    for (final MapEntry(key: name, value: provider) in ports.entries) {
      test(name, () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        expect(
          () => container.read(provider),
          throwsA(
            predicate(
              (e) => e.toString().contains('$name is not overridden'),
            ),
          ),
        );
      });
    }
  });

  test('defaults: a fresh redactor and a no-op warm-up', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(redactorProvider), isA<Redactor>());
    await container.read(attestationWarmUpProvider)();
  });

  test('use cases and orchestration build from the fakes', () {
    final container = TaroFakes().container();
    for (final provider in <ProviderBase<Object?>>[
      pendingPurchaseTrackerProvider,
      removeAdsEntitlementProvider,
      purchaseCoordinatorProvider,
      resumeReadingProvider,
      deleteAllDataProvider,
      syncAccountProvider,
      resolveReadingGateProvider,
      drawCardsProvider,
      requestReadingProvider,
      startClassicReadingProvider,
      earnRewardProvider,
      reportReadingProvider,
      exportBackupProvider,
      importBackupProvider,
    ]) {
      expect(container.read(provider), isNotNull);
    }
    final tracker = container.read(pendingPurchaseTrackerProvider)
      ..markPending(TaroProducts.all.first.id);
    expect(tracker.isPending(TaroProducts.all.first.id), isTrue);
  });

  group('reminderCopyFor (01 §7.7)', () {
    test('6 localized variants and the channel texts', () {
      final uk = reminderCopyFor('uk');
      expect(uk.variants, hasLength(kReminderVariantCount));
      expect(uk.channelName, 'Щоденне нагадування');
      expect(uk.variants.first.title, 'Taro');
      expect(uk.variants.map((v) => v.body).toSet(), hasLength(6));
    });

    test('an unknown locale falls back to English', () {
      expect(reminderCopyFor('xx').channelName, 'Daily reminder');
    });
  });

  test(
    'AnalyticsConsentTap forwards and resolves with the last mode',
    () async {
      final inner = RecordingBackend();
      final tap = AnalyticsConsentTap(inner);
      final granted = AnalyticsConsent.allGranted();
      await tap.setConsent(granted);
      await tap.log(const ReminderOpenedEvent());
      await tap.screen('S05');
      await tap.setCollectionEnabled(enabled: true);
      await tap.setUserProperties(const AnalyticsUserProperties());
      tap
        ..resolve()
        ..resolve();
      expect(await tap.resolved, granted);
      expect(inner.calls, hasLength(5));
    },
  );
}
