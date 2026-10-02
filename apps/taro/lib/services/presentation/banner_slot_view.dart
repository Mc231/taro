import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:taro/services/ads/admob_ads_service.dart';
import 'package:taro_core/taro_core.dart';

/// The banner presentation port (02 §5): `BannerSlot` (`common/`) asks it
/// for the ad of a [BannerScreen] of `kBannerAllowList` once
/// `BannerPolicy.shouldShow` holds. It returns a `Widget`, so it lives in
/// the app, not in `taro_core`.
// ignore: one_member_abstracts
abstract interface class BannerSlotView {
  /// The banner for [screen]; zero-sized unless [visible].
  Widget build(BannerScreen screen, {required bool visible});
}

/// [BannerSlotView] without ads (Remove Banner Ads, ads disabled, tests):
/// always zero-sized.
final class NoOpBannerSlotView implements BannerSlotView {
  /// Creates the no-op view.
  const NoOpBannerSlotView();

  @override
  Widget build(BannerScreen screen, {required bool visible}) =>
      const SizedBox.shrink();
}

/// Finds the anchored adaptive size for a slot [width] (logical pixels).
typedef AnchoredSizeLookup = Future<gma.AdSize?> Function(int width);

/// Builds the platform view of a loaded banner.
typedef AdWidgetBuilder = Widget Function(gma.AdWithView ad);

/// [BannerSlotView] over an AdMob anchored adaptive banner (02 §10, 04
/// §6.6, §8).
///
/// The banner loads on the first build of a visible slot, after [ready]
/// (the SDK initialised after UMP, RC19), and is disposed on unmount. It
/// stays zero-sized until the ad has loaded and collapses back to zero on
/// any failure (no fill, offline, no size), so content never jumps under a
/// grey box.
final class AdMobBannerSlotView implements BannerSlotView {
  /// A view for [adUnitId] (from `FlavorConfig`).
  const AdMobBannerSlotView({
    required this.adUnitId,
    required this.ready,
    required this.nonPersonalizedAds,
    required this.logger,
    this.analytics,
    this.anchoredSize = gma.AdSize.getLargeAnchoredAdaptiveBannerAdSize,
    this.adWidget = defaultAdWidget,
  });

  /// The banner ad unit.
  final String adUnitId;

  /// Completes when ads may be requested (`AdMobAdsService.whenInitialized`).
  final Future<void> Function() ready;

  /// Whether requests must be non-personalised (04 §10).
  final bool Function() nonPersonalizedAds;

  /// Logs load failures (never ad content).
  final Logger logger;

  /// Receives `ad_banner_impression` / `ad_banner_failed` (04 §14).
  final AnalyticsService? analytics;

  /// The adaptive size lookup (the SDK by default).
  final AnchoredSizeLookup anchoredSize;

  /// The platform view of a loaded ad.
  final AdWidgetBuilder adWidget;

  /// The SDK's `AdWidget`.
  static Widget defaultAdWidget(gma.AdWithView ad) => gma.AdWidget(ad: ad);

  @override
  Widget build(BannerScreen screen, {required bool visible}) => visible
      ? AdMobBanner(key: ValueKey(screen), view: this, screen: screen)
      : const SizedBox.shrink();
}

/// One loaded-on-mount AdMob banner of [view].
class AdMobBanner extends StatefulWidget {
  /// Creates the banner.
  const AdMobBanner({
    required this.view,
    this.screen = BannerScreen.home,
    super.key,
  });

  /// Configuration.
  final AdMobBannerSlotView view;

  /// The `kBannerAllowList` screen it is on (the analytics `screen_id`).
  final BannerScreen screen;

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  gma.BannerAd? _ad;
  bool _loaded = false;
  bool _started = false;
  bool _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load(MediaQuery.sizeOf(context).width.truncate()));
  }

  Future<void> _load(int width) async {
    final view = widget.view;
    try {
      await view.ready();
      if (_disposed) return;
      final size = await view.anchoredSize(width);
      if (size == null || _disposed) return;
      final ad = gma.BannerAd(
        size: size,
        adUnitId: view.adUnitId,
        request: adRequestFor(nonPersonalized: view.nonPersonalizedAds()),
        listener: gma.BannerAdListener(
          onAdLoaded: (_) {
            _update(() => _loaded = true);
            _log(AdBannerImpressionEvent(screenId: widget.screen));
          },
          onAdFailedToLoad: (ad, error) {
            view.logger.info('banner no fill: ${error.code}');
            _log(
              AdBannerFailedEvent(
                screenId: widget.screen,
                errorCode: error.code,
              ),
            );
            _collapse();
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } on Object catch (error, stack) {
      view.logger.warning('banner load failed', error: error, stack: stack);
      _log(AdBannerFailedEvent(screenId: widget.screen));
      _collapse();
    }
  }

  void _log(TaroAnalyticsEvent event) {
    final analytics = widget.view.analytics;
    if (analytics != null && !_disposed) unawaited(analytics.log(event));
  }

  void _collapse() {
    final ad = _ad;
    _ad = null;
    _update(() => _loaded = false);
    if (ad != null) unawaited(ad.dispose());
  }

  void _update(VoidCallback change) {
    if (_disposed) return;
    setState(change);
  }

  @override
  void dispose() {
    _disposed = true;
    final ad = _ad;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: widget.view.adWidget(ad),
    );
  }
}
