import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';

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

  /// The S17 origin of the `origin` query value; the deck grid when absent
  /// or unknown.
  static LearnCardOrigin originOf(String? name) =>
      LearnCardOrigin.values.where((o) => o.name == name).firstOrNull ??
      LearnCardOrigin.deck;
}
