import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Where the database files live and how they are opened (02 §6.1).
///
/// Both files sit in the app documents directory (`Documents/` on iOS,
/// `app_flutter/` on Android, which the Android backup rules name).
final class DatabaseLocation {
  /// A location; the defaults are the platform directories of
  /// `path_provider`. Tests pass temporary directories.
  const DatabaseLocation({
    this.directory = _documentsDirectory,
    this.tempDirectory = _temporaryDirectory,
  });

  /// The directory holding the database files.
  final Future<String> Function() directory;

  /// The directory SQLite uses for temporary files.
  final Future<String?> Function() tempDirectory;

  /// The absolute path of [fileName] in [directory].
  Future<String> pathOf(String fileName) async =>
      '${await directory()}/$fileName';

  /// [databasePath] and every SQLite sibling it can have (`-wal`, `-shm`,
  /// `-journal`).
  static List<String> filesOf(String databasePath) => [
    databasePath,
    '$databasePath-wal',
    '$databasePath-shm',
    '$databasePath-journal',
  ];

  /// Opens `<name>.db` in [directory] on a background isolate shared by
  /// every isolate of the app (`shareAcrossIsolates`, 02 §6.1).
  QueryExecutor open(String name) => driftDatabase(
    name: name,
    native: DriftNativeOptions(
      shareAcrossIsolates: true,
      databasePath: () => pathOf('$name.db'),
      tempDirectoryPath: tempDirectory,
    ),
  );
}

Future<String> _documentsDirectory() async =>
    (await getApplicationDocumentsDirectory()).path;

Future<String?> _temporaryDirectory() async =>
    (await getTemporaryDirectory()).path;

/// Runs on every open, before any query: foreign keys (the
/// `reading_cards` cascade) and WAL journaling (file databases only).
Future<void> configureConnection(GeneratedDatabase db) async {
  await db.customStatement('PRAGMA foreign_keys = ON');
  await db.customStatement('PRAGMA journal_mode = WAL');
}
