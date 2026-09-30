import 'dart:async';

import 'package:flutter/services.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:taro_core/taro_core.dart';

/// What the fake store does when a purchase sheet opens.
enum FakeSheet {
  /// The user pays: a `purchased` update.
  purchase,

  /// Ask to Buy / slow card: a `pending` update.
  pending,

  /// The user cancels: a `canceled` update (Android: empty product ID).
  cancel,

  /// A store error update.
  error,

  /// Play `itemAlreadyOwned`.
  alreadyOwned,

  /// The sheet stays open: no update.
  silent,

  /// `buy*` returns `false`.
  launchFails,

  /// `buy*` throws a `PlatformException`.
  throws,
}

/// A StoreKit 2 / Play Billing store behind the plugin platform interface
/// (04 §15 "Unit — adapters"). Consumables are unfinished until
/// `completePurchase` (iOS) or `consumePurchase` (Android); non-consumables
/// stay in the current entitlements.
base class FakeInAppPurchasePlatform extends InAppPurchasePlatform {
  /// A store for [store] listing every Taro product.
  FakeInAppPurchasePlatform({this.store = StorePlatform.ios});

  /// The platform flavour of delivered details.
  final StorePlatform store;

  final StreamController<List<PurchaseDetails>> _stream =
      StreamController.broadcast();

  /// Listed products by ID.
  final Map<String, ProductDetails> catalog = {
    for (final p in TaroProducts.all)
      p.id.value: ProductDetails(
        id: p.id.value,
        title: p.alias,
        description: p.alias,
        price: r'$2.99',
        rawPrice: 2.99,
        currencyCode: 'USD',
      ),
  };

  /// Scripted sheets, used in order; then [FakeSheet.purchase].
  final List<FakeSheet> sheets = [];

  /// Non-consumables in the current entitlements.
  final Set<String> owned = {};

  /// Delivered, unfinished transactions by purchase ID (iOS) or token.
  final Map<String, PurchaseDetails> unfinished = {};

  /// Every `PurchaseParam` passed to a buy.
  final List<PurchaseParam> params = [];

  /// The `autoConsume` flag of every `buyConsumable`.
  final List<bool> autoConsume = [];

  /// The purchase IDs (iOS) or tokens (Android) passed to
  /// `completePurchase`.
  final List<String> completed = [];

  /// How often `restorePurchases` ran.
  int restores = 0;

  /// Makes `queryProductDetails` throw.
  bool queryThrows = false;

  /// An error reported by `queryProductDetails` (with no products).
  IAPError? queryError;

  /// Makes `restorePurchases` throw.
  bool restoreThrows = false;

  /// Thrown by `restorePurchases` when set (after [restoreThrows]).
  Exception? restoreException;

  /// Makes `completePurchase` throw.
  bool completeThrows = false;

  /// What Play `acknowledgePurchase` answers.
  BillingResponse ackResponse = BillingResponse.ok;

  /// Delay the restored batch until after `restorePurchases` returns (SK2).
  bool lateRestoreBatch = false;

  int _next = 0;

  /// Pushes raw updates onto the purchase stream.
  void emit(List<PurchaseDetails> updates) => _stream.add(updates);

  /// Pushes an error onto the purchase stream.
  void failStream(Object error) => _stream.addError(error);

  /// Whether a listener is attached.
  bool get hasListener => _stream.hasListener;

  /// A new transaction of [productId] with [status].
  PurchaseDetails transaction(
    String productId, {
    PurchaseStatus status = PurchaseStatus.purchased,
    bool acknowledged = false,
  }) {
    final n = ++_next;
    if (store == StorePlatform.ios) {
      return SK2PurchaseDetails(
        productID: productId,
        purchaseID: status == PurchaseStatus.pending ? null : '$n',
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'jws-$n',
          source: 'app_store',
        ),
        transactionDate: '0',
        status: status,
      );
    }
    return GooglePlayPurchaseDetails(
      purchaseID: 'GPA.$n',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: 'token-$n',
        source: 'google_play',
      ),
      transactionDate: '0',
      billingClientPurchase: PurchaseWrapper(
        orderId: 'GPA.$n',
        packageName: 'com.vshyrochuk.taro',
        purchaseTime: 0,
        purchaseToken: 'token-$n',
        signature: '',
        products: [productId],
        isAutoRenewing: false,
        originalJson: '{}',
        isAcknowledged: acknowledged,
        purchaseState: status == PurchaseStatus.pending
            ? PurchaseStateWrapper.pending
            : PurchaseStateWrapper.purchased,
      ),
      status: status,
    );
  }

  /// The key of [details] in [unfinished].
  String keyOf(PurchaseDetails details) => store == StorePlatform.ios
      ? details.purchaseID!
      : details.verificationData.serverVerificationData;

  bool _consumable(String id) =>
      TaroProducts.byId(ProductId(id))?.isConsumable ?? true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    if (queryThrows) {
      throw PlatformException(code: 'storekit2_failed_to_fetch_product');
    }
    final error = queryError;
    if (error != null) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: identifiers.toList(),
        error: error,
      );
    }
    return ProductDetailsResponse(
      productDetails: [
        for (final id in identifiers)
          if (catalog[id] != null) catalog[id]!,
      ],
      notFoundIDs: [
        for (final id in identifiers)
          if (catalog[id] == null) id,
      ],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    params.add(purchaseParam);
    return _sheet(purchaseParam.productDetails.id);
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    params.add(purchaseParam);
    this.autoConsume.add(autoConsume);
    return _sheet(purchaseParam.productDetails.id);
  }

  Future<bool> _sheet(String id) async {
    final sheet = sheets.isEmpty ? FakeSheet.purchase : sheets.removeAt(0);
    switch (sheet) {
      case FakeSheet.purchase:
        final details = transaction(id);
        unfinished[keyOf(details)] = details;
        if (!_consumable(id)) owned.add(id);
        scheduleMicrotask(() => emit([details]));
      case FakeSheet.pending:
        scheduleMicrotask(
          () => emit([transaction(id, status: PurchaseStatus.pending)]),
        );
      case FakeSheet.cancel:
        final cancelled = transaction(
          store == StorePlatform.android ? '' : id,
          status: PurchaseStatus.canceled,
        );
        scheduleMicrotask(() => emit([cancelled]));
      case FakeSheet.error:
        final failed = transaction(id, status: PurchaseStatus.error)
          ..error = IAPError(
            source: 'store',
            code: 'purchase_error',
            message: 'BillingResponse.error',
          );
        scheduleMicrotask(() => emit([failed]));
      case FakeSheet.alreadyOwned:
        final owned = transaction(id, status: PurchaseStatus.error)
          ..error = IAPError(
            source: 'google_play',
            code: 'purchase_error',
            message: 'BillingResponse.itemAlreadyOwned',
          );
        scheduleMicrotask(() => emit([owned]));
      case FakeSheet.silent:
        break;
      case FakeSheet.launchFails:
        return false;
      case FakeSheet.throws:
        throw PlatformException(code: 'storekit2_purchase_failed');
    }
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      recordCompletion(purchase);

  /// Records a `completePurchase` of [purchase].
  Future<void> recordCompletion(PurchaseDetails purchase) async {
    if (completeThrows) throw PlatformException(code: 'finish_failed');
    final key = keyOf(purchase);
    completed.add(key);
    if (store == StorePlatform.ios) unfinished.remove(key);
  }

  /// Play's `completePurchase` returns the acknowledge result.
  Future<BillingResultWrapper> acknowledge(PurchaseDetails purchase) async {
    await recordCompletion(purchase);
    if (!_consumable(purchase.productID) && ackResponse == BillingResponse.ok) {
      unfinished.remove(keyOf(purchase));
    }
    return BillingResultWrapper(responseCode: ackResponse);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    if (restoreThrows) throw PlatformException(code: 'restore_failed');
    final exception = restoreException;
    if (exception != null) throw exception;
    final batch = [
      for (final id in owned)
        transaction(id, status: PurchaseStatus.restored, acknowledged: true),
      if (store == StorePlatform.android)
        for (final d in unfinished.values)
          if (_consumable(d.productID))
            transaction(d.productID, status: PurchaseStatus.restored),
    ];
    if (lateRestoreBatch) {
      unawaited(Future<void>.delayed(Duration.zero, () => emit(batch)));
    } else {
      emit(batch);
    }
  }

  @override
  Future<String> countryCode() async => 'USA';
}

