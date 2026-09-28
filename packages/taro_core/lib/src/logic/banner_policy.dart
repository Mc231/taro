import 'package:taro_core/src/model/entitlement.dart';
import 'package:taro_core/src/model/remote_config.dart';

// `kBannerAllowList` lives with `RemoteConfig` (model), which clamps
// `ads.bannerScreens` to it; re-exported for banner callers.
export 'package:taro_core/src/model/remote_config.dart' show kBannerAllowList;

/// A banner screen ID of [kBannerAllowList] (02 §5 `BannerSlotView`).
enum BannerScreen {
  /// S05 Home.
  home('home'),

  /// S14 Journal list.
  journalList('journal_list'),

  /// S16 Learn deck browser.
  learnLibrary('learn_library');

  const BannerScreen(this.id);

  /// The banner screen ID (`ads.bannerScreens` value, `screen_id` param).
  final String id;

  /// The screen with [id], or `null` for a screen that never has a banner.
  static BannerScreen? fromId(String id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Whether a screen shows its banner (01 PR13, 04 §8, RC18).
abstract final class BannerPolicy {
  /// `ads.enabled && ads.bannerEnabled && screenId ∈ (kBannerAllowList ∩
  /// ads.bannerScreens) && !removeAds && canRequestAds && completedReadings
  /// >= ads.bannerMinCompletedReadings`.
  ///
  /// [entitlement] `unknown` behaves as not owned; a cached `owned` hides
  /// banners (04 §6.4). [completedReadings] never counts Classic readings.
  static bool shouldShow(
    String screenId, {
    required RemoteConfig config,
    required Entitlement entitlement,
    required bool canRequestAds,
    required int completedReadings,
  }) =>
      config.adsEnabled &&
      config.adsBannerEnabled &&
      kBannerAllowList.contains(screenId) &&
      config.adsBannerScreens.contains(screenId) &&
      !entitlement.removesAds &&
      canRequestAds &&
      completedReadings >= config.adsBannerMinCompletedReadings;
}
