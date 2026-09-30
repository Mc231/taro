import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// A static mock of the daily reminder notification (S22) so the user sees
/// exactly what will appear: app name, time, title, body. It never shows
/// the card (01 §7.7). The time arrives formatted for the locale and the
/// 12/24 h setting. One screen-reader node: [semanticsLabel] ("Preview")
/// followed by the texts.
class NotificationPreview extends StatelessWidget {
  /// Creates the preview.
  const NotificationPreview({
    required this.appName,
    required this.time,
    required this.title,
    required this.body,
    this.semanticsLabel,
    this.icon,
    super.key,
  });

  /// "Taro".
  final String appName;

  /// Localised time ("8:00 PM", "20:00").
  final String time;

  /// The notification title.
  final String title;

  /// The notification body.
  final String body;

  /// Localised prefix for screen readers ("Notification preview").
  final String? semanticsLabel;

  /// The app icon (defaults to a neutral glyph).
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final iconSize = tokens.size.icon.md;
    return MergeSemantics(
      child: Semantics(
        label: semanticsLabel,
        child: Container(
          padding: EdgeInsetsDirectional.all(tokens.space.s4),
          decoration: BoxDecoration(
            color: c.bg.surfaceRaised,
            borderRadius: BorderRadius.circular(tokens.radius.lg),
            boxShadow: tokens.brightness == Brightness.light
                ? tokens.elevation.e1.shadow
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: iconSize,
                      child:
                          icon ??
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.card.back,
                              borderRadius: BorderRadius.circular(
                                tokens.radius.xs,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: tokens.size.icon.sm,
                              color: c.card.glow,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(width: tokens.space.s3),
                  Expanded(
                    child: Text(
                      appName,
                      style: tokens.typography.caption.copyWith(
                        color: c.text.secondary,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: tokens.typography.caption.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.space.s3),
              Text(
                title,
                style: tokens.typography.titleSmall.copyWith(
                  color: c.text.primary,
                ),
              ),
              SizedBox(height: tokens.space.s1),
              Text(
                body,
                style: tokens.typography.body.copyWith(
                  color: c.text.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
