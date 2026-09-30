import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/settings_controller.dart' show settingsProvider;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'language_controller.freezed.dart';

/// S21 Language picker (01 §7.10: System + 12 locales, in-app override).
@freezed
sealed class LanguageState with _$LanguageState {
  /// The choices; [localeOverride] is `null` for "System".
  const factory LanguageState.content({
    required String? localeOverride,
    required List<String> locales,
  }) = LanguageContent;
}

/// Drives S21: a choice applies at once (the app rebuilds in the new
/// locale; `ar` flips `Directionality`), with no confirmation.
final class LanguageController extends Notifier<LanguageState> {
  late ProviderSubscription<UserSettings> _settings;

  @override
  LanguageState build() {
    _settings = ref.listen(settingsProvider, (_, next) {
      state = _content(next);
    });
    return _content(_settings.read());
  }

  /// Selects [locale] (`null` = System) and logs `setting_changed`.
  Future<void> select(String? locale) async {
    if (locale != null && !kSupportedLocales.contains(locale)) return;
    if (locale == _settings.read().localeOverride) return;
    final analytics = ref.read(analyticsServiceProvider);
    final saved = await ref
        .read(settingsRepositoryProvider)
        .update((s) => s.copyWith(localeOverride: locale));
    if (saved case Err()) return;
    await analytics.log(
      SettingChangedEvent.language(
        locale: locale == null ? null : AnalyticsLocale.fromTag(locale),
      ),
    );
  }

  static LanguageState _content(UserSettings settings) => LanguageState.content(
    localeOverride: settings.localeOverride,
    locales: kSupportedLocales,
  );
}

/// S21 controller.
final NotifierProvider<LanguageController, LanguageState>
languageControllerProvider = NotifierProvider.autoDispose(
  LanguageController.new,
);
