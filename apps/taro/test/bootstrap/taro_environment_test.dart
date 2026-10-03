import 'dart:io';

import 'package:drift/native.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/secure/flutter_secure_store.dart';
import 'package:taro/di/app_graph.dart';
import 'package:taro/di/overrides_dev.dart';
import 'package:taro/di/overrides_prod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/services/ads/admob_ads_service.dart';
import 'package:taro/services/ads/no_op_ads_service.dart';
import 'package:taro/services/analytics/consent_aware_analytics.dart';
import 'package:taro/services/analytics/console_analytics_service.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro/services/attestation/platform_attestation_service.dart';
import 'package:taro/services/crash/firebase_crash_reporter.dart';
import 'package:taro/services/crash/noop_crash_reporter.dart';
import 'package:taro/services/iap/no_op_iap_service.dart';
import 'package:taro/services/iap/store_iap_service.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';
import '../services/analytics/firebase_fakes.dart';
import '../services/iap/support/fake_in_app_purchase_platform.dart';

TaroDatabases _memoryDbs() => (
  journal: JournalDatabase(NativeDatabase.memory()),
  device: DeviceDatabase(NativeDatabase.memory()),
);

Map<String, String> _defines(Flavor flavor) => {
  'flavor': flavor.name,
  'apiBaseUrl': 'https://api.example.com',
  'admob.ios.rewarded': 'ca-app-pub-3940256099942544/1712485313',
  'admob.ios.banner': 'ca-app-pub-3940256099942544/2934735716',
  'playCloudProjectNumber': '123',
  'universalLinkHost': 'taro.vshyrochuk.com',
  'supportEmail': 'support@example.com',
};

