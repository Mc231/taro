import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// Fans every call out to several backends, in order (02 §13: Firebase plus
/// the console in dev). A backend that throws is logged and skipped; the
/// others still receive the call.
final class CompositeAnalyticsService implements TaroAnalyticsBackend {
  /// Creates a composite over [backends].
  CompositeAnalyticsService(
    List<TaroAnalyticsBackend> backends, {
    required Logger logger,
  }) : _backends = List.unmodifiable(backends),
       _log = logger.child('analytics');

  final List<TaroAnalyticsBackend> _backends;
  final Logger _log;

  @override
  Future<void> log(TaroAnalyticsEvent event) => _each((b) => b.log(event));

  @override
  Future<void> screen(String screenId) => _each((b) => b.screen(screenId));

  @override
  Future<void> setCollectionEnabled({required bool enabled}) =>
      _each((b) => b.setCollectionEnabled(enabled: enabled));

  @override
  Future<void> setConsent(AnalyticsConsent consent) =>
      _each((b) => b.setConsent(consent));

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) =>
      _each((b) => b.setUserProperties(properties));

  Future<void> _each(
    Future<void> Function(TaroAnalyticsBackend backend) call,
  ) async {
    for (final backend in _backends) {
      try {
        await call(backend);
      } on Object catch (error, stack) {
        _log.warning(
          '${backend.runtimeType} failed',
          error: error,
          stack: stack,
        );
      }
    }
  }
}
