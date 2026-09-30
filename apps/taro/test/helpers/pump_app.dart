import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/bootstrap.dart' show noProviderRetry;
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/services/consent/consent_orchestrator.dart';
import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import '../../../../packages/taro_core/test/fakes/fakes.dart';
import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import 'pump_taro_widget.dart';

export '../../../../packages/taro_core/test/fakes/fakes.dart';

/// A test [FlavorConfig] (dev, no network).
FlavorConfig testFlavorConfig([Flavor flavor = Flavor.dev]) => FlavorConfig(
  flavor: flavor,
  apiBaseUrl: 'http://localhost:8787',
  admobIos: const AdmobIds(appId: 'ios-app', banner: 'b', rewarded: 'r'),
  admobAndroid: const AdmobIds(appId: 'and-app', banner: 'b', rewarded: 'r'),
  playCloudProjectNumber: '1',
  privacyPolicyUrl: 'https://taro.vshyrochuk.com/privacy',
  termsUrl: 'https://taro.vshyrochuk.com/terms',
  supportEmail: 'support@example.com',
  universalLinkHost: 'taro.vshyrochuk.com',
);

/// The store ownership answer of [iap]'s owned non-consumables.
final class FakeStoreOwnership implements StoreOwnership {
  /// Reads [iap]'s owned products.
  FakeStoreOwnership(this.iap);

  /// The fake store.
  final FakeIapService iap;

  /// Queued answer instead of the store's (e.g. an `Err` for silence).
  Result<Set<ProductId>>? next;

  @override
  Future<Result<Set<ProductId>>> queryOwnership() async =>
      next ?? Result.ok({...iap.owned});
}

/// Every `taro_core` fake with sane defaults, sharing one [clock] and one
/// [journal] (RC77, RC95). Tests change the fields they care about before
/// [toOverrides] (or `pumpTaro`) runs; the fakes stay Riverpod-free.
final class TaroFakes {
  /// Fresh fakes: a registered install, the default balance and config,
  /// onboarding done, online.
  TaroFakes({
    FakeClock? clock,
    InMemoryJournal? journal,
    ConsentState consent = const ConsentState(
      onboardingStep: OnboardingStep.done,
    ),
  }) : clock = clock ?? FakeClock(),
       journal = journal ?? InMemoryJournal() {
    consentStore = FakeConsentStore(consent);
    readings = FakeReadingRepository(journal: this.journal, clock: this.clock);
    settings = FakeSettingsRepository(journal: this.journal);
    dailyCards = FakeDailyCardRepository(
      journal: this.journal,
      clock: this.clock,
    );
    journalRepository = FakeJournalRepository(this.journal);
    rewards = FakeRewardGateway(clock: this.clock);
    storeOwnership = FakeStoreOwnership(iap);
  }

  /// The flavor configuration.
  FlavorConfig flavor = testFlavorConfig();

  /// The clock (also the device time zone).
  final FakeClock clock;

  /// The in-memory journal behind the reading, daily card, journal and
  /// settings fakes.
  final InMemoryJournal journal;

  /// The app locale.
  String locale = 'en';

  /// The CSPRNG stand-in.
  RandomSource random = SeededRandomSource();

  /// IDs.
  IdGenerator ids = SequentialIdGenerator();

  /// The captured log.
  CapturingLogger logger = CapturingLogger();

  /// The log redactor.
  Redactor redactor = Redactor();

  /// App facts.
  AppInfo appInfo = const FakeAppInfo();

  /// Secure storage.
  InMemorySecureStore secureStore = InMemorySecureStore();

  /// The session token.
  FakeSessionTokenStore sessionTokens = FakeSessionTokenStore();

  /// The install.
  FakeInstallRepository install = FakeInstallRepository();

  /// The balance (cache + scripted Worker).
  FakeBalanceRepository balance = FakeBalanceRepository(
    cached: aCreditBalance().build(),
  );

  /// Readings.
  late FakeReadingRepository readings;