/// Play's `completePurchase`, which returns a `BillingResultWrapper`.
final class FakePlayPlatform extends FakeInAppPurchasePlatform {
  /// A Play store.
  FakePlayPlatform() : super(store: StorePlatform.android);

  @override
  Future<BillingResultWrapper> completePurchase(PurchaseDetails purchase) =>
      acknowledge(purchase);
}

/// The Play addition: `consumePurchase` and `queryPastPurchases` over the
/// state of [store].
final class FakePlayAddition implements InAppPurchaseAndroidPlatformAddition {
  /// An addition over [store].
  FakePlayAddition(this.store);

  /// The store whose purchases are queried and consumed.
  final FakeInAppPurchasePlatform store;

  /// Tokens passed to `consumePurchase`.
  final List<String> consumed = [];

  /// What `consumePurchase` answers.
  BillingResponse consumeResponse = BillingResponse.ok;

  /// An error reported by `queryPastPurchases`.
  IAPError? queryError;

  /// Extra past purchases (pending ones, for example).
  final List<GooglePlayPurchaseDetails> extra = [];

  /// How often `queryPastPurchases` ran.
  int queries = 0;

  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    consumed.add(token);
    if (consumeResponse == BillingResponse.ok) store.unfinished.remove(token);
    return BillingResultWrapper(responseCode: consumeResponse);
  }

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases({
    String? applicationUserName,
  }) async {
    queries++;
    final error = queryError;
    if (error != null) {
      return QueryPurchaseDetailsResponse(
        pastPurchases: const [],
        error: error,
      );
    }
    return QueryPurchaseDetailsResponse(
      pastPurchases: [
        for (final d in store.unfinished.values) d as GooglePlayPurchaseDetails,
        for (final id in store.owned)
          if (!store.unfinished.values.any((d) => d.productID == id))
            store.transaction(id, acknowledged: true)
                as GooglePlayPurchaseDetails,
        ...extra,
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
