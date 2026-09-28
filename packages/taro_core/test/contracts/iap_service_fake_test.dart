import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runIapServiceContract(FakeIapService.new);

  group('FakeIapService hooks', () {
    late FakeIapService iap;
    const binding = PurchaseBinding();
    final pack = TaroProducts.readings10.id;

    setUp(() => iap = FakeIapService(platform: StorePlatform.android));

    test('emitPending, then approvePending delivers', () async {
      final events = <IapEvent>[];
      final delivered = <StorePurchase>[];
      final subs = [
        iap.events.listen(events.add),
        iap.deliveries.listen(delivered.add),
      ];
      iap.emitPending(pack);
      expect(iap.pending, {pack});
      expect(
        expectOk(await iap.buy(pack, binding: binding)),
        const StoreBuyResult.pending(),
      );
      final approved = iap.approvePending(pack);
      await settle();
      for (final s in subs) {
        await s.cancel();
      }
      expect(events, [IapEvent.pending(pack)]);
      expect(delivered, [approved]);
      expect(approved.purchaseToken, isNotNull);
      expect(iap.pending, isEmpty);
      expect(iap.unfinished, contains(approved.txnKey));
    });

    test('redeliver re-sends an unfinished transaction', () async {
      final delivered = <StorePurchase>[];
      final sub = iap.deliveries.listen(delivered.add);
      final txn = aStorePurchase(txnKey: 'old');
      iap.redeliver(txn);
      await settle();
      await sub.cancel();
      expect(delivered, [txn]);
      expect(iap.unfinished['old'], txn);
    });

    test('nextBuy, failNext, unknown products and emit', () async {
      iap
        ..nextBuy(const StoreBuyResult.cancelled())
        ..failNext(const Failure.purchaseCancelled(), on: 'buy');
      expect(
        expectErr(await iap.buy(pack, binding: binding)),
        const Failure.purchaseCancelled(),
      );
      expect(
        expectOk(await iap.buy(pack, binding: binding)),
        const StoreBuyResult.cancelled(),
      );
      expect(
        expectErr(
          await iap.buy(const ProductId('com.example.x'), binding: binding),
        ),
        const Failure.productUnavailable(),
      );
      final events = <IapEvent>[];
      final sub = iap.events.listen(events.add);
      iap.emit(const IapEvent.cancelled());
      await settle();
      await sub.cancel();
      expect(events, [const IapEvent.cancelled()]);
      expect(iap.bindings, hasLength(3));
      for (final m in ['products', 'restore', 'finish']) {
        iap.failNext(const Failure.network(), on: m);
      }
      expect((await iap.products({pack})).isErr, isTrue);
      expect((await iap.restore()).isErr, isTrue);
      expect((await iap.finish(aStorePurchase())).isErr, isTrue);
    });

    test('own marks a non-consumable as owned', () async {
      iap.own(TaroProducts.removeAds.id);
      expect(
        expectOk(await iap.buy(TaroProducts.removeAds.id, binding: binding)),
        const StoreBuyResult.alreadyOwned(),
      );
    });
  });
}
