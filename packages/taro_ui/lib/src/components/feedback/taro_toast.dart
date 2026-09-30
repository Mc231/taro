import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// How long a toast without an action stays (a reading-time constant, not a
/// visual duration; CLAUDE.md rule 15, RC90).
const Duration kTaroToastDuration = Duration(seconds: 4);

/// How long a toast with Undo stays: long enough to reach the action.
/// Under accessible navigation (screen readers) a toast with an action
/// stays until it is dismissed.
const Duration kTaroToastUndoDuration = Duration(seconds: 8);

/// A snackbar-style toast (S09 "Thanks — saved to your journal", S11
/// "+10 readings", S15 deleted + Undo): `color.bg.surfaceRaised`,
/// `radius.md`, a hairline outline, the message and an optional tertiary
/// action. The message is announced as a live region.
///
/// Show it with [TaroToast.show], which floats it above the bottom slot.
class TaroToast extends StatelessWidget {
  /// Creates the toast content.
  const TaroToast({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Localised message.
  final String message;

  /// Localised action ("Undo").
  final String? actionLabel;

  /// Called by the action.
  final VoidCallback? onAction;

  /// Shows a toast through the nearest `ScaffoldMessenger`, replacing the
  /// current one. The action also closes it. Enters over
  /// `motion.duration.base` (the reduced token under reduced motion).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final withAction = actionLabel != null && onAction != null;
    return messenger.showSnackBar(
      SnackBar(
        content: TaroToast(
          message: message,
          actionLabel: actionLabel,
          onAction: withAction
              ? () {
                  messenger.hideCurrentSnackBar(
                    reason: SnackBarClosedReason.action,
                  );
                  onAction();
                }
              : null,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsetsDirectional.zero,
        behavior: SnackBarBehavior.floating,
        duration: withAction ? kTaroToastUndoDuration : kTaroToastDuration,
        persist: withAction && MediaQuery.accessibleNavigationOf(context),
        margin: EdgeInsetsDirectional.symmetric(
          horizontal: context.tokens.layout.gutter,
          vertical: context.tokens.space.s5,
        ),
        dismissDirection: DismissDirection.down,
      ),
      snackBarAnimationStyle: AnimationStyle(
        duration: context.motion.duration.base,
        reverseDuration: context.motion.duration.base,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Container(
      constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.space.s5,
        tokens.space.s2,
        tokens.space.s2,
        tokens.space.s2,
      ),
      decoration: BoxDecoration(
        color: c.bg.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(color: c.border.subtle),
        boxShadow: tokens.elevation.e2.shadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: tokens.typography.body.copyWith(color: c.text.primary),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(width: tokens.space.s3),
            TaroButton.tertiary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
