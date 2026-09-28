import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_matrix.dart';
import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import '../../../../packages/taro_ui/test/helpers/golden/load_taro_test_fonts.dart';

/// Pumps [child] for a widget test without providers (06 §2.3, RC77, RC95).
///
/// Wraps it in a `MaterialApp` with `TaroLocalizations` (which also sets the
/// `Directionality` for [locale]), the Taro token theme in [theme] mode, a
/// [textScale] text scaler and reduced motion, on a [size] surface at a
/// device pixel ratio of 1.0. Riverpod-free: screens that read providers use
/// `pumpTaro` from `pump_app.dart` (Phase 13.1), which builds on this.
Future<void> pumpTaroWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1.0,
  Size size = kPhoneSmall,
}) {
  applyTestViewSize(tester, size);
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: withTaroTestFonts(TaroTheme.light()),
      darkTheme: withTaroTestFonts(TaroTheme.dark()),
      themeMode: theme,
      localizationsDelegates: TaroLocalizations.localizationsDelegates,
      supportedLocales: TaroLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

/// [GoldenPump] over [pumpTaroWidget], for app goldens:
/// `goldenMatrix('s09_result', build, pump: pumpTaroGolden)`.
Future<void> pumpTaroGolden(
  WidgetTester tester,
  Widget child,
  GoldenVariant variant,
) => pumpTaroWidget(
  tester,
  child,
  locale: variant.locale,
  theme: variant.themeMode,
  textScale: variant.textScale,
  size: variant.size,
);
