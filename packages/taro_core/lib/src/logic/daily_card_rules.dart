import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/model/deck.dart';
import 'package:taro_core/src/ports/random_source.dart';

part 'daily_card_rules.freezed.dart';

/// Today's daily card and whether it was just drawn.
@freezed
abstract class DailyCardPick with _$DailyCardPick {
  /// Creates a pick.
  const factory DailyCardPick({
    /// The card of the day.
    required DailyCard card,

    /// `true` when it was drawn now and must be persisted; `false` when it
    /// is the card already stored for today.
    required bool isNew,
  }) = _DailyCardPick;
}

/// The daily card rules (01 §7.6, §17.3): one card per install-local day,
/// computed on-device from the device timezone; the same local day always
/// returns the same card.
final class DailyCardRules {
  /// Creates the rules over `rng` (the CSPRNG port).
  const DailyCardRules(this._rng);

  final RandomSource _rng;

  /// Today's card for the local date [today] (`YYYY-MM-DD`, from
  /// `LocalDates.format(clock.nowLocal())`).
  ///
  /// If [stored] is the card of [today], it is returned unchanged and no
  /// random number is used (idempotent). Otherwise a card is drawn
  /// uniformly from [deck] with one `nextInt(78)`, and its orientation with
  /// one `nextBool()` when [reversalsEnabled].
  DailyCardPick today({
    required String today,
    required DailyCard? stored,
    required Deck deck,
    required bool reversalsEnabled,
    required DateTime now,
  }) {
    if (stored != null && stored.localDate == today) {
      return DailyCardPick(card: stored, isNew: false);
    }
    final card = deck.cards[_rng.nextInt(deck.cards.length)];
    final at = now.toUtc();
    return DailyCardPick(
      card: DailyCard(
        localDate: today,
        cardId: card.id,
        reversed: reversalsEnabled && _rng.nextBool(),
        drawnAt: at,
        createdAt: at,
        updatedAt: at,
      ),
      isNew: true,
    );
  }
}
