import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show InAppPurchase;
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show BillingResponse, BillingResultWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart'
    show InAppPurchaseAndroidPlatformAddition;
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'
    show SK2PurchaseDetails;
import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro_core/taro_core.dart';

/// How long a restore waits for the restored batch. StoreKit 2 sends the
/// `Transaction.currentEntitlements` batch from a separate task, so it can
/// arrive after `restorePurchases` has returned; Play adds it before.
const Duration kSk2RestoreSettle = Duration(seconds: 1);

/// The `wireCode` of a buy started while another store sheet is open.
const String kStoreBusyCode = 'STORE_BUSY';

/// The `wireCode` when the store could not open its sheet.
const String kStoreLaunchFailedCode = 'STORE_LAUNCH_FAILED';

/// The `wireCode` of a delivered transaction without an ID or token.
const String kStoreInvalidTransactionCode = 'STORE_INVALID_TRANSACTION';

/// The `wireCode` of a failed finish, acknowledge or consume.
const String kStoreFinishFailedCode = 'STORE_FINISH_FAILED';

/// The `wireCode` of any other store error without its own code.
const String kStoreErrorCode = 'STORE_ERROR';

Future<void> _wait(Duration duration) => Future<void>.delayed(duration);

PurchasesBlockedReason? _neverBlocked() => null;

/// The production `IapService` over `in_app_purchase` with StoreKit 2
/// (AR10, 02 §9.5, 04 §6.1). The only file importing `in_app_purchase*`
/// (`tools/import_rules.yaml`).
///
/// * The store transaction stream is subscribed at construction. A
///   transaction answering an open [buy] is returned by it; every other
///   one (launch redelivery, approved Ask to Buy, restore, Play recovery)
///   goes to [deliveries], buffered until the first listener.
/// * [buy] binds the purchase to the install: `applicationUserName` is
///   `purchaseBinding.appleAccountToken` (StoreKit 2 `appAccountToken`) on
///   iOS and `purchaseBinding.playAccountId` (`obfuscatedAccountId`) on
///   Android (RC9, MO15). Packs are refused while `purchasesAllowed` is
///   false (RC66). Consumables use `buyConsumable(autoConsume:)` with
///   `true` on iOS only: Android consumes in [finish], after the grant.
/// * [finish] is `completePurchase` plus, on Android, `consumePurchase`
///   for consumables. It is never called here: the purchase coordinator
///   calls it after the Worker grant (rule 8).
/// * [queryOwnership] is the silent ownership check (SK2 current
///   entitlements, Play `queryPastPurchases`); [restore] is the
///   user-initiated one.
///
/// Tokens, JWS and install bindings are never logged.
final class StoreIapService implements IapService, StoreOwnership {
  /// An adapter over the plugin [platform] of [store].
  ///
  /// [androidAddition] carries Play `consumePurchase` and
  /// `queryPastPurchases` (required on Android). [purchasesBlockedReason]
  /// reads `balance.purchasesBlockedReason` when `purchasesAllowed` is
  /// false, `null` otherwise. [delay] is the restore settle timer.
  StoreIapService({
    required InAppPurchasePlatform platform,
    required StorePlatform store,
    required Logger logger,
    InAppPurchaseAndroidPlatformAddition? androidAddition,
    PurchasesBlockedReason? Function() purchasesBlockedReason = _neverBlocked,
    Delay delay = _wait,
  }) : _platform = platform,
       _store = store,
       _logger = logger,
       _android = androidAddition,
       _blockedReason = purchasesBlockedReason,
       _delay = delay {
    _deliveries = StreamController<StorePurchase>.broadcast(
      onListen: _flushDeliveries,
    );
    _subscription = platform.purchaseStream.listen(
      _onUpdates,
      onError: (Object error, StackTrace stack) =>
          _logger.warning('purchase stream error', error: error, stack: stack),
    );
  }

  /// The adapter over the registered plugin (`InAppPurchase.instance`
  /// registers StoreKit 2 on iOS and Play Billing on Android).
  factory StoreIapService.fromPlugin({
    required Logger logger,
    PurchasesBlockedReason? Function() purchasesBlockedReason = _neverBlocked,
  }) {
    // Registers the platform implementation and its addition.
    InAppPurchase.instance;
    final addition = InAppPurchasePlatformAddition.instance;
    return StoreIapService(
      platform: InAppPurchasePlatform.instance,
      store: defaultTargetPlatform == TargetPlatform.iOS
          ? StorePlatform.ios
          : StorePlatform.android,
      logger: logger,
      androidAddition: addition is InAppPurchaseAndroidPlatformAddition
          ? addition
          : null,
      purchasesBlockedReason: purchasesBlockedReason,
    );
  }

