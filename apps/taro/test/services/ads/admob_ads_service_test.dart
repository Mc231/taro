import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:taro/services/ads/admob_ads_service.dart';
import 'package:taro/services/ads/no_op_ads_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'fake_ads_platform.dart';

const _unit = 'ca-app-pub-3940256099942544/5224354917';
const _both = AdRequestPolicy(bannersEnabled: true, rewardedEnabled: true);

final class _Harness implements AdsServiceHarness {
  _Harness(this.platform)
    : subject = AdMobAdsService(
        rewardedAdUnitId: _unit,
        clock: FakeClock(),
        logger: CapturingLogger(),
        loadTimeout: () => const Duration(seconds: 5),
        nonPersonalizedAds: () => false,
      );

  final FakeAdsPlatform platform;

  @override
  final AdMobAdsService subject;

  @override
  void endAd(RewardedShowResult result) {
    // The native ad reports only once it is on screen.
    unawaited(
      platform.takeShow().then(
        (id) => switch (result) {
          RewardedShowResult.earned => platform.earnAndClose(id),
          RewardedShowResult.dismissedEarly => platform.close(id),
          _ => platform.failToShow(id),
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAdsPlatform platform;
  late FakeClock clock;
  late CapturingLogger logger;
  late bool npa;
  late Duration timeout;
  late AdMobAdsService ads;

  final intent = RewardIntent(
    intentId: const IntentId('intent-42'),
    amount: 1,
    expiresAt: kTestNow.add(const Duration(minutes: 15)),
  );

  AdMobAdsService build({
    AdsSdkInitializer? initializer,
    RewardedAdLoader? loader,
  }) => ads = AdMobAdsService(
    rewardedAdUnitId: _unit,
    clock: clock,
    logger: logger,
    loadTimeout: () => timeout,
    nonPersonalizedAds: () => npa,
    initializer: initializer,
    loadRewarded: loader,
  );

  setUp(() {
    platform = FakeAdsPlatform();
    clock = FakeClock();
    logger = CapturingLogger();
    npa = false;
    timeout = const Duration(seconds: 5);
    build();
  });
  tearDown(() => platform.uninstall());

  /// Shows [intent], answering with [answer] once the ad is on screen.
  Future<RewardedShowResult> show(Future<void> Function(int id) answer) {
    unawaited(platform.takeShow().then(answer));
    return ads.showRewarded(intent).then(expectOk);
  }

  runAdsServiceContract(() => _Harness(platform));

  group('initialize', () {
    test('initialises the SDK once', () async {
      expect(ads.isInitialized, isFalse);
      final ready = ads.whenInitialized;
      await Future.wait([ads.initialize(_both), ads.initialize(_both)]);
      await ads.initialize(_both);
      await ready;
      expect(ads.isInitialized, isTrue);
      expect(
        platform.methods.where((m) => m == 'MobileAds#initialize'),
        hasLength(1),
      );
    });

    test('a policy without ads does not touch the SDK', () async {
      await ads.initialize(
        const AdRequestPolicy(bannersEnabled: false, rewardedEnabled: false),
      );
      expect(ads.isInitialized, isFalse);
      expect(platform.methods, isNot(contains('MobileAds#initialize')));
    });

    test('a failed init is logged and can be retried', () async {
      platform.failInitialize = true;
      await ads.initialize(_both);
      expect(ads.isInitialized, isFalse);
      expect(logger.logged('ads init failed'), isTrue);
      platform.failInitialize = false;
      await ads.initialize(_both);
      expect(ads.isInitialized, isTrue);
    });
  });

  group('before initialize (no consent yet)', () {
    test('nothing is loaded and a show is noFill', () async {
      await ads.preloadRewarded();
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
      expect(platform.loadedIds, isEmpty);
    });

    test('rewarded disabled by policy → noFill without a load', () async {
      await ads.initialize(
        const AdRequestPolicy(bannersEnabled: true, rewardedEnabled: false),
      );
      await ads.preloadRewarded();
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
      expect(platform.loadedIds, isEmpty);
    });
  });

  group('loadRewarded', () {
    setUp(() => ads.initialize(_both));

    test('loads the rewarded unit with a personalised request', () async {
      await ads.preloadRewarded();
      final args = platform.argsOf('loadRewardedAd');
      expect(args['adUnitId'], _unit);
      expect(
        (args['request']! as gma.AdRequest).nonPersonalizedAds,
        isNull,
      );
    });

    test('non-personalised when ad personalisation is denied', () async {
      npa = true;
      await ads.preloadRewarded();
      final request = platform.argsOf('loadRewardedAd')['request']!;
      expect((request as gma.AdRequest).nonPersonalizedAds, isTrue);
      expect(adRequestFor(nonPersonalized: false).nonPersonalizedAds, isNull);
    });

    test('a preloaded ad is reused for the show', () async {
      await ads.preloadRewarded();
      await ads.preloadRewarded();
      expect(await show(platform.earnAndClose), RewardedShowResult.earned);
      expect(platform.loadedIds, hasLength(1));
    });

    test('a loaded ad expires after 1 h and is replaced', () async {
      await ads.preloadRewarded();
      final first = platform.loadedIds.single;
      clock.advance(AdMobAdsService.rewardedLifetime);
      expect(await show(platform.close), RewardedShowResult.dismissedEarly);
      expect(platform.loadedIds, hasLength(2));
      final disposed = [
        for (final c in platform.calls)
          if (c.method == 'disposeAd')
            (c.arguments as Map<Object?, Object?>)['adId'],
      ];
      expect(disposed, [first, platform.loadedIds.last]);
    });

    test('no fill → noFill', () async {
      platform.loadMode = LoadMode.noFill;
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
      expect(logger.logged('rewarded no fill: 3'), isTrue);
    });

    test('a load error → noFill', () async {
      platform.loadMode = LoadMode.error;
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
      expect(logger.logged('rewarded load threw'), isTrue);
    });

    test(
      'past rewarded.loadTimeoutSec → noFill; the late ad is kept',
      () async {
        platform.loadMode = LoadMode.hang;
        timeout = const Duration(milliseconds: 10);
        expect(
          expectOk(await ads.showRewarded(intent)),
          RewardedShowResult.noFill,
        );
        expect(logger.logged('rewarded load timed out'), isTrue);
        await platform.loaded(platform.loadedIds.single);
        expect(await show(platform.earnAndClose), RewardedShowResult.earned);
        expect(platform.loadedIds, hasLength(1));
      },
    );
  });

  group('showRewarded', () {
    setUp(() => ads.initialize(_both));

    test('binds SSV userId = customData = intentId (RC56)', () async {
      expect(await show(platform.earnAndClose), RewardedShowResult.earned);
      final options =
          platform.argsOf(
                'setServerSideVerificationOptions',
              )['serverSideVerificationOptions']!
              as gma.ServerSideVerificationOptions;
      expect(options.userId, 'intent-42');
      expect(options.customData, 'intent-42');
      expect(
        platform.methods,
        containsAllInOrder([
          'loadRewardedAd',
          'setServerSideVerificationOptions',
          'showAdWithoutView',
          'disposeAd',
        ]),
      );
    });

    test('closed before the reward → dismissedEarly', () async {
      expect(await show(platform.close), RewardedShowResult.dismissedEarly);
    });

    test('a show error callback → failedToShow', () async {
      expect(await show(platform.failToShow), RewardedShowResult.failedToShow);
      expect(logger.logged('rewarded show failed: 1'), isTrue);
    });

    test('a throwing show → failedToShow', () async {
      platform.failShow = true;
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.failedToShow,
      );
      expect(logger.logged('rewarded show threw'), isTrue);
    });

    test('each show uses a fresh ad', () async {
      await show(platform.earnAndClose);
      await show(platform.earnAndClose);
      expect(platform.loadedIds, hasLength(2));
    });
  });

  test('injected SDK entry points are used', () async {
    var inits = 0;
    final requests = <gma.AdRequest>[];
    build(
      initializer: () async => inits++,
      loader:
          ({
            required adUnitId,
            required request,
            required rewardedAdLoadCallback,
          }) async {
            requests.add(request);
            rewardedAdLoadCallback.onAdFailedToLoad(
              gma.LoadAdError(3, 'test', 'no fill', null),
            );
          },
    );
    await ads.initialize(_both);
    expect(
      expectOk(await ads.showRewarded(intent)),
      RewardedShowResult.noFill,
    );
    expect(inits, 1);
    expect(requests, hasLength(1));
    expect(platform.calls, isEmpty);
  });

  test('a failing dispose is only logged', () async {
    await ads.initialize(_both);
    platform.failDispose = true;
    expect(await show(platform.close), RewardedShowResult.dismissedEarly);
    expect(logger.logged('ad dispose failed'), isTrue);
  });

  group('NoOpAdsService', () {
    test('never initialises and never fills', () async {
      // Non-const: the constructor line must run (06 QA2 per-file floor).
      // ignore: prefer_const_constructors
      final noOp = NoOpAdsService();
      await noOp.initialize(_both);
      await noOp.preloadRewarded();
      expect(noOp.isInitialized, isFalse);
      expect(
        expectOk(await noOp.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
    });

    test('applies when ads are off or nothing is left to show', () {
      const config = RemoteConfig.defaults;
      const owned = Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
      );
      expect(NoOpAdsService.applies(config, Entitlement.unknown), isFalse);
      expect(NoOpAdsService.applies(config, owned), isFalse);
      expect(
        NoOpAdsService.applies(
          config.copyWith(rewardedEnabled: false),
          owned,
        ),
        isTrue,
      );
      expect(
        NoOpAdsService.applies(
          config.copyWith(rewardedEnabled: false),
          Entitlement.unknown,
        ),
        isFalse,
      );
      expect(
        NoOpAdsService.applies(
          config.copyWith(adsEnabled: false),
          Entitlement.unknown,
        ),
        isTrue,
      );
    });
  });
}
