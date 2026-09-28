// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this, avoid_positional_boolean_parameters

import 'package:taro_core/taro_core.dart';

import 'defaults.dart';

/// `aCard('major_00').reversed().inPosition('past').build()`.
CardBuilder aCard(String id) => CardBuilder(id);

/// Builds a [DrawnCard] (and the matching [DeckCard]).
final class CardBuilder {
  /// Starts a builder for card [id] (an RC1 card ID).
  CardBuilder(String id) : _id = CardId.parse(id);

  final CardId _id;
  bool _reversed = false;
  PositionId _position = const PositionId('focus');

  /// Reversed (or upright with `false`).
  CardBuilder reversed([bool reversed = true]) {
    _reversed = reversed;
    return this;
  }

  /// Placed in [positionId].
  CardBuilder inPosition(String positionId) {
    _position = PositionId(positionId);
    return this;
  }

  /// The drawn card.
  DrawnCard build() =>
      DrawnCard(positionId: _position, cardId: _id, reversed: _reversed);

  /// The consistent deck card of this ID.
  DeckCard deckCard() => deckCardFor(_id);
}

/// A consistent [DeckCard] for [id] (suit element set for minors).
DeckCard deckCardFor(CardId id) {
  final parts = id.value.split('_');
  final number = int.parse(parts[1]);
  if (parts[0] == 'major') {
    return DeckCard(
      id: id,
      arcana: Arcana.major,
      suit: null,
      number: number,
      artKey: id.value,
    );
  }
  final suit = Suit.values.byName(parts[0]);
  return DeckCard(
    id: id,
    arcana: Arcana.minor,
    suit: suit,
    number: number,
    artKey: id.value,
    element: Element.values[suit.index],
  );
}

/// `aDeck().build()`: the full, valid 78-card deck.
DeckBuilder aDeck() => DeckBuilder();

/// Builds a [Deck].
final class DeckBuilder {
  int _version = 1;

  /// With content version [version].
  DeckBuilder withVersion(int version) {
    _version = version;
    return this;
  }

  /// The validated deck.
  Deck build() => Deck.validated(
    id: 'rws_original',
    version: _version,
    cards: [for (final id in kCardIds) deckCardFor(id)],
    artSet: 'rws',
  );
}

/// The localized text of [cardId] (placeholder copy, valid shape).
CardText aCardText(CardId cardId, {String locale = kTestLocale}) => CardText(
  cardId: cardId,
  locale: locale,
  name: 'Card ${cardId.value}',
  keywordsUpright: const ['clarity', 'focus', 'start'],
  keywordsReversed: const ['delay', 'doubt', 'block'],
  shortUpright: 'Upright ${cardId.value}',
  shortReversed: 'Reversed ${cardId.value}',
  meaningUpright: 'The upright meaning of ${cardId.value}.',
  meaningReversed: 'The reversed meaning of ${cardId.value}.',
  aspects: const CardAspects(
    relationshipsUpright: 'r+',
    relationshipsReversed: 'r-',
    workUpright: 'w+',
    workReversed: 'w-',
    growthUpright: 'g+',
    growthReversed: 'g-',
  ),
  reflectionQuestions: const ['What?', 'Why?', 'How?'],
  sourceHash: 'hash-${cardId.value}',
  reviewStatus: ReviewStatus.reviewed,
);
