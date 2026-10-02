import 'package:flutter/material.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The mini spread of S09 and S32 (01 §7.4): the drawn faces in the
/// spread's own layout with position labels, a reversed card rotated with
/// its "Reversed" badge. The row mirrors in RTL while the card art stays
/// LTR; above 1.5× text it reflows to a list (`SpreadCanvas`).
class ReadingMiniSpread extends StatelessWidget {
  /// Creates the spread for [cards] of [spreadId].
  const ReadingMiniSpread({
    required this.spreadId,
    required this.cards,
    required this.names,
    this.positions,
    this.artSet = CardArt.defaultArtSet,
    this.cardSize = TaroCardSize.md,
    this.faceDown = false,
    super.key,
  });

  /// The spread (position names).
  final SpreadId spreadId;

  /// The drawn cards in draw order.
  final List<DrawnCard> cards;

  /// Localized card names by ID (the ID when missing).
  final Map<CardId, String> names;

  /// The spread geometry; a card whose position is missing sits in a
  /// plain row.
  final List<SpreadPosition>? positions;

  /// The bundled art set.
  final String artSet;

  /// The card size (`md` on S09 / S32, `sm` on the S15 journal entry).
  final TaroCardSize cardSize;

  /// Shows the backs only (a pending reading's cards are not revealed yet,
  /// RC50); each slot keeps its position label.
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return SpreadCanvas(
      cardSize: cardSize,
      semanticsLabel: SpreadText.name(l10n, spreadId),
      slots: [
        for (final (index, card) in cards.indexed) _slot(l10n, card, index),
      ],
    );
  }

  SpreadCanvasSlot _slot(TaroLocalizations l10n, DrawnCard card, int index) {
    final position = positions
        ?.where((p) => p.id == card.positionId)
        .firstOrNull;
    final label = SpreadText.positionName(l10n, spreadId, card.positionId);
    final name = names[card.cardId] ?? card.cardId.value;
    return SpreadCanvasSlot(
      layout: position == null
          ? SpreadSlotLayout(x: (index + 0.5) / cards.length, y: 0.5)
          : SpreadSlotLayout(
              x: position.x,
              y: position.y,
              rotationDeg: position.rotationDeg,
            ),
      label: label,
      number: index + 1,
      card: faceDown
          ? TaroCardBack(size: cardSize, semanticsLabel: label)
          : TaroCardFace(
              image: CardArt.face(card.cardId, artSet: artSet),
              semanticsLabel: l10n.drawCardSemantics(
                name,
                card.reversed ? l10n.commonReversed : l10n.commonUpright,
                label,
              ),
              reversed: card.reversed,
              size: cardSize,
              reversedLabel: l10n.commonReversed,
            ),
    );
  }
}