/// Every provider of the graph, read once to build it.
List<ProviderListenable<Object?>> get _allProviders => [
  flavorConfigProvider,
  appLocaleProvider,
  clockProvider,
  randomSourceProvider,
  idGeneratorProvider,
  loggerProvider,
  redactorProvider,
  timezoneProvider,
  appInfoProvider,
  secureStoreProvider,
  sessionTokenStoreProvider,
  installRepositoryProvider,
  balanceRepositoryProvider,
  readingRepositoryProvider,
  journalRepositoryProvider,
  dailyCardRepositoryProvider,
  contentRepositoryProvider,
  crisisResourcesRepositoryProvider,
  remoteConfigRepositoryProvider,
  settingsRepositoryProvider,
  consentStoreProvider,
  purchaseVerifierProvider,
  purchaseOutboxProvider,
  entitlementCacheProvider,
  rewardGatewayProvider,
  reportGatewayProvider,
  dataDeletionGatewayProvider,
  iapServiceProvider,
  storeOwnershipProvider,
  adsServiceProvider,
  bannerSlotViewProvider,
  consentServiceProvider,
  trackingAuthorizationProvider,
  analyticsServiceProvider,
  crashReporterProvider,
  reminderSchedulerProvider,
  attestationServiceProvider,
  attestationWarmUpProvider,
  fileTransferProvider,
  connectivityMonitorProvider,
  reviewPrompterProvider,
  backupExclusionProvider,
  urlLauncherProvider,
  consentOrchestratorProvider,
  pendingPurchaseTrackerProvider,
  removeAdsEntitlementProvider,
  purchaseCoordinatorProvider,
  syncAccountProvider,
  resolveReadingGateProvider,
  drawCardsProvider,
  requestReadingProvider,
  startClassicReadingProvider,
  earnRewardProvider,
  reportReadingProvider,
  exportBackupProvider,
  importBackupProvider,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<ProviderContainer> build(ProductionEnvironment env) async {
    await env.initFirebase();
    final dbs = await env.openDatabases();
    final container = ProviderContainer(
      overrides: await env.buildOverrides(env.flavor, dbs),
    );
    addTearDown(() async {
      container.dispose();
      await dbs.journal.close();
      await dbs.device.close();
    });
    _allProviders.forEach(container.read);
    return container;
  }

  test('dev on Android: NoOp store and crash, debug attestation', () async {
    final mounted = <Widget>[];
    final env = ProductionEnvironment(
      Flavor.dev,
      defines: _defines(Flavor.dev),
      hooks: PlatformHooks(
        initializeFirebase: (_) async => throw StateError('no project'),
        openDatabases: () async => _memoryDbs(),
        loadAppInfo: () async =>
            const FakeAppInfo(platform: AppPlatform.android),
        runApp: mounted.add,
        platform: () => TargetPlatform.android,
        deviceLocales: () => const [Locale('xx'), Locale('uk', 'UA')],
        debugAttestationToken: 'debug-token',
      ),
    );
    final container = await build(env);

    expect(env.flavor.flavor, Flavor.dev);
    expect(container.read(iapServiceProvider), isA<NoOpIapService>());
    expect(container.read(crashReporterProvider), isA<NoOpCrashReporter>());
    expect(
      container.read(analyticsServiceProvider),
      isA<ConsentAwareAnalytics>(),
    );
    expect(
      container.read(attestationServiceProvider),
      isA<DebugAttestationService>(),
    );
    expect(container.read(appLocaleProvider)(), 'uk');
    expect(container.read(randomSourceProvider), isA<SecureRandomSource>());
    expect(container.read(adsServiceProvider), isA<AdMobAdsService>());
    expect(container.read(bannerSlotViewProvider), isA<AdMobBannerSlotView>());
    expect(env.secureStore, isA<FlutterSecureStore>());

    env.runApp(const SizedBox());
    expect(mounted, hasLength(1));

    // The consent sequence resolves the analytics buffer.
    await container
        .read(consentStoreProvider)
        .update((s) => s.copyWith(onboardingStep: OnboardingStep.done));
    final orchestrator = container.read(consentOrchestratorProvider);
    expect(orchestrator.isResolved, isFalse);
  });

  test('prod on iOS: store, Firebase, platform attestation', () async {
    await setUpFirebaseFakes();
    // Not iOS / Android, so `InAppPurchase.instance` keeps the fake.
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchasePlatform.instance = FakeInAppPurchasePlatform();
    final env = ProductionEnvironment(
      Flavor.prod,
      defines: _defines(Flavor.prod),
      hooks: PlatformHooks(
        initializeFirebase: (_) async {},
        openDatabases: () async => _memoryDbs(),
        loadAppInfo: () async => const FakeAppInfo(),
        platform: () => TargetPlatform.iOS,
        deviceLocales: () => const [Locale('fr')],
        debugAttestationToken: 'ignored-in-prod',
      ),
    );
    final container = await build(env);
    expect(container.read(iapServiceProvider), isA<StoreIapService>());
    expect(container.read(storeOwnershipProvider), isA<StoreIapService>());
    expect(
      container.read(crashReporterProvider),
      isA<FirebaseCrashReporter>(),
    );
    expect(
      container.read(attestationServiceProvider),
      isA<PlatformAttestationService>(),
    );
    expect(container.read(appLocaleProvider)(), 'fr');

    // The store adapter reads the purchases block from the cached balance.
    final balance = container.read(balanceRepositoryProvider);
    await balance.apply(aCreditBalance().withPurchasesBlocked().build());
    final bought = await container
        .read(iapServiceProvider)
        .buy(TaroProducts.all.first.id, binding: const PurchaseBinding());
    expect(bought.isOk, isFalse);
  });

  test('staging with Firebase: the injected backends', () async {
    final dbs = _memoryDbs();
    addTearDown(() async {
      await dbs.journal.close();
      await dbs.device.close();
    });
    final crash = FakeCrashReporter();
    final overrides = await devOverrides(
      GraphInputs(
        flavor: testFlavorConfig(Flavor.staging),
        databases: dbs,
        secureStore: InMemorySecureStore(),
        appInfo: const FakeAppInfo(),
        firebaseReady: true,
        platform: TargetPlatform.android,
        deviceLocales: () => const [],
        sdks: GraphSdks(
          firebaseAnalytics: ({required logger}) =>
              const NoOpAnalyticsService(),
          firebaseCrash:
              ({
                required flavor,
                required collectionEnabled,
                required redactor,
              }) async => crash,
        ),
      ),
    );
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    expect(container.read(appLocaleProvider)(), 'en');
    expect(container.read(crashReporterProvider), same(crash));
    await container
        .read(analyticsServiceProvider)
        .log(const ReminderOpenedEvent());
  });

  test('the override entry points refuse the wrong flavor', () {
    GraphInputs inputs(Flavor flavor) => GraphInputs(
      flavor: testFlavorConfig(flavor),
      databases: _memoryDbs(),
      secureStore: InMemorySecureStore(),
      appInfo: const FakeAppInfo(),
      firebaseReady: false,
      platform: TargetPlatform.android,
      deviceLocales: () => const [],
    );
    expect(() => prodOverrides(inputs(Flavor.dev)), throwsStateError);
    expect(() => devOverrides(inputs(Flavor.prod)), throwsStateError);
  });

  test('installErrorHandlers routes framework errors to the reporter', () {
    final previous = FlutterError.onError;
    addTearDown(() => FlutterError.onError = previous);
    final crash = FakeCrashReporter();
    ProductionEnvironment(
      Flavor.dev,
      defines: _defines(Flavor.dev),
    ).installErrorHandlers(crash);
    FlutterError.onError = (details) {};
    expect(crash.errors, isEmpty);
  });

  test('initFirebase passes the flavor options (Sprint 10.2)', () async {
    const options = FirebaseOptions(
      apiKey: 'key',
      appId: '1:1:ios:1',
      messagingSenderId: '1',
      projectId: 'taro-app-dev',
    );
    final received = <FirebaseOptions?>[];
    ProductionEnvironment env(FirebaseOptions Function()? firebaseOptions) =>
        ProductionEnvironment(
          Flavor.dev,
          defines: _defines(Flavor.dev),
          firebaseOptions: firebaseOptions,
          hooks: PlatformHooks(
            initializeFirebase: (o) async => received.add(o),
          ),
        );
    await env(() => options).initFirebase();
    await env(null).initFirebase();
    expect(received, [same(options), isNull]);

    // An unsupported platform throws from `currentPlatform`: Firebase off.
    await env(() => throw UnsupportedError('web')).initFirebase();
    expect(received, hasLength(2));
  });

  test('a config of another flavor fails fast', () {
    expect(
      () => ProductionEnvironment(Flavor.dev, defines: _defines(Flavor.prod)),
      throwsStateError,
    );
  });

  test('the default hooks', () async {
    const hooks = PlatformHooks();
    expect(hooks.platform(), defaultTargetPlatform);
    expect(hooks.deviceLocales(), isNotEmpty);
    final temp = Directory.systemTemp.createTempSync('taro_hooks');
    addTearDown(() => temp.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temp.path,
        );
    final dbs = await hooks.openDatabases();
    expect(dbs.journal, isA<JournalDatabase>());
    await dbs.journal.close();
    await dbs.device.close();
    await setUpFirebaseFakes();
    await hooks.initializeFirebase(null);
  });

  test('NoOpAdsService when ads are disabled', () {
    expect(
      NoOpAdsService.applies(
        RemoteConfig.defaults.copyWith(adsEnabled: false),
        Entitlement.unknown,
      ),
      isTrue,
    );
    expect(const NoOpBannerSlotView(), isA<BannerSlotView>());
  });
}