  final InAppPurchasePlatform _platform;
  final StorePlatform _store;
  final Logger _logger;
  final InAppPurchaseAndroidPlatformAddition? _android;
  final PurchasesBlockedReason? Function() _blockedReason;
  final Delay _delay;

  late final StreamController<StorePurchase> _deliveries;
  final StreamController<IapEvent> _events =
      StreamController<IapEvent>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final List<StorePurchase> _undelivered = [];

  final Map<ProductId, ProductDetails> _catalog = {};
  final Map<String, PurchaseDetails> _open = {};
  final Set<ProductId> _owned = {};
  final List<Set<ProductId>> _collectors = [];
  _BuyWaiter? _waiter;

  bool get _isIos => _store == StorePlatform.ios;

  @override
  final Set<ProductId> pending = {};

  @override
  Stream<StorePurchase> get deliveries => _deliveries.stream;

  @override
  Stream<IapEvent> get events => _events.stream;

  /// The last listing of [id], if [products] loaded it (for the price of
  /// the `purchase_completed` event).
  StoreProduct? cachedProduct(ProductId id) {
    final details = _catalog[id];
    return details == null ? null : _toStoreProduct(details);
  }

  @override
  Future<Result<List<StoreProduct>>> products(Set<ProductId> ids) async {
    final ProductDetailsResponse response;
    try {
      response = await _platform.queryProductDetails({
        for (final id in ids) id.value,
      });
    } on Exception catch (e) {
      _logger.warning('product query failed: ${_code(e)}');
      return const Result.err(Failure.productUnavailable());
    }
    final error = response.error;
    if (error != null && response.productDetails.isEmpty) {
      _logger.warning('product query failed: ${error.code}');
      return const Result.err(Failure.productUnavailable());
    }
    final listed = <StoreProduct>[];
    for (final details in response.productDetails) {
      final id = ProductId(details.id);
      if (!ids.contains(id)) continue;
      _catalog[id] = details;
      listed.add(_toStoreProduct(details));
    }
    return Result.ok(listed);
  }

  @override
  Future<Result<StoreBuyResult>> buy(
    ProductId id, {
    required PurchaseBinding binding,
  }) async {
    final product = TaroProducts.byId(id);
    if (product == null) return const Result.err(Failure.productUnavailable());
    if (product.isConsumable) {
      final blocked = _blockedReason();
      if (blocked != null) {
        return Result.err(Failure.purchasesBlocked(reason: blocked));
      }
    } else if (_owned.contains(id)) {
      return const Result.ok(StoreBuyResult.alreadyOwned());
    }
    if (_waiter != null) {
      return const Result.err(Failure.purchase(wireCode: kStoreBusyCode));
    }
    var details = _catalog[id];
    if (details == null) {
      await products({id});
      details = _catalog[id];
    }
    if (details == null) return const Result.err(Failure.productUnavailable());
    final waiter = _waiter = _BuyWaiter(id);
    final param = PurchaseParam(
      productDetails: details,
      applicationUserName: _isIos
          ? binding.appleAccountToken
          : binding.playAccountId,
    );
    try {
      final launched = product.isConsumable
          ? await _platform.buyConsumable(
              purchaseParam: param,
              autoConsume: _isIos,
            )
          : await _platform.buyNonConsumable(purchaseParam: param);
      if (!launched) {
        _resolve(
          const Result.err(Failure.purchase(wireCode: kStoreLaunchFailedCode)),
        );
      }
    } on Exception catch (e) {
      _logger.warning('buy failed: ${_code(e)}');
      _resolve(Result.err(Failure.purchase(wireCode: _code(e))));
    }
    return waiter.completer.future;
  }

  @override
  Future<Result<void>> restore() async {
    final restored = await _collectRestored();
    switch (restored) {
      case Ok(:final value):
        _owned.addAll(value);
        _events.add(IapEvent.restored(value));
        return const Result.ok(null);
      case Err(:final failure):
        return Result.err(failure);
    }
  }

  @override
  Future<Result<Set<ProductId>>> queryOwnership() async {
    final Result<Set<ProductId>> owned;
    if (_isIos) {
      owned = await _collectRestored();
    } else {
      owned = await _queryPlay();
    }
    if (owned case Ok(:final value)) {
      _owned
        ..clear()
        ..addAll(value);
    }
    return owned;
  }

