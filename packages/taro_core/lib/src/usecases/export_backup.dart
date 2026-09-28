import 'dart:convert';
import 'dart:typed_data';

import 'package:taro_core/src/logic/backup_checksum.dart';
import 'package:taro_core/src/logic/local_dates.dart';
import 'package:taro_core/src/model/backup.dart';
import 'package:taro_core/src/ports/app_info.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/file_transfer.dart';
import 'package:taro_core/src/ports/journal_repository.dart';
import 'package:taro_core/src/ports/settings_repository.dart';
import 'package:taro_core/src/result/result.dart';

/// Exports the journal as `taro-backup-YYYY-MM-DD.json` (01 §7.11, 02 §12).
///
/// Only `complete`, `refused` and `classic` readings are included; nothing
/// device-bound (credits, install ID, consent, entitlements) ever is.
final class ExportBackup {
  /// Creates the use case.
  ExportBackup({
    required JournalRepository journal,
    required SettingsRepository settings,
    required AppInfo appInfo,
    required FileTransfer files,
    required Clock clock,
  }) : _journal = journal,
       _settings = settings,
       _appInfo = appInfo,
       _files = files,
       _clock = clock;

  /// The MIME type of a backup file.
  static const String mimeType = 'application/json';

  final JournalRepository _journal;
  final SettingsRepository _settings;
  final AppInfo _appInfo;
  final FileTransfer _files;
  final Clock _clock;

  /// Builds the backup and hands it to the share sheet.
  Future<Result<BackupV1>> call() async {
    final snapshot = await _journal.snapshot();
    return snapshot.then((s) async {
      final data = BackupData.forExport(
        settings: _settings.current,
        readings: s.readings,
        dailyCards: s.dailyCards,
      );
      final backup = BackupV1(
        exportedAt: _clock.now(),
        appVersion: '${_appInfo.version}+${_appInfo.buildNumber}',
        data: data,
        checksum: BackupChecksum.of(data),
      );
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode(backup.toJson())),
      );
      final shared = await _files.share(
        bytes,
        BackupV1.fileName(LocalDates.format(_clock.nowLocal())),
        mimeType,
      );
      return shared.map((_) => backup);
    });
  }
}
