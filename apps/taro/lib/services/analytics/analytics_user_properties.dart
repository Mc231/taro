import 'package:flutter/foundation.dart';
import 'package:taro_core/taro_core.dart';

/// `ai_consent` user property values (01 §15).
enum AiConsentProperty with AnalyticsEnum {
  /// AI consent given.
  granted,

  /// AI consent declined or revoked.
  declined,

  /// Not asked yet.
  unknown,
}

/// The user properties of 01 §15 (`docs/ANALYTICS_EVENTS.md`). Same PR18
/// rules as events: bounded values only, never user content or an
/// identifier. A `null` field leaves the property unchanged.
@immutable
final class AnalyticsUserProperties {
  /// Creates a (partial) set of user properties.
  const AnalyticsUserProperties({
    this.appLocale,
    this.theme,
    this.reversalsEnabled,
    this.adsRemoved,
    this.aiConsent,
    this.hasPurchased,
    this.journalSizeBucket,
  });

  /// `app_locale`.
  final AnalyticsLocale? appLocale;

  /// `theme` (system|light|dark).
  final ThemeMode? theme;

  /// `reversals_enabled`.
  final bool? reversalsEnabled;

  /// `ads_removed`.
  final bool? adsRemoved;

  /// `ai_consent`.
  final AiConsentProperty? aiConsent;

  /// `has_purchased`.
  final bool? hasPurchased;

  /// `journal_size_bucket` (0|1-10|11-50|51-200|201+, the backup buckets).
  final EntriesBucket? journalSizeBucket;

  /// The set properties as Firebase user-property strings.
  Map<String, String> toWire() => {
    'app_locale': ?appLocale?.wire,
    'theme': ?switch (theme) {
      null => null,
      final theme => analyticsWire(theme),
    },
    'reversals_enabled': ?reversalsEnabled?.toString(),
    'ads_removed': ?adsRemoved?.toString(),
    'ai_consent': ?aiConsent?.wire,
    'has_purchased': ?hasPurchased?.toString(),
    'journal_size_bucket': ?journalSizeBucket?.wire,
  };

  /// These properties with every non-null field of [newer] applied on top.
  AnalyticsUserProperties merge(AnalyticsUserProperties newer) =>
      AnalyticsUserProperties(
        appLocale: newer.appLocale ?? appLocale,
        theme: newer.theme ?? theme,
        reversalsEnabled: newer.reversalsEnabled ?? reversalsEnabled,
        adsRemoved: newer.adsRemoved ?? adsRemoved,
        aiConsent: newer.aiConsent ?? aiConsent,
        hasPurchased: newer.hasPurchased ?? hasPurchased,
        journalSizeBucket: newer.journalSizeBucket ?? journalSizeBucket,
      );

  @override
  bool operator ==(Object other) =>
      other is AnalyticsUserProperties &&
      other.appLocale == appLocale &&
      other.theme == theme &&
      other.reversalsEnabled == reversalsEnabled &&
      other.adsRemoved == adsRemoved &&
      other.aiConsent == aiConsent &&
      other.hasPurchased == hasPurchased &&
      other.journalSizeBucket == journalSizeBucket;

  @override
  int get hashCode => Object.hash(
    appLocale,
    theme,
    reversalsEnabled,
    adsRemoved,
    aiConsent,
    hasPurchased,
    journalSizeBucket,
  );

  @override
  String toString() => 'AnalyticsUserProperties(${toWire()})';
}

/// An analytics backend of this folder: the `AnalyticsService` port plus
/// the user properties of 01 §15, which the port does not carry (02 §5); the
/// composition root reaches them through this interface.
abstract interface class TaroAnalyticsBackend implements AnalyticsService {
  /// Applies every non-null field of [properties].
  Future<void> setUserProperties(AnalyticsUserProperties properties);
}
