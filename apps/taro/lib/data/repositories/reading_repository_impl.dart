import 'dart:async';

import 'package:drift/drift.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/interceptors/retry_interceptor.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/journal_row_mapper.dart';
import 'package:taro_core/taro_core.dart';

/// [ReadingRepository] over `taro_journal.db` (readings), `taro_device.db`
/// (`pending_acks`) and the [WorkerClient] (02 §5, §9.3; RC42, RC48–RC51).
///
/// - [submit] persists the reading `pending` **before** the network call
///   (PR6), then `POST /v1/readings`. A timeout (or `409
///   REQUEST_IN_PROGRESS`) switches to polling `GET /v1/readings/{id}` at
///   1, 2, 4 and 8 s within 30 s (02 §6.3).
/// - A delivered reading (`complete` or `refused`) is persisted first and
///   then queued in `pending_acks`, so a kill before [ack] still acks it on
///   the next [flushPendingAcks] (RC51).
/// - `409 HOLD_CONFLICT` and `402` leave the draw `pending` (face-down) for
///   a resubmit with the same `clientReadingId` after a purchase (RC48,
///   RC49); `410 READING_EXPIRED_REFUNDED` and `503 AI_UNAVAILABLE` store
///   `failed(…, refunded: true)` ("you weren't charged", retry with the
///   same cards).
/// - Every balance the Worker returns (hold, reading, status) goes through
///   [BalanceRepository.apply] (RC67).
/// - [delete] removes the row at once and keeps it in memory for
///   [undoWindow] so [undoDelete] can put it back (01 §7.8 Undo snackbar).
final class ReadingRepositoryImpl implements ReadingRepository {
  /// Creates the repository. [sleep] waits between polls (tests advance a
  /// fake clock instead).
  ReadingRepositoryImpl({
    required JournalDatabase journal,
    required DeviceDatabase device,
    required WorkerClient client,
    required BalanceRepository balance,
    required Clock clock,
    required Logger logger,
    Sleep sleep = realSleep,
  }) : _journal = journal,
       _device = device,
       _client = client,
       _balance = balance,
       _clock = clock,
       _sleep = sleep,
       _logger = logger.child('readings');

  final JournalDatabase _journal;
  final DeviceDatabase _device;
  final WorkerClient _client;
  final BalanceRepository _balance;
  final Clock _clock;
  final Sleep _sleep;
  final Logger _logger;
  final Map<ReadingId, ({Reading reading, DateTime deletedAt})> _trash = {};

  /// How long a deleted reading can be restored (01 §7.8).
  static const Duration undoWindow = Duration(seconds: 5);

  // Worker calls ------------------------------------------------------------

  @override
  Future<Result<ReadingHold>> hold(
    ReadingId readingId,
    SpreadDefinition spread, {
    required String locale,
  }) async {
    final result = await _client.createHold(
      HoldRequestDto.fromDomain(readingId, spread, locale: locale),
    );
    if (result case Ok(:final value)) await _balance.apply(value.balance);
    return result;
  }

  /// Renews [current] with the same `clientReadingId` when it has less than
  /// [ReadingHold.minRevealLeft] left by server time (03 §9.0); otherwise
  /// returns it unchanged. A `402` here leaves any stored draw face-down.
  Future<Result<ReadingHold>> renewHold(
    ReadingHold current,
    SpreadDefinition spread, {
    required String locale,
  }) async => current.needsRenewalAt(_clock.now())
      ? hold(current.readingId, spread, locale: locale)
      : Result.ok(current);

  @override
  Future<Result<Reading>> submit(Reading pending) async {
    final stored = pending.copyWith(
      status: const ReadingStatus.pending(),
      deliveryAcked: false,
    );
    final saved = await _local(() => _put(stored));
    if (saved case Err(:final failure)) return Result.err(failure);
    final sent = await _client.createReading(
      CreateReadingRequestDto.fromDomain(stored),
    );
    switch (sent) {
      case Ok(:final value):
        return _deliver(stored, value, isSubmit: true);
      case Err(failure: TimeoutFailure() || RequestInProgressFailure()):
        return _poll(stored);
      case Err(:final failure):
        return _failedCall(stored, failure);
    }
  }

