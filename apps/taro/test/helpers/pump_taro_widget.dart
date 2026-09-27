import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// Pumps [child] inside a `MaterialApp` with the Taro theme and
/// localizations, for package-level widget tests (02 Testing strategy).
Future<void> pumpTaroWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: theme ?? TaroTheme.light(),
      localizationsDelegates: TaroLocalizations.localizationsDelegates,
      supportedLocales: TaroLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}
