import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/settings_controller.dart' show settingsProvider;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'reminder_settings_controller.freezed.dart';

/// S22 Reminder settings (01 §7.7: a daily local notification, toggle +
/// time, default 09:00; never shows the card).
@freezed
sealed class ReminderSettingsState with _$ReminderSettingsState {
  /// The toggle and the time (the time block is inactive when off).
  const factory ReminderSettingsState.content(ReminderSettings reminder) =
      ReminderSettingsContent;

  /// Notifications are off in system settings: the switch is off +
  /// "Notifications are off in system settings" + Open settings.
  const factory ReminderSettingsState.permissionDenied(
    ReminderSettings reminder,
  ) = ReminderSettingsPermissionDenied;
}

/// Drives S22: persists the reminder, asks for the notification permission
/// when it is turned on, and (re)schedules it in the app locale.
final class ReminderSettingsController extends Notifier<ReminderSettingsState> {
  late ProviderSubscription<UserSettings> _settings;
  bool _denied = false;

  @override
  ReminderSettingsState build() {
    _settings = ref.listen(settingsProvider, (_, _) => _update());
    return _compute();
  }

  /// The switch; turning it on asks for the permission first.
  Future<void> setEnabled({required bool enabled}) async {
    final analytics = ref.read(analyticsServiceProvider);
    if (enabled) {
      final granted = await ref
          .read(reminderSchedulerProvider)
          .requestPermission();
      await analytics.log(NotificationPermissionResultEvent(granted: granted));
      if (!ref.mounted) return;
      if (!granted) {
        _denied = true;
        _update();
        return;
      }
    }
    _denied = false;
    await _save(_settings.read().reminder.copyWith(enabled: enabled));
  }

  /// The time picker ([hour] 0–23, [minute] 0–59).
  Future<void> setTime({required int hour, required int minute}) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return;
    String two(int n) => n.toString().padLeft(2, '0');
    await _save(
      _settings.read().reminder.copyWith(time: '${two(hour)}:${two(minute)}'),
    );
  }

  /// Back from system settings: asks again (the answer may have changed).
  Future<void> recheckPermission() => setEnabled(enabled: true);

  Future<void> _save(ReminderSettings reminder) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final locale = ref.read(appLocaleProvider)();
    final saved = await ref
        .read(settingsRepositoryProvider)
        .update((s) => s.copyWith(reminder: reminder));
    if (saved case Err()) return;
    await scheduler.schedule(reminder, locale);
    await analytics.log(
      ReminderChangedEvent(enabled: reminder.enabled, hour: reminder.hour),
    );
    _update();
  }

  void _update() {
    if (ref.mounted) state = _compute();
  }

  ReminderSettingsState _compute() {
    final reminder = _settings.read().reminder;
    return _denied
        ? ReminderSettingsState.permissionDenied(
            reminder.copyWith(enabled: false),
          )
        : ReminderSettingsState.content(reminder);
  }
}

/// S22 controller.
final NotifierProvider<ReminderSettingsController, ReminderSettingsState>
reminderSettingsControllerProvider = NotifierProvider.autoDispose(
  ReminderSettingsController.new,
);
