import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/bootstrap/app_locale.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/data/api/interceptors/attestation_interceptor.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/install/install_repository_impl.dart';
import 'package:taro/data/repositories/balance_repository_impl.dart';
import 'package:taro/data/repositories/consent_store_impl.dart';
import 'package:taro/data/repositories/daily_card_repository_impl.dart';
import 'package:taro/data/repositories/data_deletion_gateway_impl.dart';
import 'package:taro/data/repositories/entitlement_cache_impl.dart';
import 'package:taro/data/repositories/journal_repository_impl.dart';
import 'package:taro/data/repositories/purchase_outbox_impl.dart';
import 'package:taro/data/repositories/purchase_verifier_impl.dart';
import 'package:taro/data/repositories/reading_repository_impl.dart';
import 'package:taro/data/repositories/remote_config_repository_impl.dart';
import 'package:taro/data/repositories/report_gateway_impl.dart';
import 'package:taro/data/repositories/reward_gateway_impl.dart';
import 'package:taro/data/repositories/settings_repository_impl.dart';
import 'package:taro/data/secure/secure_session_token_store.dart';
import 'package:taro/di/analytics_consent_tap.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/di/reminder_copy_l10n.dart';
import 'package:taro/services/ads/admob_ads_service.dart';
import 'package:taro/services/ads/no_op_ads_service.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/analytics/composite_analytics_service.dart';
import 'package:taro/services/analytics/consent_aware_analytics.dart';
import 'package:taro/services/analytics/console_analytics_service.dart';
import 'package:taro/services/analytics/firebase_analytics_service.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro/services/attestation/platform_attestation_service.dart';
import 'package:taro/services/backup/platform_backup_exclusion.dart';
import 'package:taro/services/connectivity/connectivity_plus_monitor.dart';
import 'package:taro/services/consent/att_tracking_authorization.dart';
import 'package:taro/services/consent/consent_orchestrator.dart';
import 'package:taro/services/consent/ump_consent_service.dart';
import 'package:taro/services/crash/firebase_crash_reporter.dart';
import 'package:taro/services/crash/noop_crash_reporter.dart';
import 'package:taro/services/files/platform_file_transfer.dart';
import 'package:taro/services/iap/no_op_iap_service.dart';
import 'package:taro/services/iap/store_iap_service.dart';
import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro/services/ids/secure_id_generator.dart';
import 'package:taro/services/links/platform_url_launcher.dart';
import 'package:taro/services/logging/logging_logger.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro/services/notifications/local_reminder_scheduler.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro/services/review/in_app_review_prompter.dart';
import 'package:taro/services/review/review_prompt_ledger.dart';
import 'package:taro/services/timezone/flutter_timezone_provider.dart';
import 'package:taro_core/taro_core.dart';

/// The two database files (RC75).
typedef TaroDatabases = ({JournalDatabase journal, DeviceDatabase device});

/// A store adapter that is also the silent ownership query.
typedef StoreAdapter = ({IapService iap, StoreOwnership ownership});

/// Builds the real store adapter (`StoreIapService`).
typedef StoreAdapterFactory =
    StoreAdapter Function({
      required Logger logger,
      required PurchasesBlockedReason? Function() purchasesBlockedReason,
    });

/// Builds the Firebase analytics backend.
typedef AnalyticsBackendFactory =
    TaroAnalyticsBackend Function({required Logger logger});

/// Builds the Crashlytics reporter.
typedef CrashReporterFactory =
    Future<CrashReporter> Function({
      required String flavor,
      required bool collectionEnabled,
      required Redactor redactor,
    });

StoreAdapter _storeIap({
  required Logger logger,
  required PurchasesBlockedReason? Function() purchasesBlockedReason,
}) {
  final store = StoreIapService.fromPlugin(
    logger: logger,
    purchasesBlockedReason: purchasesBlockedReason,
  );
  return (iap: store, ownership: store);
}

/// The SDK singletons the graph touches while it is built, injectable so
/// the whole graph runs in tests over platform fakes (RC76).
@immutable
final class GraphSdks {
  /// The production entry points.
  const GraphSdks({
    this.storeIap = _storeIap,
    this.firebaseAnalytics = FirebaseAnalyticsService.fromPlugin,
    this.firebaseCrash = FirebaseCrashReporter.fromPlugin,
  });

