import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The sync state the chip shows (01 §7.1).
enum BalanceChipSync {
  /// A sync is running (live-region announcement of the result).
  syncing,

  /// The balance is current.
  synced,

  /// Offline or older than `balance.staleAfterSec`: last known value with
  /// an offline glyph.
  stale,

  /// The device could not be verified: "Readings unavailable on this
  /// device" + Retry.
  unavailable,
}

/// Everything [BalanceChip] renders, derived from the app state by
/// [BalanceChipView.from] (display only; the Worker decides, AR8).
@immutable
final class BalanceChipView {
  /// Creates a view.
  const BalanceChipView({required this.balance, required this.sync});

  /// Derives the view from the displayed [balance], the [stale] flag
  /// (`balanceStaleProvider`) and the coordinator's [status].
  factory BalanceChipView.from({
    required CreditBalance? balance,
    required bool stale,
    required SyncStatus status,
  }) {
    final sync = switch (status) {
      SyncStatusUnavailable(:final failure)
          when balance == null || failure is AttestationFailure =>
        BalanceChipSync.unavailable,
      SyncStatusSyncing() => BalanceChipSync.syncing,
      _ when stale => BalanceChipSync.stale,
      _ => BalanceChipSync.synced,
    };
    return BalanceChipView(balance: balance, sync: sync);
  }

  /// The displayed balance; `null` before the first sync.
  final CreditBalance? balance;

  /// The sync state.
  final BalanceChipSync sync;

  /// Free readings left today.
  int get free => balance?.free.remaining ?? 0;

  /// Purchased and earned readings (`paid` clamped at 0, plus `bonus`).
  int get credits => (balance?.bonus ?? 0) + (balance?.displayPaid ?? 0);

  /// The pill variant.
  BalancePillState get pillState {
    if (sync == BalanceChipSync.unavailable) {
      return BalancePillState.unverified;
    }
    if (sync == BalanceChipSync.stale || balance == null) {
      return BalancePillState.stale;
    }
    if (credits > 0) return BalancePillState.credits;
    if (free > 0) return BalancePillState.free;
    return BalancePillState.zero;
  }

  /// The chip sentence ("1 free reading", "3 readings · 1 free today",
  /// "Free reading used · 3 readings", "Free reading used"). [today] is the
  /// S07 wording ("1 free reading today").
  String label(TaroLocalizations l10n, {bool today = false}) {
    if (sync == BalanceChipSync.unavailable) return l10n.balanceUnavailable;
    if (balance == null) return l10n.balanceUnknown;
    if (free > 0 && credits > 0) {
      return l10n.commonItemSeparator(
        l10n.balanceReadings(credits),
        l10n.balanceFreeToday(free),
      );
    }
    if (free > 0) {
      return today
          ? l10n.balanceFreeReadingsToday(free)
          : l10n.balanceFreeReadings(free);
    }
    if (credits > 0) {
      return l10n.commonItemSeparator(
        l10n.balanceFreeUsed,
        l10n.balanceReadings(credits),
      );
    }
    return l10n.balanceFreeUsed;
  }

  @override
  bool operator ==(Object other) =>
      other is BalanceChipView &&
      other.balance == balance &&
      other.sync == sync;

  @override
  int get hashCode => Object.hash(balance, sync);
}

/// The chip's view from the app state (`balanceChipProvider`).
final balanceChipProvider = Provider<BalanceChipView>(
  (ref) => BalanceChipView.from(
    balance: ref.watch(balanceProvider),
    stale: ref.watch(balanceStaleProvider),
    status: ref.watch(syncStatusProvider),
  ),
);

/// The reading balance chip (01 §7.1; S05, S07, S11, S12) over the
/// `taro_ui` [BalancePill].
///
/// Tapping calls [onTap] (the caller opens S10 or S11); in the
/// `unavailable` state it runs a sync pass instead (Retry). The balance is
/// announced politely while syncing (01 §12).
class BalanceChip extends ConsumerWidget {
  /// Creates the chip.
  const BalanceChip({this.onTap, this.today = false, super.key});

  /// Opens the reading options.
  final VoidCallback? onTap;

  /// The S07 wording ("1 free reading today").
  final bool today;

  /// Whether the chip for [view] fits on one line in a [TaroAppBar] that
  /// has a leading button and no title, at the current width and text scale.
  /// Long translations (`uk`, `fr`) move the chip into the body instead of
  /// overflowing the bar (01 §12).
  static bool fitsAppBar(
    BuildContext context,
    BalanceChipView view, {
    bool today = false,
  }) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final style = tokens.typography.label;
    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: scaler,
        textDirection: direction,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    var width = 2 * tokens.space.s5 + measure(view.label(l10n, today: today));
    width += switch (view.pillState) {
      BalancePillState.free || BalancePillState.credits => 2 * tokens.space.s3,
      BalancePillState.zero => 0,
      BalancePillState.stale ||
      BalancePillState.unverified => tokens.size.icon.sm + tokens.space.s3,
    };
    if (view.sync == BalanceChipSync.unavailable) {
      width += 2 * tokens.space.s3 + measure(l10n.commonRetry);
    }
    final available =
        MediaQuery.sizeOf(context).width -
        2 * tokens.space.s2 -
        tokens.size.touchTarget.min -
        tokens.space.s2;
    return width <= available;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final view = ref.watch(balanceChipProvider);
    final label = view.label(l10n, today: today);
    if (view.sync == BalanceChipSync.unavailable) {
      return BalancePill(
        state: BalancePillState.unverified,
        label: label,
        actionLabel: l10n.commonRetry,
        semanticsLabel: l10n.commonItemSeparator(label, l10n.commonRetry),
        onTap: () => ref.read(balanceProvider.notifier).refresh(),
      );
    }
    return BalancePill(
      state: view.pillState,
      label: label,
      onTap: onTap,
      semanticsHint: view.sync == BalanceChipSync.stale
          ? l10n.balanceStale
          : (onTap == null ? null : l10n.balanceOpensOptions),
      announce: view.sync == BalanceChipSync.syncing,
    );
  }
}
