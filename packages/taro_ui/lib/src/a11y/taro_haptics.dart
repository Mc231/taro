import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/a11y/taro_a11y_scope.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The `haptic.*` tokens (01 §14.4), gated by Settings → Haptics
/// ([TaroA11yScope.hapticsEnabled]; on when there is no scope).
abstract final class TaroHaptics {
  /// `haptic.pick`: a card is picked from the fan.
  static Future<void> pick(BuildContext context) =>
      _play(context, context.tokens.haptic.pick);

  /// `haptic.flip`: a card turns over.
  static Future<void> flip(BuildContext context) =>
      _play(context, context.tokens.haptic.flip);

  /// `haptic.ready`: the reading has arrived.
  static Future<void> ready(BuildContext context) =>
      _play(context, context.tokens.haptic.ready);

  static Future<void> _play(BuildContext context, String pattern) {
    final enabled = TaroA11yScope.maybeOf(context)?.hapticsEnabled ?? true;
    return enabled ? play(pattern) : Future<void>.value();
  }

  /// Plays a `haptic.*` token value (`selection`, `light`, `medium`, `heavy`,
  /// `vibrate`); unknown values do nothing (`validate_tokens` rejects them).
  static Future<void> play(String pattern) => switch (pattern) {
    'selection' => HapticFeedback.selectionClick(),
    'light' => HapticFeedback.lightImpact(),
    'medium' => HapticFeedback.mediumImpact(),
    'heavy' => HapticFeedback.heavyImpact(),
    'vibrate' => HapticFeedback.vibrate(),
    _ => Future<void>.value(),
  };
}
