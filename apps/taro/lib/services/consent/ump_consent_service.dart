import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:taro_core/taro_core.dart';

/// Shows a UMP form and completes with its error (`null` when it closed
/// normally or was not needed).
typedef UmpFormCall = Future<gma.FormError?> Function();

/// [ConsentService] over Google UMP (`ConsentInformation`, `ConsentForm` of
/// `google_mobile_ads`; 02 §5, §9.7, 04 §10).
///
/// [gather] runs `requestConsentInfoUpdate` with
/// `tagForUnderAgeOfConsent: false` (05 CS4, RC93) on every call (UMP needs
/// it once per launch), then `loadAndShowConsentFormIfRequired`. A failed
/// update or form is logged and the cached SDK state is returned: UMP keeps
/// `canRequestAds` from the previous session.
///
/// The debug geography (EEA) is honoured only when [allowDebugGeography]
/// is set, i.e. in non-prod builds from the hidden debug menu (02 §15).
final class UmpConsentService implements ConsentService {
  /// An adapter over the SDK singletons, or [info] and the form calls in
  /// tests.
  UmpConsentService({
    required Logger logger,
    this.allowDebugGeography = false,
    this.debugTestDeviceIds = const [],
    gma.ConsentInformation? info,
    UmpFormCall? loadAndShowIfRequired,
    UmpFormCall? showPrivacyOptionsForm,
  }) : _logger = logger,
       _info = info ?? gma.ConsentInformation.instance,
       _loadAndShow = loadAndShowIfRequired ?? _defaultLoadAndShow,
       _showPrivacy = showPrivacyOptionsForm ?? _defaultShowPrivacyOptions;

  /// Whether `gather(debugEea: true)` may force the EEA geography
  /// (`!FlavorConfig.isProd`).
  final bool allowDebugGeography;

  /// Hashed device IDs the debug geography applies to (simulators need
  /// none).
  final List<String> debugTestDeviceIds;

  final Logger _logger;
  final gma.ConsentInformation _info;
  final UmpFormCall _loadAndShow;
  final UmpFormCall _showPrivacy;

  static Future<gma.FormError?> _defaultLoadAndShow() {
    final done = Completer<gma.FormError?>();
    unawaited(gma.ConsentForm.loadAndShowConsentFormIfRequired(done.complete));
    return done.future;
  }

  static Future<gma.FormError?> _defaultShowPrivacyOptions() {
    final done = Completer<gma.FormError?>();
    unawaited(gma.ConsentForm.showPrivacyOptionsForm(done.complete));
    return done.future;
  }

  /// The request parameters for [gather] (`debugEea` already gated).
  gma.ConsentRequestParameters requestParameters({required bool debugEea}) =>
      gma.ConsentRequestParameters(
        tagForUnderAgeOfConsent: false,
        consentDebugSettings: debugEea
            ? gma.ConsentDebugSettings(
                debugGeography: gma.DebugGeography.debugGeographyEea,
                testIdentifiers: debugTestDeviceIds,
              )
            : null,
      );

  @override
  Future<AdsConsent> gather({bool debugEea = false}) async {
    final params = requestParameters(
      debugEea: debugEea && allowDebugGeography,
    );
    if (await _requestUpdate(params)) {
      await _form('consent form', _loadAndShow);
    }
    return current();
  }

  @override
  Future<void> showPrivacyOptions() => _form('privacy options', _showPrivacy);

  @override
  Future<AdsConsent> current() async {
    try {
      final status = await _info.getConsentStatus();
      final canRequestAds = await _info.canRequestAds();
      final privacy = await _info.getPrivacyOptionsRequirementStatus();
      return AdsConsent(
        status: mapConsentStatus(status),
        canRequestAds: canRequestAds,
        privacyOptionsRequired:
            privacy == gma.PrivacyOptionsRequirementStatus.required,
      );
    } on Object catch (error, stack) {
      _logger.warning('ump state unavailable', error: error, stack: stack);
      return const AdsConsent();
    }
  }

  Future<bool> _requestUpdate(gma.ConsentRequestParameters params) {
    final done = Completer<bool>();
    try {
      _info.requestConsentInfoUpdate(
        params,
        () => done.complete(true),
        (error) {
          _logger.warning('ump update failed: ${error.errorCode}');
          done.complete(false);
        },
      );
    } on Object catch (error, stack) {
      _logger.warning('ump update threw', error: error, stack: stack);
      done.complete(false);
    }
    return done.future;
  }

  Future<void> _form(String what, UmpFormCall call) async {
    try {
      final error = await call();
      if (error != null) {
        _logger.warning('ump $what failed: ${error.errorCode}');
      }
    } on Object catch (error, stack) {
      _logger.warning('ump $what threw', error: error, stack: stack);
    }
  }
}

/// The domain status of the SDK's [status].
AdsConsentStatus mapConsentStatus(gma.ConsentStatus status) => switch (status) {
  gma.ConsentStatus.notRequired => AdsConsentStatus.notRequired,
  gma.ConsentStatus.obtained => AdsConsentStatus.obtained,
  gma.ConsentStatus.required => AdsConsentStatus.required,
  gma.ConsentStatus.unknown => AdsConsentStatus.unknown,
};

/// [ConsentService] without UMP (tests, dev without ads): consent is not
/// required and ads may be requested (02 §5).
final class NoOpConsentService implements ConsentService {
  /// Creates the no-op service.
  const NoOpConsentService();

  static const _state = AdsConsent(
    status: AdsConsentStatus.notRequired,
    canRequestAds: true,
  );

  @override
  Future<AdsConsent> gather({bool debugEea = false}) async => _state;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<AdsConsent> current() async => _state;
}
