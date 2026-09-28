import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `EntitlementCache` contract (04 §6.4). [create] returns an empty
/// cache.
void runEntitlementCacheContract(EntitlementCache Function() create) {
  group('EntitlementCache contract', () {
    late EntitlementCache cache;

    setUp(() => cache = create());

    test('an empty cache reads unknown, which does not remove ads', () {
      expect(cache.read(), Entitlement.unknown);
      expect(cache.read().removesAds, isFalse);
    });

    test('reads back what was written', () async {
      final owned = Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
        verifiedAt: DateTime.utc(2026, 9, 26),
      );
      expectOk(await cache.write(owned));
      expect(cache.read().removeAds, EntitlementState.owned);
      expect(cache.read().removesAds, isTrue);
      expect(cache.read().verifiedAt, DateTime.utc(2026, 9, 26));
    });

    test('the last write wins', () async {
      await cache.write(
        const Entitlement(
          removeAds: EntitlementState.owned,
          source: EntitlementSource.store,
        ),
      );
      await cache.write(
        const Entitlement(
          removeAds: EntitlementState.notOwned,
          source: EntitlementSource.store,
        ),
      );
      expect(cache.read().removeAds, EntitlementState.notOwned);
    });
  });
}
