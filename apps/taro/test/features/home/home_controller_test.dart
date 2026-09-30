import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = aiReadyFakes());

  Future<StateLog<HomeState>> open() async {
    final log = StateLog(fakes.container(), homeControllerProvider);
    await pumpEventQueue();
    return log;
  }

  HomeView viewOf(StateLog<HomeState> log) => (log.last as HomeContent).view;

  test('loading → content with the defaults', () async {
    final container = fakes.container();
    final log = StateLog(container, homeControllerProvider);
    expect(log.last, isA<HomeLoading>());
    await pumpEventQueue();
    final view = viewOf(log);
    expect(view.variant, HomeBalanceVariant.freeAvailable);
    expect(view.firstRun, isTrue);
    expect(view.deviceUnverified, isFalse);
    expect(view.dailyCardDrawn, isFalse);
    expect(view.adsRemoved, isFalse);
    expect(view.updateAvailable, isFalse);
    expect(view.recentReadings, isEmpty);
  });

  test('balance variants', () async {
    fakes.balance = FakeBalanceRepository();
    expect(viewOf(await open()).variant, HomeBalanceVariant.unknown);
    fakes.balance = FakeBalanceRepository(
      cached: aCreditBalance().withFreeRemaining(0).withBonus(2).build(),
    );
    expect(
      viewOf(await open()).variant,
      HomeBalanceVariant.freeUsedWithCredits,
    );
    fakes.balance = FakeBalanceRepository(
      cached: aCreditBalance().withFreeRemaining(0).build(),
    );
    expect(viewOf(await open()).variant, HomeBalanceVariant.zeroReadings);
  });

  test('firstRun until the coachmark is dismissed, remembered', () async {
    final container = fakes.container();
    final log = StateLog(container, homeControllerProvider);
    await pumpEventQueue();
    final controller = container.read(homeControllerProvider.notifier);
    await controller.dismissFirstRun();
    await pumpEventQueue();
    expect(viewOf(log).firstRun, isFalse);
    expect(fakes.secureStore.values[HomeNoticeKeys.firstRunDone], isNotNull);
    await container.read(homeControllerProvider.notifier).dismissFirstRun();
    expect(viewOf(await open()).firstRun, isFalse);
  });

  test('deviceUnverified: logged once, Retry syncs', () async {
    fakes.install = FakeInstallRepository(
      identity: anInstallIdentity(registered: false),
    );
    final container = fakes.container();
    final log = StateLog(container, homeControllerProvider);
    await pumpEventQueue();
    expect(viewOf(log).deviceUnverified, isTrue);
    fakes.balance.seed(aCreditBalance().withLedgerVersion(3).build());
    await pumpEventQueue();
    expect(eventsOf<DeviceUnverifiedShownEvent>(fakes), hasLength(1));
    await container.read(homeControllerProvider.notifier).retryVerification();
    await pumpEventQueue();
    expect(fakes.balance.syncReasons, contains(SyncReason.manual));
    expect(viewOf(log).deviceUnverified, isFalse);
  });

  test('updateAvailable once per version, dismissible', () async {
    fakes.config.current = RemoteConfig.defaults.copyWith(
      appRecommendedVersionIos: '2.0.0',
    );
    final container = fakes.container();
    final log = StateLog(container, homeControllerProvider);
    await pumpEventQueue();
    expect(viewOf(log).updateAvailable, isTrue);
    expect(
      fakes.secureStore.values[HomeNoticeKeys.updateNoticeVersion],
      '2.0.0',
    );
    expect(
      eventsOf<AppUpdateAvailableShownEvent>(fakes).single.origin,
      AppNoticeOrigin.launch,
    );
    fakes.balance.seed(aCreditBalance().withLedgerVersion(4).build());
    await pumpEventQueue();
    expect(viewOf(log).updateAvailable, isTrue);
    container.read(homeControllerProvider.notifier).dismissUpdateNotice();
    await pumpEventQueue();
    expect(viewOf(log).updateAvailable, isFalse);
    // Next launch (a new process): already shown for 2.0.0.
    expect(viewOf(await open()).updateAvailable, isFalse);
    expect(eventsOf<AppUpdateAvailableShownEvent>(fakes), hasLength(1));
  });

  test('android reads its own recommended version', () async {
    fakes.appInfo = const FakeAppInfo(platform: AppPlatform.android);
    fakes.config.current = RemoteConfig.defaults.copyWith(
      appRecommendedVersionAndroid: '1.5.0',
    );
    expect(viewOf(await open()).updateAvailable, isTrue);
  });

  test('the daily card, recent readings and Remove Ads', () async {
    fakes.entitlements.entitlement = Entitlement(
      removeAds: EntitlementState.owned,
      source: EntitlementSource.store,
      verifiedAt: kTestNow,
    );
    for (var i = 0; i < 5; i++) {
      fakes.journal.putReading(aReading().withId('reading-$i').build());
    }
    await fakes.dailyCards.drawToday();
    final view = viewOf(await open());
    expect(view.dailyCardDrawn, isTrue);
    expect(view.recentReadings, hasLength(HomeController.recentCount));
    expect(view.adsRemoved, isTrue);
  });
}
