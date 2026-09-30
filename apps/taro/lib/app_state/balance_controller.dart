import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The displayed credit balance (AR8: display only, the Worker decides).
///
/// Seeded synchronously from the drift cache, so the first frame is right
/// offline (02 §9.1 step 4), then follows `BalanceRepository.watch` (which
/// applies RC67: an older response never replaces a newer one).
final class BalanceController extends Notifier<CreditBalance?> {
  @override
  CreditBalance? build() {
    final repository = ref.watch(balanceRepositoryProvider);
    final subscription = repository.watch().listen((balance) {
      state = balance;
    });
    ref.onDispose(subscription.cancel);
    return repository.cached;
  }

  /// A manual sync pass (pull to refresh, the chip's Retry).
  Future<SyncStatus> refresh() =>
      ref.read(syncCoordinatorProvider).run(SyncReason.manual);
}

/// The app-wide balance (`balanceProvider`, 02 §7).
final balanceProvider = NotifierProvider<BalanceController, CreditBalance?>(
  BalanceController.new,
);

/// Whether the balance chip shows the offline / stale state (01 §7.1): no
/// balance yet, the last sync failed, or the balance is older than
/// `balance.staleAfterSec`.
final balanceStaleProvider = Provider<bool>((ref) {
  final balance = ref.watch(balanceProvider);
  if (balance == null) return true;
  final status = ref.watch(syncStatusProvider);
  if (status is SyncStatusStale || status is SyncStatusUnavailable) {
    return true;
  }
  final config = ref.watch(remoteConfigRepositoryProvider).current;
  final age = ref.watch(clockProvider).now().difference(balance.syncedAt);
  return age > config.balanceStaleAfter;
});
