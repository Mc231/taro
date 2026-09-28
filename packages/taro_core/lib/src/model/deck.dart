import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/deck_card.dart';
import 'package:taro_core/src/result/ids.dart';

part 'deck.freezed.dart';

/// The bundled deck: exactly the 78 canonical cards (01 §10.1, 02 §4).
@freezed
abstract class Deck with _$Deck {
  /// Creates a deck without checking it; prefer [Deck.validated].
  const factory Deck({
    /// Deck ID, `rws_original`.
    required String id,

    /// Content version.
    required int version,

    /// The 78 cards.
    required List<DeckCard> cards,

    /// Art set key.
    required String artSet,
  }) = _Deck;

  /// Creates a deck and throws an [ArgumentError] listing every
  /// [problemsOf] entry when the cards are not exactly the 78 canonical,
  /// consistent cards.
  factory Deck.validated({
    required String id,
    required int version,
    required List<DeckCard> cards,
    required String artSet,
  }) {
    final problems = problemsOf(cards);
    if (problems.isNotEmpty) {
      throw ArgumentError.value(cards.length, 'cards', problems.join('; '));
    }
    return Deck(
      id: id,
      version: version,
      cards: List.unmodifiable(cards),
      artSet: artSet,
    );
  }

  const Deck._();

  /// The number of cards in a complete deck.
  static const int size = 78;

  /// Every reason [cards] is not a valid deck; empty when it is.
  static List<String> problemsOf(List<DeckCard> cards) {
    final ids = cards.map((c) => c.id).toList();
    final unique = ids.toSet();
    final canonical = kCardIds.toSet();
    return [
      if (cards.length != size) 'expected $size cards, got ${cards.length}',
      if (unique.length != ids.length) 'duplicate card IDs',
      for (final missing in canonical.difference(unique))
        'missing ${missing.value}',
      for (final card in cards) ...card.problems,
    ];
  }

  /// The card with [id], or `null` if it is not in this deck.
  DeckCard? card(CardId id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Whether [id] is in this deck.
  bool contains(CardId id) => card(id) != null;
}
