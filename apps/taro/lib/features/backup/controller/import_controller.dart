import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'import_controller.freezed.dart';

/// Why a picked file cannot be imported (01 §8.3 S25 `invalid(reason)`).
enum ImportInvalidReason {
  /// Not JSON or not a `taro.backup` file.
  notTaro,

  /// A newer `schemaVersion`: "Update Taro to import this backup".
  newerVersion,

  /// Schema or checksum mismatch: "This file is damaged".
  corrupt,

  /// Over 20 MB or 50,000 entries.
  tooLarge;

  /// The reason of a validator failure.
  static ImportInvalidReason of(BackupInvalidReason reason) => switch (reason) {
    BackupInvalidReason.notJson || BackupInvalidReason.wrongFormat => notTaro,
    BackupInvalidReason.unsupportedVersion => newerVersion,
    BackupInvalidReason.checksum || BackupInvalidReason.schema => corrupt,
    BackupInvalidReason.tooLarge => tooLarge,
  };

  /// The `import_failed.reason` alias.
  ImportFailureReason get analytics => switch (this) {
    notTaro => ImportFailureReason.notTaro,
    newerVersion => ImportFailureReason.newerVersion,
    corrupt => ImportFailureReason.corrupt,
    tooLarge => ImportFailureReason.tooLarge,
  };
}

/// S25 Import backup (01 §7.11, F5): pick → validate → preview → Merge or
/// Replace → progress → result. The balance is never part of a backup.
@freezed
sealed class ImportState with _$ImportState {
  /// "Choose a file" (the OS picker, `.json`).
  const factory ImportState.picking() = ImportPicking;

  /// Checking the file ("Checking the file…").
  const factory ImportState.validating() = ImportValidating;

  /// The file cannot be imported; "Choose another file".
  const factory ImportState.invalid(ImportInvalidReason reason) = ImportInvalid;

  /// "128 readings, 240 daily cards, settings from 2026-09-12" + the mode;
  /// with the "Readings balance and purchases are not part of backups"
  /// copy.
  const factory ImportState.preview(
    ImportPreview preview, {
    @Default(MergeMode.merge) MergeMode mode,
  }) = ImportPreviewing;

  /// "Replace your journal? The [localEntries] entries on this phone will
  /// be removed." Replace / Cancel.
  const factory ImportState.confirmReplace(
    ImportPreview preview, {
    required int localEntries,
  }) = ImportConfirmReplace;

  /// Writing the journal ([progress] 0..1; back disabled).
  const factory ImportState.importing({required double progress}) =
      ImportImporting;

  /// "Imported 96 readings and 40 daily cards" + Open Journal.
  const factory ImportState.done({
    required MergeReport summary,
    required int readings,
    required int dailyCards,
  }) = ImportDone;

  /// Reading or writing failed; the journal is unchanged. Retry.
  const factory ImportState.failed(ErrorKind kind) = ImportFailed;
}

/// Drives S25 over [ImportBackup]. No AI call is made on import.
final class ImportController extends Notifier<ImportState> {
  ImportPreview? _preview;
  MergeMode _mode = MergeMode.merge;
  late AnalyticsService _analytics;

  @override
  ImportState build() {
    _analytics = ref.watch(analyticsServiceProvider);
    return const ImportState.picking();
  }

  /// Opens the file picker and validates the chosen file; a cancelled
  /// picker stays on `picking`.
  Future<void> pick() async {
    if (state is ImportValidating || state is ImportImporting) return;
    final importer = ref.read(importBackupProvider);
    final picked = await ref.read(fileTransferProvider).pickJson();
    if (!ref.mounted) return;
    switch (picked) {
      case Err(:final failure):
        await _fail(failure);
      case Ok(value: null):
        state = const ImportState.picking();
      case Ok(value: final bytes?):
        state = const ImportState.validating();
        final inspected = await importer.inspect(bytes);
        if (!ref.mounted) return;
        switch (inspected) {
          case Ok(:final value):
            _preview = value;
            _mode = MergeMode.merge;
            state = ImportState.preview(value);
          case Err(failure: BackupInvalidFailure(:final reason)):
            final invalid = ImportInvalidReason.of(reason);
            await _analytics.log(ImportFailedEvent(reason: invalid.analytics));
            if (ref.mounted) state = ImportState.invalid(invalid);
          case Err(:final failure):
            await _fail(failure);
        }
    }
  }

  /// Chooses Merge or Replace on the preview.
  void setMode(MergeMode mode) {
    final preview = _preview;
    if (preview == null || state is! ImportPreviewing) return;
    _mode = mode;
    state = ImportState.preview(preview, mode: mode);
  }

  /// "Import": Merge runs at once; Replace asks first.
  Future<void> confirm() async {
    final preview = _preview;
    if (preview == null || state is! ImportPreviewing) return;
    if (_mode == MergeMode.merge) return _apply(preview);
    final local = await ref.read(journalRepositoryProvider).snapshot();
    if (!ref.mounted) return;
    state = ImportState.confirmReplace(
      preview,
      localEntries: switch (local) {
        Ok(:final value) => value.readings.length + value.dailyCards.length,
        Err() => 0,
      },
    );
  }

  /// "Replace" in the confirmation.
  Future<void> confirmReplace() async {
    final preview = _preview;
    if (preview == null || state is! ImportConfirmReplace) return;
    await _apply(preview);
  }

  /// "Cancel" in the confirmation: back to the preview.
  void cancelReplace() {
    final preview = _preview;
    if (preview == null || state is! ImportConfirmReplace) return;
    state = ImportState.preview(preview, mode: _mode);
  }

  /// "Choose another file" / Retry.
  void reset() {
    _preview = null;
    _mode = MergeMode.merge;
    state = const ImportState.picking();
  }

  Future<void> _apply(ImportPreview preview) async {
    state = const ImportState.importing(progress: 0);
    final mode = _mode;
    final applied = await ref
        .read(importBackupProvider)
        .apply(preview, mode: mode);
    switch (applied) {
      case Ok(:final value):
        final entries = preview.readings + preview.dailyCards;
        await _analytics.log(
          ImportCompletedEvent(
            mode: switch (mode) {
              MergeMode.merge => ImportMode.merge,
              MergeMode.replace => ImportMode.replace,
            },
            entriesBucket: EntriesBucket.fromCount(entries),
            schemaVersion: BackupV1.schemaVersion,
          ),
        );
        if (!ref.mounted) return;
        state = ImportState.done(
          summary: value,
          readings: preview.readings,
          dailyCards: preview.dailyCards,
        );
      case Err(:final failure):
        await _fail(failure);
    }
  }

  Future<void> _fail(Failure failure) async {
    await _analytics.log(
      const ImportFailedEvent(reason: ImportFailureReason.storage),
    );
    if (ref.mounted) state = ImportState.failed(ErrorKind.fromFailure(failure));
  }
}

/// S25 controller.
final NotifierProvider<ImportController, ImportState> importControllerProvider =
    NotifierProvider.autoDispose(ImportController.new);
