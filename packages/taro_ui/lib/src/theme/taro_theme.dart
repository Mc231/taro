import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_script.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// Taro's Material 3 themes, built from the design tokens (02 §14.1): the
/// `ColorScheme` is mapped from the semantic colour tokens, the text theme
/// from the `type.*` roles, and [TaroTokens] is attached as an extension.
abstract final class TaroTheme {
  /// The light theme; [script] picks the font families (01 §13).
  static ThemeData light({TaroScript script = TaroScript.latin}) =>
      fromTokens(TaroTokens.light(script: script));

  /// The dark theme; [script] picks the font families (01 §13).
  static ThemeData dark({TaroScript script = TaroScript.latin}) =>
      fromTokens(TaroTokens.dark(script: script));

  /// A theme for arbitrary [tokens].
  static ThemeData fromTokens(TaroTokens tokens) {
    final c = tokens.color;
    final type = tokens.typography;
    final scheme = ColorScheme(
      brightness: tokens.brightness,
      primary: c.accent.primary,
      onPrimary: c.text.onAccent,
      primaryContainer: c.accent.subtle,
      onPrimaryContainer: c.text.primary,
      secondary: c.accent.secondary,
      onSecondary: c.text.onAccent,
      secondaryContainer: c.accent.subtle,
      onSecondaryContainer: c.text.primary,
      tertiary: c.status.info,
      onTertiary: c.status.onInfo,
      error: c.status.error,
      onError: c.status.onError,
      surface: c.bg.surface,
      onSurface: c.text.primary,
      onSurfaceVariant: c.text.secondary,
      surfaceDim: c.bg.sunken,
      surfaceBright: c.bg.surfaceRaised,
      surfaceContainerLowest: c.bg.canvas,
      surfaceContainerLow: c.bg.surface,
      surfaceContainer: c.bg.surface,
      surfaceContainerHigh: c.bg.surfaceRaised,
      surfaceContainerHighest: c.bg.surfaceRaised,
      outline: c.border.strong,
      outlineVariant: c.border.subtle,
      shadow: c.bg.scrim.withValues(alpha: 1),
      scrim: c.bg.scrim,
      inverseSurface: c.text.primary,
      onInverseSurface: c.text.inverse,
      inversePrimary: c.accent.subtle,
      surfaceTint: Colors.transparent,
    );
    final textTheme = TextTheme(
      displayLarge: type.display,
      displayMedium: type.display,
      displaySmall: type.headline,
      headlineLarge: type.headline,
      headlineMedium: type.headline,
      headlineSmall: type.title,
      titleLarge: type.title,
      titleMedium: type.titleSmall,
      titleSmall: type.label,
      bodyLarge: type.body,
      bodyMedium: type.body,
      bodySmall: type.caption,
      labelLarge: type.label,
      labelMedium: type.caption,
      labelSmall: type.caption,
    ).apply(bodyColor: c.text.primary, displayColor: c.text.primary);
    final sheetShape = RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.vertical(
        top: Radius.circular(tokens.radius.sheet),
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg.canvas,
      canvasColor: c.bg.canvas,
      cardColor: c.bg.surface,
      dividerColor: c.border.subtle,
      disabledColor: c.text.disabled,
      hintColor: c.text.tertiary,
      focusColor: c.accent.primary.withValues(alpha: tokens.opacity.pressed),
      hoverColor: c.accent.primary.withValues(alpha: tokens.opacity.pressed),
      highlightColor: c.text.primary.withValues(alpha: tokens.opacity.pressed),
      splashFactory: NoSplash.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: c.text.onAccent,
        displayColor: c.text.onAccent,
      ),
      iconTheme: IconThemeData(
        color: c.text.primary,
        size: tokens.size.icon.md,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg.canvas,
        foregroundColor: c.text.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: type.title.copyWith(color: c.text.primary),
        iconTheme: IconThemeData(
          color: c.text.primary,
          size: tokens.size.icon.md,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.border.subtle,
        thickness: TaroStrokes.hairline,
        space: TaroStrokes.hairline,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bg.surfaceRaised,
        modalBackgroundColor: c.bg.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: sheetShape,
        showDragHandle: true,
        dragHandleColor: c.border.strong,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.bg.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.xl),
        ),
        titleTextStyle: type.title.copyWith(color: c.text.primary),
        contentTextStyle: type.body.copyWith(color: c.text.secondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text.primary,
        contentTextStyle: type.body.copyWith(color: c.text.inverse),
        actionTextColor: c.accent.subtle,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent.primary,
        linearTrackColor: c.skeleton.base,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent.primary,
        selectionColor: c.accent.subtle,
        selectionHandleColor: c.accent.primary,
      ),
      extensions: [tokens],
    );
  }
}
