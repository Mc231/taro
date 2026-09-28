import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'deck_card.freezed.dart';

/// Major or minor arcana (01 §10.1).
enum Arcana {
  /// The 22 trumps, `major_00` … `major_21`.
  major,

  /// The 56 suit cards.
  minor,
}

/// A minor-arcana suit (01 §10.1). [name] is the card ID prefix.
enum Suit {
  /// Wands (fire).
  wands,

  /// Cups (water).
  cups,

  /// Swords (air).
  swords,

  /// Pentacles (earth).
  pentacles,
}

/// A classical element (01 §10.1).
enum Element {
  /// Fire.
  fire,

  /// Water.
  water,

  /// Air.
  air,

  /// Earth.
  earth,
}

/// The 78 canonical card IDs in GLOSSARY §1 order (RC1).
final List<CardId> kCardIds = List.unmodifiable([
  for (var n = 0; n <= 21; n++) CardId('major_${_two(n)}'),
  for (final suit in Suit.values)
    for (var n = 1; n <= 14; n++) CardId('${suit.name}_${_two(n)}'),
]);

String _two(int n) => n.toString().padLeft(2, '0');

/// A locale-independent card of the bundled deck (01 §10.1 `DeckCard`,
/// 02 §4 `TarotCard`).
@freezed
abstract class DeckCard with _$DeckCard {
  /// Creates a card. Use [problems] to check its invariants.
  const factory DeckCard({
    /// `major_00` … `pentacles_14` (RC1).
    required CardId id,

    /// Major or minor arcana.
    required Arcana arcana,

    /// The suit; `null` for major arcana.
    required Suit? suit,

    /// 0–21 for major arcana, 1–14 for minor (01 = Ace … 14 = King).
    required int number,

    /// Art asset key of the bundled art set.
    required String artKey,

    /// The suit element; authored for majors.
    Element? element,

    /// Authored astrological correspondence key, e.g. `venus`.
    String? astrology,
  }) = _DeckCard;

  const DeckCard._();

  /// The ID this card must have given [arcana], [suit] and [number].
  String get expectedId => switch (arcana) {
    Arcana.major => 'major_${_two(number)}',
    Arcana.minor => '${suit?.name ?? 'none'}_${_two(number)}',
  };

  /// Every invariant this card breaks; empty when the card is consistent.
  List<String> get problems => [
    if (!CardId.isValid(id.value)) '${id.value}: not an RC1 card ID',
    if (arcana == Arcana.major && suit != null)
      '${id.value}: a major arcana card has no suit',
    if (arcana == Arcana.minor && suit == null)
      '${id.value}: a minor arcana card needs a suit',
    if (arcana == Arcana.major && (number < 0 || number > 21))
      '${id.value}: major number must be 0–21',
    if (arcana == Arcana.minor && (number < 1 || number > 14))
      '${id.value}: minor number must be 1–14',
    if (expectedId != id.value)
      '${id.value}: ID does not match arcana/suit/number ($expectedId)',
  ];
}
