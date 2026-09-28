import 'package:taro_core/src/model/consent_state.dart';

/// App Tracking Transparency (iOS; `notSupported` elsewhere, 02 §5, §9.7).
/// The neutral pre-prompt is app UI shown before [request].
abstract interface class TrackingAuthorization {
  /// The current status without prompting.
  Future<TrackingStatus> status();

  /// Shows the system prompt (only after UMP and `canRequestAds`, RC19).
  Future<TrackingStatus> request();
}
