import 'package:taro_core/taro_core.dart';

/// Products whose purchase awaits approval (Ask to Buy, Play slow payment,
/// `202 pending`) (04 §6.3, 02 §9.5 step 7).
///
/// In memory only: a pending mark settles on a completed, cancelled or
/// failed purchase and lapses after `store.pendingHoldMinutes` (30) without
/// a store settlement, so a declined Ask to Buy (StoreKit stays silent)
/// never blocks the pack for the rest of the session. While a pack is
/// pending its button shows "Waiting for approval"; other packs stay
/// purchasable.
final class PendingPurchaseTracker {
  /// A tracker reading the time from [clock] and the hold from
  /// [holdMinutes] (`store.pendingHoldMinutes`, read on every check so a
  /// config refresh applies at once).
  PendingPurchaseTracker({
    required Clock clock,
    required int Function() holdMinutes,
  }) : _clock = clock,
       _holdMinutes = holdMinutes;

  final Clock _clock;
  final int Function() _holdMinutes;
  final Map<ProductId, DateTime> _since = {};

  /// Marks [productId] pending from now (a repeated mark restarts the hold).
  void markPending(ProductId productId) => _since[productId] = _clock.now();

  /// Clears the pending mark of [productId] (completed, cancelled, failed).
  void settle(ProductId productId) => _since.remove(productId);

  /// Whether [productId] is pending and its hold has not lapsed.
  bool isPending(ProductId productId) {
    final since = _since[productId];
    if (since == null) return false;
    final hold = Duration(minutes: _holdMinutes());
    if (_clock.now().difference(since) >= hold) {
      _since.remove(productId);
      return false;
    }
    return true;
  }

  /// Every product that is still pending.
  Set<ProductId> get pending => {
    for (final id in _since.keys.toList())
      if (isPending(id)) id,
  };
}
