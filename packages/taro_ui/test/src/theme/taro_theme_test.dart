import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('light theme is Material 3, light, and carries the tokens', () {
    final theme = TaroTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    final tokens = theme.extension<TaroTokens>()!;
    expect(tokens.brightness, Brightness.light);
    expect(tokens.color, same(TaroColorTokens.light));
  });

  test('dark theme is dark', () {
    final theme = TaroTheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.extension<TaroTokens>()!.color, same(TaroColorTokens.dark));
  });

  for (final (name, theme, color) in [
    ('light', TaroTheme.light(), TaroColorTokens.light),
    ('dark', TaroTheme.dark(), TaroColorTokens.dark),
  ]) {
    test('$name ColorScheme is mapped from the semantic tokens', () {
      final s = theme.colorScheme;
      expect(s.primary, color.accent.primary);
      expect(s.onPrimary, color.text.onAccent);
      expect(s.secondary, color.accent.secondary);
      expect(s.error, color.status.error);
      expect(s.onError, color.status.onError);
      expect(s.surface, color.bg.surface);
      expect(s.onSurface, color.text.primary);
      expect(s.onSurfaceVariant, color.text.secondary);
      expect(s.outline, color.border.strong);
      expect(s.outlineVariant, color.border.subtle);
      expect(s.scrim, color.bg.scrim);
      expect(theme.scaffoldBackgroundColor, color.bg.canvas);
      expect(theme.textTheme.bodyLarge!.color, color.text.primary);
      expect(theme.primaryTextTheme.bodyLarge!.color, color.text.onAccent);
    });
  }

  test('the text theme comes from the type roles', () {
    final theme = TaroTheme.light();
    final type = theme.extension<TaroTokens>()!.typography;
    expect(theme.textTheme.bodyLarge!.fontSize, type.body.fontSize);
    expect(theme.textTheme.displayLarge!.fontFamily, type.display.fontFamily);
    expect(theme.textTheme.titleLarge!.fontWeight, type.title.fontWeight);
    expect(theme.textTheme.bodySmall!.fontSize, type.caption.fontSize);
    expect(theme.textTheme.labelLarge!.fontSize, type.label.fontSize);
  });

  test('the script picks the font families', () {
    final theme = TaroTheme.light(script: TaroScript.arabic);
    expect(
      theme.textTheme.bodyLarge!.fontFamily,
      'packages/taro_ui/IBM Plex Sans Arabic',
    );
    final dark = TaroTheme.dark(script: TaroScript.hangul);
    expect(
      dark.textTheme.bodyLarge!.fontFamily,
      'packages/taro_ui/IBM Plex Sans KR',
    );
  });

  test('component themes use tokens', () {
    final theme = TaroTheme.light();
    const c = TaroColorTokens.light;
    expect(theme.bottomSheetTheme.backgroundColor, c.bg.surfaceRaised);
    expect(theme.dialogTheme.backgroundColor, c.bg.surfaceRaised);
    expect(theme.dividerTheme.color, c.border.subtle);
    expect(theme.snackBarTheme.backgroundColor, c.text.primary);
    expect(theme.appBarTheme.backgroundColor, c.bg.canvas);
    expect(theme.textSelectionTheme.cursorColor, c.accent.primary);
    expect(theme.progressIndicatorTheme.color, c.accent.primary);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
  });
}
