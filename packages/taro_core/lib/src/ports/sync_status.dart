import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/failure.dart';

part 'sync_status.freezed.dart';

/// The balance chip's sync state (01 §7.1, 02 §9.2).
@freezed
sealed class SyncStatus with _$SyncStatus {
  /// A sync is running.
  const factory SyncStatus.syncing() = SyncStatusSyncing;

  /// The last sync succeeded at [at] (UTC).
  const factory SyncStatus.synced({required DateTime at}) = SyncStatusSynced;

  /// The cached balance is older than `balance.staleAfterSec` or past
  /// `free.resetsAt`; [lastSyncedAt] is when it was fetched, if ever.
  const factory SyncStatus.stale({DateTime? lastSyncedAt}) = SyncStatusStale;

  /// The balance could not be fetched and nothing usable is cached.
  const factory SyncStatus.unavailable({required Failure failure}) =
      SyncStatusUnavailable;
}
