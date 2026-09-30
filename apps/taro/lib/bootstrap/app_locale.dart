import 'dart:ui' show Locale;

import 'package:taro_core/taro_core.dart';

/// The app locale (02 §11): the Settings [override] when it is an app
/// locale, else the first supported [deviceLocales] language, else `en`.
String resolveAppLocale({
  required String? override,
  required List<Locale> deviceLocales,
}) {
  if (override != null && kSupportedLocales.contains(override)) {
    return override;
  }
  for (final locale in deviceLocales) {
    if (kSupportedLocales.contains(locale.languageCode)) {
      return locale.languageCode;
    }
  }
  return kSupportedLocales.first;
}
