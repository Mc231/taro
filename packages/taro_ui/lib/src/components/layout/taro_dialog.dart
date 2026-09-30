import 'package:flutter/material.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// A centred modal dialog (02 §14.3) on `color.bg.surfaceRaised`,
/// `radius.xl`, `color.bg.scrim` behind it.
///
/// * [TaroDialog.new]: confirm (title, body, two actions; a destructive
///   confirm passes a `TaroButton.destructive`). S15 delete, S26, S04.
/// * [TaroDialog.progress]: blocking progress (spinner + text + an optional
///   Cancel), announced as a live region. S12 `loadingAd`, `granting`.
///
/// Open it with [TaroDialog.show]. The content scrolls at large text.
class TaroDialog extends StatelessWidget {
  /// A confirm dialog.
  const TaroDialog({
    required this.title,
    this.body,
    this.actions = const [],
    super.key,
  }) : progress = false;

  /// A progress dialog: [title] is the progress text ("Adding your
  /// reading…"); [actions] typically holds one Cancel button.
  const TaroDialog.progress({
    required this.title,
    this.body,
    this.actions = const [],
    super.key,
  }) : progress = true;

  /// Localised title (`type.title`) or progress text.
  final String title;

  /// Localised body (`type.body`, `color.text.secondary`).
  final String? body;

  /// Actions stacked full width, primary first.
  final List<Widget> actions;

  /// Whether this is the progress layout.
  final bool progress;

  /// Shows the dialog built by `builder`. [dismissible] lets a scrim tap
  /// close it (never for a progress dialog, which is cancelled explicitly).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = false,
  }) {
    final tokens = context.tokens;
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: dismissible,
      barrierColor: tokens.color.bg.scrim,
      animationStyle: AnimationStyle(
        duration: context.motion.duration.base,
        curve: context.motion.easing.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final titleText = Text(
      title,
      textAlign: progress ? TextAlign.center : TextAlign.start,
      style: tokens.typography.title.copyWith(color: c.text.primary),
    );
    return Dialog(
      backgroundColor: c.bg.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: tokens.layout.gutter,
        vertical: tokens.space.s7,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.xl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.layout.maxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.all(tokens.space.s7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress) ...[
                const Center(child: _DialogSpinner()),
                SizedBox(height: tokens.space.s5),
                Semantics(liveRegion: true, child: titleText),
              ] else
                Semantics(header: true, child: titleText),
              if (body != null) ...[
                SizedBox(height: tokens.space.s3),
                Text(
                  body!,
                  textAlign: progress ? TextAlign.center : TextAlign.start,
                  style: tokens.typography.body.copyWith(
                    color: c.text.secondary,
                  ),
                ),
              ],
              for (var i = 0; i < actions.length; i++) ...[
                SizedBox(height: i == 0 ? tokens.space.s6 : tokens.space.s3),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogSpinner extends StatelessWidget {
  const _DialogSpinner();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = tokens.size.icon.lg;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          // Reduced motion: a still arc instead of the spinning one.
          value: context.reduceMotion ? 0.75 : null,
          strokeWidth: TaroStrokes.focusRing,
          color: tokens.color.accent.primary,
        ),
      ),
    );
  }
}
