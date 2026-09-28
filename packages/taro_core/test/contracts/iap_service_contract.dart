import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `IapService` contract (04 §6.1, rule 8, rule 9). [create] returns a
/// store (sandbox) listing every Taro product, with nothing owned.
void runIapServiceContract(IapService Function() create) {
  group('IapService contract', () {
    late IapService iap;
    final pack = TaroProducts.readings3.id;
    final removeAds = TaroProducts.removeAds.id;
    const binding = PurchaseBinding(appleAccountToken: 'token');

    setUp(() => iap = create());

    test('lists requested products with a localized price', () async {
      final ids = {for (final p in TaroProducts.all) p.id};
      final products = expectOk(await iap.products(ids));
      expect({for (final p in products) p.id}, ids);
      for (final p in products) {
        expect(TaroProducts.byId(p.id), isNotNull, reason: p.id.value);
        expect(p.price, isNotEmpty);
        expect(p.rawPrice, greaterThan(0));
        expect(p.currencyCode, matches(RegExp(r'^[A-Z]{3}$')));
      }
    });

    test('omits unknown products', () async {
      final products = expectOk(
        await iap.products({const ProductId('com.example.unknown'), pack}),
      );
      expect([for (final p in products) p.id], [pack]);
    });

    test('buying a pack delivers a transaction to verify', () async {
      final result = expectOk(await iap.buy(pack, binding: binding));
      final purchase = (result as StoreBuyPurchased).purchase;
      expect(purchase.productId, pack);
      expect(purchase.txnKey, isNotEmpty);
      expect(purchase.isRestored, isFalse);
      expectOk(await iap.finish(purchase));
    });

    test('each purchase is its own transaction', () async {
      final a = expectOk(await iap.buy(pack, binding: binding));
      final b = expectOk(await iap.buy(pack, binding: binding));
      expect(
        (a as StoreBuyPurchased).purchase.txnKey,
        isNot((b as StoreBuyPurchased).purchase.txnKey),
      );
    });

    test('finish is idempotent', () async {
      final result = expectOk(await iap.buy(pack, binding: binding));
      final purchase = (result as StoreBuyPurchased).purchase;
      expectOk(await iap.finish(purchase));
      expectOk(await iap.finish(purchase));
    });

    test('an owned non-consumable is alreadyOwned', () async {
      final first = expectOk(await iap.buy(removeAds, binding: binding));
      await iap.finish((first as StoreBuyPurchased).purchase);
      expect(
        expectOk(await iap.buy(removeAds, binding: binding)),
        const StoreBuyResult.alreadyOwned(),
      );
    });

    test('restore re-delivers owned non-consumables only', () async {
      final bought = expectOk(await iap.buy(removeAds, binding: binding));
      await iap.finish((bought as StoreBuyPurchased).purchase);
      final pb = expectOk(await iap.buy(pack, binding: binding));
      await iap.finish((pb as StoreBuyPurchased).purchase);

      final delivered = <StorePurchase>[];
      final sub = iap.deliveries.listen(delivered.add);
      expectOk(await iap.restore());
      await settle();
      await sub.cancel();
      expect(delivered, isNotEmpty);
      expect(delivered.every((p) => p.productId == removeAds), isTrue);
      expect(delivered.every((p) => p.isRestored), isTrue);
    });

    test('nothing is pending at first', () {
      expect(iap.pending, isEmpty);
    });
  });
}
