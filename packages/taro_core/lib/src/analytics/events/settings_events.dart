part of '../taro_analytics_event.dart';

/// Settings events (01 §15 `SettingsEvent`).
sealed class SettingsEvent extends TaroAnalyticsEvent {
  const SettingsEvent._() : super._();
}

/// `setting_changed`: a setting changed. The named constructors keep
/// [key] and [value] consistent.
final class SettingChangedEvent extends SettingsEvent {
  /// The theme changed to [mode].
  const SettingChangedEvent.theme({required ThemeMode mode})
    : this._(SettingKey.theme, mode);

  /// The app language changed; `null` follows the device (`system`).
  const SettingChangedEvent.language({required AnalyticsLocale? locale})
    : this._(SettingKey.language, locale ?? SettingValue.system);

  /// Reversed cards were turned on or off.
  const SettingChangedEvent.reversals({required bool enabled})
    : this._(
        SettingKey.reversals,
        enabled ? SettingValue.on : SettingValue.off,
      );

  /// Haptics were turned on or off.
  const SettingChangedEvent.haptics({required bool enabled})
    : this._(SettingKey.haptics, enabled ? SettingValue.on : SettingValue.off);

  const SettingChangedEvent._(this.key, this.value) : super._();

  /// The setting.
  final SettingKey key;

  /// The new value: a [ThemeMode], an [AnalyticsLocale] or a
  /// [SettingValue].
  final Enum value;

  @override
  String get eventName => 'setting_changed';

  @override
  Map<String, Object> get parameters => {
    'key': key.wire,
    'value': analyticsWire(value),
  };
}
