import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The kinds of [TaroInlineNotice] (design system **InlineNotice**).
enum TaroNoticeKind {
  /// Neutral information.
  info,

  /// Something worked.
  success,

  /// Needs attention.
  warning,

  /// Something failed.
  error;

  /// The kind's icon (never the only signal: the title says it).
  IconData get icon => switch (this) {
    TaroNoticeKind.info => Icons.info_outline_rounded,
    TaroNoticeKind.success => Icons.check_circle_outline_rounded,
    TaroNoticeKind.warning => Icons.warning_amber_rounded,
    TaroNoticeKind.error => Icons.error_outline_rounded,
  };
}

/// An in-screen notice (01 §8.2): kind icon, one-sentence title, optional
/// body and actions, optionally dismissible. [prominent] is the larger,
/// centred layout with stacked actions (S31 "AI readings are paused").
class TaroInlineNotice extends StatelessWidget {
  /// Creates the notice.
  const TaroInlineNotice({
    required this.kind,
    required this.title,
    this.body,
    this.actions = const [],
    this.onDismiss,
    this.dismissLabel,
    this.prominent = false,
    this.liveRegion = false,
    super.key,
  });

  /// The kind (icon and icon colour).
  final TaroNoticeKind kind;

  /// Localised one-sentence title.
  final String title;

  /// Localised body.
  final String? body;

  /// Action buttons (`TaroButton`s).
  final List<Widget> actions;

  /// Shows a close button when set (S05 `updateAvailable`).
  final VoidCallback? onDismiss;

  /// Localised label of the close button ("Dismiss").
  final String? dismissLabel;

  /// The larger centred layout.
  final bool prominent;

  /// Announce the notice when it appears (errors, results of an action).
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final iconColor = switch (kind) {
      TaroNoticeKind.info => c.status.info,
      TaroNoticeKind.success => c.status.success,
      TaroNoticeKind.warning => c.status.warning,
      TaroNoticeKind.error => c.status.error,
    };
    final titleText = Text(
      title,
      textAlign: prominent ? TextAlign.center : TextAlign.start,
      style:
          (prominent ? tokens.typography.title : tokens.typography.titleSmall)
              .copyWith(
                color: c.text.primary,
              ),
    );
    final bodyText = body == null
        ? null
        : Text(
            body!,
            textAlign: prominent ? TextAlign.center : TextAlign.start,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          );
    final Widget content;
    if (prominent) {
      final badge = tokens.size.touchTarget.min;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: c.accent.subtle,
                  borderRadius: BorderRadius.circular(tokens.radius.md),
                ),
                child: Icon(
                  kind.icon,
                  size: tokens.size.icon.md,
                  color: iconColor,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.space.s5),
          titleText,
          if (bodyText != null) ...[
            SizedBox(height: tokens.space.s3),
            bodyText,
          ],
          for (final action in actions) ...[
            SizedBox(height: tokens.space.s4),
            action,
          ],
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(kind.icon, size: tokens.size.icon.md, color: iconColor),
          ),
          SizedBox(width: tokens.space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleText,
                if (bodyText != null) ...[
                  SizedBox(height: tokens.space.s1),
                  bodyText,
                ],
                if (actions.isNotEmpty) ...[
                  SizedBox(height: tokens.space.s3),
                  Wrap(
                    spacing: tokens.space.s3,
                    runSpacing: tokens.space.s3,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: dismissLabel,
              icon: Icon(Icons.close_rounded, size: tokens.size.icon.md),
              color: c.text.secondary,
              constraints: BoxConstraints.tightFor(
                width: tokens.size.touchTarget.min,
                height: tokens.size.touchTarget.min,
              ),
              padding: EdgeInsetsDirectional.zero,
            ),
        ],
      );
    }
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(
            prominent ? tokens.radius.lg : tokens.radius.md,
          ),
          border: prominent
              ? Border.all(
                  color: c.border.subtle,
                ) // width: TaroStrokes.hairline
              : null,
        ),
        padding: prominent
            ? EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s6,
                vertical: tokens.space.s7,
              )
            : EdgeInsetsDirectional.fromSTEB(
                tokens.space.s5,
                tokens.space.s4,
                onDismiss == null ? tokens.space.s5 : tokens.space.s1,
                tokens.space.s4,
              ),
        child: content,
      ),
    );
  }
}
