import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/entitlement_cache_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';

void main() {
  late DeviceDatabase db;
  late CapturingLogger logger;
  late EntitlementCacheImpl cache;

  Future<EntitlementCacheImpl> open() async {
    final opened = await EntitlementCacheImpl.open(
      dao: db.entitlementsDao,
      logger: logger,
    );
    addTearDown(opened.close);
    return opened;
  }

  setUp(() async {
    db = memoryDevice();
    logger = CapturingLogger();
    addTearDown(db.close);
    cache = await open();
  });

  runEntitlementCacheContract(() => cache);

  final owned = Entitlement(
    removeAds: EntitlementState.owned,
    source: EntitlementSource.store,
    verifiedAt: at(1),
  );

  test('a restart reads the row back as a cached value', () async {
    expectOk(await cache.write(owned));
    final row = await db.entitlementsDao.byKey('remove_ads');
    expect(row!.state, 'owned');
    expect(row.source, 'store');
    final reopened = await open();
    expect(
      reopened.read(),
      owned.copyWith(source: EntitlementSource.cache),
    );
    expect(reopened.read().removesAds, isTrue);
  });

  test('watch emits the cached value and every write', () async {
    final seen = <Entitlement>[];
    final sub = cache.watch().listen(seen.add);
    await settle();
    await cache.write(owned);
    await settle();
    await sub.cancel();
    expect(seen, [Entitlement.unknown, owned]);
  });

  test('an unknown stored state reads as unknown', () async {
    await db.entitlementsDao.put(
      EntitlementsCompanion.insert(
        key: 'remove_ads',
        state: 'lifetime',
        source: 'store',
      ),
    );
    expect((await open()).read(), Entitlement.unknown);
    expect(logger.logged('unknown state'), isTrue);
  });

  test('an unreadable table reads as unknown', () async {
    await db.customStatement('DROP TABLE entitlements');
    expect((await open()).read(), Entitlement.unknown);
    expect(logger.logged('entitlement cache unreadable'), isTrue);
  });

  test(
    'a failed write returns a storage failure and keeps the value',
    () async {
      await db.customStatement('DROP TABLE entitlements');
      expect(expectErr(await cache.write(owned)), isA<StorageFailure>());
      expect(cache.read(), Entitlement.unknown);
      expect(logger.logged('entitlement cache write failed'), isTrue);
    },
  );
}
