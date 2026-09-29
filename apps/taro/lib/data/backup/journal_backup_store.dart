import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/db/journal/journal_row_mapper.dart';
import 'package:taro_core/taro_core.dart';

/// The journal side of backup export and import (01 §7.11, 02 §12):
/// reads `taro_journal.db` as domain types and writes a whole journal in
/// **one drift transaction**.
///
/// `JournalRepository.snapshot` / `replaceAll` (Sprint 11.4) delegate here.
/// [importBackup] runs read → `BackupMerge` → write inside a single
/// transaction, so a concurrent edit can never be lost between the snapshot
/// and the write. Only `taro_journal.db` is touched: nothing in an import
/// reaches credits, entitlements, consent or the Worker ledger.
///
/// Every method returns `StorageFailure` on a database error or a
/// malformed row; the transaction is then rolled back.
final class JournalBackupStore {
  /// Creates the store over a journal database.
  JournalBackupStore(this._db, {required Logger logger})
    : _logger = logger.child('journal_backup_store');

  final JournalDatabase _db;
  final Logger _logger;

  /// Every reading (whatever its status) and daily card.
  Future<Result<JournalSnapshot>> snapshot() => _guard('snapshot', () async {
    final local = await _read();
    return JournalSnapshot(
      readings: local.readings,
      dailyCards: local.dailyCards,
    );
  });

  /// The stored user settings (defaults before the first write).
  Future<Result<UserSettings>> settings() =>
      _guard('settings', () async => (await _read()).settings);

  /// The exportable journal: settings, `complete` / `refused` / `classic`
  /// readings and daily cards, newest first, read in one transaction.
  Future<Result<BackupData>> exportData() => _guard('export', () async {
    final local = await _read();
    return BackupData.forExport(
      settings: local.settings,
      readings: local.readings,
      dailyCards: local.dailyCards,
    );
  });

  /// Makes the journal exactly [data] (readings, daily cards, settings) in
  /// one transaction.
  Future<Result<void>> replaceAll(BackupData data) =>
      _guard('replaceAll', () async {
        await _write(
          await _read(),
          settings: data.settings,
          readings: data.readings,
          dailyCards: data.dailyCards,
        );
      });

  /// Merges or replaces the journal with an imported backup's [incoming]
  /// data (`BackupMerge`, [mode]) in one transaction and returns the counts
  /// for the result summary.
  Future<Result<MergeReport>> importBackup(
    BackupData incoming, {
    MergeMode mode = MergeMode.merge,
  }) => _guard('import', () async {
    final local = await _read();
    final merged = BackupMerge.merge(
      localSettings: local.settings,
      localReadings: local.readings,
      localDailyCards: local.dailyCards,
      incoming: incoming,
      mode: mode,
    );
    await _write(
      local,
      settings: merged.settings,
      readings: merged.readings,
      dailyCards: merged.dailyCards,
    );
    return merged.report;
  });

  Future<_Journal> _read() async {
    final readings = await _db.readingsDao.all();
    final daily = await _db.dailyCardsDao.all();
    final settings = await _db.settingsDao.readAll();
    return _Journal(
      settings: JournalRowMapper.settings(settings),
      readings: readings.map(JournalRowMapper.reading).toList(),
      dailyCards: daily.map(JournalRowMapper.dailyCard).toList(),
    );
  }

  /// Writes only what differs from [local]: deletes entries that are gone,
  /// upserts entries that are new or changed, and rewrites the settings
  /// when they changed.
  Future<void> _write(
    _Journal local, {
    required UserSettings settings,
    required List<Reading> readings,
    required List<DailyCard> dailyCards,
  }) async {
    final localReadings = {for (final r in local.readings) r.id: r};
    final keepReadings = {for (final r in readings) r.id};
    for (final id in localReadings.keys) {
      if (!keepReadings.contains(id)) {
        await _db.readingsDao.deleteById(id.value);
      }
    }
    for (final r in readings) {
      if (localReadings[r.id] != r) {
        await _db.readingsDao.upsert(
          JournalRowMapper.readingRow(r),
          JournalRowMapper.cardRows(r),
        );
      }
    }
    final localDaily = {for (final d in local.dailyCards) d.localDate: d};
    final keepDaily = {for (final d in dailyCards) d.localDate};
    for (final date in localDaily.keys) {
      if (!keepDaily.contains(date)) {
        await _db.dailyCardsDao.deleteByDate(date);
      }
    }
    for (final d in dailyCards) {
      if (localDaily[d.localDate] != d) {
        await _db.dailyCardsDao.upsert(JournalRowMapper.dailyCardRow(d));
      }
    }
    if (settings != local.settings) {
      await _db.settingsDao.replaceAll(JournalRowMapper.settingsRows(settings));
    }
  }

  /// Runs [body] in a transaction; any error rolls it back and becomes
  /// `StorageFailure`. Only the error type is logged: messages may quote
  /// journal text.
  Future<Result<T>> _guard<T>(String op, Future<T> Function() body) async {
    try {
      return Result.ok(await _db.transaction(body));
    } on Object catch (e, stack) {
      _logger.severe('$op failed: ${e.runtimeType}', stack: stack);
      return const Result.err(Failure.storage());
    }
  }
}

/// The journal as read at the start of a transaction.
final class _Journal {
  _Journal({
    required this.settings,
    required this.readings,
    required this.dailyCards,
  });

  final UserSettings settings;
  final List<Reading> readings;
  final List<DailyCard> dailyCards;
}
