import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The non-blocking offline banner at the top of a screen (01 §8.2):
/// `color.bg.surfaceRaised`, a `color.status.info` icon and `type.label`
/// text, announced as a live region. Put it in `TaroScaffold.topBanner`.
class TaroOfflineBanner extends StatelessWidget {
  /// Creates the banner.
  const TaroOfflineBanner({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Localised message ("You're offline. Your journal still works.").
  final String message;

  /// Optional action label ("Retry").
  final String? actionLabel;

  /// Optional action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg.surfaceRaised,
          border: Border(
            // Width: TaroStrokes.hairline (the BorderSide default).
            bottom: BorderSide(color: c.border.subtle),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.layout.gutter,
            vertical: tokens.space.s3,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: tokens.size.icon.sm,
                  color: c.status.info,
                ),
              ),
              SizedBox(width: tokens.space.s3),
              Expanded(
                child: Text(
                  message,
                  style: tokens.typography.label.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(width: tokens.space.s3),
                TaroButton.tertiary(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
