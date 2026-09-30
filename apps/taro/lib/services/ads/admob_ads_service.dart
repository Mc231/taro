import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:taro_core/taro_core.dart';

/// Initialises the Mobile Ads SDK (`MobileAds.instance.initialize`).
typedef AdsSdkInitializer = Future<void> Function();

/// Starts loading a rewarded ad (`RewardedAd.load`).
typedef RewardedAdLoader =
    Future<void> Function({
      required String adUnitId,
      required gma.AdRequest request,
      required gma.RewardedAdLoadCallback rewardedAdLoadCallback,
    });

/// [AdsService] over AdMob (`google_mobile_ads`; 02 §5, §9.6, 04 §6.6, §9).
///
/// - [initialize] runs only when `ConsentOrchestrator` says `canRequestAds`
///   (RC19); before it nothing is loaded or shown.
/// - Rewarded ads are loaded lazily ([preloadRewarded] when S10/S11 opens,
///   or on [showRewarded]) and a loaded ad is kept for [rewardedLifetime]
///   (AdMob guidance), then replaced.
/// - A load that does not finish within `loadTimeout`
///   (`rewarded.loadTimeoutSec`) is `noFill`; the late ad is kept for the
///   next attempt.
/// - [showRewarded] binds SSV to the intent: `userId` = `customData` =
///   `intentId`, never the install ID (RC56). The result is `earned` when
///   `onUserEarnedReward` fired before the ad closed, else `dismissedEarly`;
///   a show error is `failedToShow`. The client never grants (MO10).
/// - Requests are non-personalised (`npa`) while `nonPersonalizedAds` says
///   the user did not consent to ad personalisation (04 §10).
final class AdMobAdsService implements AdsService {
  /// An adapter for [rewardedAdUnitId] (from `FlavorConfig`); [initializer]
  /// and [loadRewarded] default to the SDK.
  AdMobAdsService({
    required String rewardedAdUnitId,
    required Clock clock,
    required Logger logger,
    required Duration Function() loadTimeout,
    required bool Function() nonPersonalizedAds,
    AdsSdkInitializer? initializer,
    RewardedAdLoader? loadRewarded,
  }) : _adUnitId = rewardedAdUnitId,
       _clock = clock,
       _logger = logger,
       _loadTimeout = loadTimeout,
       _nonPersonalized = nonPersonalizedAds,
       _initializer = initializer ?? _initializeSdk,
       _loadRewarded = loadRewarded ?? gma.RewardedAd.load;

  /// How long a loaded rewarded ad stays usable (04 §6.6).
  static const Duration rewardedLifetime = Duration(hours: 1);

  final String _adUnitId;
  final Clock _clock;
  final Logger _logger;
  final Duration Function() _loadTimeout;
  final bool Function() _nonPersonalized;
  final AdsSdkInitializer _initializer;
  final RewardedAdLoader _loadRewarded;

  final Completer<void> _ready = Completer<void>();
  AdRequestPolicy? _policy;
  Future<void>? _initializing;
  gma.RewardedAd? _cached;
  DateTime? _loadedAt;
  Future<gma.RewardedAd?>? _loading;

  static Future<void> _initializeSdk() => gma.MobileAds.instance.initialize();

  @override
  bool get isInitialized => _ready.isCompleted;

  /// Completes when the SDK is initialised (banners wait for it).
  Future<void> get whenInitialized => _ready.future;

  /// The ad request for the current consent.
  gma.AdRequest adRequest() =>
      adRequestFor(nonPersonalized: _nonPersonalized());

  @override
  Future<void> initialize(AdRequestPolicy policy) {
    if (isInitialized || !policy.needsSdk) return Future<void>.value();
    _policy = policy;
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initializer();
      _ready.complete();
    } on Object catch (error, stack) {
      _logger.warning('ads init failed', error: error, stack: stack);
      _initializing = null;
    }
  }

  bool get _rewardedAllowed =>
      isInitialized && (_policy?.rewardedEnabled ?? false);

  @override
  Future<void> preloadRewarded() async {
    if (!_rewardedAllowed) return;
    await _obtain();
  }

  @override
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent) async {
    if (!_rewardedAllowed) return const Result.ok(RewardedShowResult.noFill);
    final ad = await _obtain();
    if (ad == null) return const Result.ok(RewardedShowResult.noFill);
    _cached = null;
    final result = await _show(ad, intent.intentId.value);
    await _dispose(ad);
    return Result.ok(result);
  }

  Future<RewardedShowResult> _show(gma.RewardedAd ad, String intentId) async {
    final done = Completer<RewardedShowResult>();
    void finish(RewardedShowResult result) {
      if (!done.isCompleted) done.complete(result);
    }

    var earned = false;
    ad.fullScreenContentCallback =
        gma.FullScreenContentCallback<gma.RewardedAd>(
          onAdFailedToShowFullScreenContent: (_, error) {
            _logger.warning('rewarded show failed: ${error.code}');
            finish(RewardedShowResult.failedToShow);
          },
          onAdDismissedFullScreenContent: (_) => finish(
            earned
                ? RewardedShowResult.earned
                : RewardedShowResult.dismissedEarly,
          ),
        );
    try {
      await ad.setServerSideOptions(
        gma.ServerSideVerificationOptions(
          userId: intentId,
          customData: intentId,
        ),
      );
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } on Object catch (error, stack) {
      _logger.warning('rewarded show threw', error: error, stack: stack);
      finish(RewardedShowResult.failedToShow);
    }
    return done.future;
  }

  /// A fresh loaded ad, loading one within the timeout when needed.
  Future<gma.RewardedAd?> _obtain() async {
    final cached = _cached;
    final loadedAt = _loadedAt;
    if (cached != null && loadedAt != null) {
      if (_clock.now().difference(loadedAt) < rewardedLifetime) return cached;
      _cached = null;
      await _dispose(cached);
    }
    final loading = _loading ??= _load();
    return loading.timeout(
      _loadTimeout(),
      onTimeout: () {
        _logger.info('rewarded load timed out');
        return null;
      },
    );
  }

  Future<gma.RewardedAd?> _load() async {
    final done = Completer<gma.RewardedAd?>();
    try {
      await _loadRewarded(
        adUnitId: _adUnitId,
        request: adRequest(),
        rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _cached = ad;
            _loadedAt = _clock.now();
            done.complete(ad);
          },
          onAdFailedToLoad: (error) {
            _logger.info('rewarded no fill: ${error.code}');
            done.complete(null);
          },
        ),
      );
    } on Object catch (error, stack) {
      _logger.warning('rewarded load threw', error: error, stack: stack);
      if (!done.isCompleted) done.complete(null);
    }
    try {
      return await done.future;
    } finally {
      _loading = null;
    }
  }

  Future<void> _dispose(gma.Ad ad) async {
    try {
      await ad.dispose();
    } on Object catch (error, stack) {
      _logger.fine('ad dispose failed', error: error, stack: stack);
    }
  }
}

/// An AdMob request; `npa` when [nonPersonalized] (04 §10).
gma.AdRequest adRequestFor({required bool nonPersonalized}) =>
    gma.AdRequest(nonPersonalizedAds: nonPersonalized ? true : null);
