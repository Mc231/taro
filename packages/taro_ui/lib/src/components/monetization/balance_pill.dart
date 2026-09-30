import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// What a [BalancePill] shows (the app-level `BalanceChip` maps its sync
/// state to one of these; `docs/design/components.md` § BalanceChip).
enum BalancePillState {
  /// The free reading is available ("1 free reading").
  free,

  /// Purchased or granted readings ("3 readings · 1 free today").
  credits,

  /// Nothing left ("0 readings"): neutral, never red or urgent.
  zero,

  /// The last known balance while offline (offline glyph).
  stale,

  /// The device could not be verified ("Readings unavailable on this
  /// device" + [BalancePill.actionLabel] "Retry").
  unverified,
}

/// The reading balance as a sentence in a pill: the stateless visual of the
/// app's `BalanceChip` (S05, S07, S11, S12).
///
/// `color.accent.subtle` pill, `radius.full`, `type.label`, an ochre
/// `color.card.frame` dot while readings are available; at least
/// `size.touchTarget.min` high. Tapping calls [onTap] (opens S10/S11, or
/// retries when unverified). [announce] makes a changed [label] a live
/// region (the "updating" state).
class BalancePill extends StatelessWidget {
  /// Creates the pill.
  const BalancePill({
    required this.state,
    required this.label,
    this.onTap,
    this.actionLabel,
    this.semanticsLabel,
    this.semanticsHint,
    this.announce = false,
    super.key,
  });

  /// The state.
  final BalancePillState state;

  /// The localised balance sentence.
  final String label;

  /// Opens the store or retries.
  final VoidCallback? onTap;

  /// Trailing localised action ("Retry"), shown when set.
  final String? actionLabel;

  /// Localised screen-reader label; defaults to [label] (pass one that
  /// includes [actionLabel] when it is set).
  final String? semanticsLabel;

  /// Localised screen-reader hint ("Opens the store").
  final String? semanticsHint;

  /// Announces label changes.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final dotSize = tokens.space.s3;
    final Widget? leading = switch (state) {
      BalancePillState.free || BalancePillState.credits => Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: c.card.frame,
          shape: BoxShape.circle,
        ),
      ),
      BalancePillState.zero => null,
      BalancePillState.stale => Icon(
        Icons.cloud_off_rounded,
        size: tokens.size.icon.sm,
        color: c.text.secondary,
      ),
      BalancePillState.unverified => Icon(
        Icons.info_outline_rounded,
        size: tokens.size.icon.sm,
        color: c.text.secondary,
      ),
    };
    final action = actionLabel;
    final radius = BorderRadius.circular(tokens.radius.full);
    return Semantics(
      container: true,
      button: onTap != null,
      liveRegion: announce,
      label: semanticsLabel ?? label,
      hint: semanticsHint,
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.size.touchTarget.min,
          minWidth: tokens.size.touchTarget.min,
        ),
        child: Material(
          color: c.accent.subtle,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            overlayColor: WidgetStatePropertyAll(
              c.text.primary.withValues(alpha: tokens.opacity.pressed),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s5,
                vertical: tokens.space.s3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    ExcludeSemantics(child: leading),
                    SizedBox(width: tokens.space.s3),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: tokens.typography.label.copyWith(
                        color: c.text.primary,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    SizedBox(width: tokens.space.s3),
                    Container(
                      padding: EdgeInsetsDirectional.only(
                        start: tokens.space.s3,
                      ),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(color: c.border.strong),
                        ),
                      ),
                      child: Text(
                        action,
                        style: tokens.typography.label.copyWith(
                          color: c.accent.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