  /// Replaces [readings] as the port (e.g. a wrapper that holds a call
  /// open).
  ReadingRepository? readingsPort;

  /// The journal list.
  late FakeJournalRepository journalRepository;

  /// Daily cards.
  late FakeDailyCardRepository dailyCards;

  /// Bundled content.
  FakeContentRepository content = FakeContentRepository();

  /// Crisis resources.
  FakeCrisisResourcesRepository crisis = FakeCrisisResourcesRepository();

  /// Remote config.
  FakeRemoteConfigRepository config = FakeRemoteConfigRepository();

  /// User settings.
  late FakeSettingsRepository settings;

  /// Consent state.
  late FakeConsentStore consentStore;

  /// Purchase verification.
  FakePurchaseVerifier verifier = FakePurchaseVerifier();

  /// The purchase outbox.
  FakePurchaseOutbox outbox = FakePurchaseOutbox();

  /// The entitlement cache.
  FakeEntitlementCache entitlements = FakeEntitlementCache();

  /// Rewarded intents.
  late FakeRewardGateway rewards;

  /// Reading reports.
  FakeReportGateway reports = FakeReportGateway();

  /// Server data deletion.
  FakeDataDeletionGateway deletion = FakeDataDeletionGateway();

  /// The store.
  FakeIapService iap = FakeIapService();

  /// The silent ownership query.
  late FakeStoreOwnership storeOwnership;

  /// Ads.
  FakeAdsService ads = FakeAdsService();

  /// The banner view.
  BannerSlotView banners = const NoOpBannerSlotView();

  /// UMP.
  FakeConsentService consentService = FakeConsentService();

  /// ATT.
  FakeTrackingAuthorization tracking = FakeTrackingAuthorization();

  /// Analytics.
  FakeAnalyticsService analytics = FakeAnalyticsService();

  /// Replaces [analytics] as the port (e.g. the production
  /// `ConsentAwareAnalytics` decorator over it, RC68).
  AnalyticsService? analyticsPort;

  /// Crash reporting.
  FakeCrashReporter crash = FakeCrashReporter();

  /// Reminders.
  FakeReminderScheduler reminders = FakeReminderScheduler();

  /// Attestation.
  FakeAttestationService attestation = FakeAttestationService();

  /// Replaces [attestation] as the port (e.g. a `DebugAttestationService`).
  AttestationService? attestationPort;

  /// How often the attestation warm-up ran.
  int warmUps = 0;

  /// The attestation warm-up (counts [warmUps] by default).
  late Future<void> Function() warmUp = () async => warmUps++;

  /// The device time zone source ([clock] by default).
  late TimezoneProvider timezone = clock;

  /// Files.
  FakeFileTransfer files = FakeFileTransfer();

  /// Connectivity.
  FakeConnectivityMonitor connectivity = FakeConnectivityMonitor();

  /// Review prompts.
  FakeReviewPrompter review = FakeReviewPrompter();

  /// Backup exclusion.
  FakeBackupExclusion backupExclusion = FakeBackupExclusion();

  /// The bundled articles of S19 / S28: an empty article per ID (tests of
  /// those screens replace it).
  ArticleLoader articles = (id, locale) async =>
      Result.ok(Article(title: id.name, sections: const []));

  /// The consent orchestrator over the UMP / ATT / ads / analytics fakes.
  late final ConsentOrchestrator orchestrator = ConsentOrchestrator(
    consent: consentService,
    tracking: tracking,
    ads: ads,
    analytics: analytics,
    store: consentStore,
    config: config,
    policy: () =>
        const AdRequestPolicy(bannersEnabled: true, rewardedEnabled: true),
    logger: logger,
  );

  /// Replaces [orchestrator] (e.g. one over the [analyticsPort] tap).
  ConsentOrchestrator? orchestratorPort;

