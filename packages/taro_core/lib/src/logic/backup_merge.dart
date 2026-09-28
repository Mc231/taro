import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/backup.dart';
import 'package:taro_core/src/model/daily_card.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/user_settings.dart';

part 'backup_merge.freezed.dart';

/// How an import combines with the journal (01 §7.11).
enum MergeMode {
  /// Union by `id` / `localDate`; the default.
  merge,

  /// The journal is replaced by the file (after a confirmation dialog).
  replace,
}

/// What an import did, for the result summary (01 §7.11). Counts cover
/// readings and daily cards together.
@freezed
abstract class MergeReport with _$MergeReport {
  /// Creates a report.
  const factory MergeReport({
    /// Entries that were not in the journal.
    @Default(0) int added,

    /// Existing entries changed by the file.
    @Default(0) int updated,

    /// File entries that changed nothing (older or identical).
    @Default(0) int skipped,

    /// Journal entries dropped by [MergeMode.replace].
    @Default(0) int removed,
  }) = _MergeReport;

  const MergeReport._();

  /// Adds [other] to this report.
  MergeReport operator +(MergeReport other) => MergeReport(
    added: added + other.added,
    updated: updated + other.updated,
    skipped: skipped + other.skipped,
    removed: removed + other.removed,
  );
}

/// The journal after an import, to be written in one transaction.
@freezed
abstract class MergeResult with _$MergeResult {
  /// Creates a result.
  const factory MergeResult({
    /// Settings to store.
    required UserSettings settings,

    /// Every reading, in journal order then new ones in file order.
    required List<Reading> readings,

    /// Every daily card, in journal order then new ones in file order.
    required List<DailyCard> dailyCards,

    /// The counts.
    required MergeReport report,
  }) = _MergeResult;
}

/// Combines an imported backup with the local journal (01 §7.11, 02 §4.1).
///
/// **Merge:** readings are matched by `id` and daily cards by `localDate`.
/// On a conflict the entry with the newer `updatedAt` wins (a tie keeps the
/// local one); if the notes differ, the longer note is kept on the winner
/// whichever side it came from. An entry the file cannot improve is
/// `skipped`. A winning imported reading keeps the local device-only fields
/// (`draw`, `modelId`, `chargeSource`, `deliveryAcked`), which a backup does
/// not carry. Settings stay local.
///
/// **Replace:** the file's readings, daily cards and settings replace the
/// journal. Local readings that are never exported (`pending`, `failed`)
/// are kept unless the file has the same `id`: they may hold a paid hold
/// that must stay retryable (PR6). The device-only `reduceMotion` setting
/// is always kept.
abstract final class BackupMerge {
  /// Applies [incoming] to the local journal.
  static MergeResult merge({
    required UserSettings localSettings,
    required List<Reading> localReadings,
    required List<DailyCard> localDailyCards,
    required BackupData incoming,
    required MergeMode mode,
  }) => switch (mode) {
    MergeMode.merge => _merge(
      localSettings,
      localReadings,
      localDailyCards,
      incoming,
    ),
    MergeMode.replace => _replace(
      localSettings,
      localReadings,
      localDailyCards,
      incoming,
    ),
  };

  static MergeResult _merge(
    UserSettings settings,
    List<Reading> localReadings,
    List<DailyCard> localDaily,
    BackupData incoming,
  ) {
    var report = const MergeReport();
    final readings = _union<Reading, String>(
      localReadings,
      incoming.readings,
      key: (r) => r.id.value,
      resolve: _resolveReading,
      onCount: (r) => report += r,
    );
    final daily = _union<DailyCard, String>(
      localDaily,
      incoming.dailyCards,
      key: (d) => d.localDate,
      resolve: _resolveDaily,
      onCount: (r) => report += r,
    );
    return MergeResult(
      settings: settings,
      readings: readings,
      dailyCards: daily,
      report: report,
    );
  }

  static MergeResult _replace(
    UserSettings settings,
    List<Reading> localReadings,
    List<DailyCard> localDaily,
    BackupData incoming,
  ) {
    final incomingIds = {for (final r in incoming.readings) r.id};
    final kept = [
      for (final r in localReadings)
        if (!r.isExportable && !incomingIds.contains(r.id)) r,
    ];
    return MergeResult(
      settings: incoming.settings.copyWith(
        reduceMotion: settings.reduceMotion,
      ),
      readings: List.unmodifiable([...kept, ...incoming.readings]),
      dailyCards: List.unmodifiable(incoming.dailyCards),
      report: MergeReport(
        added: incoming.entryCount,
        removed: localReadings.length - kept.length + localDaily.length,
      ),
    );
  }

  /// Unions [local] with [incoming] by [key]; [resolve] returns the merged
  /// entry, which counts as `skipped` when it equals the local one.
  static List<T> _union<T, K>(
    List<T> local,
    List<T> incoming, {
    required K Function(T) key,
    required T Function(T local, T incoming) resolve,
    required void Function(MergeReport) onCount,
  }) {
    final out = [...local];
    final index = <K, int>{for (var i = 0; i < out.length; i++) key(out[i]): i};
    for (final item in incoming) {
      final at = index[key(item)];
      if (at == null) {
        index[key(item)] = out.length;
        out.add(item);
        onCount(const MergeReport(added: 1));
        continue;
      }
      final merged = resolve(out[at], item);
      if (merged == out[at]) {
        onCount(const MergeReport(skipped: 1));
      } else {
        out[at] = merged;
        onCount(const MergeReport(updated: 1));
      }
    }
    return List.unmodifiable(out);
  }

  /// The note to keep: the longer one when they differ, else [winner]'s.
  static String? _longerNote(String? winner, String? loser) {
    if (winner == loser) return winner;
    return (loser?.length ?? 0) > (winner?.length ?? 0) ? loser : winner;
  }

  static Reading _resolveReading(Reading local, Reading incoming) {
    if (incoming.updatedAt.isAfter(local.updatedAt)) {
      return incoming.copyWith(
        draw: local.draw,
        modelId: local.modelId,
        chargeSource: local.chargeSource,
        deliveryAcked: local.deliveryAcked,
        note: _longerNote(incoming.note, local.note),
      );
    }
    return local.copyWith(note: _longerNote(local.note, incoming.note));
  }

  static DailyCard _resolveDaily(DailyCard local, DailyCard incoming) {
    if (incoming.updatedAt.isAfter(local.updatedAt)) {
      return incoming.copyWith(note: _longerNote(incoming.note, local.note));
    }
    return local.copyWith(note: _longerNote(local.note, incoming.note));
  }
}
