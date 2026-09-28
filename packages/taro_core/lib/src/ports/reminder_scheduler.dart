import 'package:taro_core/src/model/user_settings.dart';

/// Local daily-reminder notifications (02 §5).
abstract interface class ReminderScheduler {
  /// (Re)schedules the reminder for [settings] with copy in [locale];
  /// cancels it when disabled.
  Future<void> schedule(ReminderSettings settings, String locale);

  /// Cancels every scheduled reminder.
  Future<void> cancelAll();

  /// Asks for notification permission; `true` when granted.
  Future<bool> requestPermission();

  /// Emits the route of each tapped notification.
  Stream<String> get taps;
}
