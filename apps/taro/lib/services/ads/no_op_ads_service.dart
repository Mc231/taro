import 'package:taro_core/taro_core.dart';

/// [AdsService] that never touches the SDK (02 §5, §9.1 step 7): used when
/// `ads.enabled == false`, when Remove Banner Ads is owned **and**
/// `rewarded.enabled == false` (nothing left to show), and in tests. Every
/// show answers `noFill`, so rewarded stays disabled with a reason.
final class NoOpAdsService implements AdsService {
  /// Creates the no-op service.
  const NoOpAdsService();

  /// Whether the app should bind [NoOpAdsService] instead of the AdMob
  /// adapter for [config] and [entitlement].
  static bool applies(RemoteConfig config, Entitlement entitlement) =>
      !config.adsEnabled || (entitlement.removesAds && !config.rewardedEnabled);

  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize(AdRequestPolicy policy) async {}

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent) async =>
      const Result.ok(RewardedShowResult.noFill);
}
