import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The card sizes of the deck components (`size.card.*`, 01 §14).
enum TaroCardSize {
  /// `size.card.thumb`: journal rows and compact spread strips.
  thumb,

  /// `size.card.sm`: the fan, spread slots and grid cells.
  sm,

  /// `size.card.md`: the daily card and the S08 reveal.
  md,

  /// `size.card.lg`: the S02 hero and S17 card detail.
  lg;

  /// The card width in [context] (`size.card.<this>`).
  double widthIn(BuildContext context) => widthOf(context.tokens);

  /// The card width for [tokens].
  double widthOf(TaroTokens tokens) {
    final card = tokens.size.card;
    return switch (this) {
      TaroCardSize.thumb => card.thumb,
      TaroCardSize.sm => card.sm,
      TaroCardSize.md => card.md,
      TaroCardSize.lg => card.lg,
    };
  }

  /// The card size for [tokens]: [widthOf] × (width ÷
  /// `size.card.aspectRatio`).
  Size sizeOf(TaroTokens tokens) {
    final width = widthOf(tokens);
    return Size(width, width / tokens.size.card.aspectRatio);
  }
}
