import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:taro/services/iap/store_iap_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/fake_in_app_purchase_platform.dart';

Future<void> _tick(Duration _) => Future<void>.delayed(Duration.zero);

final ProductId _pack = TaroProducts.readings3.id;
final ProductId _removeAds = TaroProducts.removeAds.id;
const _binding = PurchaseBinding(
  appleAccountToken: 'apple-token',
  playAccountId: 'play-account',
);

StoreIapService _ios(
  FakeInAppPurchasePlatform platform, {
  CapturingLogger? logger,
  PurchasesBlockedReason? Function()? blocked,
  Delay delay = _tick,
}) => StoreIapService(
  platform: platform,
  store: StorePlatform.ios,
  logger: logger ?? CapturingLogger(),
  purchasesBlockedReason: blocked ?? () => null,
  delay: delay,
);

StoreIapService _android(
  FakePlayPlatform platform, {
  FakePlayAddition? addition,
  bool withAddition = true,
  CapturingLogger? logger,
}) => StoreIapService(
  platform: platform,
  store: StorePlatform.android,
  logger: logger ?? CapturingLogger(),
  androidAddition: withAddition ? addition ?? FakePlayAddition(platform) : null,
  delay: _tick,
);

void main() {
  group('StoreKit 2', () {
    runIapServiceContract(() => _ios(FakeInAppPurchasePlatform()));
  });

  group('Play Billing', () {
    runIapServiceContract(() => _android(FakePlayPlatform()));
  });

  group('products', () {
    test('maps localized price, rawPrice and currencyCode', () async {
      final platform = FakeInAppPurchasePlatform();
      platform.catalog[_pack.value] = ProductDetails(
        id: _pack.value,
        title: '3 Readings',
        description: '',
        price: '€3,49',
        rawPrice: 3.49,
        currencyCode: 'EUR',
      );
      final iap = _ios(platform);
      expect(iap.cachedProduct(_pack), isNull);
      final listed = expectOk(await iap.products({_pack}));
      const expected = StoreProduct(
        id: ProductId('com.vshyrochuk.taro.readings_3'),
        title: '3 Readings',
        price: '€3,49',
        rawPrice: 3.49,
        currencyCode: 'EUR',
      );
      expect(listed, [expected]);
      expect(iap.cachedProduct(_pack), expected);
    });

    test('drops listings that were not asked for', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      platform.catalog['com.example.extra'] = ProductDetails(
        id: 'com.example.extra',
        title: 'x',
        description: '',
        price: '1',
        rawPrice: 1,
        currencyCode: 'USD',
      );
      // The fake lists only what is asked for; ask for the extra one too
      // but request the pack only through a narrower set.
      final listed = expectOk(await iap.products({_pack}));
      expect([for (final p in listed) p.id], [_pack]);
    });

    test('a thrown query or a query error is productUnavailable', () async {
      final platform = FakeInAppPurchasePlatform()..queryThrows = true;
      final logger = CapturingLogger();
      final iap = _ios(platform, logger: logger);
      expect(
        expectErr(await iap.products({_pack})),
        const Failure.productUnavailable(),
      );
      platform
        ..queryThrows = false
        ..queryError = IAPError(source: 's', code: 'network', message: '');
      expect(
        expectErr(await iap.products({_pack})),
        const Failure.productUnavailable(),
      );
      expect(logger.logged('product query failed'), isTrue);
    });
  });

  group('buy', () {
    test('iOS: appAccountToken binding and autoConsume true', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      final result = expectOk(await iap.buy(_pack, binding: _binding));
      final purchase = (result as StoreBuyPurchased).purchase;
      expect(platform.params.single.applicationUserName, 'apple-token');
      expect(platform.autoConsume, [true]);
      expect(purchase.platform, StorePlatform.ios);
      expect(purchase.transactionId, purchase.txnKey);
      expect(purchase.signedTransaction, startsWith('jws-'));
      expect(purchase.purchaseToken, isNull);
    });

    test('Android: obfuscatedAccountId binding, autoConsume false, '
        'txnKey = sha256(purchaseToken)', () async {
      final platform = FakePlayPlatform();
      final iap = _android(platform);
      final result = expectOk(await iap.buy(_pack, binding: _binding));
      final purchase = (result as StoreBuyPurchased).purchase;
      expect(platform.params.single.applicationUserName, 'play-account');
      expect(platform.autoConsume, [false]);
      expect(purchase.purchaseToken, 'token-1');
      expect(purchase.orderId, 'GPA.1');
      expect(purchase.txnKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(purchase.txnKey, isNot(contains('token')));
    });

    test('Remove Ads uses buyNonConsumable', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      expectOk(await iap.buy(_removeAds, binding: _binding));
      expect(platform.autoConsume, isEmpty);
      expect(platform.params, hasLength(1));
    });

    test('packs are refused while purchasesAllowed is false (RC66)', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(
        platform,
        blocked: () => PurchasesBlockedReason.refundDebt,
      );
      expect(
        expectErr(await iap.buy(_pack, binding: _binding)),
        const Failure.purchasesBlocked(
          reason: PurchasesBlockedReason.refundDebt,
        ),
      );
      expect(platform.params, isEmpty);
      // Remove Banner Ads stays purchasable.
      expect(
        expectOk(await iap.buy(_removeAds, binding: _binding)),
        isA<StoreBuyPurchased>(),
      );
    });

    test('unknown or unlisted products are unavailable', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      expect(
        expectErr(
          await iap.buy(const ProductId('com.example.x'), binding: _binding),
        ),
        const Failure.productUnavailable(),
      );
      platform.catalog.remove(_pack.value);
      expect(
        expectErr(await iap.buy(_pack, binding: _binding)),
        const Failure.productUnavailable(),
      );
    });

    test('pending (Ask to Buy) is reported and tracked', () async {
      final platform = FakeInAppPurchasePlatform()
        ..sheets.add(FakeSheet.pending);
      final iap = _ios(platform);
      final events = <IapEvent>[];
      iap.events.listen(events.add);
      expect(
        expectOk(await iap.buy(_pack, binding: _binding)),
        const StoreBuyResult.pending(),
      );
      await settle();
      expect(iap.pending, {_pack});
      expect(events, [IapEvent.pending(_pack)]);
      // The approval later arrives as a delivery.
      final delivered = <StorePurchase>[];
      iap.deliveries.listen(delivered.add);
      platform.emit([platform.transaction(_pack.value)]);
      await settle();
      expect(delivered.single.productId, _pack);
      expect(iap.pending, isEmpty);
    });

    test('cancel on iOS and on Play (empty product ID)', () async {
      final ios = FakeInAppPurchasePlatform()..sheets.add(FakeSheet.cancel);
      expect(
        expectOk(await _ios(ios).buy(_pack, binding: _binding)),
        const StoreBuyResult.cancelled(),
      );
      final play = FakePlayPlatform()..sheets.add(FakeSheet.cancel);
      expect(
        expectOk(await _android(play).buy(_pack, binding: _binding)),
        const StoreBuyResult.cancelled(),
      );
    });

    test('a store error is a PurchaseFailure with the store code', () async {
      final platform = FakeInAppPurchasePlatform()..sheets.add(FakeSheet.error);
      expect(
        expectErr(await _ios(platform).buy(_pack, binding: _binding)),
        const Failure.purchase(wireCode: 'purchase_error'),
      );
    });

    test('itemAlreadyOwned is alreadyOwned, then answered locally', () async {
      final platform = FakePlayPlatform()..sheets.add(FakeSheet.alreadyOwned);
      final iap = _android(platform);
      expect(
        expectOk(await iap.buy(_removeAds, binding: _binding)),
        const StoreBuyResult.alreadyOwned(),
      );
      expect(
        expectOk(await iap.buy(_removeAds, binding: _binding)),
        const StoreBuyResult.alreadyOwned(),
      );
      expect(platform.params, hasLength(1));
    });

    test('a sheet that fails to launch or throws', () async {
      final platform = FakeInAppPurchasePlatform()
        ..sheets.addAll([FakeSheet.launchFails, FakeSheet.throws]);
      final iap = _ios(platform);
      expect(
        expectErr(await iap.buy(_pack, binding: _binding)),
        const Failure.purchase(wireCode: kStoreLaunchFailedCode),
      );
      expect(
        expectErr(await iap.buy(_pack, binding: _binding)),
        const Failure.purchase(wireCode: 'storekit2_purchase_failed'),
      );
    });

    test('a second sheet while one is open is refused', () async {
      final platform = FakeInAppPurchasePlatform()
        ..sheets.add(FakeSheet.silent);
      final iap = _ios(platform);
      final first = iap.buy(_pack, binding: _binding);
      await settle();
      expect(
        expectErr(await iap.buy(_pack, binding: _binding)),
        const Failure.purchase(wireCode: kStoreBusyCode),
      );
      platform.emit([
        platform.transaction(_pack.value, status: PurchaseStatus.canceled),
      ]);
      expect(expectOk(await first), const StoreBuyResult.cancelled());
    });

    test('a purchased update without a transaction ID fails the buy', () async {
      final platform = FakeInAppPurchasePlatform()
        ..sheets.add(FakeSheet.silent);
      final logger = CapturingLogger();
      final iap = _ios(platform, logger: logger);
      final buying = iap.buy(_pack, binding: _binding);
      await settle();
      platform.emit([
        PurchaseDetails(
          productID: _pack.value,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'app_store',
          ),
          transactionDate: null,
          status: PurchaseStatus.purchased,
        ),
      ]);
      expect(
        expectErr(await buying),
        const Failure.purchase(wireCode: kStoreInvalidTransactionCode),
      );
      expect(logger.logged('without an ID'), isTrue);
    });
  });

  group('stream updates outside buy', () {
    test('deliveries are buffered until the first listener', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      platform.emit([platform.transaction(_pack.value)]);
      await settle();
      final delivered = <StorePurchase>[];
      iap.deliveries.listen(delivered.add);
      await settle();
      expect(delivered.single.productId, _pack);
      expect(delivered.single.isRestored, isFalse);
    });

    test('cancel and error updates become events', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      final events = <IapEvent>[];
      iap.events.listen(events.add);
      final failed = platform.transaction(
        _pack.value,
        status: PurchaseStatus.error,
      );
      platform.emit([
        platform.transaction(_pack.value, status: PurchaseStatus.canceled),
        failed,
        platform.transaction('', status: PurchaseStatus.pending),
      ]);
      await settle();
      expect(events, [
        const IapEvent.cancelled(),
        const IapEvent.failed(Failure.purchase(wireCode: kStoreErrorCode)),
      ]);
    });

    test('updates without an ID or token are dropped', () async {
      final ios = FakeInAppPurchasePlatform();
      final iosIap = _ios(ios);
      final delivered = <StorePurchase>[];
      iosIap.deliveries.listen(delivered.add);
      ios.emit([
        PurchaseDetails(
          productID: _removeAds.value,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'app_store',
          ),
          transactionDate: null,
          status: PurchaseStatus.restored,
        ),
        PurchaseDetails(
          productID: _pack.value,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'app_store',
          ),
          transactionDate: null,
          status: PurchaseStatus.purchased,
        ),
      ]);
      await settle();
      final play = FakePlayPlatform();
      final playIap = _android(play);
      playIap.deliveries.listen(delivered.add);
      play.emit([
        PurchaseDetails(
          purchaseID: '',
          productID: _pack.value,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          transactionDate: null,
          status: PurchaseStatus.purchased,
        ),
      ]);
      await settle();
      expect(delivered, isEmpty);
    });

    test('a Play purchase without an order ID keeps orderId null', () async {
      final play = FakePlayPlatform();
      final iap = _android(play);
      final delivered = <StorePurchase>[];
      iap.deliveries.listen(delivered.add);
      play.emit([
        PurchaseDetails(
          productID: _pack.value,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: 'tok',
            source: 'google_play',
          ),
          transactionDate: null,
          status: PurchaseStatus.purchased,
        ),
      ]);
      await settle();
      expect(delivered.single.orderId, isNull);
      expect(delivered.single.purchaseToken, 'tok');
    });

    test('stream errors are logged', () async {
      final platform = FakeInAppPurchasePlatform();
      final logger = CapturingLogger();
      _ios(platform, logger: logger);
      platform.failStream(StateError('boom'));
      await settle();
      expect(logger.logged('purchase stream error'), isTrue);
    });
  });

  group('finish', () {
    test('iOS completes a delivered transaction', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      final bought = expectOk(await iap.buy(_pack, binding: _binding));
      final purchase = (bought as StoreBuyPurchased).purchase;
      expectOk(await iap.finish(purchase));
      expect(platform.completed, [purchase.transactionId]);
      expect(platform.unfinished, isEmpty);
    });

    test('iOS finishes an outbox row from an earlier launch', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      expectOk(await iap.finish(aStorePurchase(txnKey: '42')));
      expect(platform.completed, ['42']);
    });

    test('a throwing finish is STORE_FINISH_FAILED', () async {
      final platform = FakeInAppPurchasePlatform()..completeThrows = true;
      final logger = CapturingLogger();
      final iap = _ios(platform, logger: logger);
      expect(
        expectErr(await iap.finish(aStorePurchase())),
        const Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
      expect(logger.logged('finish failed'), isTrue);
    });

    test('Android consumes a pack after acknowledging it', () async {
      final platform = FakePlayPlatform();
      final addition = FakePlayAddition(platform);
      final iap = _android(platform, addition: addition);
      final bought = expectOk(await iap.buy(_pack, binding: _binding));
      final purchase = (bought as StoreBuyPurchased).purchase;
      expect(addition.consumed, isEmpty);
      expectOk(await iap.finish(purchase));
      expect(platform.completed, ['token-1']);
      expect(addition.consumed, ['token-1']);
    });

    test('Android: a failed acknowledge still consumes a pack', () async {
      final platform = FakePlayPlatform()
        ..ackResponse = BillingResponse.developerError;
      final addition = FakePlayAddition(platform);
      final logger = CapturingLogger();
      final iap = _android(platform, addition: addition, logger: logger);
      final bought = expectOk(await iap.buy(_pack, binding: _binding));
      expectOk(await iap.finish((bought as StoreBuyPurchased).purchase));
      expect(addition.consumed, hasLength(1));
      expect(logger.logged('acknowledge skipped'), isTrue);
    });

    test('Android: a failed acknowledge fails Remove Ads', () async {
      final platform = FakePlayPlatform()..ackResponse = BillingResponse.error;
      final iap = _android(platform);
      final bought = expectOk(await iap.buy(_removeAds, binding: _binding));
      expect(
        expectErr(await iap.finish((bought as StoreBuyPurchased).purchase)),
        const Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
    });

    test('Android: consume errors fail, itemNotOwned is done', () async {
      final platform = FakePlayPlatform();
      final addition = FakePlayAddition(platform)
        ..consumeResponse = BillingResponse.serviceUnavailable;
      final iap = _android(platform, addition: addition);
      final bought = expectOk(await iap.buy(_pack, binding: _binding));
      final purchase = (bought as StoreBuyPurchased).purchase;
      expect(
        expectErr(await iap.finish(purchase)),
        const Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
      addition.consumeResponse = BillingResponse.itemNotOwned;
      expectOk(await iap.finish(purchase));
    });

    test(
      'Android finds an outbox row from an earlier launch by token',
      () async {
        final platform = FakePlayPlatform();
        final addition = FakePlayAddition(platform);
        final details = platform.transaction(_pack.value);
        platform.unfinished['token-1'] = details;
        final iap = _android(platform, addition: addition);
        final row = aStorePurchase(
          txnKey: 'k',
          platform: StorePlatform.android,
        ).copyWith(purchaseToken: 'token-1');
        expectOk(await iap.finish(row));
        expect(addition.consumed, ['token-1']);
        // Gone from the store: already consumed, nothing to do.
        expectOk(await iap.finish(row));
        expect(addition.consumed, ['token-1']);
      },
    );

    test('Android without the addition, or a failed query, fails', () async {
      final platform = FakePlayPlatform();
      final bare = _android(platform, withAddition: false);
      expect(
        expectErr(
          await bare.finish(aStorePurchase(platform: StorePlatform.android)),
        ),
        const Failure.purchase(wireCode: kStoreErrorCode),
      );
      final addition = FakePlayAddition(platform)
        ..queryError = IAPError(source: 's', code: 'e', message: '');
      final iap = _android(platform, addition: addition);
      expect(
        expectErr(
          await iap.finish(aStorePurchase(platform: StorePlatform.android)),
        ),
        const Failure.purchase(wireCode: kStoreFinishFailedCode),
      );
    });
  });

  group('restore', () {
    test('emits restored with the owned non-consumables', () async {
      final platform = FakeInAppPurchasePlatform()..owned.add(_removeAds.value);
      final iap = _ios(platform);
      final events = <IapEvent>[];
      iap.events.listen(events.add);
      expectOk(await iap.restore());
      await settle();
      expect(events, [
        IapEvent.restored({_removeAds}),
      ]);
      expect(
        expectOk(await iap.buy(_removeAds, binding: _binding)),
        const StoreBuyResult.alreadyOwned(),
      );
    });

    test(
      'a StoreKit 2 batch after restorePurchases returns is collected',
      () async {
        final platform = FakeInAppPurchasePlatform()
          ..owned.add(_removeAds.value)
          ..lateRestoreBatch = true;
        final iap = _ios(
          platform,
          delay: (_) => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        expect(expectOk(await iap.queryOwnership()), {_removeAds});
      },
    );

    test('a failed restore is a PurchaseFailure', () async {
      final platform = FakeInAppPurchasePlatform()..restoreThrows = true;
      final iap = _ios(platform);
      expect(
        expectErr(await iap.restore()),
        const Failure.purchase(wireCode: 'restore_failed'),
      );
      expect(
        expectErr(await iap.queryOwnership()),
        const Failure.purchase(wireCode: 'restore_failed'),
      );
    });
  });

  test('restore maps plugin and unknown exceptions to codes', () async {
    final platform = FakeInAppPurchasePlatform()
      ..restoreException = InAppPurchaseException(
        source: 'app_store',
        code: 'storekit2_restore_failed',
      );
    final iap = _ios(platform);
    expect(
      expectErr(await iap.restore()),
      const Failure.purchase(wireCode: 'storekit2_restore_failed'),
    );
    platform.restoreException = const FormatException('odd');
    expect(
      expectErr(await iap.restore()),
      const Failure.purchase(wireCode: kStoreErrorCode),
    );
  });

  test('the default restore settle is a real timer', () async {
    final platform = FakePlayPlatform()..owned.add(_removeAds.value);
    final iap = StoreIapService(
      platform: platform,
      store: StorePlatform.android,
      logger: CapturingLogger(),
      androidAddition: FakePlayAddition(platform),
    );
    expectOk(await iap.restore());
    expect(
      expectOk(await iap.buy(_removeAds, binding: _binding)),
      const StoreBuyResult.alreadyOwned(),
    );
  });

  group('queryOwnership', () {
    test('iOS reads the current entitlements silently', () async {
      final platform = FakeInAppPurchasePlatform();
      final iap = _ios(platform);
      final events = <IapEvent>[];
      iap.events.listen(events.add);
      expect(expectOk(await iap.queryOwnership()), isEmpty);
      platform.owned.add(_removeAds.value);
      expect(expectOk(await iap.queryOwnership()), {_removeAds});
      expect(platform.restores, 2);
      await settle();
      expect(events, isEmpty);
    });

    test('Play: owned set, unfinished packs and pending purchases', () async {
      final platform = FakePlayPlatform()..owned.add(_removeAds.value);
      final addition = FakePlayAddition(platform);
      final pack = platform.transaction(_pack.value);
      platform.unfinished['token-1'] = pack;
      addition.extra.add(
        platform.transaction(
              TaroProducts.readings10.id.value,
              status: PurchaseStatus.pending,
            )
            as GooglePlayPurchaseDetails,
      );
      final iap = _android(platform, addition: addition);
      final delivered = <StorePurchase>[];
      final events = <IapEvent>[];
      iap.deliveries.listen(delivered.add);
      iap.events.listen(events.add);
      expect(expectOk(await iap.queryOwnership()), {_removeAds});
      await settle();
      expect(delivered.single.purchaseToken, 'token-1');
      expect(delivered.single.isRestored, isFalse);
      expect(iap.pending, {TaroProducts.readings10.id});
      expect(events, [IapEvent.pending(TaroProducts.readings10.id)]);
      // A second query does not redeliver the same transaction.
      expectOk(await iap.queryOwnership());
      await settle();
      expect(delivered, hasLength(1));
    });

    test(
      'Play: an unacknowledged Remove Ads is delivered as restored',
      () async {
        final platform = FakePlayPlatform();
        final addition = FakePlayAddition(platform);
        platform.unfinished['token-1'] = platform.transaction(_removeAds.value);
        final iap = _android(platform, addition: addition);
        final delivered = <StorePurchase>[];
        iap.deliveries.listen(delivered.add);
        expect(expectOk(await iap.queryOwnership()), {_removeAds});
        await settle();
        expect(delivered.single.isRestored, isTrue);
      },
    );

    test('Play: a query error or no addition is an Err', () async {
      final platform = FakePlayPlatform();
      final addition = FakePlayAddition(platform)
        ..queryError = IAPError(source: 's', code: 'service', message: '');
      expect(
        expectErr(
          await _android(platform, addition: addition).queryOwnership(),
        ),
        const Failure.purchase(wireCode: 'service'),
      );
      expect(
        expectErr(
          await _android(platform, withAddition: false).queryOwnership(),
        ),
        const Failure.purchase(wireCode: kStoreErrorCode),
      );
    });
  });

  group('fromPlugin', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('wraps the registered platform and its Play addition', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      final platform = FakePlayPlatform();
      InAppPurchasePlatform.instance = platform;
      InAppPurchasePlatformAddition.instance = FakePlayAddition(platform);
      final iap = StoreIapService.fromPlugin(logger: CapturingLogger());
      final bought = expectOk(await iap.buy(_pack, binding: _binding));
      expect(
        (bought as StoreBuyPurchased).purchase.platform,
        StorePlatform.android,
      );
      expectOk(await iap.queryOwnership());

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      InAppPurchasePlatformAddition.instance = null;
      final ios = FakeInAppPurchasePlatform();
      InAppPurchasePlatform.instance = ios;
      final iosIap = StoreIapService.fromPlugin(
        logger: CapturingLogger(),
        purchasesBlockedReason: () => PurchasesBlockedReason.blocked,
      );
      expect(
        expectErr(await iosIap.buy(_pack, binding: _binding)),
        const Failure.purchasesBlocked(reason: PurchasesBlockedReason.blocked),
      );
      final removeAds = expectOk(
        await iosIap.buy(_removeAds, binding: _binding),
      );
      expect(
        (removeAds as StoreBuyPurchased).purchase.platform,
        StorePlatform.ios,
      );
    });
  });

  test('dispose stops listening and closes the streams', () async {
    final platform = FakeInAppPurchasePlatform();
    final iap = _ios(platform);
    final done = Completer<void>();
    iap.events.listen(null, onDone: done.complete);
    await iap.dispose();
    await done.future;
    expect(platform.hasListener, isFalse);
  });
}
