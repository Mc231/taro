import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'delete_data_controller.freezed.dart';

/// The "What's erased" / "What's kept" panels of S26 (RC37).
@freezed
abstract class DeleteDataSummary with _$DeleteDataSummary {
  /// Creates a summary.
  const factory DeleteDataSummary({
    /// Journal entries (readings + daily cards) that will be erased.
    required int journalEntries,

    /// Readings kept (purchased + earned; "Your readings balance: 3").
    required int readingsKept,

    /// Remove Banner Ads is owned and kept.
    required bool removeAdsKept,
  }) = _DeleteDataSummary;
}

/// S26 Delete all data (01 §7.10, RC37): a two-step confirmation (the
/// localized word typed), then the wipe. The install ID, credits and Remove
/// Banner Ads are kept, and the copy says so.
@freezed
sealed class DeleteDataState with _$DeleteDataState {
  /// The page with an empty (or wrong) confirmation word: the destructive
  /// button is disabled.
  const factory DeleteDataState.confirm1(DeleteDataSummary summary) =
      DeleteDataConfirm1;

  /// The typed word matches: the destructive button is enabled.
  const factory DeleteDataState.confirm2(DeleteDataSummary summary) =
      DeleteDataConfirm2;

  /// Wiping (back disabled).
  const factory DeleteDataState.deleting() = DeleteDataDeleting;

  /// "Your data is deleted" + "Your remaining readings and Remove Banner
  /// Ads are kept."
  const factory DeleteDataState.done() = DeleteDataDone;

  /// Deleted on this phone; the Worker erasure is queued and retried on the
  /// next sync.
  const factory DeleteDataState.partial() = DeleteDataPartial;

  /// The local wipe failed; nothing was sent. Retry.
  const factory DeleteDataState.failed(ErrorKind kind) = DeleteDataFailed;
}

/// Drives S26 over [DeleteAllData].
final class DeleteDataController extends Notifier<DeleteDataState> {
  late ProviderSubscription<CreditBalance?> _balance;
  late ProviderSubscription<Entitlement> _entitlement;
  int _entries = 0;
  bool _matches = false;

  @override
  DeleteDataState build() {
    _balance = ref.listen(balanceProvider, (_, _) => _refresh());
    _entitlement = ref.listen(entitlementProvider, (_, _) => _refresh());
    unawaited(_count());
    return DeleteDataState.confirm1(_summary());
  }

  /// The confirmation field changed; [word] is the localized word (ARB),
  /// compared case-insensitively.
  void updateTyped(String typed, {required String word}) {
    _matches =
        word.trim().isNotEmpty &&
        typed.trim().toLowerCase() == word.trim().toLowerCase();
    _refresh();
  }

  /// "Delete all data" (enabled in `confirm2` only).
  Future<void> delete() async {
    if (state is! DeleteDataConfirm2) return;
    state = const DeleteDataState.deleting();
    final analytics = ref.read(analyticsServiceProvider);
    final result = await ref.read(deleteAllDataProvider).call();
    switch (result) {
      case Ok(:final value):
        final complete = value == DataDeletionOutcome.complete;
        await analytics.log(DataDeletedEvent(workerAck: complete));
        if (!ref.mounted) return;
        state = complete
            ? const DeleteDataState.done()
            : const DeleteDataState.partial();
      case Err(:final failure):
        if (!ref.mounted) return;
        state = DeleteDataState.failed(ErrorKind.fromFailure(failure));
    }
  }

  /// Back to the confirmation after `failed`.
  void retry() {
    if (state is! DeleteDataFailed) return;
    _matches = false;
    _refresh(force: true);
  }

  Future<void> _count() async {
    final snapshot = await ref.read(journalRepositoryProvider).snapshot();
    if (snapshot case Ok(:final value)) {
      _entries = value.readings.length + value.dailyCards.length;
    }
    _refresh();
  }

  void _refresh({bool force = false}) {
    if (!ref.mounted) return;
    final confirming =
        state is DeleteDataConfirm1 || state is DeleteDataConfirm2;
    if (!confirming && !force) return;
    state = _matches
        ? DeleteDataState.confirm2(_summary())
        : DeleteDataState.confirm1(_summary());
  }

  DeleteDataSummary _summary() {
    final balance = _balance.read();
    return DeleteDataSummary(
      journalEntries: _entries,
      readingsKept: balance == null ? 0 : balance.bonus + balance.displayPaid,
      removeAdsKept: _entitlement.read().removesAds,
    );
  }
}

/// S26 controller.
final NotifierProvider<DeleteDataController, DeleteDataState>
deleteDataControllerProvider = NotifierProvider.autoDispose(
  DeleteDataController.new,
);
