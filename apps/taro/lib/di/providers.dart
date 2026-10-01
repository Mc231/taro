import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/services/consent/consent_orchestrator.dart';
import 'package:taro/services/iap/pending_purchase_tracker.dart';
import 'package:taro/services/iap/purchase_coordinator.dart';
import 'package:taro/services/iap/remove_ads_entitlement.dart';
import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart';

// The bundled-article loader of S19 and S28 (features read it here).
export 'package:taro/di/article_source.dart'
    show
        Article,
        ArticleEntry,
        ArticleId,
        ArticleLoader,
        ArticleSection,
        articleLoaderProvider;
// The Support ID and contact details of S20 / S28 (RC43).
export 'package:taro/di/support_info.dart'
    show SupportInfo, loadSupportInfo, supportIdOf;
// The service-layer result types that app_state/ and features/ read through
// this file (they never import services/, 02 §2.1).
export 'package:taro/services/consent/consent_orchestrator.dart'
    show ConsentOutcome;
export 'package:taro/services/iap/purchase_coordinator.dart'
    show PurchaseUpdate;

/// The provider graph (02 §7, AR3): one provider per `taro_core` port, each
/// throwing [UnimplementedError] until `bootstrap()` (or a test) overrides
/// it, plus the orchestrators and use cases derived from them.
///
/// Overrides: `di/overrides_prod.dart` / `di/overrides_dev.dart` (through
/// `di/app_graph.dart`); in tests `TaroFakes.toOverrides()`
/// (`test/helpers/pump_app.dart`).
Never _missing(String name) =>
    throw UnimplementedError('$name is not overridden (bootstrap or test)');

// Configuration ---------------------------------------------------------------

/// The active [FlavorConfig]; overridden in `bootstrap()`.
final flavorConfigProvider = Provider<FlavorConfig>(
  (ref) => _missing('flavorConfigProvider'),
);

/// The app locale code (`en`, `uk`, …) read per call: the Settings
/// override, else the device locale when supported, else `en` (02 §11).
final appLocaleProvider = Provider<String Function()>(
  (ref) => _missing('appLocaleProvider'),
);

// Determinism ports (rule 5) --------------------------------------------------

/// The [Clock] port.
final clockProvider = Provider<Clock>((ref) => _missing('clockProvider'));

/// The [RandomSource] port (CSPRNG in production).
final randomSourceProvider = Provider<RandomSource>(
  (ref) => _missing('randomSourceProvider'),
);

/// The [IdGenerator] port.
final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => _missing('idGeneratorProvider'),
);

/// The root [Logger] port.
final loggerProvider = Provider<Logger>((ref) => _missing('loggerProvider'));

/// The log [Redactor] shared by the logger and the crash reporter; the
/// install ID and secrets are registered on it at bootstrap.
final redactorProvider = Provider<Redactor>((ref) => Redactor());

/// The [TimezoneProvider] port.
final timezoneProvider = Provider<TimezoneProvider>(
  (ref) => _missing('timezoneProvider'),
);

/// The [AppInfo] port.
final appInfoProvider = Provider<AppInfo>((ref) => _missing('appInfoProvider'));

// Storage and Worker ports ----------------------------------------------------

/// The [SecureStore] port.
final secureStoreProvider = Provider<SecureStore>(
  (ref) => _missing('secureStoreProvider'),
);

/// The [SessionTokenStore] port.
final sessionTokenStoreProvider = Provider<SessionTokenStore>(
  (ref) => _missing('sessionTokenStoreProvider'),
);

/// The [InstallRepository] port.
final installRepositoryProvider = Provider<InstallRepository>(
  (ref) => _missing('installRepositoryProvider'),
);

/// The [BalanceRepository] port.
final balanceRepositoryProvider = Provider<BalanceRepository>(
  (ref) => _missing('balanceRepositoryProvider'),
);

/// The [ReadingRepository] port.
final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => _missing('readingRepositoryProvider'),
);

/// The [JournalRepository] port.
final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => _missing('journalRepositoryProvider'),
);

/// The [DailyCardRepository] port.
final dailyCardRepositoryProvider = Provider<DailyCardRepository>(
  (ref) => _missing('dailyCardRepositoryProvider'),
);

/// The [ContentRepository] port (bundled deck content, RC26).
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => _missing('contentRepositoryProvider'),
);

/// The [CrisisResourcesRepository] port (RC25, RC81).
final crisisResourcesRepositoryProvider = Provider<CrisisResourcesRepository>(
  (ref) => _missing('crisisResourcesRepositoryProvider'),
);

/// The [RemoteConfigRepository] port.
final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>(
  (ref) => _missing('remoteConfigRepositoryProvider'),
);

/// The [SettingsRepository] port.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => _missing('settingsRepositoryProvider'),
);

/// The [ConsentStore] port.
final consentStoreProvider = Provider<ConsentStore>(
  (ref) => _missing('consentStoreProvider'),
);

/// The [PurchaseVerifier] port.
final purchaseVerifierProvider = Provider<PurchaseVerifier>(
  (ref) => _missing('purchaseVerifierProvider'),
);

