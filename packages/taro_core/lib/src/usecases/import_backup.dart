import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/logic/backup_merge.dart';
import 'package:taro_core/src/logic/backup_validator.dart';
import 'package:taro_core/src/model/backup.dart';
import 'package:taro_core/src/ports/content_repository.dart';
import 'package:taro_core/src/ports/file_transfer.dart';
import 'package:taro_core/src/ports/journal_repository.dart';
import 'package:taro_core/src/ports/settings_repository.dart';
import 'package:taro_core/src/result/result.dart';

part 'import_backup.freezed.dart';

/// A validated backup and its counts, for the preview step (02 §12).
@freezed
abstract class ImportPreview with _$ImportPreview {
  /// Creates a preview.
  const factory ImportPreview(BackupV1 backup) = _ImportPreview;

  const ImportPreview._();

  /// Readings in the file.
  int get readings => backup.data.readings.length;

  /// Daily cards in the file.
  int get dailyCards => backup.data.dailyCards.length;
}

/// Imports a backup (01 §7.11, 02 §12, RC70): validate → preview → Merge
/// (default) or Replace in one journal transaction. Nothing in an import
/// ever reaches the Worker ledger.
final class ImportBackup {
  /// Creates the use case.
  ImportBackup({
    required FileTransfer files,
    required ContentRepository content,
    required JournalRepository journal,
    required SettingsRepository settings,
  }) : _files = files,
       _content = content,
       _journal = journal,
       _settings = settings;

  final FileTransfer _files;
  final ContentRepository _content;
  final JournalRepository _journal;
  final SettingsRepository _settings;

  /// Lets the user pick a file and validates it; `Ok(null)` when they
  /// cancel.
  Future<Result<ImportPreview?>> pick() async {
    final picked = await _files.pickJson();
    return picked.then((bytes) async {
      if (bytes == null) return const Result.ok(null);
      return inspect(bytes);
    });
  }

  /// Validates raw file [bytes]: size, JSON, format, schema version,
  /// schema, card IDs against the bundled deck, checksum
  /// (`BackupInvalidFailure`).
  Future<Result<ImportPreview>> inspect(List<int> bytes) async {
    final deck = await _content.deck();
    return deck.then(
      (d) async => BackupValidator(deck: d)
          .validateBytes(bytes, reduceMotion: _settings.current.reduceMotion)
          .map(ImportPreview.new),
    );
  }

  /// Merges or replaces the journal with [preview]'s data.
  Future<Result<MergeReport>> apply(
    ImportPreview preview, {
    MergeMode mode = MergeMode.merge,
  }) async {
    final snapshot = await _journal.snapshot();
    return snapshot.then((s) async {
      final merged = BackupMerge.merge(
        localSettings: _settings.current,
        localReadings: s.readings,
        localDailyCards: s.dailyCards,
        incoming: preview.backup.data,
        mode: mode,
      );
      final written = await _journal.replaceAll(
        BackupData(
          settings: merged.settings,
          readings: merged.readings,
          dailyCards: merged.dailyCards,
        ),
      );
      return written.map((_) => merged.report);
    });
  }
}
