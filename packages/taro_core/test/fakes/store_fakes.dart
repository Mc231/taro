import 'dart:async';

import 'package:taro_core/taro_core.dart';

import 'builders/builders.dart';
import 'fake_behaviour.dart';

/// A store (StoreKit 2 / Play Billing) with in-memory transactions.
///
/// * [buy] delivers a new transaction (`txn-1`, `txn-2`, …) unless a
///   result is queued with [nextBuy] or a failure with `failNext`; an
///   owned non-consumable is `alreadyOwned`; a product with a pending
///   approval is `pending`.
/// * [emitPending] starts an Ask to Buy approval; [approvePending]
///   delivers it on [deliveries]; [redeliver] re-sends a transaction (as
///   on launch for an unfinished one).
/// * [restore] re-delivers owned non-consumables with `isRestored`.
final class FakeIapService with FakeBehaviour implements IapService {
  /// A store listing [catalog] (every Taro product by default).
  FakeIapService({
    Map<ProductId, StoreProduct>? catalog,
    this.platform = StorePlatform.ios,
  }) : catalog =
           catalog ??
           {for (final p in TaroProducts.all) p.id: aStoreProduct(p)};

  @override
  String get fakeName => 'IapService';

  /// Listed products.
  final Map<ProductId, StoreProduct> catalog;

  /// The platform of delivered transactions.
  final StorePlatform platform;

  /// Owned non-consumables.
  final Set<ProductId> owned = {};

  /// Delivered, not yet finished transactions by `txnKey`.
  final Map<String, StorePurchase> unfinished = {};

  /// `txnKey`s passed to [finish] successfully.
  final List<String> finished = [];

  /// The binding of every [buy] call.
  final List<PurchaseBinding> bindings = [];

  @override
  final Set<ProductId> pending = {};

  final List<StoreBuyResult> _scripted = [];
  final StreamController<StorePurchase> _deliveries =
      StreamController.broadcast();
  final StreamController<IapEvent> _events = StreamController.broadcast();
  int _txn = 0;

  /// Makes the next [buy] return [result].
  void nextBuy(StoreBuyResult result) => _scripted.add(result);

  /// Marks [id] owned (a non-consumable bought earlier).
  void own(ProductId id) => owned.add(id);

  /// A new transaction of [id] (unfinished until [finish]).
  StorePurchase newTransaction(ProductId id, {bool isRestored = false}) {
    final purchase = aStorePurchase(
      txnKey: 'txn-${++_txn}',
      productId: id,
      platform: platform,
      isRestored: isRestored,
    );
    unfinished[purchase.txnKey] = purchase;
    return purchase;
  }

  /// Ask to Buy / deferred payment for [id].
  void emitPending(ProductId id) {
    pending.add(id);
    _events.add(IapEvent.pending(id));
  }

  /// Approves the pending purchase of [id] and delivers it.
  StorePurchase approvePending(ProductId id) {
    pending.remove(id);
    final purchase = newTransaction(id);
    _deliveries.add(purchase);
    return purchase;
  }

  /// Re-delivers [purchase] (an unfinished transaction on launch).
  void redeliver(StorePurchase purchase) {
    unfinished[purchase.txnKey] = purchase;
    _deliveries.add(purchase);
  }

  /// Emits [event] on [events].
  void emit(IapEvent event) => _events.add(event);

  @override
  Stream<StorePurchase> get deliveries => _deliveries.stream;

  @override
  Stream<IapEvent> get events => _events.stream;

  @override
  Future<Result<List<StoreProduct>>> products(Set<ProductId> ids) async {
    record('products');
    final failure = takeFailure('products');
    if (failure != null) return Result.err(failure);
    return Result.ok([
      for (final id in ids)
        if (catalog[id] != null) catalog[id]!,
    ]);
  }

  @override
  Future<Result<StoreBuyResult>> buy(
    ProductId id, {
    required PurchaseBinding binding,
  }) async {
    record('buy');
    bindings.add(binding);
    final failure = takeFailure('buy');
    if (failure != null) return Result.err(failure);
    if (_scripted.isNotEmpty) return Result.ok(_scripted.removeAt(0));
    if (!catalog.containsKey(id)) {
      return const Result.err(Failure.productUnavailable());
    }
    if (pending.contains(id)) return const Result.ok(StoreBuyResult.pending());
    final consumable = TaroProducts.byId(id)?.isConsumable ?? true;
    if (!consumable && owned.contains(id)) {
      return const Result.ok(StoreBuyResult.alreadyOwned());
    }
    if (!consumable) owned.add(id);
    return Result.ok(StoreBuyResult.purchased(newTransaction(id)));
  }

  @override
  Future<Result<void>> restore() async {
    record('restore');
    final failure = takeFailure('restore');
    if (failure != null) return Result.err(failure);
    for (final id in owned) {
      _deliveries.add(newTransaction(id, isRestored: true));
    }
    _events.add(IapEvent.restored({...owned}));
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> finish(StorePurchase purchase) async {
    record('finish');
    final failure = takeFailure('finish');
    if (failure != null) return Result.err(failure);
    unfinished.remove(purchase.txnKey);
    finished.add(purchase.txnKey);
    return const Result.ok(null);
  }
}

/// A [PurchaseOutboxDrainer] with scripted outcomes (the app's
/// `PurchaseCoordinator` in production).
///
/// [drainOutbox] records the reason and returns [outcomes] unless a failure
/// is queued with `failNext`.
final class FakePurchaseOutboxDrainer
    with FakeBehaviour
    implements PurchaseOutboxDrainer {
  /// A drainer answering [outcomes] (none by default).
  FakePurchaseOutboxDrainer([this.outcomes = const {}]);

  @override
  String get fakeName => 'PurchaseOutboxDrainer';

  /// What every [drainOutbox] returns.
  Map<String, PurchaseOutcome> outcomes;

  /// The reason of every [drainOutbox] call.
  final List<SyncReason> reasons = [];

  @override
  Future<Result<Map<String, PurchaseOutcome>>> drainOutbox({
    required SyncReason reason,
  }) async {
    record('drainOutbox');
    reasons.add(reason);
    final failure = takeFailure('drainOutbox');
    if (failure != null) return Result.err(failure);
    return Result.ok(outcomes);
  }
}
