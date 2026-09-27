import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Result of [Fts5Probe.run].
final class Fts5ProbeResult {
  /// Creates a probe result.
  const Fts5ProbeResult({
    required this.sqliteVersion,
    required this.fts5Available,
    required this.matchedRows,
    this.error,
  });

  /// `sqlite_version()` of the linked SQLite library.
  final String sqliteVersion;

  /// Whether an FTS5 virtual table could be created and queried.
  final bool fts5Available;

  /// Rows returned by the probe `MATCH` query (expected: 1).
  final int matchedRows;

  /// The error raised while creating/querying the FTS5 table, if any.
  final String? error;

  @override
  String toString() =>
      'Fts5ProbeResult(sqlite $sqliteVersion, fts5: $fts5Available, '
      'matched: $matchedRows${error == null ? '' : ', error: $error'})';
}

/// Checks that the SQLite linked through drift + `sqlite3` build hooks
/// supports FTS5 (RC91; journal search in Phase 11.1). If it does not, the
/// journal falls back to `LIKE` over an indexed lowercase `search_text`
/// column.
abstract final class Fts5Probe {
  /// Runs the probe on [executor] and closes it afterwards.
  static Future<Fts5ProbeResult> run(QueryExecutor executor) async {
    final db = _ProbeDatabase(executor);
    try {
      final version = await db
          .customSelect('SELECT sqlite_version() AS v')
          .map((row) => row.read<String>('v'))
          .getSingle();
      try {
        await db.customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS fts5_probe '
          'USING fts5(question, note)',
        );
        await db.customStatement('DELETE FROM fts5_probe');
        await db.customStatement(
          'INSERT INTO fts5_probe (question, note) VALUES (?, ?), (?, ?)',
          [
            'Will the new moon bring clarity?',
            'The Moon, reversed',
            'Career path this month',
            'Three of Pentacles',
          ],
        );
        final rows = await db
            .customSelect(
              'SELECT rowid FROM fts5_probe WHERE fts5_probe MATCH ?',
              variables: [Variable.withString('moon')],
            )
            .get();
        await db.customStatement('DROP TABLE fts5_probe');
        return Fts5ProbeResult(
          sqliteVersion: version,
          fts5Available: rows.length == 1,
          matchedRows: rows.length,
        );
      } on Object catch (e) {
        return Fts5ProbeResult(
          sqliteVersion: version,
          fts5Available: false,
          matchedRows: 0,
          error: '$e',
        );
      }
    } finally {
      await db.close();
    }
  }

  /// Runs the probe against an in-memory database on the current isolate.
  static Future<Fts5ProbeResult> runInMemory() => run(NativeDatabase.memory());

  /// Runs the probe against a file database opened exactly like the app's
  /// databases (`drift_flutter`'s `driftDatabase`, 02 §6.1).
  ///
  /// [databaseDirectory] and [tempDirectoryPath] override the platform
  /// directories from `path_provider` (host tests).
  static Future<Fts5ProbeResult> runOnDevice({
    Future<Object> Function()? databaseDirectory,
    Future<String?> Function()? tempDirectoryPath,
  }) {
    return run(
      driftDatabase(
        name: 'taro_fts5_probe',
        native: DriftNativeOptions(
          shareAcrossIsolates: true,
          databaseDirectory: databaseDirectory,
          tempDirectoryPath: tempDirectoryPath,
        ),
      ),
    );
  }
}

final class _ProbeDatabase extends GeneratedDatabase {
  _ProbeDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}
