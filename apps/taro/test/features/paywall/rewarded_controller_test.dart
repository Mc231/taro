import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

const ConsentState _adsAllowed = ConsentState(
  onboardingStep: OnboardingStep.done,
  ads: AdsConsent(status: AdsConsentStatus.notRequired, canRequestAds: true),
);

CreditBalance _eligible({bool available = true, int grantedToday = 0}) =>
    aCreditBalance()
        .withFreeRemaining(0)
        .withRewarded(available: available, grantedToday: grantedToday)
        .build();

void main() {
  late TaroFakes fakes;
  late List<RewardedState> states;

  setUp(() {
    fakes = TaroFakes(consent: _adsAllowed);
    fakes.balance.seed(_eligible());
    states = [];
  });

  (ProviderContainer, RewardedController) open() {
    final container =
        fakes.container(
          extra: [
            rewardedPollDelayProvider.overrideWithValue(fakes.clock.delay),
          ],
        )..listen(
          rewardedControllerProvider,
          (_, next) => states.add(next),
          fireImmediately: true,
        );
    return (container, container.read(rewardedControllerProvider.notifier));
  }

  Map<String, Object> paramsOf(String name) =>
      fakes.analytics.events.lastWhere((e) => e.eventName == name).parameters;

  test('loadingAd → showing → granting → granted; the Worker balance is '
      'applied (RC33)', () async {
    final granted = _eligible().copyWith(bonus: 1, ledgerVersion: 2);
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards
      ..autoGrant = true
      ..grantBalance = granted;
    final (_, controller) = open();
    await controller.start();
    expect(states, const [
      RewardedState.loadingAd(),
      RewardedState.showing(),
      RewardedState.granting(),
      RewardedState.granted(amount: 1),
    ]);
    expect(fakes.balance.applied, [granted]);
    expect(fakes.rewards.adUnitIds, ['r']);
    expect(paramsOf('rewarded_ad_result'), {'result': 'completed'});
    expect(paramsOf('rewarded_grant_result'), {
      'result': 'granted',
      'wait_ms': 0,
    });
  });

  test('a second start is ignored', () async {
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards.autoGrant = true;
    final (_, controller) = open();
    await controller.start();
    await controller.start();
    expect(fakes.rewards.adUnitIds, hasLength(1));
  });

  test('the Android ad unit is used on Android', () async {
    fakes
      ..appInfo = const FakeAppInfo(platform: AppPlatform.android)
      ..ads.autoResult = RewardedShowResult.earned
      ..rewards.autoGrant = true;
    final (_, controller) = open();
    await controller.start();
    expect(fakes.rewards.adUnitIds, ['r']);
    expect(states.last, const RewardedState.granted(amount: 1));
  });

  test('grantDelayed after the poll timeout (non-blocking)', () async {
    fakes.ads.autoResult = RewardedShowResult.earned;
    final (_, controller) = open();
    await controller.start();
    expect(states.last, const RewardedState.grantDelayed());
    expect(paramsOf('rewarded_grant_result'), {
      'result': 'delayed',
      'wait_ms': 21000,
    });
  });

  test('dismissedEarly cancels the intent (RC57)', () async {
    fakes.ads.autoResult = RewardedShowResult.dismissedEarly;
    final (_, controller) = open();
    await controller.start();
    expect(states.last, const RewardedState.dismissedEarly());
    expect(fakes.rewards.cancelled, [const IntentId('intent-1')]);
    expect(paramsOf('rewarded_ad_result'), {'result': 'dismissed'});
  });

  test('noFill cancels the intent and greys the S10 row for 60 s', () async {
    fakes.ads.autoResult = RewardedShowResult.noFill;
    final (container, controller) = open();
    await controller.start();
    expect(states.last, const RewardedState.noFill());
    expect(fakes.rewards.cancelled, hasLength(1));
    expect(
      container.read(rewardedNoFillProvider),
      fakes.clock.now().add(kRewardedNoFillCooldown),
    );
    expect(paramsOf('rewarded_ad_result'), {'result': 'no_fill'});
  });

  test('a Worker rejection adds nothing', () async {
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards.scriptStatuses(const IntentId('intent-1'), const [
      RewardStatus(state: RewardIntentState.rejected, amount: 1),
    ]);
    final (_, controller) = open();
    await controller.start();
    expect(states.last, const RewardedState.failed(ErrorKind.server));
    expect(
      fakes.analytics.eventNames,
      isNot(contains('rewarded_grant_result')),
    );
  });

  test('cap and cooldown are unavailable with their grant result', () async {
    fakes.balance.seed(_eligible(available: false, grantedToday: 3));
    var (container, controller) = open();
    await controller.start();
    expect(
      states.last,
      const RewardedState.unavailable(RewardUnavailableReason.cap),
    );
    expect(paramsOf('rewarded_grant_result'), {
      'result': 'capped',
      'wait_ms': 0,
    });
    container.dispose();

    fakes.balance.seed(
      aCreditBalance()
          .withFreeRemaining(0)
          .withRewarded(
            available: false,
            cooldownEndsAt: fakes.clock.now().add(const Duration(minutes: 3)),
          )
          .build(),
    );
    (container, controller) = open();
    await controller.start();
    expect(
      states.last,
      const RewardedState.unavailable(RewardUnavailableReason.cooldown),
    );
    expect(paramsOf('rewarded_grant_result'), {
      'result': 'cooldown',
      'wait_ms': 0,
    });
  });

  test('disabled by config is unavailable without a grant event', () async {
    fakes.config.current = aRemoteConfig().withRewardedEnabled(false).build();
    final (_, controller) = open();
    await controller.start();
    expect(
      states.last,
      const RewardedState.unavailable(RewardUnavailableReason.disabled),
    );
    expect(fakes.analytics.events, isEmpty);
  });

  test('offline fails with network and logs an ad error', () async {
    fakes.connectivity.setOnline(online: false);
    final (_, controller) = open();
    await controller.start();
    expect(states.last, const RewardedState.failed(ErrorKind.network));
    expect(paramsOf('rewarded_ad_result'), {'result': 'error'});
  });

  test('a show failure after the load waits for the SDK', () async {
    final (_, controller) = open();
    final run = controller.start();
    await pumpEventQueue();
    expect(states.last, const RewardedState.showing());
    expect(fakes.ads.isShowing, isTrue);
    fakes.ads.dismissRewarded();
    await run;
    expect(states.last, const RewardedState.dismissedEarly());
  });

  test('the overlay closing mid-flow drops the late result', () async {
    final (container, controller) = open();
    final run = controller.start();
    await pumpEventQueue();
    container.dispose();
    fakes.ads.dismissRewarded();
    await run;
    expect(states.last, const RewardedState.showing());
  });
}
