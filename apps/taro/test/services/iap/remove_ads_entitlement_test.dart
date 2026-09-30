import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/iap/remove_ads_entitlement.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/iap_test_support.dart';

const _owned = Entitlement(
  removeAds: EntitlementState.owned,
  source: EntitlementSource.cache,
);
const _notOwned = Entitlement(
  removeAds: EntitlementState.notOwned,
  source: EntitlementSource.cache,
);

void main() {
  late FakeEntitlementCache cache;
  late FakeStoreOwnership store;
  late FakeClock clock;
  late FakeAnalyticsService analytics;
  late CapturingLogger logger;
  late ManualDelay delay;
  final removeAds = TaroProducts.removeAds.id;

  RemoveAdsEntitlement create([Entitlement cached = Entitlement.unknown]) {
    cache = FakeEntitlementCache(cached);
    return RemoveAdsEntitlement(
      cache: cache,
      ownership: store,
      clock: clock,
      analytics: analytics,
      logger: logger,
      delay: delay.call,
    );
  }

  setUp(() {
    store = FakeStoreOwnership();
    clock = FakeClock();
    analytics = FakeAnalyticsService();
    logger = CapturingLogger();
    delay = ManualDelay();
  });

  test('the cache is read instantly, before any store answer', () {
    final entitlement = create(_owned);
    expect(entitlement.current, _owned);
    expect(entitlement.removesAds, isTrue);
    expect(store.queries, 0);
  });

  test('the store answering with Remove Ads grants it', () async {
    final entitlement = create();
    final changes = <bool>[];
    entitlement.changes.listen(changes.add);
    store.answer = Result.ok({removeAds});
    await entitlement.refresh();
    expect(
      entitlement.current,
      Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
        verifiedAt: clock.now(),
      ),
    );
    expect(cache.entitlement, entitlement.current);
    expect(changes, [true]);
    expect(analytics.events.single, isA<RemoveAdsChangedEvent>());
    expect(analytics.events.single.parameters, {
      'owned': true,
      'source': 'ownership_check',
    });
  });

  test(
    'revoked only when the store answers without it (refund, REVOKE)',
    () async {
      final entitlement = create(_owned);
      final changes = <bool>[];
      entitlement.changes.listen(changes.add);
      store.answer = const Result.ok({});
      await entitlement.refresh();
      expect(entitlement.current.removeAds, EntitlementState.notOwned);
      expect(entitlement.removesAds, isFalse);
      expect(cache.entitlement.removeAds, EntitlementState.notOwned);
      expect(changes, [false]);
      expect(analytics.events.single.parameters, {
        'owned': false,
        'source': 'revoked',
      });
    },
  );

  test('a store error never revokes', () async {
    final entitlement = create(_owned);
    store.answer = const Result.err(Failure.network());
    await entitlement.refresh();
    expect(entitlement.current, _owned);
    expect(cache.callCount('write'), 0);
    expect(analytics.events, isEmpty);
    expect(logger.logged('ownership query failed'), isTrue);
  });

  test('silence past the 10 s bound keeps the cache; a late answer is '
      'ignored', () async {
    final entitlement = create(_owned);
    store
      ..hold = true
      ..answer = const Result.ok({});
    final refreshing = entitlement.refresh();
    await settle();
    expect(delay.waiting, [kOwnershipQueryTimeout]);
    delay.fire(kOwnershipQueryTimeout);
    await refreshing;
    expect(entitlement.current, _owned);
    expect(logger.logged('timed out'), isTrue);
    store.release();
    await settle();
    expect(entitlement.current, _owned);
    expect(cache.callCount('write'), 0);
  });

  test('concurrent refreshes share one store query', () async {
    final entitlement = create();
    store.hold = true;
    final a = entitlement.refresh();
    final b = entitlement.refresh();
    await settle();
    store.release();
    await Future.wait([a, b]);
    expect(store.queries, 1);
  });

  test('no flip, no event (unknown → notOwned)', () async {
    final entitlement = create();
    await entitlement.refresh();
    expect(entitlement.current.removeAds, EntitlementState.notOwned);
    expect(analytics.events, isEmpty);
  });

  group('whenOwnershipLoaded', () {
    test('returns at once when the cache says owned', () async {
      final entitlement = create(_owned);
      await entitlement.whenOwnershipLoaded();
      expect(delay.requested, isEmpty);
    });

    test('waits for the first answer when the cache says notOwned', () async {
      final entitlement = create(_notOwned);
      store
        ..hold = true
        ..answer = Result.ok({removeAds});
      var loaded = false;
      final refreshing = entitlement.refresh();
      final waiting = entitlement.whenOwnershipLoaded().then(
        (_) => loaded = true,
      );
      await settle();
      expect(loaded, isFalse);
      expect(delay.waiting, contains(kOwnershipFirstAnswerWait));
      store.release();
      await refreshing;
      await waiting;
      expect(loaded, isTrue);
      expect(entitlement.removesAds, isTrue);
      // Answered: later calls return at once.
      final before = delay.requested.length;
      await entitlement.whenOwnershipLoaded();
      expect(delay.requested.length, before);
    });

    test('gives up after 2 s without an answer', () async {
      final entitlement = create(_notOwned);
      final waiting = entitlement.whenOwnershipLoaded();
      await settle();
      expect(delay.fire(kOwnershipFirstAnswerWait), isTrue);
      await waiting;
      expect(entitlement.removesAds, isFalse);
    });

    test('a failed query also counts as the first answer', () async {
      final entitlement = create(_notOwned);
      store.answer = const Result.err(Failure.network());
      await entitlement.refresh();
      await entitlement.whenOwnershipLoaded();
      expect(delay.requested, [kOwnershipQueryTimeout]);
    });
  });

  test('markOwned records a purchase', () async {
    final entitlement = create(_notOwned);
    await entitlement.markOwned(source: RemoveAdsSource.purchase);
    expect(entitlement.removesAds, isTrue);
    expect(cache.entitlement.source, EntitlementSource.store);
    expect(analytics.events.single.parameters, {
      'owned': true,
      'source': 'purchase',
    });
    // Already owned: no second event.
    await entitlement.markOwned(source: RemoveAdsSource.restore);
    expect(analytics.events, hasLength(1));
    await entitlement.whenOwnershipLoaded();
  });

  test('a failed cache write is logged; memory still updates', () async {
    final entitlement = create(_notOwned);
    cache.failNext(const Failure.storage(), on: 'write');
    await entitlement.markOwned(source: RemoveAdsSource.purchase);
    expect(entitlement.removesAds, isTrue);
    expect(logger.logged('entitlement cache write failed'), isTrue);
  });

  test('dispose closes changes', () async {
    final entitlement = create();
    var done = false;
    entitlement.changes.listen(null, onDone: () => done = true);
    await entitlement.dispose();
    await settle();
    expect(done, isTrue);
    // A flip after dispose is not emitted.
    await entitlement.markOwned(source: RemoveAdsSource.purchase);
    expect(entitlement.removesAds, isTrue);
  });
}
