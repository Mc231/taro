import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// The micros in one currency unit (`purchase_completed.value`).
const int _microsPerUnit = 1000000;

/// The production `AnalyticsService` over Firebase Analytics (02 §5, §13,
/// AR19). The only file importing `firebase_analytics`.
///
/// No user ID is ever set and the install ID is never sent: events carry
/// bounded values only (PR18). It sits behind `ConsentAwareAnalytics`
/// (RC68); the composition root calls [setConsent] with
/// `AnalyticsConsent.allDenied()` before any event.
///
/// Firebase errors are logged and swallowed: analytics never breaks a flow.
final class FirebaseAnalyticsService implements TaroAnalyticsBackend {
  /// Creates the adapter over `analytics` (`FirebaseAnalytics.instance` in
  /// production, a platform fake in tests).
  FirebaseAnalyticsService(this._analytics, {required Logger logger})
    : _log = logger.child('analytics');

  /// The adapter over the plugin singleton (after `Firebase.initializeApp`).
  factory FirebaseAnalyticsService.fromPlugin({required Logger logger}) =>
      FirebaseAnalyticsService(FirebaseAnalytics.instance, logger: logger);

  final FirebaseAnalytics _analytics;
  final Logger _log;
  bool _enabled = true;

  /// Whether events are sent (the Settings toggle).
  bool get collectionEnabled => _enabled;

  @override
  Future<void> log(TaroAnalyticsEvent event) async {
    if (!_enabled) return;
    await _guard(event.eventName, () {
      if (event is ScreenViewEvent) {
        return _analytics.logScreenView(
          screenName: event.screen.wire,
          parameters: {'previous': ?event.previous?.wire},
        );
      }
      return _analytics.logEvent(
        name: event.eventName,
        parameters: firebaseParameters(event),
      );
    });
  }

  @override
  Future<void> screen(String screenId) async {
    if (!_enabled) return;
    await _guard(
      'screen_view',
      () => _analytics.logScreenView(screenName: screenId),
    );
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    _enabled = enabled;
    await _guard(
      'collection',
      () => _analytics.setAnalyticsCollectionEnabled(enabled),
    );
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) => _guard(
    'consent',
    () => _analytics.setConsent(
      analyticsStorageConsentGranted: consent.analyticsStorage,
      adStorageConsentGranted: consent.adStorage,
      adUserDataConsentGranted: consent.adUserData,
      adPersonalizationSignalsConsentGranted: consent.adPersonalization,
    ),
  );

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) async {
    for (final MapEntry(:key, :value) in properties.toWire().entries) {
      await _guard(
        'user_property',
        () => _analytics.setUserProperty(name: key, value: value),
      );
    }
  }

  /// [event]'s parameters in the types Firebase accepts (`String` or `num`):
  /// `bool` becomes `"true"`/`"false"`, and `purchase_completed.value`
  /// (micros, PR18) becomes currency units for the revenue reports.
  static Map<String, Object> firebaseParameters(TaroAnalyticsEvent event) => {
    for (final MapEntry(:key, :value) in event.parameters.entries)
      key: switch (value) {
        final bool flag => flag.toString(),
        final int micros
            when event is PurchaseCompletedEvent && key == 'value' =>
          micros / _microsPerUnit,
        final num number => number,
        _ => value.toString(),
      },
  };

  Future<void> _guard(String what, Future<void> Function() call) async {
    try {
      await call();
    } on Object catch (error, stack) {
      _log.warning('firebase $what failed', error: error, stack: stack);
    }
  }
}
