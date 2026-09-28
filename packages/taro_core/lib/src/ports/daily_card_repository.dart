import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/result/result.dart';

/// The daily card (01 §7.6, 02 §5). Local only; the same local day returns
/// the same card.
abstract interface class DailyCardRepository {
  /// Today's card, if drawn.
  Stream<DailyCard?> watchToday();

  /// Draws today's card, or returns it if already drawn (idempotent).
  Future<Result<DailyCard>> drawToday();

  /// Sets or clears the note of the card for [localDate].
  Future<Result<void>> setNote(String localDate, String? note);

  /// Sets the favourite flag of the card for [localDate].
  Future<Result<void>> setFavourite(
    String localDate, {
    required bool favourite,
  });
}
