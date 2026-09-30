import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/a11y/taro_a11y_scope.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/generated/taro_tokens.g.dart';

/// Motion accessors that honour reduced motion (01 §14.4, 02 §14.2).
abstract final class TaroMotion {
  /// Whether reduced motion is on: the system setting
  /// (`MediaQuery.disableAnimations`) or the in-app setting
  /// ([TaroA11yScope.reduceMotion]).
  static bool isReduced(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (TaroA11yScope.maybeOf(context)?.reduceMotion ?? false);

  /// The `motion.*` tokens to use in [context]: the reduced-motion values
  /// (instant / cross-fade) when [isReduced], else the defaults.
  static TaroMotionTokens of(BuildContext context) {
    final tokens = context.tokens;
    return isReduced(context) ? tokens.reducedMotion : tokens.motion;
  }
}

/// `context.motion` and `context.reduceMotion`.
extension TaroMotionContext on BuildContext {
  /// `motion.*`, reduced when reduced motion is on ([TaroMotion.of]).
  TaroMotionTokens get motion => TaroMotion.of(this);

  /// Whether reduced motion is on ([TaroMotion.isReduced]).
  bool get reduceMotion => TaroMotion.isReduced(this);
}
