import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/ports/reward_gateway.dart';
import 'package:taro_core/src/ports/rewarded_show_result.dart';
import 'package:taro_core/src/result/result.dart';

part 'ads_service.freezed.dart';

/// What the ads SDK is initialised for (02 §9.1 step 7).
@freezed
abstract class AdRequestPolicy with _$AdRequestPolicy {
  /// Creates a policy.
  const factory AdRequestPolicy({
    /// Banners may be requested (`ads.enabled`, `ads.bannerEnabled`, Remove
    /// Banner Ads not owned).
    required bool bannersEnabled,

    /// Rewarded ads may be requested (`ads.enabled`, `rewarded.enabled`).
    required bool rewardedEnabled,
  }) = _AdRequestPolicy;

  const AdRequestPolicy._();

  /// Whether the SDK needs initialising at all.
  bool get needsSdk => bannersEnabled || rewardedEnabled;
}

/// The ads SDK (AdMob, 02 §5, 04 §6.6). Initialised only after UMP says
/// `canRequestAds` (RC19). Rewarded ads are always user-initiated.
abstract interface class AdsService {
  /// Initialises the SDK for [policy].
  Future<void> initialize(AdRequestPolicy policy);

  /// Loads a rewarded ad when S10/S11 opens and rewarded is eligible.
  Future<void> preloadRewarded();

  /// Shows a rewarded ad bound to [intent] (SSV `customData` = `userId` =
  /// intent ID, never the install ID, RC56).
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent);

  /// Whether [initialize] has completed.
  bool get isInitialized;
}
