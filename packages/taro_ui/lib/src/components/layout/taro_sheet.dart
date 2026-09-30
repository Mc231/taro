import 'package:flutter/material.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// A modal bottom sheet (02 §14.3): grabber, `radius.sheet` top corners on
/// `color.bg.surfaceRaised`, `color.bg.scrim` behind it. It never contains a
/// banner (RC59). S10 out of readings, S33 report, S20 theme picker, S25
/// replace confirmation, S09 More menu.
///
/// Open it with [TaroSheet.show]. The body scrolls, so it never clips at
/// 200 % text; on tablets it is capped at `layout.maxContentWidth`.
class TaroSheet extends StatelessWidget {
  /// Creates the sheet content.
  const TaroSheet({
    required this.child,
    this.title,
    this.actions = const [],
    super.key,
  });

  /// Localised title (`type.title`, a header).
  final String? title;

  /// The body.
  final Widget child;

  /// Actions under the body (`TaroButton`s, primary first).
  final List<Widget> actions;

  /// Shows the sheet built by `builder` modally. Opens over
  /// `motion.duration.slow` with `motion.easing.decelerate`; reduced motion
  /// shortens it to the reduced token. [dismissible] lets a scrim tap or a
  /// drag close it.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
  }) {
    final tokens = context.tokens;
    final motion = context.motion;
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      showDragHandle: false,
      backgroundColor: tokens.color.bg.surfaceRaised,
      barrierColor: tokens.color.bg.scrim,
      elevation: 0,
      constraints: BoxConstraints(maxWidth: tokens.layout.maxContentWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radius.sheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: AnimationStyle(
        duration: motion.duration.slow,
        reverseDuration: motion.duration.base,
        curve: motion.easing.decelerate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.layout.gutter,
          tokens.space.s3,
          tokens.layout.gutter,
          tokens.space.s7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: tokens.space.s9,
                  height: tokens.space.s2,
                  decoration: BoxDecoration(
                    color: c.border.strong,
                    borderRadius: BorderRadius.circular(tokens.radius.full),
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.space.s5),
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(
                  title!,
                  style: tokens.typography.title.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ),
              SizedBox(height: tokens.space.s4),
            ],
            child,
            for (final action in actions) ...[
              SizedBox(height: tokens.space.s4),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
