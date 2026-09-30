import 'dart:async';

import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// Wires `ConsentOrchestrator` to `ConsentAwareAnalytics` (RC68).
///
/// The orchestrator sets the Firebase consent mode through this tap, which
/// passes every call to [inner] and remembers the last consent mode; once
/// the orchestrator's `whenResolved` completes, [resolve] completes
/// [resolved] with that mode, which releases or drops the analytics buffer.
final class AnalyticsConsentTap implements TaroAnalyticsBackend {
  /// A tap in front of [inner].
  AnalyticsConsentTap(this.inner);

  /// The decorated backend (the consent-aware analytics).
  final TaroAnalyticsBackend inner;

  final Completer<AnalyticsConsent> _resolved = Completer<AnalyticsConsent>();
  AnalyticsConsent _last = AnalyticsConsent.allDenied();

  /// The consent mode at resolution (all denied until then).
  Future<AnalyticsConsent> get resolved => _resolved.future;

  /// Completes [resolved] with the last consent mode (once).
  void resolve() {
    if (!_resolved.isCompleted) _resolved.complete(_last);
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) {
    _last = consent;
    return inner.setConsent(consent);
  }

  @override
  Future<void> log(TaroAnalyticsEvent event) => inner.log(event);

  @override
  Future<void> screen(String screenId) => inner.screen(screenId);

  @override
  Future<void> setCollectionEnabled({required bool enabled}) =>
      inner.setCollectionEnabled(enabled: enabled);

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) =>
      inner.setUserProperties(properties);
}
