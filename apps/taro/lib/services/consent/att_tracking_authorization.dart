import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    as att;
import 'package:taro_core/taro_core.dart';

/// Reads or requests the ATT status from the SDK.
typedef AttStatusCall = Future<att.TrackingStatus> Function();

/// iOS [TrackingAuthorization] over `app_tracking_transparency` (02 §5,
/// §9.7). The neutral pre-prompt is app UI that `ConsentOrchestrator` shows
/// before [request] (RC19, CS14); this adapter never prompts on its own.
///
/// A failing platform call answers `denied`: no tracking, and the
/// orchestrator does not retry a prompt it cannot show.
final class AttTrackingAuthorization implements TrackingAuthorization {
  /// An adapter over the plugin's static calls, or [readStatus] /
  /// [requestAuthorization] in tests.
  AttTrackingAuthorization({
    required Logger logger,
    AttStatusCall? readStatus,
    AttStatusCall? requestAuthorization,
  }) : _logger = logger,
       _readStatus =
           readStatus ??
           (() => att.AppTrackingTransparency.trackingAuthorizationStatus),
       _request =
           requestAuthorization ??
           att.AppTrackingTransparency.requestTrackingAuthorization;

  final Logger _logger;
  final AttStatusCall _readStatus;
  final AttStatusCall _request;

  @override
  Future<TrackingStatus> status() => _call('status', _readStatus);

  @override
  Future<TrackingStatus> request() => _call('request', _request);

  Future<TrackingStatus> _call(String what, AttStatusCall call) async {
    try {
      return mapAttStatus(await call());
    } on Object catch (error, stack) {
      _logger.warning('att $what failed', error: error, stack: stack);
      return TrackingStatus.denied;
    }
  }
}

/// The domain status of the plugin's [status].
TrackingStatus mapAttStatus(att.TrackingStatus status) => switch (status) {
  att.TrackingStatus.notDetermined => TrackingStatus.notDetermined,
  att.TrackingStatus.restricted => TrackingStatus.restricted,
  att.TrackingStatus.denied => TrackingStatus.denied,
  att.TrackingStatus.authorized => TrackingStatus.authorized,
  att.TrackingStatus.notSupported => TrackingStatus.notSupported,
};

/// [TrackingAuthorization] where the platform has no ATT (Android): always
/// `notSupported`, never prompts (02 §5).
final class NotSupportedTrackingAuthorization implements TrackingAuthorization {
  /// Creates the Android binding.
  const NotSupportedTrackingAuthorization();

  @override
  Future<TrackingStatus> status() async => TrackingStatus.notSupported;

  @override
  Future<TrackingStatus> request() async => TrackingStatus.notSupported;
}
