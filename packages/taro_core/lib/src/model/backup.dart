import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/user_settings.dart';

part 'backup.freezed.dart';

/// The journal content of a backup (`data`, RC70).
@Freezed(fromJson: false, toJson: false)
abstract class BackupData with _$BackupData {
  /// Creates backup data. Use [BackupData.forExport] to build it from the
  /// journal, which drops readings that are never exported.
  const factory BackupData({
    /// Exported settings.
    required UserSettings settings,

    /// `complete`, `refused` and `classic` readings.
    required List<Reading> readings,

    /// Daily cards.
    required List<DailyCard> dailyCards,
  }) = _BackupData;

  const BackupData._();

  /// Builds export data, keeping only exportable readings (01 §7.11).
  factory BackupData.forExport({
    required UserSettings settings,
    required Iterable<Reading> readings,
    required Iterable<DailyCard> dailyCards,
  }) => BackupData(
    settings: settings,
    readings: readings.where((r) => r.isExportable).toList(growable: false),
    dailyCards: dailyCards.toList(growable: false),
  );

  /// Parses `data`; throws a [FormatException]. Schema validation
  /// (`additionalProperties`, limits) is `BackupValidator`'s job and runs
  /// first.
  factory BackupData.fromJson(
    Map<String, Object?> json, {
    bool? reduceMotion,
  }) => BackupData(
    settings: UserSettings.fromBackupJson(
      reqMap(json, 'settings'),
      reduceMotion: reduceMotion,
    ),
    readings: reqMaps(
      json,
      'readings',
    ).map(Reading.fromBackupJson).toList(growable: false),
    dailyCards: reqMaps(
      json,
      'dailyCards',
    ).map(DailyCard.fromBackupJson).toList(growable: false),
  );

  /// The `data` JSON; its RFC 8785 canonical form is what the checksum
  /// covers.
  Map<String, Object?> toJson() => {
    'settings': settings.toBackupJson(),
    'readings': [for (final r in readings) r.toBackupJson()],
    'dailyCards': [for (final d in dailyCards) d.toBackupJson()],
  };

  /// Number of readings plus daily cards (limit 50,000 each, 01 §7.11).
  int get entryCount => readings.length + dailyCards.length;
}

/// A backup file, schema version 1 (01 §7.11, `backup_schema_v1.json`,
/// RC17, RC70). The schema is frozen.
@Freezed(fromJson: false, toJson: false)
abstract class BackupV1 with _$BackupV1 {
  /// Creates a backup. [checksum] is the lowercase hex SHA-256 of the JCS
  /// canonical JSON of `data` (computed by `BackupChecksum`).
  const factory BackupV1({
    /// Export time (UTC).
    required DateTime exportedAt,

    /// `major.minor.patch+build` of the exporting app.
    required String appVersion,

    /// The journal content.
    required BackupData data,

    /// 64 lowercase hex characters.
    required String checksum,
  }) = _BackupV1;

  const BackupV1._();

  /// Parses a whole file; throws a [FormatException] on a wrong `format`, a
  /// `schemaVersion` other than 1, or a malformed field.
  factory BackupV1.fromJson(
    Map<String, Object?> json, {
    bool? reduceMotion,
  }) {
    final fileFormat = req<String>(json, 'format');
    if (fileFormat != format) {
      throw FormatException('"format" must be $format', fileFormat);
    }
    final version = reqInt(json, 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException('"schemaVersion" must be $schemaVersion', version);
    }
    return BackupV1(
      exportedAt: reqInstant(json, 'exportedAt'),
      appVersion: req<String>(json, 'appVersion'),
      data: BackupData.fromJson(
        reqMap(json, 'data'),
        reduceMotion: reduceMotion,
      ),
      checksum: req<String>(json, 'checksum'),
    );
  }

  /// The fixed `format` value.
  static const String format = 'taro.backup';

  /// The schema version this type reads and writes.
  static const int schemaVersion = 1;

  /// The file JSON, keys in schema order.
  Map<String, Object?> toJson() => {
    'format': format,
    'schemaVersion': schemaVersion,
    'exportedAt': formatInstant(exportedAt),
    'appVersion': appVersion,
    'data': data.toJson(),
    'checksum': checksum,
  };

  /// The export file name `taro-backup-YYYY-MM-DD.json` for [localDate]
  /// (`YYYY-MM-DD`, 02 §12).
  static String fileName(String localDate) => 'taro-backup-$localDate.json';
}
