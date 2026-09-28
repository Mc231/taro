part of '../taro_analytics_event.dart';

/// Reminder and notification events (01 §15 `NotificationEvent`).
sealed class NotificationEvent extends TaroAnalyticsEvent {
  const NotificationEvent._() : super._();
}

/// `reminder_offer_answered`: the daily reminder offer was answered.
final class ReminderOfferAnsweredEvent extends NotificationEvent {
  /// Creates the event.
  const ReminderOfferAnsweredEvent({required this.accepted}) : super._();

  /// Whether the offer was accepted.
  final bool accepted;

  @override
  String get eventName => 'reminder_offer_answered';

  @override
  Map<String, Object> get parameters => {'accepted': accepted};
}

/// `notification_permission_result`: the OS permission prompt answered.
final class NotificationPermissionResultEvent extends NotificationEvent {
  /// Creates the event.
  const NotificationPermissionResultEvent({required this.granted}) : super._();

  /// Whether permission was granted.
  final bool granted;

  @override
  String get eventName => 'notification_permission_result';

  @override
  Map<String, Object> get parameters => {'granted': granted};
}

/// `reminder_changed`: reminder settings were saved on S22.
final class ReminderChangedEvent extends NotificationEvent {
  /// Creates the event.
  const ReminderChangedEvent({required this.enabled, required this.hour})
    : super._();

  /// Whether the reminder is on.
  final bool enabled;

  /// The local hour (0–23).
  final int hour;

  @override
  String get eventName => 'reminder_changed';

  @override
  Map<String, Object> get parameters => {'enabled': enabled, 'hour': hour};
}

/// `reminder_opened`: the app was opened from the reminder notification.
final class ReminderOpenedEvent extends NotificationEvent {
  /// Creates the event.
  const ReminderOpenedEvent() : super._();

  @override
  String get eventName => 'reminder_opened';

  @override
  Map<String, Object> get parameters => const {};
}
