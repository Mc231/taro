import 'package:flutter/widgets.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// The `disclaimerShort` footer (05 §3): "For entertainment and
/// self-reflection. Not professional advice."
///
/// Rendered at the end of **every** reading state (S09, S15, S32, including
/// loading and error), and in the S10 / S11 / S19 footers. The source label
/// ("AI-generated" / "Classic reading") is not part of it; it sits in the
/// reading header. [onOpenDisclaimer] adds the "Full disclaimer" link
/// (→ S29 `/legal/disclaimer`).
class DisclaimerFooter extends StatelessWidget {
  /// Creates the footer.
  const DisclaimerFooter({
    this.onOpenDisclaimer,
    this.centered = false,
    super.key,
  });

  /// Opens the full disclaimer; no link when `null`.
  final VoidCallback? onOpenDisclaimer;

  /// Centres the caption (paywall footers); reading screens align it to the
  /// start.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final open = onOpenDisclaimer;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s7),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.disclaimerShort,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.tertiary,
            ),
          ),
          if (open != null)
            TaroButton.tertiary(
              label: l10n.readingFullDisclaimer,
              onPressed: open,
            ),
        ],
      ),
    );
  }
}
