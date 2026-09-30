import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import 'golden/golden_sizes.dart';
import 'golden/load_taro_test_fonts.dart';

/// Languages that lay out right to left.
const Set<String> kRtlLanguages = {'ar', 'fa', 'he', 'ur'};

/// The text direction of [locale].
TextDirection textDirectionOf(Locale locale) =>
    kRtlLanguages.contains(locale.languageCode)
    ? TextDirection.rtl
    : TextDirection.ltr;

/// Pumps a `taro_ui` [child] in a `MaterialApp` with the Taro theme (RC95:
/// the package cannot import the app, so no `TaroLocalizations`; components
/// take localised strings as parameters).
///
/// [locale] sets the text direction (`ar` is RTL) and the font script;
/// [textScale] and [size] match the app-level `pumpTaroWidget`. Animations
/// are disabled (reduced motion).
Future<void> pumpTaroUiWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
  Size size = kPhoneSmall,
}) {
  applyTestViewSize(tester, size);
  final direction = textDirectionOf(locale);
  final script = TaroScript.forLocale(locale);
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withTaroTestFonts(TaroTheme.light(script: script)),
      darkTheme: withTaroTestFonts(TaroTheme.dark(script: script)),
      themeMode: themeMode,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Scaffold(body: child),
    ),
  );
}
