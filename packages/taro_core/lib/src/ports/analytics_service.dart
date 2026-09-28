import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/analytics/taro_analytics_event.dart';

part 'analytics_service.freezed.dart';

/// Firebase consent-mode signals (02 §9.7, RC68).
@freezed
abstract class AnalyticsConsent with _$AnalyticsConsent {
  /// Creates a consent-mode setting.
  const factory AnalyticsConsent({
    /// `analytics_storage`.
    required bool analyticsStorage,

    /// `ad_storage`.
    required bool adStorage,

    /// `ad_user_data`.
    required bool adUserData,

    /// `ad_personalization`.
    required bool adPersonalization,
  }) = _AnalyticsConsent;

  /// Everything denied: the bootstrap default before consent resolves.
  factory AnalyticsConsent.allDenied() => const AnalyticsConsent(
    analyticsStorage: false,
    adStorage: false,
    adUserData: false,
    adPersonalization: false,
  );

  /// Everything granted (UMP: consent not required).
  factory AnalyticsConsent.allGranted() => const AnalyticsConsent(
    analyticsStorage: true,
    adStorage: true,
    adUserData: true,
    adPersonalization: true,
  );
}

/// Product analytics (02 §5, §13).
abstract interface class AnalyticsService {
  /// Logs [event] (typed only, rule 18).
  Future<void> log(TaroAnalyticsEvent event);

  /// Logs a screen view (`S01`…`S33`, GLOSSARY U23).
  Future<void> screen(String screenId);

  /// Enables or disables collection (Settings toggle).
  Future<void> setCollectionEnabled({required bool enabled});

  /// Sets Firebase consent mode.
  Future<void> setConsent(AnalyticsConsent consent);
}
