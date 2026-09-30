import 'package:flutter/material.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';
import 'package:taro_ui/src/tokens/taro_script.dart';
import 'package:taro_ui/src/tokens/taro_typography.dart';

/// The Taro design tokens as a `ThemeExtension` (02 §14.1). Read them with
/// `context.tokens` (e.g. `context.tokens.color.text.primary`,
/// `context.tokens.space.s4`); motion goes through `context.motion`, which
/// honours reduced motion.
@immutable
final class TaroTokens extends ThemeExtension<TaroTokens> {
  /// Creates the tokens from the generated groups.
  const TaroTokens({
    required this.brightness,
    required this.color,
    required this.typography,
    required this.space,
    required this.radius,
    required this.size,
    required this.layout,
    required this.opacity,
    required this.elevation,
    required this.motion,
    required this.reducedMotion,
    required this.font,
    required this.haptic,
  });

  /// The light-mode tokens with [script]'s font families.
  factory TaroTokens.light({TaroScript script = TaroScript.latin}) =>
      TaroTokens.of(Brightness.light, script: script);

  /// The dark-mode tokens with [script]'s font families.
  factory TaroTokens.dark({TaroScript script = TaroScript.latin}) =>
      TaroTokens.of(Brightness.dark, script: script);

  /// The tokens for [brightness] with [script]'s font families.
  factory TaroTokens.of(
    Brightness brightness, {
    TaroScript script = TaroScript.latin,
  }) {
    final dark = brightness == Brightness.dark;
    return TaroTokens(
      brightness: brightness,
      color: dark ? TaroColorTokens.dark : TaroColorTokens.light,
      typography: (dark ? TaroTypeTokens.dark : TaroTypeTokens.light).forScript(
        script,
        dark ? TaroFontTokens.dark : TaroFontTokens.light,
      ),
      space: dark ? TaroSpaceTokens.dark : TaroSpaceTokens.light,
      radius: dark ? TaroRadiusTokens.dark : TaroRadiusTokens.light,
      size: dark ? TaroSizeTokens.dark : TaroSizeTokens.light,
      layout: dark ? TaroLayoutTokens.dark : TaroLayoutTokens.light,
      opacity: dark ? TaroOpacityTokens.dark : TaroOpacityTokens.light,
      elevation: dark ? TaroElevationTokens.dark : TaroElevationTokens.light,
      motion: dark ? TaroMotionTokens.dark : TaroMotionTokens.light,
      reducedMotion: TaroMotionTokens.reduced,
      font: dark ? TaroFontTokens.dark : TaroFontTokens.light,
      haptic: dark ? TaroHapticTokens.dark : TaroHapticTokens.light,
    );
  }

  /// Light or dark.
  final Brightness brightness;

  /// `color.*` (01 §14.1).
  final TaroColorTokens color;

  /// `type.*` for the active script (01 §14.2). Named `typography` because
  /// `ThemeExtension.type` is the extension's lookup key.
  final TaroTypeTokens typography;

  /// `space.*` (01 §14.3).
  final TaroSpaceTokens space;

  /// `radius.*`.
  final TaroRadiusTokens radius;

  /// `size.*`.
  final TaroSizeTokens size;

  /// `layout.*`.
  final TaroLayoutTokens layout;

  /// `opacity.*`.
  final TaroOpacityTokens opacity;

  /// `elevation.*` (shadow in light, tonal overlay in dark).
  final TaroElevationTokens elevation;

  /// `motion.*` default values. Widgets read `context.motion` instead.
  final TaroMotionTokens motion;

  /// `motion.*` reduced-motion values (01 §14.4).
  final TaroMotionTokens reducedMotion;

  /// `font.family.*`.
  final TaroFontTokens font;

  /// `haptic.*` (played by `TaroHaptics`).
  final TaroHapticTokens haptic;

  @override
  TaroTokens copyWith({
    Brightness? brightness,
    TaroColorTokens? color,
    TaroTypeTokens? typography,
    TaroSpaceTokens? space,
    TaroRadiusTokens? radius,
    TaroSizeTokens? size,
    TaroLayoutTokens? layout,
    TaroOpacityTokens? opacity,
    TaroElevationTokens? elevation,
    TaroMotionTokens? motion,
    TaroMotionTokens? reducedMotion,
    TaroFontTokens? font,
    TaroHapticTokens? haptic,
  }) => TaroTokens(
    brightness: brightness ?? this.brightness,
    color: color ?? this.color,
    typography: typography ?? this.typography,
    space: space ?? this.space,
    radius: radius ?? this.radius,
    size: size ?? this.size,
    layout: layout ?? this.layout,
    opacity: opacity ?? this.opacity,
    elevation: elevation ?? this.elevation,
    motion: motion ?? this.motion,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    font: font ?? this.font,
    haptic: haptic ?? this.haptic,
  );

  @override
  TaroTokens lerp(covariant TaroTokens? other, double t) {
    if (other == null) return this;
    return TaroTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      color: TaroColorTokens.lerp(color, other.color, t),
      typography: TaroTypeTokens.lerp(typography, other.typography, t),
      space: TaroSpaceTokens.lerp(space, other.space, t),
      radius: TaroRadiusTokens.lerp(radius, other.radius, t),
      size: TaroSizeTokens.lerp(size, other.size, t),
      layout: TaroLayoutTokens.lerp(layout, other.layout, t),
      opacity: TaroOpacityTokens.lerp(opacity, other.opacity, t),
      elevation: TaroElevationTokens.lerp(elevation, other.elevation, t),
      motion: TaroMotionTokens.lerp(motion, other.motion, t),
      reducedMotion: TaroMotionTokens.lerp(
        reducedMotion,
        other.reducedMotion,
        t,
      ),
      font: TaroFontTokens.lerp(font, other.font, t),
      haptic: TaroHapticTokens.lerp(haptic, other.haptic, t),
    );
  }
}

final TaroTokens _fallbackLight = TaroTokens.light();
final TaroTokens _fallbackDark = TaroTokens.dark();

/// `context.tokens`.
extension TaroTokensContext on BuildContext {
  /// The [TaroTokens] of the ambient theme (the default light or dark tokens
  /// when the theme was not built by `TaroTheme`).
  TaroTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<TaroTokens>() ??
        (theme.brightness == Brightness.dark ? _fallbackDark : _fallbackLight);
  }
}
