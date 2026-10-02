import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Labels shared by the Learn screens.
abstract final class LearnLabels {
  /// The deck section heading ("Major Arcana", "Cups").
  static String section(TaroLocalizations l10n, DeckSectionKind kind) =>
      switch (kind) {
        DeckSectionKind.majorArcana => l10n.learnSectionMajor,
        DeckSectionKind.wands => l10n.suitWands,
        DeckSectionKind.cups => l10n.suitCups,
        DeckSectionKind.swords => l10n.suitSwords,
        DeckSectionKind.pentacles => l10n.suitPentacles,
      };

  /// The section heading of [card].
  static String sectionOf(TaroLocalizations l10n, DeckCard card) =>
      section(l10n, DeckSectionKind.of(card));

  /// The suit glyph of a deck section.
  static TaroSuit suitOf(DeckSectionKind kind) => switch (kind) {
    DeckSectionKind.majorArcana => TaroSuit.major,
    DeckSectionKind.wands => TaroSuit.wands,
    DeckSectionKind.cups => TaroSuit.cups,
    DeckSectionKind.swords => TaroSuit.swords,
    DeckSectionKind.pentacles => TaroSuit.pentacles,
  };

  /// The suit glyph of [card].
  static TaroSuit suitOfCard(DeckCard card) => suitOf(DeckSectionKind.of(card));

  /// "Major Arcana" or "Minor Arcana · Cups".
  static String arcanaLine(TaroLocalizations l10n, DeckCard card) =>
      switch (card.arcana) {
        Arcana.major => l10n.learnSectionMajor,
        Arcana.minor => l10n.commonItemSeparator(
          l10n.arcanaMinor,
          sectionOf(l10n, card),
        ),
      };

  /// The localized element name.
  static String element(TaroLocalizations l10n, Element element) =>
      switch (element) {
        Element.fire => l10n.elementFire,
        Element.water => l10n.elementWater,
        Element.air => l10n.elementAir,
        Element.earth => l10n.elementEarth,
      };

  /// The number fact of [card] ("Number: …"): Roman for the Major Arcana
  /// ("XVII", "0"), the rank for pip cards ("3"), `null` for court cards
  /// (Page to King: their name already says it).
  static String? numeral(DeckCard card) => switch (card.arcana) {
    Arcana.major => roman(card.number),
    Arcana.minor when card.number <= 10 => '${card.number}',
    Arcana.minor => null,
  };

  /// The grid tile numeral, as the card art prints it: Roman for the Major
  /// Arcana and the pip cards ("XVII", "III"), `null` for court cards.
  static String? tileNumeral(DeckCard card) =>
      card.arcana == Arcana.minor && card.number > 10
      ? null
      : roman(card.number);

  /// Major Arcana numerals stay Latin in every locale ("XVII"; 0 is "0").
  static String roman(int number) {
    if (number <= 0) return '0';
    final out = StringBuffer();
    var rest = number;
    for (final (value, symbol) in _numerals) {
      while (rest >= value) {
        out.write(symbol);
        rest -= value;
      }
    }
    return out.toString();
  }

  static const List<(int, String)> _numerals = [
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];

  /// The S17 origin of the `origin` query value; the deck grid when absent
  /// or unknown.
  static LearnCardOrigin originOf(String? name) =>
      LearnCardOrigin.values.where((o) => o.name == name).firstOrNull ??
      LearnCardOrigin.deck;
}
