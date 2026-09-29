import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'reading_repository.freezed.dart';

/// A pre-draw hold (`POST /v1/readings/holds` 201, 03 §9.0, RC50).
///
/// A reservation, not a charge. Cards are revealed only while the hold has
/// at least [minRevealLeft] left by server time.
@freezed
abstract class ReadingHold with _$ReadingHold {
  /// Creates a hold.
  const factory ReadingHold({
    /// The `clientReadingId` (= `Idempotency-Key`, RC42).
    required ReadingId readingId,

    /// Which allowance the Worker reserved.
    required ChargeSource chargeSource,

    /// When the hold lapses (server time, UTC).
    required DateTime expiresAt,

    /// The balance returned with the hold.
    required CreditBalance balance,
  }) = _ReadingHold;

  const ReadingHold._();

  /// The minimum hold time left for a reveal; below it the hold is renewed
  /// first (03 §9.0: "at least 120 s left by server time").
  static const Duration minRevealLeft = Duration(seconds: 120);

  /// The server time at device instant [now], estimated from the balance
  /// that came with the hold (`serverTime + (now - syncedAt)`, 02 §6.3).
  DateTime serverNowAt(DateTime now) =>
      balance.serverTime.add(now.difference(balance.syncedAt));

  /// Whether the hold must be renewed before a reveal at device instant
  /// [now].
  bool needsRenewalAt(DateTime now) =>
      expiresAt.difference(serverNowAt(now)) < minRevealLeft;

  /// Whether the hold has lapsed at device instant [now].
  bool isExpiredAt(DateTime now) => !serverNowAt(now).isBefore(expiresAt);
}

/// AI and Classic readings: local journal rows plus the Worker reading
/// calls (02 §5, §9.3).
///
/// The adapter persists before every network call (crash-safe) and applies
/// any balance the Worker returns with a reading to the `BalanceRepository`
/// itself.
abstract interface class ReadingRepository {
  /// How long [undoDelete] can restore a deleted reading (01 §7.8 Undo
  /// snackbar).
  static const Duration undoWindow = Duration(seconds: 5);

  /// `POST /v1/readings/holds` for [readingId] (same key on renewal).
  Future<Result<ReadingHold>> hold(
    ReadingId readingId,
    SpreadDefinition spread, {
    required String locale,
  });

  /// Persists [pending] (status `pending`) and calls `POST /v1/readings`,
  /// polling `GET /v1/readings/{id}` on a timeout. Returns the stored
  /// terminal reading (`complete` or `refused`).
  Future<Result<Reading>> submit(Reading pending);

  /// `GET /v1/readings/{id}` for a reading left `pending` and stores the
  /// outcome.
  Future<Result<Reading>> resume(ReadingId id);

  /// `POST /v1/readings/{id}/ack` after the reading is persisted; on failure
  /// the adapter queues it in `pending_acks` (RC51).
  Future<Result<void>> ack(ReadingId id);

  /// Retries every queued delivery ack; returns how many succeeded.
  Future<Result<int>> flushPendingAcks();

  /// Persists a Classic reading (`status: classic`, no Worker call, RC20).
  Future<Result<Reading>> saveClassic(Reading reading);

  /// The stored reading, or `null`.
  Future<Result<Reading?>> get(ReadingId id);

  /// Every reading still `pending` (to resume on launch/resume).
  Future<Result<List<Reading>>> pending();

  /// Watches one reading.
  Stream<Reading?> watch(ReadingId id);

  /// Sets or clears the note.
  Future<Result<void>> setNote(ReadingId id, String? note);

  /// Sets the favourite flag.
  Future<Result<void>> setFavourite(ReadingId id, {required bool favourite});

  /// Sets or clears the rating and its reason.
  Future<Result<void>> setRating(
    ReadingId id,
    Rating? rating, {
    RatingReason? reason,
  });

  /// Sets the local `reported` flag after a successful report (S33).
  Future<Result<void>> markReported(ReadingId id);

  /// Deletes one reading; [undoDelete] can restore it for [undoWindow].
  Future<Result<void>> delete(ReadingId id);

  /// Restores the reading [id] deleted less than [undoWindow] ago; returns
  /// whether it was restored (`false` when it was never deleted, the window
  /// has passed or it was already restored).
  Future<Result<bool>> undoDelete(ReadingId id);
}