/// The [PurchaseOutbox] port.
final purchaseOutboxProvider = Provider<PurchaseOutbox>(
  (ref) => _missing('purchaseOutboxProvider'),
);

/// The [EntitlementCache] port.
final entitlementCacheProvider = Provider<EntitlementCache>(
  (ref) => _missing('entitlementCacheProvider'),
);

/// The [RewardGateway] port.
final rewardGatewayProvider = Provider<RewardGateway>(
  (ref) => _missing('rewardGatewayProvider'),
);

/// The [ReportGateway] port.
final reportGatewayProvider = Provider<ReportGateway>(
  (ref) => _missing('reportGatewayProvider'),
);

/// The [DataDeletionGateway] port.
final dataDeletionGatewayProvider = Provider<DataDeletionGateway>(
  (ref) => _missing('dataDeletionGatewayProvider'),
);

// Platform service ports ------------------------------------------------------

/// The [IapService] port.
final iapServiceProvider = Provider<IapService>(
  (ref) => _missing('iapServiceProvider'),
);

/// The silent store ownership query behind [RemoveAdsEntitlement].
final storeOwnershipProvider = Provider<StoreOwnership>(
  (ref) => _missing('storeOwnershipProvider'),
);

/// The [AdsService] port.
final adsServiceProvider = Provider<AdsService>(
  (ref) => _missing('adsServiceProvider'),
);

/// The [BannerSlotView] presentation port (`common/` `BannerSlot` reads it;
/// only `bootstrap/` and `di/` import `services/presentation/`).
final bannerSlotViewProvider = Provider<BannerSlotView>(
  (ref) => _missing('bannerSlotViewProvider'),
);

/// The UMP [ConsentService] port.
final consentServiceProvider = Provider<ConsentService>(
  (ref) => _missing('consentServiceProvider'),
);

/// The ATT [TrackingAuthorization] port.
final trackingAuthorizationProvider = Provider<TrackingAuthorization>(
  (ref) => _missing('trackingAuthorizationProvider'),
);

/// The [AnalyticsService] port: `ConsentAwareAnalytics` in front of the
/// backends (RC68).
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => _missing('analyticsServiceProvider'),
);

/// The [CrashReporter] port.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => _missing('crashReporterProvider'),
);

/// The [ReminderScheduler] port.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => _missing('reminderSchedulerProvider'),
);

/// The [AttestationService] port.
final attestationServiceProvider = Provider<AttestationService>(
  (ref) => _missing('attestationServiceProvider'),
);

/// The Android attestation warm-up of the sync pass (02 §9.1 step 6);
/// a no-op where there is nothing to prepare.
final attestationWarmUpProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// The [FileTransfer] port.
final fileTransferProvider = Provider<FileTransfer>(
  (ref) => _missing('fileTransferProvider'),
);

/// Plain-text share through the system share sheet (PR19, S09 Share).
/// Until a text-share adapter overrides it, the text goes through
/// [FileTransfer] as `taro-reading.txt`.
final shareTextProvider = Provider<Future<Result<void>> Function(String text)>(
  (ref) {
    final files = ref.watch(fileTransferProvider);
    return (text) => files.share(
      Uint8List.fromList(utf8.encode(text)),
      'taro-reading.txt',
      'text/plain',
    );
  },
);

/// The [ConnectivityMonitor] port.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>(
  (ref) => _missing('connectivityMonitorProvider'),
);

/// The [ReviewPrompter] port.
final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => _missing('reviewPrompterProvider'),
);

/// The [UrlLauncher] port (tel:, sms: and https: links outside the app).
final urlLauncherProvider = Provider<UrlLauncher>(
  (ref) => _missing('urlLauncherProvider'),
);

/// The [BackupExclusion] port (RC75).
final backupExclusionProvider = Provider<BackupExclusion>(
  (ref) => _missing('backupExclusionProvider'),
);

// Orchestration (02 §9.5–§9.7) ------------------------------------------------

/// The UMP → ATT → Mobile Ads sequence (RC19); built with the analytics
/// graph, so it is overridden together with [analyticsServiceProvider].
final consentOrchestratorProvider = Provider<ConsentOrchestrator>(
  (ref) => _missing('consentOrchestratorProvider'),
);

/// Store-pending purchases (Ask to Buy, `202 pending`).
final pendingPurchaseTrackerProvider = Provider<PendingPurchaseTracker>((ref) {
  final config = ref.watch(remoteConfigRepositoryProvider);
  return PendingPurchaseTracker(
    clock: ref.watch(clockProvider),
    holdMinutes: () => config.current.storePendingHoldMinutes,
  );
});

/// The Remove Banner Ads entitlement (MO7): cache first, store answer later.
final removeAdsEntitlementProvider = Provider<RemoveAdsEntitlement>((ref) {
  final entitlement = RemoveAdsEntitlement(
    cache: ref.watch(entitlementCacheProvider),
    ownership: ref.watch(storeOwnershipProvider),
    clock: ref.watch(clockProvider),
    analytics: ref.watch(analyticsServiceProvider),
    logger: ref.watch(loggerProvider).child('entitlement'),
  );
  ref.onDispose(entitlement.dispose);
  return entitlement;
});

