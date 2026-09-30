import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'export_controller.freezed.dart';

/// S24 Export backup (01 §7.11, F5). No network is needed.
@freezed
sealed class ExportState with _$ExportState {
  /// Before the first export (the "Export backup" button).
  const factory ExportState.idle() = ExportIdle;

  /// Building `taro-backup-YYYY-MM-DD.json` ("Preparing…").
  const factory ExportState.preparing() = ExportPreparing;

  /// The OS share sheet is open; the button stays disabled.
  const factory ExportState.shareSheetOpen() = ExportShareSheetOpen;

  /// Shared: [entries] readings and daily cards are in the file.
  const factory ExportState.done({required int entries}) = ExportDone;

  /// "We couldn't create the backup file." + Retry.
  const factory ExportState.failed(ErrorKind kind) = ExportFailed;
}

/// Drives S24 over [ExportBackup]; the share step is observed so the view
/// can show `shareSheetOpen`.
final class ExportController extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState.idle();

  /// Builds and shares the backup (a second tap while busy is ignored).
  Future<void> export() async {
    if (state is ExportPreparing || state is ExportShareSheetOpen) return;
    state = const ExportState.preparing();
    final analytics = ref.read(analyticsServiceProvider);
    var sharing = false;
    final exporter = ExportBackup(
      journal: ref.read(journalRepositoryProvider),
      settings: ref.read(settingsRepositoryProvider),
      appInfo: ref.read(appInfoProvider),
      files: _ObservedShare(
        ref.read(fileTransferProvider),
        onShare: () {
          sharing = true;
          if (ref.mounted) state = const ExportState.shareSheetOpen();
        },
      ),
      clock: ref.read(clockProvider),
    );
    final result = await exporter();
    switch (result) {
      case Ok(:final value):
        final entries =
            value.data.readings.length + value.data.dailyCards.length;
        await analytics.log(
          ExportCompletedEvent(entriesBucket: EntriesBucket.fromCount(entries)),
        );
        if (ref.mounted) state = ExportState.done(entries: entries);
      case Err(:final failure):
        await analytics.log(
          ExportFailedEvent(
            entriesBucket: EntriesBucket.none,
            error: switch (failure) {
              StorageFailure() => ExportError.storage,
              _ when sharing => ExportError.shareFailed,
              _ => ExportError.unknown,
            },
          ),
        );
        if (ref.mounted) {
          state = ExportState.failed(ErrorKind.fromFailure(failure));
        }
    }
  }
}

/// S24 controller.
final NotifierProvider<ExportController, ExportState> exportControllerProvider =
    NotifierProvider.autoDispose(ExportController.new);

/// Reports when the share sheet opens.
final class _ObservedShare implements FileTransfer {
  _ObservedShare(this._inner, {required this.onShare});

  final FileTransfer _inner;
  final void Function() onShare;

  @override
  Future<Result<void>> share(Uint8List bytes, String fileName, String mime) {
    onShare();
    return _inner.share(bytes, fileName, mime);
  }

  @override
  Future<Result<Uint8List?>> pickJson() => _inner.pickJson();
}
