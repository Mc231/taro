part of '../taro_analytics_event.dart';

/// App-level notice events (01 §15 `AppEvent`).
sealed class AppEvent extends TaroAnalyticsEvent {
  const AppEvent._() : super._();
}

/// `app_update_required_shown`: S30 was shown.
final class AppUpdateRequiredShownEvent extends AppEvent {
  /// Creates the event.
  const AppUpdateRequiredShownEvent({required this.origin}) : super._();

  /// When it was shown.
  final AppNoticeOrigin origin;

  @override
  String get eventName => 'app_update_required_shown';

  @override
  Map<String, Object> get parameters => {'origin': origin.wire};
}

/// `app_update_available_shown`: the soft update banner was shown.
final class AppUpdateAvailableShownEvent extends AppEvent {
  /// Creates the event.
  const AppUpdateAvailableShownEvent({required this.origin}) : super._();

  /// When it was shown.
  final AppNoticeOrigin origin;

  @override
  String get eventName => 'app_update_available_shown';

  @override
  Map<String, Object> get parameters => {'origin': origin.wire};
}

/// `readings_paused_shown`: S31 was shown (RC47).
final class ReadingsPausedShownEvent extends AppEvent {
  /// Creates the event.
  const ReadingsPausedShownEvent({required this.origin}) : super._();

  /// When it was shown.
  final AppNoticeOrigin origin;

  @override
  String get eventName => 'readings_paused_shown';

  @override
  Map<String, Object> get parameters => {'origin': origin.wire};
}

/// `device_unverified_shown`: the device-unverified state was shown.
final class DeviceUnverifiedShownEvent extends AppEvent {
  /// Creates the event.
  const DeviceUnverifiedShownEvent({required this.origin}) : super._();

  /// When it was shown.
  final AppNoticeOrigin origin;

  @override
  String get eventName => 'device_unverified_shown';

  @override
  Map<String, Object> get parameters => {'origin': origin.wire};
}

/// `rate_prompt_shown`: the in-app review prompt was requested.
final class RatePromptShownEvent extends AppEvent {
  /// Creates the event.
  const RatePromptShownEvent() : super._();

  @override
  String get eventName => 'rate_prompt_shown';

  @override
  Map<String, Object> get parameters => const {};
}
