import 'dart:async';

import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro_core/taro_core.dart';

/// How long the launch ownership query may take before the cache is kept
/// (04 §6.4: "a 10 s bound").
const Duration kOwnershipQueryTimeout = Duration(seconds: 10);

/// How long the first banner load waits for the first ownership answer
/// when the cache does not say `owned` (04 §6.4, `whenOwnershipLoaded`).
const Duration kOwnershipFirstAnswerWait = Duration(seconds: 2);

Future<void> _wait(Duration duration) => Future<void>.delayed(duration);

/// The Remove Banner Ads entitlement (MO7, 04 §6.4, RC14, RC75, RC80).
///
/// * The `entitlements` cache is read synchronously at construction, so a
///   paying user never sees a banner flash on launch.
/// * [refresh] runs the silent store ownership query with a
///   [kOwnershipQueryTimeout] bound. Only an answer from the store that
///   lacks `remove_ads` revokes (refund, `REVOKE`, Family Sharing
///   stopped); an error or silence keeps the cache ("never revoke on
///   silence", the quiz_apps `RemoveAdsOwnershipSource` lesson). A late
///   answer after the bound is ignored; the next launch asks again.
/// * [whenOwnershipLoaded] lets the first banner load wait up to
///   [kOwnershipFirstAnswerWait] for that answer, so a reinstalled owner
///   does not see an ad.
/// * [changes] emits whenever [removesAds] flips; `remove_ads_changed` is
///   logged on every flip.
final class RemoveAdsEntitlement {
  /// Creates the entitlement over [cache] and the store [ownership].
  ///
  /// [delay] is the timer used for the bounds (injected in tests).
  RemoveAdsEntitlement({
    required EntitlementCache cache,
    required StoreOwnership ownership,
    required Clock clock,
    required AnalyticsService analytics,
    required Logger logger,
    Delay delay = _wait,
    Duration queryTimeout = kOwnershipQueryTimeout,
    Duration firstAnswerWait = kOwnershipFirstAnswerWait,
  }) : _cache = cache,
       _ownership = ownership,
       _clock = clock,
       _analytics = analytics,
       _logger = logger,
       _delay = delay,
       _queryTimeout = queryTimeout,
       _firstAnswerWait = firstAnswerWait,
       _current = cache.read();

  final EntitlementCache _cache;
  final StoreOwnership _ownership;
  final Clock _clock;
  final AnalyticsService _analytics;
  final Logger _logger;
  final Delay _delay;
  final Duration _queryTimeout;
  final Duration _firstAnswerWait;

  Entitlement _current;
  final Completer<void> _firstAnswer = Completer<void>();
  final StreamController<bool> _changes = StreamController<bool>.broadcast();
  Future<void>? _refreshing;

  /// The current entitlement (the cache until the store answers).
  Entitlement get current => _current;

  /// Whether banners are removed now.
  bool get removesAds => _current.removesAds;

  /// Emits the new [removesAds] value on every flip.
  Stream<bool> get changes => _changes.stream;

  /// The silent launch ownership check. Concurrent calls share one query.
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(
    () => _refreshing = null,
  );

  Future<void> _refresh() async {
    final answer = await Future.any<Result<Set<ProductId>>?>([
      _ownership.queryOwnership(),
      _delay(_queryTimeout).then((_) => null),
    ]);
    switch (answer) {
      case null:
        _logger.info('ownership query timed out; keeping the cache');
      case Err(:final failure):
        _logger.info('ownership query failed: ${failure.code}');
      case Ok(:final value):
        final owned = value.contains(TaroProducts.removeAds.id);
        await _set(
          owned ? EntitlementState.owned : EntitlementState.notOwned,
          source: owned
              ? RemoveAdsSource.ownershipCheck
              : RemoveAdsSource.revoked,
        );
    }
    _answered();
  }

  /// Records a delivered Remove Banner Ads transaction (a purchase or a
  /// restore); called by the purchase coordinator before it finishes it.
  Future<void> markOwned({required RemoveAdsSource source}) async {
    await _set(EntitlementState.owned, source: source);
    _answered();
  }

  /// Completes when the first ownership answer is in, or at once when the
  /// cache already says owned (no banner is loaded then anyway); never
  /// waits longer than [kOwnershipFirstAnswerWait].
  Future<void> whenOwnershipLoaded() async {
    if (removesAds || _firstAnswer.isCompleted) return;
    await Future.any<void>([_firstAnswer.future, _delay(_firstAnswerWait)]);
  }

  /// Closes [changes].
  Future<void> dispose() => _changes.close();

  void _answered() {
    if (!_firstAnswer.isCompleted) _firstAnswer.complete();
  }

  Future<void> _set(
    EntitlementState state, {
    required RemoveAdsSource source,
  }) async {
    final wasOwned = removesAds;
    _current = Entitlement(
      removeAds: state,
      source: EntitlementSource.store,
      verifiedAt: _clock.now(),
    );
    final written = await _cache.write(_current);
    if (written case Err(:final failure)) {
      _logger.warning('entitlement cache write failed: ${failure.code}');
    }
    final owned = removesAds;
    if (owned == wasOwned) return;
    if (!_changes.isClosed) _changes.add(owned);
    await _analytics.log(RemoveAdsChangedEvent(owned: owned, source: source));
  }
}
