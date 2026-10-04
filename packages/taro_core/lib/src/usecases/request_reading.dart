import 'package:taro_core/src/logic/local_dates.dart';
import 'package:taro_core/src/model/draw.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/ports/balance_repository.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/id_generator.dart';
import 'package:taro_core/src/ports/install_repository.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';
import 'package:taro_core/src/usecases/delivery_ack.dart';

/// An AI reading after `GateDecision.allowed` (02 §9.3, RC42, RC49, RC50).
///
/// 1. [hold] before any card is drawn (`POST /v1/readings/holds`);
/// 2. `DrawCards` under that hold; [ensureFresh] before the reveal;
/// 3. [submit] when the last card is placed (persisted `pending` first,
///    then `POST /v1/readings`, then the delivery ack).
///
/// [retry] resubmits a failed or pending reading with the same ID and the
/// same draw: retrying never re-rolls the cards.
final class RequestReading {
  /// Creates the use case.
  RequestReading({
    required ReadingRepository readings,
    required BalanceRepository balance,
    required InstallRepository install,
    required IdGenerator ids,
    required Clock clock,
    required Logger logger,
  }) : _readings = readings,
       _balance = balance,
       _install = install,
       _ids = ids,
       _clock = clock,
       _logger = logger;

  final ReadingRepository _readings;
  final BalanceRepository _balance;
  final InstallRepository _install;
  final IdGenerator _ids;
  final Clock _clock;
  final Logger _logger;

  /// Takes (or renews, with the same [readingId]) the pre-draw hold and
  /// applies the balance that came with it. A new reading gets a fresh
  /// UUIDv4 (= `clientReadingId` = `Idempotency-Key`).
  ///
  /// A hold refused for the device (an [AttestationFailure], locally when
  /// the platform cannot sign or from the Worker, or a
  /// [SessionExpiredFailure]) repairs the registration and is tried once
  /// more, so S07 is never stuck on "couldn't verify this device" while a
  /// re-registration can fix it (02 §6.4). The failure kind is logged at
  /// `severe` (a Crashlytics non-fatal in prod; no IDs or keys).
  Future<Result<ReadingHold>> hold(
    SpreadDefinition spread, {
    required String locale,
    ReadingId? readingId,
  }) async {
    final id = readingId ?? ReadingId(_ids.uuidV4());
    var result = await _readings.hold(id, spread, locale: locale);
    if (result case Err(:final failure) when _repairable(failure)) {
      _logger.severe('reading hold refused: ${describeDeviceFailure(failure)}');
      final repaired = await _install.repairRegistration();
      if (repaired case Ok()) {
        result = await _readings.hold(id, spread, locale: locale);
        if (result case Err(:final failure) when _repairable(failure)) {
          _logger.severe(
            'reading hold refused after repair: '
            '${describeDeviceFailure(failure)}',
          );
        }
      }
    }
    if (result case Ok(:final value)) await _balance.apply(value.balance);
    return result;
  }

  static bool _repairable(Failure failure) =>
      failure is AttestationFailure || failure is SessionExpiredFailure;

  /// A log-safe description of a device-verification failure: its code and,
  /// for an [AttestationFailure], the kind.
  static String describeDeviceFailure(Failure failure) => switch (failure) {
    AttestationFailure(:final kind) => '${failure.code}(${kind.name})',
    _ => failure.code,
  };

  /// Returns [current] while it has at least `ReadingHold.minRevealLeft`
  /// left by server time; otherwise renews it (a `402` here means S10 with
  /// the cards kept face-down, RC48).
  Future<Result<ReadingHold>> ensureFresh(
    ReadingHold current,
    SpreadDefinition spread, {
    required String locale,
  }) async {
    if (!current.needsRenewalAt(_clock.now())) return Result.ok(current);
    return hold(spread, locale: locale, readingId: current.readingId);
  }

  /// Persists the reading as `pending` and asks the Worker for it.
  Future<Result<Reading>> submit({
    required ReadingHold hold,
    required Draw draw,
    required String locale,
    String? question,
  }) {
    final now = _clock.now();
    return _deliver(
      Reading(
        id: hold.readingId,
        createdAt: now,
        updatedAt: now,
        localDate: LocalDates.format(_clock.nowLocal()),
        draw: draw,
        status: const ReadingStatus.pending(),
        contentLocale: locale,
        question: normalizeQuestion(question),
        chargeSource: hold.chargeSource,
      ),
    );
  }

  /// Retries [reading] (status `pending` or `failed`) with the same ID and
  /// draw: re-takes the hold (idempotent), then resubmits (RC49). Any other
  /// status is returned unchanged.
  Future<Result<Reading>> retry(
    Reading reading,
    SpreadDefinition spread,
  ) async {
    final retryable = switch (reading.status) {
      ReadingStatusPending() || ReadingStatusFailed() => true,
      _ => false,
    };
    if (!retryable) return Result.ok(reading);
    final renewed = await hold(
      spread,
      locale: reading.contentLocale,
      readingId: reading.id,
    );
    return renewed.then(
      (h) => _deliver(
        reading.copyWith(
          status: const ReadingStatus.pending(),
          chargeSource: h.chargeSource,
          updatedAt: _clock.now(),
        ),
      ),
    );
  }

  Future<Result<Reading>> _deliver(Reading pending) async {
    final result = await _readings.submit(pending);
    if (result case Ok(:final value)) {
      await acknowledgeDelivery(_readings, _logger, value);
    }
    return result;
  }
}