  /// One override per port provider (plus the orchestrator, the locale and
  /// the attestation warm-up); derived providers build from these.
  List<Override> toOverrides() => [
    flavorConfigProvider.overrideWithValue(flavor),
    appLocaleProvider.overrideWithValue(() => locale),
    clockProvider.overrideWithValue(clock),
    randomSourceProvider.overrideWithValue(random),
    idGeneratorProvider.overrideWithValue(ids),
    loggerProvider.overrideWithValue(logger),
    redactorProvider.overrideWithValue(redactor),
    timezoneProvider.overrideWithValue(timezone),
    appInfoProvider.overrideWithValue(appInfo),
    secureStoreProvider.overrideWithValue(secureStore),
    sessionTokenStoreProvider.overrideWithValue(sessionTokens),
    installRepositoryProvider.overrideWithValue(install),
    balanceRepositoryProvider.overrideWithValue(balance),
    readingRepositoryProvider.overrideWithValue(readingsPort ?? readings),
    journalRepositoryProvider.overrideWithValue(journalRepository),
    dailyCardRepositoryProvider.overrideWithValue(dailyCards),
    contentRepositoryProvider.overrideWithValue(content),
    crisisResourcesRepositoryProvider.overrideWithValue(crisis),
    remoteConfigRepositoryProvider.overrideWithValue(config),
    settingsRepositoryProvider.overrideWithValue(settings),
    consentStoreProvider.overrideWithValue(consentStore),
    purchaseVerifierProvider.overrideWithValue(verifier),
    purchaseOutboxProvider.overrideWithValue(outbox),
    entitlementCacheProvider.overrideWithValue(entitlements),
    rewardGatewayProvider.overrideWithValue(rewards),
    reportGatewayProvider.overrideWithValue(reports),
    dataDeletionGatewayProvider.overrideWithValue(deletion),
    iapServiceProvider.overrideWithValue(iap),
    storeOwnershipProvider.overrideWithValue(storeOwnership),
    adsServiceProvider.overrideWithValue(ads),
    bannerSlotViewProvider.overrideWithValue(banners),
    consentServiceProvider.overrideWithValue(consentService),
    trackingAuthorizationProvider.overrideWithValue(tracking),
    analyticsServiceProvider.overrideWithValue(analyticsPort ?? analytics),
    crashReporterProvider.overrideWithValue(crash),
    reminderSchedulerProvider.overrideWithValue(reminders),
    attestationServiceProvider.overrideWithValue(
      attestationPort ?? attestation,
    ),
    attestationWarmUpProvider.overrideWithValue(warmUp),
    fileTransferProvider.overrideWithValue(files),
    connectivityMonitorProvider.overrideWithValue(connectivity),
    reviewPrompterProvider.overrideWithValue(review),
    backupExclusionProvider.overrideWithValue(backupExclusion),
    articleLoaderProvider.overrideWithValue(articles),
    consentOrchestratorProvider.overrideWithValue(
      orchestratorPort ?? orchestrator,
    ),
  ];

  /// A container over [toOverrides] (retry off, 02 §7) disposed at the end
  /// of the test.
  ProviderContainer container({List<Override> extra = const []}) {
    final container = ProviderContainer(
      overrides: [...toOverrides(), ...extra],
      retry: noProviderRetry,
    );
    addTearDown(container.dispose);
    return container;
  }
}

/// Pumps [screen] for a screen test with providers (06 §2.3, RC77, RC95):
/// `ProviderScope(overrides: fakes.toOverrides())` around
/// [pumpTaroWidget]'s scaffolding (locale, theme, text scale, size, reduced
/// motion). Returns the fakes in use.
Future<TaroFakes> pumpTaro(
  WidgetTester tester,
  Widget screen, {
  TaroFakes? fakes,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1.0,
  Size size = kPhoneSmall,
}) async {
  final used = (fakes ?? TaroFakes())..locale = locale.languageCode;
  await pumpTaroWidget(
    tester,
    ProviderScope(
      overrides: [...used.toOverrides(), ...overrides],
      retry: noProviderRetry,
      child: screen,
    ),
    locale: locale,
    theme: theme,
    textScale: textScale,
    size: size,
  );
  return used;
}
