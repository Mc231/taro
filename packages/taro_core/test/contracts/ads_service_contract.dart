import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `AdsService` contract needs besides the port.
abstract interface class AdsServiceHarness {
  /// The service under test (not initialised, an ad available).
  AdsService get subject;

  /// Ends the rewarded ad on screen with [result] (the user watches to the
  /// end, closes it early, …).
  void endAd(RewardedShowResult result);
}

/// The `AdsService` contract (04 §6.6, RC19, RC56).
void runAdsServiceContract(AdsServiceHarness Function() create) {
  group('AdsService contract', () {
    late AdsServiceHarness harness;
    late AdsService ads;
    final intent = RewardIntent(
      intentId: const IntentId('intent-1'),
      amount: 1,
      expiresAt: kTestNow.add(const Duration(minutes: 15)),
    );
    const policy = AdRequestPolicy(bannersEnabled: true, rewardedEnabled: true);

    setUp(() {
      harness = create();
      ads = harness.subject;
    });

    test('is initialised only after initialize', () async {
      expect(ads.isInitialized, isFalse);
      await ads.initialize(policy);
      expect(ads.isInitialized, isTrue);
    });

    test('a watched ad is earned', () async {
      await ads.initialize(policy);
      await ads.preloadRewarded();
      final shown = ads.showRewarded(intent);
      await settle();
      harness.endAd(RewardedShowResult.earned);
      expect(expectOk(await shown), RewardedShowResult.earned);
    });

    test('an ad closed early is not earned', () async {
      await ads.initialize(policy);
      final shown = ads.showRewarded(intent);
      await settle();
      harness.endAd(RewardedShowResult.dismissedEarly);
      expect(expectOk(await shown), RewardedShowResult.dismissedEarly);
    });
  });
}