  @override
  Future<Result<Reading>> resume(ReadingId id) async {
    final loaded = await get(id);
    switch (loaded) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: null):
        return const Result.err(Failure.contract(wireCode: 'NOT_FOUND'));
      case Ok(:final Reading value) when value.status is! ReadingStatusPending:
        return Result.ok(value);
      case Ok(:final Reading value):
        final state = await _client.fetchReading(id);
        switch (state) {
          case Ok(value: final outcome):
            return _deliver(value, outcome, isSubmit: false);
          case Err(failure: ContractFailure(wireCode: 'NOT_FOUND')):
            // The Worker never saw the reading (killed before the POST): a
            // submit with the same ID takes the hold inline (03 §9.1).
            return submit(value);
          case Err(:final failure):
            // A refunded failure is stored: return the stored reading.
            final failed = await _failedCall(value, failure);
            return !_isRefunded(failure) ||
                    failed.failureOrNull is StorageFailure
                ? failed
                : _stored(id);
        }
    }
  }

  /// Polls `GET /v1/readings/{id}` after a timed-out submit (02 §6.3).
  Future<Result<Reading>> _poll(Reading stored) async {
    final start = _clock.now();
    for (var poll = 0; ; poll++) {
      final delay = ApiTimeouts.readingPollDelay(
        poll,
        _clock.now().difference(start),
      );
      if (delay == null) break;
      await _sleep(delay);
      final state = await _client.fetchReading(stored.id);
      switch (state) {
        case Ok(value: ReadingInProgress(:final balance)):
          await _balance.apply(balance);
        case Ok(value: final outcome):
          return _deliver(stored, outcome, isSubmit: true);
        case Err(
          failure: NetworkFailure() ||
              TimeoutFailure() ||
              ServerFailure() ||
              RequestInProgressFailure() ||
              ContractFailure(wireCode: 'NOT_FOUND'),
        ):
          continue;
        case Err(:final failure):
          return _failedCall(stored, failure);
      }
    }
    _logger.info('reading still generating after the poll budget');
    return const Result.err(Failure.timeout());
  }

  /// Stores [outcome] for [stored]. With [isSubmit] (submit), a reading that
  /// did not end `complete` or `refused` is an `Err`; otherwise (resume)
  /// every stored state is `Ok`.
  Future<Result<Reading>> _deliver(
    Reading stored,
    ReadingOutcome outcome, {
    required bool isSubmit,
  }) async {
    await _balance.apply(outcome.balance);
    final now = _clock.now();
    final Reading next;
    switch (outcome) {
      case ReadingCompleted(
        :final content,
        :final chargeSource,
        :final promptVersion,
      ):
        next = stored.copyWith(
          status: const ReadingStatus.complete(),
          content: content,
          promptVersion: promptVersion ?? stored.promptVersion,
          chargeSource: chargeSource ?? stored.chargeSource,
          updatedAt: now,
        );
      case ReadingDeclined(:final safety):
        next = stored.copyWith(
          status: ReadingStatus.refused(safety: safety),
          content: null,
          chargeSource: null,
          updatedAt: now,
        );
      case ReadingInProgress():
        return isSubmit
            ? const Result.err(Failure.timeout())
            : Result.ok(stored);
      case ReadingAttemptFailed():
        final status = outcome.status as ReadingStatusFailed;
        final saved = await _local(
          () => _put(stored.copyWith(status: status, updatedAt: now)),
        );
        if (saved case Err(:final failure)) return Result.err(failure);
        return isSubmit ? Result.err(status.failure) : _stored(stored.id);
    }
    final saved = await _local(() async {
      await _put(next);
      await _device.pendingAcksDao.enqueue(next.id.value, now: now);
    });
    if (saved case Err(:final failure)) return Result.err(failure);
    return _stored(next.id);
  }

  /// A Worker error for [stored]: refunded failures are stored as
  /// `failed(…, refunded: true)`; anything else leaves the draw `pending`.
  Future<Result<Reading>> _failedCall(Reading stored, Failure failure) async {
    if (failure case ReadingExpiredRefundedFailure(:final balance?)) {
      await _balance.apply(balance);
    }
    if (_isRefunded(failure)) {
      final saved = await _local(
        () => _put(
          stored.copyWith(
            status: ReadingStatus.failed(
              JournalRowMapper.failureOfCode(failure.code),
              refunded: true,
            ),
            updatedAt: _clock.now(),
          ),
        ),
      );
      if (saved case Err(failure: final storage)) return Result.err(storage);
    }
    return Result.err(failure);
  }

  static bool _isRefunded(Failure failure) => switch (failure) {
    ReadingExpiredRefundedFailure() || AiUnavailableFailure() => true,
    _ => false,
  };

  @override
  Future<Result<void>> ack(ReadingId id) async {
    final sent = await _client.ackReading(id);
    switch (sent) {
      case Ok():
        return _local(() => _markAcked(id));
      case Err(:final failure):
        final queued = await _local(() async {
          await _device.pendingAcksDao.enqueue(id.value, now: _clock.now());
          await _device.pendingAcksDao.recordAttempt(id.value);
        });
        return queued.isErr ? queued : Result.err(failure);
    }
  }

  @override
  Future<Result<int>> flushPendingAcks() async {
    final queue = await _local(() async {
      await _enqueueUnacked();
      return _device.pendingAcksDao.all();
    });
    switch (queue) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: final rows):
        var delivered = 0;
        for (final row in rows) {
          final id = ReadingId(row.readingId);
          final sent = await _client.ackReading(id);
          switch (sent) {
            case Ok():
            case Err(failure: ContractFailure(wireCode: 'NOT_FOUND')):
              // 404: the Worker has no such reading any more (erased).
              final done = await _local(() => _markAcked(id));
              if (done case Err(:final failure)) return Result.err(failure);
              if (sent.isOk) delivered++;
            case Err(failure: NetworkFailure() || TimeoutFailure()):
              await _local(
                () => _device.pendingAcksDao.recordAttempt(row.readingId),
              );
              return Result.ok(delivered);
            case Err(:final failure):
              _logger.info('delivery ack deferred: ${failure.code}');
              await _local(
                () => _device.pendingAcksDao.recordAttempt(row.readingId),
              );
          }
        }
        return Result.ok(delivered);
    }
  }

  /// Queues every delivered reading whose ack never reached the Worker (a
  /// kill between persisting and queueing, RC51).
  Future<void> _enqueueUnacked() async {
    final r = _journal.readings;
    final rows =
        await (_journal.selectOnly(r)
              ..addColumns([r.id, r.createdAt])
              ..where(
                r.deliveryAcked.equals(false) &
                    r.status.isIn(const ['complete', 'refused']),
              ))
            .get();
    for (final row in rows) {
      await _device.pendingAcksDao.enqueue(
        row.read(r.id)!,
        now: row.readWithConverter<DateTime?, int>(r.createdAt)!,
      );
    }
  }

  Future<void> _markAcked(ReadingId id) async {
    await _journal.readingsDao.patch(
      id.value,
      const ReadingsCompanion(deliveryAcked: Value(true)),
    );
    await _device.pendingAcksDao.remove(id.value);
  }

  // Local calls -------------------------------------------------------------

  @override
  Future<Result<Reading>> saveClassic(Reading reading) => _local(() async {
    await _put(reading);
    return reading;
  });

  @override
  Future<Result<Reading?>> get(ReadingId id) => _local(() async {
    final row = await _journal.readingsDao.byId(id.value);
    return row == null ? null : JournalRowMapper.reading(row);
  });

  @override
  Future<Result<List<Reading>>> pending() => _local(
    () async => [
      for (final row in await _journal.readingsDao.byStatus('pending'))
        JournalRowMapper.reading(row),
    ],
  );

  @override
  Stream<Reading?> watch(ReadingId id) => _journal.readingsDao
      .watchById(id.value)
      .map((row) => row == null ? null : JournalRowMapper.reading(row))
      .distinct();

  @override
  Future<Result<void>> setNote(ReadingId id, String? note) =>
      _patch(id, ReadingsCompanion(note: Value(note)));

  @override
  Future<Result<void>> setFavourite(ReadingId id, {required bool favourite}) =>
      _patch(id, ReadingsCompanion(favourite: Value(favourite)));

  @override
  Future<Result<void>> setRating(
    ReadingId id,
    Rating? rating, {
    RatingReason? reason,
  }) => _patch(
    id,
    ReadingsCompanion(
      rating: Value(rating?.name),
      ratingReason: Value(rating == null ? null : reason?.wire),
    ),
  );

  @override
  Future<Result<void>> markReported(ReadingId id) =>
      _patch(id, const ReadingsCompanion(reported: Value(true)));

  @override
  Future<Result<void>> delete(ReadingId id) => _local(() async {
    _purgeTrash();
    final row = await _journal.readingsDao.byId(id.value);
    if (row == null) return;
    await _journal.readingsDao.deleteById(id.value);
    _trash[id] = (
      reading: JournalRowMapper.reading(row),
      deletedAt: _clock.now(),
    );
  });

  /// Restores the reading [id] deleted less than [undoWindow] ago; returns
  /// whether it was restored (01 §7.8 Undo).
  Future<Result<bool>> undoDelete(ReadingId id) => _local(() async {
    _purgeTrash();
    final deleted = _trash.remove(id);
    if (deleted == null) return false;
    await _put(deleted.reading);
    return true;
  });

  void _purgeTrash() {
    final now = _clock.now();
    _trash.removeWhere((_, d) => now.difference(d.deletedAt) >= undoWindow);
  }

  // Plumbing ----------------------------------------------------------------

  Future<void> _put(Reading reading) => _journal.readingsDao.upsert(
    JournalRowMapper.readingRow(reading),
    JournalRowMapper.cardRows(reading),
  );

  /// The reading [id] as stored; a row gone after a write is a
  /// [StorageFailure].
  Future<Result<Reading>> _stored(ReadingId id) async => (await get(id)).fold(
    (reading) => reading == null
        ? const Result.err(Failure.storage())
        : Result.ok(reading),
    Result.err,
  );

  Future<Result<void>> _patch(ReadingId id, ReadingsCompanion changes) =>
      _local(
        () => _journal.readingsDao.patch(
          id.value,
          changes.copyWith(updatedAt: Value(_clock.now())),
        ),
      );

  /// Runs a local database call; a thrown error becomes [StorageFailure]
  /// (logged by type only: rows hold user text).
  Future<Result<T>> _local<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } on Object catch (error) {
      _logger.warning('journal storage failed', error: error.runtimeType);
      return const Result.err(Failure.storage());
    }
  }
}
