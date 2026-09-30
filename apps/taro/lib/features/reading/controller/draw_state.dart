import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/taro_core.dart';

part 'draw_state.freezed.dart';

/// What S08 shows in every state: the spread, the draw (faces only for
/// placed-and-revealed cards), and the ritual progress (01 §7.3).
@freezed
abstract class DrawView with _$DrawView {
  /// Creates a view.
  const factory DrawView({
    required SpreadDefinition spread,
    required Draw draw,
    required bool classic,
    @Default(0) int placed,
    @Default(0) int revealed,
    @Default(false) bool autoDraw,
    @Default(false) bool reducedMotion,
    ReadingId? readingId,
    String? question,
  }) = _DrawView;

  const DrawView._();

  /// The number of cards to place.
  int get cardCount => draw.cards.length;

  /// Whether every card is placed.
  bool get allPlaced => placed >= cardCount;

  /// Whether every card is face up.
  bool get allRevealed => revealed >= cardCount;
}

/// S08 Draw ritual (01 §8.3, 02 §7): `reducedMotion` is the
/// [DrawView.reducedMotion] variant of every state.
@freezed
sealed class DrawState with _$DrawState {
  const DrawState._();

  /// No reading session (a stale route): S08 closes to Home.
  const factory DrawState.unavailable() = DrawUnavailable;

  /// The draw is being prepared (deck loaded, hold checked).
  const factory DrawState.preparing() = DrawPreparing;

  /// Shuffle animation (≥ `motion.ritual.shuffle`); the order is fixed.
  const factory DrawState.shuffling(DrawView view) = DrawShuffling;

  /// Picking N cards from the fan.
  const factory DrawState.picking(DrawView view) = DrawPicking;

  /// Flipping the placed cards (only while the hold has ≥ 120 s left).
  const factory DrawState.revealing(DrawView view) = DrawRevealing;

  /// Every card is up; the Worker is still writing (keywords view, PR8).
  const factory DrawState.awaitingReading(DrawView view) = DrawAwaitingReading;

  /// Still waiting after 20 s: a calm progress text.
  const factory DrawState.slowReading(DrawView view) = DrawSlowReading;

  /// The 60 s client timeout passed; the status is polled (RC31).
  const factory DrawState.timeoutPolling(DrawView view) = DrawTimeoutPolling;

  /// The reading failed: cards kept + Try again (same cards and
  /// `clientReadingId`, RC49) + "Save and finish later".
  const factory DrawState.generationFailed(
    DrawView view, {
    required Failure failure,
  }) = DrawGenerationFailed;

  /// The hold renewal or submit returned `402` / `409`: S10 with the cards
  /// **face-down**, then the same draw is resubmitted (RC48, RC50).
  const factory DrawState.holdLost(DrawView view) = DrawHoldLost;

  /// `410 READING_EXPIRED_REFUNDED`: "you weren't charged" + Try again with
  /// the same cards (RC51).
  const factory DrawState.deliveryExpired(DrawView view) = DrawDeliveryExpired;

  /// Declined `self_harm` / `harm_to_others` → S27 at once; no ads, no
  /// upsell.
  const factory DrawState.crisis(DrawView view, {required SafetyInfo safety}) =
      DrawCrisis;

  /// The outcome belongs to S07 (declined, paused, consent, region; see
  /// `ReadingHandoff`): S08 closes back to S07.
  const factory DrawState.returnedToQuestion(DrawView view) =
      DrawReturnedToQuestion;

  /// Stored (and acknowledged): S09, or S32 for a Classic reading.
  const factory DrawState.completed(DrawView view, {required Reading reading}) =
      DrawCompleted;

  /// The draw could not be prepared or the Classic reading not saved.
  const factory DrawState.failed({required Failure failure, DrawView? view}) =
      DrawFailed;
}
