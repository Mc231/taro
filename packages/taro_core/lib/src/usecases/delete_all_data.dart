import 'package:taro_core/src/ports/data_deletion_gateway.dart';
import 'package:taro_core/src/ports/id_generator.dart';
import 'package:taro_core/src/ports/journal_repository.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/reminder_scheduler.dart';
import 'package:taro_core/src/result/result.dart';

/// How "Delete all data" ended (S26).
enum DataDeletionOutcome {
  /// Local and server data are gone.
  complete,

  /// Local data is gone; the server erasure is queued and retried
  /// (S26 `partial`).
  partial,
}

/// "Delete all data" (01 §7.10, CS15, RC37).
///
/// Wipes the journal (readings, daily cards, settings) and erases the
/// install's server-side usage data. Keeps the install ID, secret and
/// token, the purchase outbox and the Remove Banner Ads entitlement:
/// remaining readings and Remove Banner Ads are kept.
final class DeleteAllData {
  /// Creates the use case.
  DeleteAllData({
    required JournalRepository journal,
    required DataDeletionGateway deletion,
    required ReminderScheduler reminders,
    required IdGenerator ids,
    required Logger logger,
  }) : _journal = journal,
       _deletion = deletion,
       _reminders = reminders,
       _ids = ids,
       _logger = logger;

  final JournalRepository _journal;
  final DataDeletionGateway _deletion;
  final ReminderScheduler _reminders;
  final IdGenerator _ids;
  final Logger _logger;

  /// Runs the deletion. Fails only when the local wipe fails.
  Future<Result<DataDeletionOutcome>> call() async {
    final wiped = await _journal.deleteAll();
    return wiped.then((_) async {
      await _reminders.cancelAll();
      final key = _ids.uuidV4();
      // Queued first, so a kill before the call still erases on next sync.
      final queued = await _deletion.queue(idempotencyKey: key);
      if (queued case Err(:final failure)) {
        _logger.warning('erasure queue write failed: ${failure.code}');
      }
      return Result.ok(await _erase(key));
    });
  }

  /// Retries a queued server erasure (from `SyncAccount`); `null` when
  /// nothing is queued.
  Future<DataDeletionOutcome?> retryQueued() async {
    final queued = await _deletion.queued();
    final key = queued.valueOrNull;
    if (key == null) return null;
    return _erase(key);
  }

  Future<DataDeletionOutcome> _erase(String key) async {
    final erased = await _deletion.eraseServerData(idempotencyKey: key);
    switch (erased) {
      case Ok():
        await _deletion.clearQueue();
        return DataDeletionOutcome.complete;
      case Err(:final failure):
        _logger.info('server erasure queued: ${failure.code}');
        return DataDeletionOutcome.partial;
    }
  }
}
