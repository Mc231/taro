import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runEntitlementCacheContract(FakeEntitlementCache.new);

  test('failNext keeps the cached value', () async {
    final cache = FakeEntitlementCache()..failNext(const Failure.storage());
    final result = await cache.write(
      const Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
      ),
    );
    expect(result.isErr, isTrue);
    expect(cache.read(), Entitlement.unknown);
  });
}