  @override
  Future<Result<void>> finish(StorePurchase purchase) async {
    final consumable =
        TaroProducts.byId(purchase.productId)?.isConsumable ?? true;
    try {
      final done = _isIos
          ? await _finishIos(purchase)
          : await _finishAndroid(purchase, consumable: consumable);
      if (done case Err()) return done;
    } on Exception catch (e) {
      _logger.warning('finish failed: ${_code(e)}');
      return const Result.err(
        Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
    }
    _open.remove(purchase.txnKey);
    if (!consumable) _owned.add(purchase.productId);
    return const Result.ok(null);
  }

  /// Stops listening to the store and closes the streams.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _deliveries.close();
    await _events.close();
  }

  // Store updates ------------------------------------------------------------

  void _onUpdates(List<PurchaseDetails> updates) {
    updates.forEach(_onUpdate);
  }

  void _onUpdate(PurchaseDetails details) {
    final id = ProductId(details.productID);
    final waiter = _waiter;
    final forWaiter =
        waiter != null && (details.productID.isEmpty || id == waiter.productId);
    switch (details.status) {
      case PurchaseStatus.pending:
        if (details.productID.isNotEmpty) {
          pending.add(id);
          _events.add(IapEvent.pending(id));
        }
        if (forWaiter) _resolve(const Result.ok(StoreBuyResult.pending()));
      case PurchaseStatus.purchased:
        pending.remove(id);
        final purchase = _toStorePurchase(details, isRestored: false);
        if (purchase == null) {
          _logger.warning('purchased transaction without an ID');
          if (forWaiter) {
            _resolve(
              const Result.err(
                Failure.purchase(wireCode: kStoreInvalidTransactionCode),
              ),
            );
          }
          return;
        }
        _open[purchase.txnKey] = details;
        if (forWaiter) {
          _resolve(Result.ok(StoreBuyResult.purchased(purchase)));
        } else {
          _deliver(purchase);
        }
      case PurchaseStatus.restored:
        final purchase = _toStorePurchase(details, isRestored: true);
        if (purchase == null) return;
        _open[purchase.txnKey] = details;
        for (final collected in _collectors) {
          collected.add(id);
        }
        _deliver(purchase);
      case PurchaseStatus.canceled:
        pending.remove(id);
        if (forWaiter) {
          _resolve(const Result.ok(StoreBuyResult.cancelled()));
        } else {
          _events.add(const IapEvent.cancelled());
        }
      case PurchaseStatus.error:
        pending.remove(id);
        final error = details.error;
        if (_isAlreadyOwned(error)) {
          _owned.add(id);
          if (forWaiter) {
            _resolve(const Result.ok(StoreBuyResult.alreadyOwned()));
          }
          return;
        }
        final failure = Failure.purchase(
          wireCode: error?.code ?? kStoreErrorCode,
        );
        _logger.info('store error: ${failure.code}');
        if (forWaiter) {
          _resolve(Result.err(failure));
        } else {
          _events.add(IapEvent.failed(failure));
        }
    }
  }

  void _resolve(Result<StoreBuyResult> result) {
    final waiter = _waiter;
    if (waiter == null) return;
    _waiter = null;
    waiter.completer.complete(result);
  }

  void _deliver(StorePurchase purchase) {
    if (_deliveries.hasListener) {
      _deliveries.add(purchase);
    } else {
      _undelivered.add(purchase);
    }
  }

  void _flushDeliveries() {
    final buffered = [..._undelivered];
    _undelivered.clear();
    buffered.forEach(_deliveries.add);
  }

  bool _isAlreadyOwned(IAPError? error) =>
      error != null &&
      (error.message.contains(BillingResponse.itemAlreadyOwned.name) ||
          error.code.contains(BillingResponse.itemAlreadyOwned.name));

  // Restore and ownership ----------------------------------------------------

  Future<Result<Set<ProductId>>> _collectRestored() async {
    final collected = <ProductId>{};
    _collectors.add(collected);
    try {
      await _platform.restorePurchases();
      await _delay(_isIos ? kSk2RestoreSettle : Duration.zero);
    } on Exception catch (e) {
      _logger.info('restore failed: ${_code(e)}');
      return Result.err(Failure.purchase(wireCode: _code(e)));
    } finally {
      _collectors.remove(collected);
    }
    return Result.ok({
      for (final id in collected)
        if (TaroProducts.byId(id)?.isConsumable == false) id,
    });
  }

