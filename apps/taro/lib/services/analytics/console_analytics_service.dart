import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// Echoes analytics to the `Logger` (logger `taro.analytics.console`, level
/// FINE) so the dev flavor shows what would be sent (02 §5, §13). Events
/// carry bounded values only (PR18), so nothing sensitive is logged.
final class ConsoleAnalyticsService implements TaroAnalyticsBackend {
  /// Creates the console backend.
  ConsoleAnalyticsService({required Logger logger})
    : _log = logger.child('analytics').child('console');

  final Logger _log;
  bool _enabled = true;

  @override
  Future<void> log(TaroAnalyticsEvent event) async {
    if (_enabled) _log.fine('event ${event.eventName} ${event.parameters}');
  }

  @override
  Future<void> screen(String screenId) async {
    if (_enabled) _log.fine('screen $screenId');
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    _enabled = enabled;
    _log.fine('collection ${enabled ? 'on' : 'off'}');
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) async => _log.fine(
    'consent analytics=${consent.analyticsStorage} ad=${consent.adStorage} '
    'ad_user_data=${consent.adUserData} '
    'ad_personalization=${consent.adPersonalization}',
  );

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) async {
    if (_enabled) _log.fine('user properties ${properties.toWire()}');
  }
}

/// The `AnalyticsService` that drops everything (analytics disabled, tests;
/// 02 §5, 06 §3).
final class NoOpAnalyticsService implements TaroAnalyticsBackend {
  /// Creates the no-op backend.
  const NoOpAnalyticsService();

  @override
  Future<void> log(TaroAnalyticsEvent event) async {}

  @override
  Future<void> screen(String screenId) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}

  @override
  Future<void> setConsent(AnalyticsConsent consent) async {}

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) async {}
}
