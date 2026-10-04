import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/sync_coordinator.dart';
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

  group('deviceUnverified never races registration (iOS-R2-01)', () {
    late _ManualSync sync;

    Future<(StateLog<HomeState>, _ManualSync)> openWith(
      SyncStatus initial,
    ) async {
      sync = _ManualSync(initial);
      final container = fakes.container(
        extra: [syncStatusProvider.overrideWith(() => sync)],
      );
      final log = StateLog(container, homeControllerProvider);
      await pumpEventQueue();
      return (log, sync);
    }

    setUp(() {
      fakes
        ..install = FakeInstallRepository.firstLaunch()
        ..balance = FakeBalanceRepository();
    });

    test('fresh install before the first pass: not unverified', () async {
      final (log, _) = await openWith(const SyncStatus.stale());
      expect(viewOf(log).deviceUnverified, isFalse);
      expect(eventsOf<DeviceUnverifiedShownEvent>(fakes), isEmpty);
    });

    test('registration in flight (syncing) with a balance applied: '
        'not unverified', () async {
      final (log, sync) = await openWith(const SyncStatus.stale());
      sync.status = const SyncStatus.syncing();
      fakes.balance.seed(aCreditBalance().build());
      await pumpEventQueue();
      expect(viewOf(log).variant, HomeBalanceVariant.freeAvailable);
      expect(viewOf(log).deviceUnverified, isFalse);
    });

    test('registered during the pass, balance sync failed: '
        'not unverified', () async {
      final (log, sync) = await openWith(const SyncStatus.syncing());
      fakes.install.identity = anInstallIdentity();
      sync.status = const SyncStatus.unavailable(failure: Failure.network());
      await pumpEventQueue();
      expect(viewOf(log).deviceUnverified, isFalse);
    });

    test('registration failed after the pass: unverified', () async {
      final (log, sync) = await openWith(const SyncStatus.syncing());
      expect(viewOf(log).deviceUnverified, isFalse);
      sync.status = const SyncStatus.unavailable(failure: Failure.network());
      await pumpEventQueue();
      expect(viewOf(log).deviceUnverified, isTrue);
    });
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

final class _ManualSync extends SyncStatusController {
  _ManualSync(this.initial);

  final SyncStatus initial;

  @override
  SyncStatus build() => initial;

  SyncStatus get status => state;

  set status(SyncStatus value) => state = value;
}
