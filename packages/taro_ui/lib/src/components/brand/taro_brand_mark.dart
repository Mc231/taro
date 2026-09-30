import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/deck/taro_card_ornament.dart';
import 'package:taro_ui/src/components/deck/taro_card_size.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The Taro mark (the eight-point star in an ochre card frame, as on the app
/// icon and splash) with an optional wordmark in `type.display` (S01, S30;
/// `docs/design/components.md` § TaroBrandMark). Static: it never animates.
///
/// The mark follows the theme's `color.card.frame`; [semanticsLabel] (the
/// app name) makes it one image node.
class TaroBrandMark extends StatelessWidget {
  /// Creates the mark. [wordmark] is the app name set under it.
  const TaroBrandMark({
    required this.semanticsLabel,
    this.wordmark,
    this.size = TaroCardSize.md,
    super.key,
  });

  /// The app name for screen readers.
  final String semanticsLabel;

  /// The wordmark text; null shows the mark only.
  final String? wordmark;

  /// The mark's card size (`size.card.md` matches the splash).
  final TaroCardSize size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = size.sizeOf(tokens);
    final mark = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.card),
        boxShadow: tokens.elevation.e3.shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.card),
        child: CustomPaint(
          size: card,
          painter: TaroCardOrnamentPainter(
            field: tokens.color.card.back,
            frame: tokens.color.card.frame,
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (wordmark != null) ...[
            SizedBox(height: tokens.space.s6),
            Text(
              wordmark!,
              textAlign: TextAlign.center,
              style: tokens.typography.display.copyWith(
                color: tokens.color.text.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
