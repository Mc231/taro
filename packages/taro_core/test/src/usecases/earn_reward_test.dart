import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeRewardGateway gateway;
  late FakeAdsService ads;
  late FakeBalanceRepository balance;
  late FakeRemoteConfigRepository config;
  late FakeConsentStore consent;
  late FakeConnectivityMonitor connectivity;
  late FakeClock clock;
  late CapturingLogger logger;
  late EarnReward earn;

  const adsAllowed = ConsentState(
    ads: AdsConsent(status: AdsConsentStatus.obtained, canRequestAds: true),
  );
  final outOfFree = aCreditBalance().withFreeRemaining(0).build();
  final afterGrant = aCreditBalance()
      .withFreeRemaining(0)
      .withBonus(1)
      .withLedgerVersion(2)
      .build();

  setUp(() {
    clock = FakeClock();
    gateway = FakeRewardGateway(clock: clock, grantBalance: afterGrant);
    ads = FakeAdsService(autoResult: RewardedShowResult.earned);
    balance = FakeBalanceRepository(cached: outOfFree);
    config = FakeRemoteConfigRepository();
    consent = FakeConsentStore(adsAllowed);
    logger = CapturingLogger();
    connectivity = FakeConnectivityMonitor();
    earn = EarnReward(
      gateway: gateway,
      ads: ads,
      balance: balance,
      config: config,
      consent: consent,
      connectivity: connectivity,
      clock: clock,
      logger: logger,
      delay: clock.delay,
    );
  });

  group('unavailableReason', () {
    test('is null when a rewarded ad may be offered', () {
      expect(earn.unavailableReason(), isNull);
    });

    test('ads or rewarded switched off → disabled', () {
      config.current = aRemoteConfig().withAdsEnabled(false).build();
      expect(earn.unavailableReason(), RewardUnavailableReason.disabled);
      config.current = aRemoteConfig().withRewardedEnabled(false).build();
      expect(earn.unavailableReason(), RewardUnavailableReason.disabled);
    });

    test('no ad consent → consent', () {
      consent.seed(const ConsentState());
      expect(earn.unavailableReason(), RewardUnavailableReason.consent);
    });

    test('no balance yet leaves it to the Worker', () {
      balance.seed(null);
      expect(earn.unavailableReason(), isNull);
    });

    test('free readings left or rewarded off in the balance → disabled', () {
      balance.seed(aCreditBalance().build());
      expect(earn.unavailableReason(), RewardUnavailableReason.disabled);
      balance.seed(
        aCreditBalance()
            .withFreeRemaining(0)
            .withRewarded(enabled: false)
            .build(),
      );
      expect(earn.unavailableReason(), RewardUnavailableReason.disabled);
    });

    test('a running cooldown → cooldown; otherwise the cap', () {
      balance.seed(
        aCreditBalance()
            .withFreeRemaining(0)
            .withRewarded(
              available: false,
              cooldownEndsAt: kTestNow.add(const Duration(minutes: 3)),
            )
            .build(),
      );
      expect(earn.unavailableReason(), RewardUnavailableReason.cooldown);
      clock.advance(const Duration(minutes: 3));
      expect(earn.unavailableReason(), RewardUnavailableReason.cap);
      balance.seed(
        aCreditBalance()
            .withFreeRemaining(0)
            .withRewarded(available: false, grantedToday: 3)
            .build(),
      );
      expect(earn.unavailableReason(), RewardUnavailableReason.cap);
    });
  });

  group('call', () {
    test('an unavailable ad fails before any Worker call', () async {
      consent.seed(const ConsentState());
      expect(
        expectErr(await earn(adUnitId: kTestAdUnitId)),
        const Failure.rewardUnavailable(
          reason: RewardUnavailableReason.consent,
        ),
      );
      expect(gateway.calls, isEmpty);
      expect(ads.shown, isEmpty);
    });

    test('offline fails before any Worker call (RC34)', () async {
      connectivity.setOnline(online: false);
      expect(
        expectErr(await earn(adUnitId: kTestAdUnitId)),
        const Failure.network(),
      );
      expect(gateway.calls, isEmpty);
      expect(ads.shown, isEmpty);
    });

    test('a refused intent is returned', () async {
      gateway.failNext(
        const Failure.rewardUnavailable(reason: RewardUnavailableReason.cap),
        on: 'createIntent',
      );
      expect(
        expectErr(await earn(adUnitId: kTestAdUnitId)),
        const Failure.rewardUnavailable(reason: RewardUnavailableReason.cap),
      );
      expect(ads.shown, isEmpty);
    });

    test('an earned, verified view grants and applies the balance', () async {
      gateway.autoGrant = true;
      final outcome = expectOk(await earn(adUnitId: kTestAdUnitId));
      expect(outcome, const RewardOutcome.granted(amount: 1));
      expect(gateway.adUnitIds, [kTestAdUnitId]);
      expect(ads.shown.single.intentId, const IntentId('intent-1'));
      expect(balance.cached?.bonus, 1);
      expect(gateway.cancelled, isEmpty);
    });

    test('a grant without a balance applies nothing', () async {
      gateway
        ..autoGrant = true
        ..grantBalance = null;
      expect(
        expectOk(await earn(adUnitId: kTestAdUnitId)),
        const RewardOutcome.granted(amount: 1),
      );
      expect(balance.applied, isEmpty);
    });

    test('waits for SSV, polling every 1.5 s', () async {
      gateway.scriptStatuses(const IntentId('intent-1'), [
        const RewardStatus(state: RewardIntentState.issued, amount: 1),
        const RewardStatus(state: RewardIntentState.issued, amount: 1),
        RewardStatus(
          state: RewardIntentState.granted,
          amount: 1,
          balance: afterGrant,
        ),
      ]);
      final outcome = expectOk(await earn(adUnitId: kTestAdUnitId));
      expect(outcome, const RewardOutcome.granted(amount: 1));
      expect(gateway.callCount('status'), 3);
      expect(clock.now(), kTestNow.add(const Duration(seconds: 3)));
    });

    test('a failed poll is logged and retried', () async {
      gateway
        ..autoGrant = true
        ..failNext(const Failure.network(), on: 'status');
      expect(
        expectOk(await earn(adUnitId: kTestAdUnitId)),
        const RewardOutcome.granted(amount: 1),
      );
      expect(logger.logged('NETWORK', level: LogLevel.info), isTrue);
    });

    test('still issued at the poll timeout → delayed', () async {
      config.current = aRemoteConfig().withGrantPollTimeoutSec(5).build();
      final outcome = expectOk(await earn(adUnitId: kTestAdUnitId));
      expect(outcome, const RewardOutcome.delayed());
      expect(clock.now().difference(kTestNow), const Duration(seconds: 6));
      expect(gateway.callCount('status'), 5);
    });

    test('a rejected view is not granted', () async {
      gateway.scriptStatuses(const IntentId('intent-1'), const [
        RewardStatus(state: RewardIntentState.rejected, amount: 1),
      ]);
      expect(
        expectOk(await earn(adUnitId: kTestAdUnitId)),
        const RewardOutcome.notGranted(RewardIntentState.rejected),
      );
    });

    test('closing early cancels the intent; no penalty', () async {
      ads.autoResult = RewardedShowResult.dismissedEarly;
      expect(
        expectOk(await earn(adUnitId: kTestAdUnitId)),
        const RewardOutcome.dismissed(),
      );
      expect(gateway.cancelled, [const IntentId('intent-1')]);
      expect(
        gateway.states[const IntentId('intent-1')],
        RewardIntentState.cancelled,
      );
    });

    for (final result in [
      RewardedShowResult.noFill,
      RewardedShowResult.failedToShow,
    ]) {
      test('${result.name} cancels the intent → noFill', () async {
        ads.autoResult = result;
        expect(
          expectErr(await earn(adUnitId: kTestAdUnitId)),
          const Failure.rewardUnavailable(
            reason: RewardUnavailableReason.noFill,
          ),
        );
        expect(gateway.cancelled, hasLength(1));
      });
    }

    test('an ads SDK failure cancels the intent', () async {
      ads.failNext(const Failure.timeout());
      expect(
        expectErr(await earn(adUnitId: kTestAdUnitId)),
        const Failure.timeout(),
      );
      expect(gateway.cancelled, hasLength(1));
    });

    test('the ad is shown until the user finishes it', () async {
      ads.autoResult = null;
      gateway.autoGrant = true;
      final pending = earn(adUnitId: kTestAdUnitId);
      await settle();
      expect(ads.isShowing, isTrue);
      ads.completeRewarded();
      expect(
        expectOk(await pending),
        const RewardOutcome.granted(amount: 1),
      );
    });
  });

  test('the default delay waits in real time', () async {
    final real = EarnReward(
      gateway: gateway..autoGrant = true,
      ads: ads,
      balance: balance,
      config: config,
      consent: consent,
      connectivity: connectivity,
      clock: clock,
      logger: logger,
    );
    expect(
      expectOk(await real(adUnitId: kTestAdUnitId)),
      const RewardOutcome.granted(amount: 1),
    );
  });
}