  /// The StoreKit 2 / Play Billing adapter.
  final StoreAdapterFactory storeIap;

  /// The Firebase analytics backend.
  final AnalyticsBackendFactory firebaseAnalytics;

  /// The Crashlytics reporter.
  final CrashReporterFactory firebaseCrash;
}

/// Everything the composition root needs from the platform.
@immutable
final class GraphInputs {
  /// The inputs of one build.
  const GraphInputs({
    required this.flavor,
    required this.databases,
    required this.secureStore,
    required this.appInfo,
    required this.firebaseReady,
    required this.platform,
    required this.deviceLocales,
    this.debugAttestationToken = '',
    this.bundle,
    this.sdks = const GraphSdks(),
  });

  /// The flavor configuration.
  final FlavorConfig flavor;

  /// The opened databases.
  final TaroDatabases databases;

  /// The secure store.
  final SecureStore secureStore;

  /// The app / device info.
  final AppInfo appInfo;

  /// Whether `Firebase.initializeApp` succeeded (no Firebase project in a
  /// build means NoOp analytics and crash reporting).
  final bool firebaseReady;

  /// The running platform.
  final TargetPlatform platform;

  /// The device locales, most preferred first (read per call).
  final List<Locale> Function() deviceLocales;

  /// The dev/staging `DEBUG_ATTESTATION_TOKEN` (`--dart-define`); ignored
  /// in prod (RC86).
  final String debugAttestationToken;

  /// The asset bundle of the bundled content (default `rootBundle`).
  final AssetBundle? bundle;

  /// The SDK entry points.
  final GraphSdks sdks;
}

