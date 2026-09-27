import 'package:flutter/material.dart';

/// Taro themes. Placeholder until the token pipeline lands (Phase 15).
abstract final class TaroTheme {
  /// The light theme.
  static ThemeData light() => ThemeData(brightness: Brightness.light);

  /// The dark theme.
  static ThemeData dark() => ThemeData(brightness: Brightness.dark);
}