  Future<Result<Set<ProductId>>> _queryPlay() async {
    final android = _android;
    if (android == null) {
      return const Result.err(Failure.purchase(wireCode: kStoreErrorCode));
    }
    final response = await android.queryPastPurchases();
    final error = response.error;
    if (error != null) {
      _logger.info('ownership query failed: ${error.code}');
      return Result.err(Failure.purchase(wireCode: error.code));
    }
    final owned = <ProductId>{};
    for (final details in response.pastPurchases) {
      final id = ProductId(details.productID);
      final consumable = TaroProducts.byId(id)?.isConsumable ?? true;
      if (details.status == PurchaseStatus.pending) {
        if (pending.add(id)) _events.add(IapEvent.pending(id));
        continue;
      }
      if (!consumable) owned.add(id);
      // Unconsumed packs and unacknowledged Remove Ads were never
      // finished: Play does not redeliver them on the purchase stream.
      if (consumable || details.pendingCompletePurchase) {
        final purchase = _toStorePurchase(details, isRestored: !consumable);
        if (purchase == null || _open.containsKey(purchase.txnKey)) continue;
        _open[purchase.txnKey] = details;
        _deliver(purchase);
      }
    }
    return Result.ok(owned);
  }

  // Finishing ----------------------------------------------------------------

  Future<Result<void>> _finishIos(StorePurchase purchase) async {
    final details =
        _open[purchase.txnKey] ??
        SK2PurchaseDetails(
          productID: purchase.productId.value,
          purchaseID: purchase.transactionId ?? purchase.txnKey,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: purchase.signedTransaction ?? '',
            source: 'app_store',
          ),
          transactionDate: null,
          status: PurchaseStatus.purchased,
        );
    await _platform.completePurchase(details);
    return const Result.ok(null);
  }

  Future<Result<void>> _finishAndroid(
    StorePurchase purchase, {
    required bool consumable,
  }) async {
    final android = _android;
    if (android == null) {
      return const Result.err(Failure.purchase(wireCode: kStoreErrorCode));
    }
    var details = _open[purchase.txnKey];
    if (details == null) {
      final response = await android.queryPastPurchases();
      if (response.error != null) {
        return const Result.err(
          Failure.purchase(wireCode: kStoreFinishFailedCode),
        );
      }
      details = response.pastPurchases
          .where(
            (d) =>
                d.verificationData.serverVerificationData ==
                purchase.purchaseToken,
          )
          .firstOrNull;
      // Already consumed or acknowledged: nothing left to finish.
      if (details == null) return const Result.ok(null);
    }
    final acknowledged = await _acknowledge(details);
    if (consumable) {
      // The Worker acknowledged after the grant; consuming also
      // acknowledges, so a failed client acknowledge is not fatal.
      if (!acknowledged) _logger.info('acknowledge skipped before consume');
      final consumed = await android.consumePurchase(details);
      final code = consumed.responseCode;
      if (code != BillingResponse.ok && code != BillingResponse.itemNotOwned) {
        _logger.warning('consume failed: ${code.name}');
        return const Result.err(
          Failure.purchase(wireCode: kStoreFinishFailedCode),
        );
      }
    } else if (!acknowledged) {
      return const Result.err(
        Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
    }
    return const Result.ok(null);
  }

  /// `completePurchase` on Play returns a `BillingResultWrapper` behind the
  /// platform interface's `Future<void>`.
  Future<bool> _acknowledge(PurchaseDetails details) async {
    final result = await Future<Object?>.value(
      _platform.completePurchase(details),
    );
    return result is! BillingResultWrapper ||
        result.responseCode == BillingResponse.ok;
  }

  // Mapping ------------------------------------------------------------------

  StoreProduct _toStoreProduct(ProductDetails details) => StoreProduct(
    id: ProductId(details.id),
    title: details.title,
    price: details.price,
    rawPrice: details.rawPrice,
    currencyCode: details.currencyCode,
  );

  StorePurchase? _toStorePurchase(
    PurchaseDetails details, {
    required bool isRestored,
  }) {
    final productId = ProductId(details.productID);
    final server = details.verificationData.serverVerificationData;
    if (_isIos) {
      final transactionId = details.purchaseID;
      if (transactionId == null || transactionId.isEmpty) return null;
      return StorePurchase(
        txnKey: transactionId,
        productId: productId,
        platform: StorePlatform.ios,
        transactionId: transactionId,
        signedTransaction: server.isEmpty ? null : server,
        isRestored: isRestored,
      );
    }
    if (server.isEmpty) return null;
    final orderId = details.purchaseID;
    return StorePurchase(
      txnKey: sha256.convert(utf8.encode(server)).toString(),
      productId: productId,
      platform: StorePlatform.android,
      purchaseToken: server,
      orderId: orderId == null || orderId.isEmpty ? null : orderId,
      isRestored: isRestored,
    );
  }

  static String _code(Exception e) => switch (e) {
    PlatformException(:final code) => code,
    InAppPurchaseException(:final code) => code,
    _ => kStoreErrorCode,
  };
}

final class _BuyWaiter {
  _BuyWaiter(this.productId);

  final ProductId productId;
  final Completer<Result<StoreBuyResult>> completer = Completer();
}
