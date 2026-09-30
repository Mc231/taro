import 'dart:async';

import 'package:taro_core/taro_core.dart';

/// Shows the neutral in-app ATT pre-prompt (CS14 copy, single "Continue")
/// and completes when the user taps it. App UI, attached by the shell.
typedef AttPrePrompt = Future<void> Function();

/// The TCF v2.2 purpose consents string (`IABTCF_PurposeConsents`, e.g.
/// `"1101…"`, one digit per purpose) or `null` when it cannot be read.
typedef TcfPurposeSource = Future<String?> Function();

/// What one consent run decided.
typedef ConsentOutcome = ({
  AdsConsent ads,
  TrackingStatus tracking,
  AnalyticsConsent analytics,
  bool adsInitialized,
});

/// Firebase consent mode for the UMP answer [ads] and the TCF [purposes]
/// (02 §9.7, RC68).
///
/// Consent not required → everything granted. Consent obtained → from the
/// TCF purposes, Google's consent-mode mapping: `ad_storage` = P1,
/// `ad_user_data` = P1 + P7, `ad_personalization` = P3 + P4, and
/// `analytics_storage` = P1 + P8 (measure content performance). Anything
/// else, or no readable purposes, → everything denied.
AnalyticsConsent analyticsConsentFor(AdsConsent ads, String? purposes) {
  if (!ads.canRequestAds) return AnalyticsConsent.allDenied();
  if (ads.status == AdsConsentStatus.notRequired) {
    return AnalyticsConsent.allGranted();
  }
  if (ads.status != AdsConsentStatus.obtained || purposes == null) {
    return AnalyticsConsent.allDenied();
  }
  bool p(int purpose) =>
      purposes.length >= purpose && purposes[purpose - 1] == '1';
  return AnalyticsConsent(
    analyticsStorage: p(1) && p(8),
    adStorage: p(1),
    adUserData: p(1) && p(7),
    adPersonalization: p(3) && p(4),
  );
}

/// Runs the consent sequence once per launch (02 §9.1 step 7, §9.7; 04
/// §6.7, §10; 05 CS14; RC19, RC68):
///
/// onboarding reached the UMP step → UMP `gather` → Firebase consent mode
/// from the UMP purposes ([whenResolved] completes) → if `canRequestAds`
/// and ATT is `notDetermined` (iOS only; Android is `notSupported`): the
/// neutral pre-prompt when `ads.attPrepromptEnabled`, then the system
/// prompt → `AdsService.initialize` when the policy needs the SDK.
///
/// `canRequestAds == false` → no ATT, no pre-prompt and no SDK init this
/// launch; the persisted `consent.ads.canRequestAds == false` hides banners
/// (`BannerPolicy`) and disables rewarded with the "Ads unavailable" reason
/// (`EarnReward`). Never throws: a failing step is logged and treated as
/// denied, and [whenResolved] still completes.
final class ConsentOrchestrator {
  /// Creates the orchestrator; [policy] is read when the SDK would be
  /// initialised (`ads.enabled`, Remove Banner Ads and `rewarded.enabled`).
  ConsentOrchestrator({
    required ConsentService consent,
    required TrackingAuthorization tracking,
    required AdsService ads,
    required AnalyticsService analytics,
    required ConsentStore store,
    required RemoteConfigRepository config,
    required AdRequestPolicy Function() policy,
    required Logger logger,
    this.prePrompt,
    TcfPurposeSource? tcfPurposes,
    bool Function()? debugEea,
  }) : _consent = consent,
       _tracking = tracking,
       _ads = ads,
       _analytics = analytics,
       _store = store,
       _config = config,
       _policy = policy,
       _logger = logger,
       _tcfPurposes = tcfPurposes ?? _noPurposes,
       _debugEea = debugEea ?? _never;

  /// The neutral ATT pre-prompt; `null` skips it (the system prompt is
  /// still shown).
  AttPrePrompt? prePrompt;

  final ConsentService _consent;
  final TrackingAuthorization _tracking;
  final AdsService _ads;
  final AnalyticsService _analytics;
  final ConsentStore _store;
  final RemoteConfigRepository _config;
  final AdRequestPolicy Function() _policy;
  final Logger _logger;
  final TcfPurposeSource _tcfPurposes;
  final bool Function() _debugEea;