/// Builds every adapter of the app (02 §5, §9.1) and returns the provider
/// overrides. The cache-backed repositories are opened here, so the first
/// frame shows the cached config, balance, entitlement, settings and
/// consent offline (02 §9.1 step 4).
///
/// Per flavor (02 §15): IAP is the store only in prod (dev and staging have
/// no products); Crashlytics is off in dev; the console analytics backend
/// runs in dev; the debug attestation (and its request header) exists only
/// outside prod.
Future<List<Override>> buildAppOverrides(GraphInputs inputs) async {
  final flavor = inputs.flavor;
  final isProd = flavor.isProd;
  final isDev = flavor.flavor == Flavor.dev;
  final isIos = inputs.platform == TargetPlatform.iOS;
  final journalDb = inputs.databases.journal;
  final deviceDb = inputs.databases.device;
  final secure = inputs.secureStore;

  const clock = SystemClock();
  final random = SecureRandomSource();
  final ids = SecureIdGenerator();
  final redactor = Redactor();

  final crash = !isDev && inputs.firebaseReady
      ? await inputs.sdks.firebaseCrash(
          flavor: flavor.flavor.name,
          collectionEnabled: true,
          redactor: redactor,
        )
      : const NoOpCrashReporter();
  final logger = PackageLoggingLogger.forBuild(
    isProd: isProd,
    crash: crash,
    redactor: redactor,
  );

  // Cached state for the first frame.
  final consent = await ConsentStoreImpl.open(
    cache: deviceDb.cacheDao,
    clock: clock,
    logger: logger,
  );
  final settings = await SettingsRepositoryImpl.open(
    dao: journalDb.settingsDao,
    logger: logger,
  );
  final entitlements = await EntitlementCacheImpl.open(
    dao: deviceDb.entitlementsDao,
    logger: logger,
  );
  String appLocale() => resolveAppLocale(
    override: settings.current.localeOverride,
    deviceLocales: inputs.deviceLocales(),
  );

  // Attestation (RC86, RC87) and the Worker client.
  final timezone = FlutterTimezoneProvider(logger: logger);
  final platformAttestation = PlatformAttestationService(
    cloudProjectNumber: flavor.playCloudProjectNumber,
    platform: inputs.platform,
    logger: logger.child('attestation'),
  );
  final debugAttestation = DebugAttestationService.forBuild(
    isProd: isProd,
    token: inputs.debugAttestationToken,
    signals: platformAttestation,
  );
  final attestation = debugAttestation ?? platformAttestation;
  final tokens = SecureSessionTokenStore(secure, logger: logger);
  final workerConfig = WorkerClientConfig.fromAppInfo(
    inputs.appInfo,
    baseUrl: flavor.apiBaseUrl,
    locale: appLocale,
    flavor: isProd ? null : flavor.flavor.name,
    extraHeaders: debugAttestation?.headers ?? const {},
  );
  final client = WorkerClient(
    config: workerConfig,
    tokens: tokens,
    attestation: attestation,
    consent: consent,
    clock: clock,
    ids: ids,
    random: random,
    logger: logger,
    attestationKeyId: AttestationInterceptor.storedKeyId(secure),
  );

  final config = await RemoteConfigRepositoryImpl.open(
    cache: deviceDb.cacheDao,
    fetch: client.fetchConfig,
    clock: clock,
    logger: logger,
  );
  final balance = await BalanceRepositoryImpl.open(
    cache: deviceDb.cacheDao,
    fetch: client.fetchBalance,
    logger: logger,
  );
  final install = InstallRepositoryImpl(
    client: client,
    config: workerConfig,
    secure: secure,
    cache: deviceDb.cacheDao,
    attestation: attestation,
    timezone: timezone,
    clock: clock,
    ids: ids,
    random: random,
    logger: logger,
    onRegistered: (registration) async {
      redactor.registerSecret(registration.token.token);
      await balance.apply(registration.balance);
    },
  );

  // Content, journal and readings.
  final content = AssetContentRepository.fromBundle(
    inputs.bundle ?? rootBundle,
  );
  final readings = ReadingRepositoryImpl(
    journal: journalDb,
    device: deviceDb,
    client: client,
    balance: balance,
    clock: clock,
    logger: logger,
  );

  // Ads and consent (RC19, RC68).
  final adIds = isIos ? flavor.admobIos : flavor.admobAndroid;
  ConsentOrchestrator? orchestrator;
  bool nonPersonalizedAds() =>
      !(orchestrator?.outcome?.analytics.adPersonalization ?? false);
  final ads =
      NoOpAdsService.applies(
        config.current,
        entitlements.read(),
      )
      ? const NoOpAdsService()
      : AdMobAdsService(
          rewardedAdUnitId: adIds.rewarded,
          clock: clock,
          logger: logger.child('ads'),
          loadTimeout: () => config.current.rewardedLoadTimeout,
          nonPersonalizedAds: nonPersonalizedAds,
        );

  final backends = <TaroAnalyticsBackend>[
    if (inputs.firebaseReady) inputs.sdks.firebaseAnalytics(logger: logger),
    if (isDev) ConsoleAnalyticsService(logger: logger),
  ];
  final inner = backends.isEmpty
      ? const NoOpAnalyticsService()
      : CompositeAnalyticsService(backends, logger: logger);
  final tap = AnalyticsConsentTap(inner);
  final analytics = ConsentAwareAnalytics(
    inner: tap,
    whenResolved: tap.resolved,
    logger: logger,
  );
  final banners = ads is AdMobAdsService
      ? AdMobBannerSlotView(
          adUnitId: adIds.banner,
          ready: () => ads.whenInitialized,
          nonPersonalizedAds: nonPersonalizedAds,
          logger: logger.child('banner'),
          analytics: analytics,
        )
      : const NoOpBannerSlotView();
  final ump = UmpConsentService(
    logger: logger.child('ump'),
    allowDebugGeography: !isProd,
  );
  final tracking = isIos
      ? AttTrackingAuthorization(logger: logger.child('att'))
      : const NotSupportedTrackingAuthorization();
  orchestrator = ConsentOrchestrator(
    consent: ump,
    tracking: tracking,
    ads: ads,
    analytics: tap,
    store: consent,
    config: config,
    policy: () => AdRequestPolicy(
      bannersEnabled:
          config.current.adsEnabled &&
          config.current.adsBannerEnabled &&
          !entitlements.read().removesAds,
      rewardedEnabled:
          config.current.adsEnabled && config.current.rewardedEnabled,
    ),
    logger: logger.child('consent'),
  );
  unawaited(orchestrator.whenResolved.then((_) => tap.resolve()));

  // Store (02 §15: products exist only on the prod bundle).
  final StoreAdapter store;
  if (isProd) {
    store = inputs.sdks.storeIap(
      logger: logger.child('iap'),
      purchasesBlockedReason: () {
        final cached = balance.cached;
        return cached == null || cached.purchasesAllowed
            ? null
            : cached.purchasesBlockedReason;
      },
    );
  } else {
    final noOp = NoOpIapService();
    store = (iap: noOp, ownership: noOp);
  }

  return [
    flavorConfigProvider.overrideWithValue(flavor),
    appLocaleProvider.overrideWithValue(appLocale),
    clockProvider.overrideWithValue(clock),
    randomSourceProvider.overrideWithValue(random),
    idGeneratorProvider.overrideWithValue(ids),
    loggerProvider.overrideWithValue(logger),
    redactorProvider.overrideWithValue(redactor),
    timezoneProvider.overrideWithValue(timezone),
    appInfoProvider.overrideWithValue(inputs.appInfo),
    secureStoreProvider.overrideWithValue(secure),
    sessionTokenStoreProvider.overrideWithValue(tokens),
    installRepositoryProvider.overrideWithValue(install),
    balanceRepositoryProvider.overrideWithValue(balance),
    readingRepositoryProvider.overrideWithValue(readings),
    journalRepositoryProvider.overrideWithValue(
      JournalRepositoryImpl(
        journal: journalDb,
        logger: logger,
        cardNames: JournalRepositoryImpl.contentNames(content, appLocale),
      ),
    ),
    dailyCardRepositoryProvider.overrideWithValue(
      DailyCardRepositoryImpl(
        dao: journalDb.dailyCardsDao,
        content: content,
        settings: settings,
        clock: clock,
        random: random,
        logger: logger,
      ),
    ),
    contentRepositoryProvider.overrideWithValue(content),
    crisisResourcesRepositoryProvider.overrideWithValue(content.crisis),
    remoteConfigRepositoryProvider.overrideWithValue(config),
    settingsRepositoryProvider.overrideWithValue(settings),
    consentStoreProvider.overrideWithValue(consent),
    purchaseVerifierProvider.overrideWithValue(PurchaseVerifierImpl(client)),
    purchaseOutboxProvider.overrideWithValue(
      PurchaseOutboxImpl(dao: deviceDb.outboxDao, logger: logger),
    ),
    entitlementCacheProvider.overrideWithValue(entitlements),
    rewardGatewayProvider.overrideWithValue(
      RewardGatewayImpl(client: client, ids: ids, logger: logger),
    ),
    reportGatewayProvider.overrideWithValue(
      ReportGatewayImpl(client: client, readings: readings),
    ),
    dataDeletionGatewayProvider.overrideWithValue(
      DataDeletionGatewayImpl(
        client: client,
        cache: deviceDb.cacheDao,
        logger: logger,
      ),
    ),
    iapServiceProvider.overrideWithValue(store.iap),
    storeOwnershipProvider.overrideWithValue(store.ownership),
    adsServiceProvider.overrideWithValue(ads),
    bannerSlotViewProvider.overrideWithValue(banners),
    consentServiceProvider.overrideWithValue(ump),
    trackingAuthorizationProvider.overrideWithValue(tracking),
    analyticsServiceProvider.overrideWithValue(analytics),
    consentOrchestratorProvider.overrideWithValue(orchestrator),
    crashReporterProvider.overrideWithValue(crash),
    reminderSchedulerProvider.overrideWithValue(
      LocalReminderScheduler(
        clock: clock,
        timezones: timezone,
        copy: reminderCopyFor,
        logger: logger,
        platform: inputs.platform,
      ),
    ),
    attestationServiceProvider.overrideWithValue(attestation),
    attestationWarmUpProvider.overrideWithValue(platformAttestation.warmUp),
    fileTransferProvider.overrideWithValue(
      PlatformFileTransfer(logger: logger),
    ),
    connectivityMonitorProvider.overrideWithValue(
      ConnectivityPlusMonitor(logger: logger),
    ),
    reviewPrompterProvider.overrideWithValue(
      InAppReviewPrompter(
        clock: clock,
        config: config,
        ledger: SecureStoreReviewPromptLedger(secure),
        logger: logger,
      ),
    ),
    urlLauncherProvider.overrideWithValue(
      PlatformUrlLauncher(logger: logger, isIos: isIos),
    ),
    backupExclusionProvider.overrideWithValue(
      isIos ? const PlatformBackupExclusion() : const NoOpBackupExclusion(),
    ),
  ];
}
