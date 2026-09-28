part of '../taro_analytics_event.dart';

/// Consent events (01 §15 `ConsentEvent`; UMP and ATT per 04 §14).
sealed class ConsentEvent extends TaroAnalyticsEvent {
  const ConsentEvent._() : super._();
}

/// `ai_consent_decided`: the AI data-sharing choice was made.
final class AiConsentDecidedEvent extends ConsentEvent {
  /// Creates the event.
  const AiConsentDecidedEvent({
    required this.granted,
    required this.origin,
    required this.consentVersion,
  }) : super._();

  /// Whether consent was granted.
  final bool granted;

  /// Where the choice was made.
  final AiConsentOrigin origin;

  /// The disclosure version shown (`ai.consentVersion`).
  final int consentVersion;

  @override
  String get eventName => 'ai_consent_decided';

  @override
  Map<String, Object> get parameters => {
    'granted': granted,
    'origin': origin.wire,
    'consent_version': consentVersion,
  };
}

/// `consent_ump_result`: the UMP flow finished.
final class ConsentUmpResultEvent extends ConsentEvent {
  /// Creates the event.
  const ConsentUmpResultEvent({
    required this.status,
    required this.formShown,
    required this.canRequestAds,
  }) : super._();

  /// The UMP outcome.
  final UmpResultStatus status;

  /// Whether the consent form was shown.
  final bool formShown;

  /// Whether ads may be requested.
  final bool canRequestAds;

  @override
  String get eventName => 'consent_ump_result';

  @override
  Map<String, Object> get parameters => {
    'status': status.wire,
    'form_shown': formShown,
    'can_request_ads': canRequestAds,
  };
}

/// `consent_att_result`: the ATT prompt finished (iOS).
final class ConsentAttResultEvent extends ConsentEvent {
  /// Creates the event.
  const ConsentAttResultEvent({
    required this.status,
    required this.prepromptShown,
  }) : super._();

  /// The ATT outcome.
  final AttResultStatus status;

  /// Whether the neutral pre-prompt was shown.
  final bool prepromptShown;

  @override
  String get eventName => 'consent_att_result';

  @override
  Map<String, Object> get parameters => {
    'status': status.wire,
    'preprompt_shown': prepromptShown,
  };
}

/// `analytics_toggled`: the Settings analytics toggle changed.
final class AnalyticsToggledEvent extends ConsentEvent {
  /// Creates the event.
  const AnalyticsToggledEvent({required this.enabled}) : super._();

  /// The new state.
  final bool enabled;

  @override
  String get eventName => 'analytics_toggled';

  @override
  Map<String, Object> get parameters => {'enabled': enabled};
}