/// The single purchase path (04 §6.2, rule 8): `StoreController` buys and
/// restores through it, and `SyncAccount` drains its outbox. Read at
/// bootstrap so it listens to store deliveries before any UI.
final purchaseCoordinatorProvider = Provider<PurchaseCoordinator>((ref) {
  final coordinator = PurchaseCoordinator(
    iap: ref.watch(iapServiceProvider),
    verifier: ref.watch(purchaseVerifierProvider),
    outbox: ref.watch(purchaseOutboxProvider),
    balance: ref.watch(balanceRepositoryProvider),
    install: ref.watch(installRepositoryProvider),
    config: ref.watch(remoteConfigRepositoryProvider),
    removeAds: ref.watch(removeAdsEntitlementProvider),
    tracker: ref.watch(pendingPurchaseTrackerProvider),
    analytics: ref.watch(analyticsServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider).child('iap'),
    connectivity: ref.watch(connectivityMonitorProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

// Use cases (02 §9) -----------------------------------------------------------

/// [ResumeReading].
final resumeReadingProvider = Provider<ResumeReading>(
  (ref) => ResumeReading(
    readings: ref.watch(readingRepositoryProvider),
    logger: ref.watch(loggerProvider).child('readings'),
  ),
);

/// [DeleteAllData] (S26, RC37).
final deleteAllDataProvider = Provider<DeleteAllData>(
  (ref) => DeleteAllData(
    journal: ref.watch(journalRepositoryProvider),
    deletion: ref.watch(dataDeletionGatewayProvider),
    reminders: ref.watch(reminderSchedulerProvider),
    ids: ref.watch(idGeneratorProvider),
    logger: ref.watch(loggerProvider).child('deletion'),
  ),
);

/// [SyncAccount]: one launch / resume pass (run by `SyncCoordinator`).
final syncAccountProvider = Provider<SyncAccount>(
  (ref) => SyncAccount(
    install: ref.watch(installRepositoryProvider),
    tokens: ref.watch(sessionTokenStoreProvider),
    config: ref.watch(remoteConfigRepositoryProvider),
    timezone: ref.watch(timezoneProvider),
    balance: ref.watch(balanceRepositoryProvider),
    purchases: ref.watch(purchaseCoordinatorProvider),
    resume: ref.watch(resumeReadingProvider),
    readings: ref.watch(readingRepositoryProvider),
    deletion: ref.watch(deleteAllDataProvider),
    reminders: ref.watch(reminderSchedulerProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider).child('sync'),
  ),
);

/// [ResolveReadingGate] (RC44).
final resolveReadingGateProvider = Provider<ResolveReadingGate>(
  (ref) => ResolveReadingGate(
    install: ref.watch(installRepositoryProvider),
    balance: ref.watch(balanceRepositoryProvider),
    config: ref.watch(remoteConfigRepositoryProvider),
    consent: ref.watch(consentStoreProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// [DrawCards] (CSPRNG draw, RC50).
final drawCardsProvider = Provider<DrawCards>(
  (ref) => DrawCards(
    content: ref.watch(contentRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    random: ref.watch(randomSourceProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// [RequestReading].
final requestReadingProvider = Provider<RequestReading>(
  (ref) => RequestReading(
    readings: ref.watch(readingRepositoryProvider),
    balance: ref.watch(balanceRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider).child('readings'),
  ),
);

/// [StartClassicReading] (F8, RC20).
final startClassicReadingProvider = Provider<StartClassicReading>(
  (ref) => StartClassicReading(
    draws: ref.watch(drawCardsProvider),
    readings: ref.watch(readingRepositoryProvider),
    ids: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// [EarnReward] (04 §9.2).
final earnRewardProvider = Provider<EarnReward>(
  (ref) => EarnReward(
    gateway: ref.watch(rewardGatewayProvider),
    ads: ref.watch(adsServiceProvider),
    balance: ref.watch(balanceRepositoryProvider),
    config: ref.watch(remoteConfigRepositoryProvider),
    consent: ref.watch(consentStoreProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider).child('rewarded'),
  ),
);

/// [ReportReading] (S33, RC72).
final reportReadingProvider = Provider<ReportReading>(
  (ref) => ReportReading(
    readings: ref.watch(readingRepositoryProvider),
    gateway: ref.watch(reportGatewayProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// [ExportBackup] (S24).
final exportBackupProvider = Provider<ExportBackup>(
  (ref) => ExportBackup(
    journal: ref.watch(journalRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    appInfo: ref.watch(appInfoProvider),
    files: ref.watch(fileTransferProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// [ImportBackup] (S25).
final importBackupProvider = Provider<ImportBackup>(
  (ref) => ImportBackup(
    files: ref.watch(fileTransferProvider),
    content: ref.watch(contentRepositoryProvider),
    journal: ref.watch(journalRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);
