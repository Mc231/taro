import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/components/icons/taro_icons.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The arcana and suits of the deck, for suit-coloured visuals.
enum TaroSuit {
  /// Major Arcana.
  major,

  /// Wands.
  wands,

  /// Cups.
  cups,

  /// Swords.
  swords,

  /// Pentacles.
  pentacles;

  /// The suit's glyph.
  TaroIcons get glyph => switch (this) {
    TaroSuit.major => TaroIcons.majorStar,
    TaroSuit.wands => TaroIcons.wand,
    TaroSuit.cups => TaroIcons.cup,
    TaroSuit.swords => TaroIcons.sword,
    TaroSuit.pentacles => TaroIcons.pentacle,
  };

  /// `color.suit.<this>` in [context].
  Color colorIn(BuildContext context) {
    final suit = context.tokens.color.suit;
    return switch (this) {
      TaroSuit.major => suit.major,
      TaroSuit.wands => suit.wands,
      TaroSuit.cups => suit.cups,
      TaroSuit.swords => suit.swords,
      TaroSuit.pentacles => suit.pentacles,
    };
  }

  /// `color.chart.suit.<this>` in [context].
  Color chartColorIn(BuildContext context) {
    final chart = context.tokens.color.chart.suit;
    return switch (this) {
      TaroSuit.major => chart.major,
      TaroSuit.wands => chart.wands,
      TaroSuit.cups => chart.cups,
      TaroSuit.swords => chart.swords,
      TaroSuit.pentacles => chart.pentacles,
    };
  }
}

/// The two sizes of a [SuitGlyph].
enum SuitGlyphSize {
  /// `size.icon.sm`.
  sm,

  /// `size.icon.md`.
  md,
}

/// A suit or Major Arcana glyph in its `color.suit.*` colour
/// (`docs/design/components.md` § SuitGlyph).
///
/// Always paired with the suit name on screen: colour is never the only
/// signal. Decorative (excluded from semantics) unless [semanticsLabel] is
/// given, for a glyph that stands alone.
class SuitGlyph extends StatelessWidget {
  /// Creates the glyph.
  const SuitGlyph(
    this.suit, {
    this.size = SuitGlyphSize.md,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  /// The suit.
  final TaroSuit suit;

  /// `size.icon.sm` or `size.icon.md`.
  final SuitGlyphSize size;

  /// Overrides `color.suit.*` (the patterns chart uses
  /// `color.chart.suit.*`).
  final Color? color;

  /// Localised suit name when the glyph stands alone.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final icon = context.tokens.size.icon;
    return TaroIcon(
      suit.glyph,
      size: size == SuitGlyphSize.sm ? icon.sm : icon.md,
      color: color ?? suit.colorIn(context),
      semanticsLabel: semanticsLabel,
    );
  }
}
