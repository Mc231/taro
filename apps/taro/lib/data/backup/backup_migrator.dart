import 'package:taro_core/taro_core.dart';

/// One step of the backup migration chain: turns a decoded document of
/// schema version [fromVersion] into one of `fromVersion + 1` (01 §7.11:
/// every future app imports every older `schemaVersion`).
///
/// A step checks the source document's own checksum rule (a mismatch is
/// `BackupInvalidFailure(checksum)`) and seals its output with the target
/// version's rule, usually through [BackupMigrator.reseal]. It throws a
/// [FormatException] (→ `schema`) on a malformed source.
abstract interface class BackupMigration {
  /// The `schemaVersion` this step reads.
  int get fromVersion;

  /// The document at `fromVersion + 1`.
  Result<Map<String, Object?>> migrate(Map<String, Object?> document);
}

/// The production chain. v1 is the first published version, so it is
/// empty; a v2 adds a `BackupMigration` with `fromVersion: 1` here and bumps
/// `BackupMigrator.currentVersion`.
const List<BackupMigration> kBackupMigrations = [];

/// Runs [steps] until a decoded backup document reaches [currentVersion]
/// (02 §12: `schemaVersion` ≤ current → migrate stepwise → validate).
///
/// A newer version is `unsupportedVersion` ("Update Taro to import this
/// backup"); a missing or non-integer version, or an older version with no
/// step, is `schema`. The migrated document still goes through
/// `BackupValidator` afterwards.
final class BackupMigrator {
  /// Creates a migrator.
  const BackupMigrator({
    this.steps = kBackupMigrations,
    this.currentVersion = BackupV1.schemaVersion,
  });

  /// The chain, one step per source version.
  final List<BackupMigration> steps;

  /// The version this app reads.
  final int currentVersion;

  /// Migrates [document] to [currentVersion]; a current document is
  /// returned unchanged.
  Result<Map<String, Object?>> migrate(Map<String, Object?> document) {
    var doc = document;
    while (true) {
      final version = versionOf(doc);
      if (version == null) return _fail(BackupInvalidReason.schema);
      if (version > currentVersion) {
        return _fail(BackupInvalidReason.unsupportedVersion);
      }
      if (version == currentVersion) return Result.ok(doc);
      final step = _stepFrom(version);
      if (step == null) return _fail(BackupInvalidReason.schema);
      final Result<Map<String, Object?>> next;
      try {
        next = step.migrate(doc);
      } on FormatException {
        return _fail(BackupInvalidReason.schema);
      }
      switch (next) {
        case Err(:final failure):
          return Result.err(failure);
        case Ok(:final value):
          if (versionOf(value) != version + 1) {
            return _fail(BackupInvalidReason.schema);
          }
          doc = value;
      }
    }
  }

  /// The integral `schemaVersion` of [document], or `null`.
  static int? versionOf(Map<String, Object?> document) {
    final v = document['schemaVersion'];
    if (v is int) return v;
    if (v is double && v.isFinite && v == v.truncateToDouble()) {
      return v.toInt();
    }
    return null;
  }

  /// A copy of [document] whose `checksum` is the v1 rule (RC70) over its
  /// `data`.
  static Map<String, Object?> reseal(Map<String, Object?> document) => {
    ...document,
    'checksum': BackupChecksum.ofJson(document['data']),
  };

  BackupMigration? _stepFrom(int version) {
    for (final s in steps) {
      if (s.fromVersion == version) return s;
    }
    return null;
  }

  static Result<Map<String, Object?>> _fail(BackupInvalidReason reason) =>
      Result.err(Failure.backupInvalid(reason: reason));
}
