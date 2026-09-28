import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements AdsServiceHarness {
  final FakeAdsService ads = FakeAdsService();

  @override
  AdsService get subject => ads;

  @override
  void endAd(RewardedShowResult result) => ads.finishRewarded(result);
}

void main() {
  runAdsServiceContract(_Harness.new);

  group('FakeAdsService hooks', () {
    final intent = RewardIntent(
      intentId: const IntentId('i'),
      amount: 1,
      expiresAt: kTestNow,
    );

    test('completeRewarded and dismissRewarded end the ad', () async {
      final ads = FakeAdsService();
      final earned = ads.showRewarded(intent);
      expect(ads.isShowing, isTrue);
      ads.completeRewarded();
      expect(expectOk(await earned), RewardedShowResult.earned);
      final dismissed = ads.showRewarded(intent);
      ads.dismissRewarded();
      expect(expectOk(await dismissed), RewardedShowResult.dismissedEarly);
      expect(ads.isShowing, isFalse);
      expect(ads.completeRewarded, throwsStateError);
    });

    test('autoResult, nextShow and failNext answer at once', () async {
      final ads = FakeAdsService(autoResult: RewardedShowResult.noFill)
        ..nextShow(RewardedShowResult.failedToShow)
        ..failNext(const Failure.network());
      expect((await ads.showRewarded(intent)).isErr, isTrue);
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.failedToShow,
      );
      expect(
        expectOk(await ads.showRewarded(intent)),
        RewardedShowResult.noFill,
      );
      expect(ads.shown, hasLength(3));
      await ads.preloadRewarded();
      await ads.initialize(
        const AdRequestPolicy(bannersEnabled: false, rewardedEnabled: true),
      );
      expect(ads.preloads, 1);
      expect(ads.policy?.needsSdk, isTrue);
    });
  });
}
