import 'package:taro_core/src/result/result.dart';

/// Keeps device-bound files out of OS backups and device transfer
/// (`taro_device.db` and its `-wal`/`-shm`/`-journal` siblings; 02 AR7,
/// §6.1, RC75).
///
/// iOS sets `NSURLIsExcludedFromBackupKey` on each file. Android excludes
/// the same files declaratively (`data_extraction_rules.xml`,
/// `full_backup_content.xml`), so its binding is [NoOpBackupExclusion].
// ignore: one_member_abstracts
abstract interface class BackupExclusion {
  /// Excludes every file of [paths] that exists from OS backup. Absent
  /// paths are skipped, and excluding a file twice succeeds.
  Future<Result<void>> exclude(List<String> paths);
}

/// A [BackupExclusion] that does nothing: Android (declarative XML rules)
/// and host tests.
final class NoOpBackupExclusion implements BackupExclusion {
  /// Creates the no-op exclusion.
  const NoOpBackupExclusion();

  @override
  Future<Result<void>> exclude(List<String> paths) async =>
      const Result.ok(null);
}
