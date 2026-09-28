import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';

part 'user_settings.freezed.dart';

/// The app theme choice (02 §4; backup `theme`).
enum ThemeMode {
  /// Follow the OS.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// The 12 app locales (01 §13); `localeOverride` must be one of them.
const List<String> kSupportedLocales = [
  'en',
  'ar',
  'de',
  'es',
  'fr',
  'it',
  'ja',
  'ko',
  'nl',
  'pt',
  'tr',
  'uk',
];

/// A `HH:mm` 24-hour local time.
final RegExp reminderTimePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// The daily reminder (01 §7.7).
@Freezed(fromJson: false, toJson: false)
abstract class ReminderSettings with _$ReminderSettings {
  /// Creates reminder settings.
  const factory ReminderSettings({
    /// Whether the reminder is scheduled.
    @Default(false) bool enabled,

    /// Local time `HH:mm`.
    @Default('09:00') String time,
  }) = _ReminderSettings;

  const ReminderSettings._();

  /// Parses a backup `reminder`; throws a [FormatException].
  factory ReminderSettings.fromJson(Map<String, Object?> json) {
    final time = req<String>(json, 'time');
    if (!reminderTimePattern.hasMatch(time)) {
      throw FormatException('"time" must be HH:mm', time);
    }
    return ReminderSettings(enabled: req<bool>(json, 'enabled'), time: time);
  }

  /// The hour of [time].
  int get hour => int.parse(time.substring(0, 2));

  /// The minute of [time].
  int get minute => int.parse(time.substring(3, 5));

  /// The backup JSON.
  Map<String, Object?> toJson() => {'enabled': enabled, 'time': time};
}

/// User preferences (02 §4); exported in backups except [reduceMotion].
@freezed
abstract class UserSettings with _$UserSettings {
  /// Creates settings; the defaults are the first-launch settings.
  const factory UserSettings({
    /// App theme.
    @Default(ThemeMode.system) ThemeMode themeMode,

    /// One of [kSupportedLocales]; `null` follows the device.
    String? localeOverride,

    /// Whether cards may be drawn reversed.
    @Default(true) bool reversalsEnabled,

    /// Haptic feedback.
    @Default(true) bool hapticsEnabled,

    /// Daily reminder.
    @Default(ReminderSettings()) ReminderSettings reminder,

    /// Reduce motion; `null` follows the OS. Device-local, not exported.
    bool? reduceMotion,
  }) = _UserSettings;

  const UserSettings._();

  /// Parses a backup `settings`; throws a [FormatException]. The backup has
  /// no reduce-motion flag, so [reduceMotion] keeps the given device value.
  factory UserSettings.fromBackupJson(
    Map<String, Object?> json, {
    bool? reduceMotion,
  }) {
    final locale = opt<String>(json, 'localeOverride');
    if (locale != null && !kSupportedLocales.contains(locale)) {
      throw FormatException('"localeOverride" is not an app locale', locale);
    }
    return UserSettings(
      themeMode: reqEnum(json, 'theme', ThemeMode.values.asNameMap()),
      localeOverride: locale,
      reversalsEnabled: req<bool>(json, 'reversalsEnabled'),
      hapticsEnabled: req<bool>(json, 'hapticsEnabled'),
      reminder: ReminderSettings.fromJson(reqMap(json, 'reminder')),
      reduceMotion: reduceMotion,
    );
  }

  /// The backup JSON (`backup_schema_v1.json` `settings`).
  Map<String, Object?> toBackupJson() => {
    'theme': themeMode.name,
    'reversalsEnabled': reversalsEnabled,
    'hapticsEnabled': hapticsEnabled,
    'reminder': reminder.toJson(),
    'localeOverride': localeOverride,
  };
}