  final Completer<void> _resolved = Completer<void>();
  Future<ConsentOutcome>? _run;
  ConsentOutcome? _outcome;

  static Future<String?> _noPurposes() async => null;
  static bool _never() => false;

  /// Completes once UMP has answered and Firebase consent mode is set
  /// (`ConsentAwareAnalytics` flushes or drops its buffer then, RC68).
  Future<void> get whenResolved => _resolved.future;

  /// Whether [whenResolved] has completed.
  bool get isResolved => _resolved.isCompleted;

  /// The last outcome, `null` before the first run finished.
  ConsentOutcome? get outcome => _outcome;

  /// Runs the sequence; later calls return the same run. `null` while
  /// onboarding has not reached the UMP step (the product comes first,
  /// 01 PR10): onboarding calls [run] again when it gets there.
  Future<ConsentOutcome?> run() {
    final step = _store.current.onboardingStep;
    if (step.index < OnboardingStep.ump.index) {
      return Future<ConsentOutcome?>.value();
    }
    return _run ??= _gatherAndApply();
  }

  /// Shows the UMP privacy options form ("Privacy choices" in Settings) and
  /// applies the new answer the same way (a new `canRequestAds` may now
  /// allow ATT and the SDK).
  Future<ConsentOutcome> showPrivacyOptions() async {
    try {
      await _consent.showPrivacyOptions();
    } on Object catch (error, stack) {
      _logger.warning('privacy options failed', error: error, stack: stack);
    }
    return _apply(await _safe('ump current', _consent.current));
  }

  Future<ConsentOutcome> _gatherAndApply() async {
    await _analytics.setConsent(AnalyticsConsent.allDenied());
    final ads = await _safe(
      'ump gather',
      () => _consent.gather(debugEea: _debugEea()),
    );
    return _apply(ads);
  }

  Future<ConsentOutcome> _apply(AdsConsent ads) async {
    var analytics = AnalyticsConsent.allDenied();
    try {
      await _persist((s) => s.copyWith(ads: ads));
      analytics = analyticsConsentFor(ads, await _tcfPurposes());
      await _analytics.setConsent(analytics);
    } on Object catch (error, stack) {
      _logger.warning('consent mode failed', error: error, stack: stack);
    } finally {
      if (!_resolved.isCompleted) _resolved.complete();
    }
    var tracking = _store.current.tracking;
    var initialized = _ads.isInitialized;
    if (ads.canRequestAds) {
      tracking = await _askTracking();
      await _persist((s) => s.copyWith(tracking: tracking));
      initialized = await _initializeAds();
    }
    final outcome = (
      ads: ads,
      tracking: tracking,
      analytics: analytics,
      adsInitialized: initialized,
    );
    _logger.info(
      'consent: ${ads.status.name} ads=${ads.canRequestAds} '
      'att=${tracking.name} init=$initialized',
    );
    return _outcome = outcome;
  }

  Future<TrackingStatus> _askTracking() async {
    try {
      final status = await _tracking.status();
      if (status != TrackingStatus.notDetermined) return status;
      final show = prePrompt;
      if (_config.current.adsAttPrepromptEnabled && show != null) {
        await show();
      }
      return await _tracking.request();
    } on Object catch (error, stack) {
      _logger.warning('att failed', error: error, stack: stack);
      return TrackingStatus.denied;
    }
  }

  Future<bool> _initializeAds() async {
    if (_ads.isInitialized) return true;
    final policy = _policy();
    if (!policy.needsSdk) return false;
    try {
      await _ads.initialize(policy);
    } on Object catch (error, stack) {
      _logger.warning('ads init failed', error: error, stack: stack);
    }
    return _ads.isInitialized;
  }

  Future<void> _persist(ConsentState Function(ConsentState) change) async {
    final saved = await _store.update(change);
    if (saved case Err(:final failure)) {
      _logger.warning('consent not saved: ${failure.code}');
    }
  }

  Future<AdsConsent> _safe(
    String what,
    Future<AdsConsent> Function() call,
  ) async {
    try {
      return await call();
    } on Object catch (error, stack) {
      _logger.warning('$what failed', error: error, stack: stack);
      return const AdsConsent();
    }
  }
}
