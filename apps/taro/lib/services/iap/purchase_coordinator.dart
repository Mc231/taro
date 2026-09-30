import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:taro/services/iap/pending_purchase_tracker.dart';
import 'package:taro/services/iap/remove_ads_entitlement.dart';
import 'package:taro_core/taro_core.dart';

/// The in-session verification retries after a deferred verify (04 §6.2
/// step 4: 2 s, 10 s, 60 s); after them the outbox is drained on launch,
/// resume and connectivity-regained.
const List<Duration> kVerifyRetryBackoff = [
  Duration(seconds: 2),
  Duration(seconds: 10),
  Duration(seconds: 60),
];

/// `details.reason` of `422 PURCHASE_INVALID` when the sandbox grant cap
/// is reached (RC63): the transaction is finished (no real money was
/// taken) and the user sees a neutral message.
const String kSandboxCapReason = 'sandbox_cap';

Future<void> _wait(Duration duration) => Future<void>.delayed(duration);

StoreProduct? _noPrice(ProductId id) => null;

/// One purchase outcome reported by [PurchaseCoordinator.updates].
@immutable
final class PurchaseUpdate {
  /// An [outcome] for [productId].
  const PurchaseUpdate(this.productId, this.outcome);

  /// The product.
  final ProductId productId;

  /// What happened.
  final PurchaseOutcome outcome;

  /// Paid but not verified yet: "Your purchase is safe" (02 §9.5 step 6).
  bool get verificationDeferred => outcome is PurchaseVerificationDelayed;

  /// A `422 sandbox_cap` rejection: shown with a neutral message, never as
  /// a failed payment (RC63).
  bool get isSandboxCap => switch (outcome) {
    PurchaseOutcomeFailed(failure: PurchaseFailure(:final reason)) =>
      reason == kSandboxCapReason,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      other is PurchaseUpdate &&
      other.productId == productId &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(productId, outcome);

  @override
  String toString() => 'PurchaseUpdate(${productId.value}, $outcome)';
}

/// Purchase coordination outside the widget tree (04 §6.2, 02 §9.5, AR10,
/// MO8, rule 8). Construct it at bootstrap, before any UI: it subscribes
/// to the store deliveries at construction.
///
/// Per consumable transaction:
/// 1. in-flight dedupe by the delivery's `txnKey`;
/// 2. `PurchaseOutbox.enqueue` **before** `PurchaseVerifier.verify`;
/// 3. `granted` / `already_granted` → outbox `granted` → balance applied
///    → `IapService.finish` → outbox `finished` (`purchase_completed` only
///    on `granted`); `202 pending` → kept open, tracked as pending;
///    `422` → finished + outbox `rejected` (`sandbox_cap` is neutral);
///    `409 PURCHASE_ALREADY_CLAIMED` → `rejected`, **not** finished
///    (RC84); anything else (transport, 5xx, 401/403) → never finished,
///    `verificationDelayed`, retried after [kVerifyRetryBackoff] and on
///    every [drainOutbox] until `store.verifyRetryWindowHours`, then on
///    launch only with `iap_verify_stuck`.
///
/// Store-pending purchases (Ask to Buy, Play slow payment) go to the
/// [PendingPurchaseTracker] without a Worker call. Remove Banner Ads is
/// cached through [RemoveAdsEntitlement] and finished without a Worker
/// call.
final class PurchaseCoordinator {
  /// Creates the coordinator and subscribes to [iap] (and to
  /// [connectivity], which drains the outbox when it comes back).
  ///
  /// [priceOf] gives the store listing for the `purchase_completed` value;
  /// [delay] is the backoff timer (injected in tests).
  PurchaseCoordinator({
    required IapService iap,
    required PurchaseVerifier verifier,
    required PurchaseOutbox outbox,
    required BalanceRepository balance,
    required InstallRepository install,
    required RemoteConfigRepository config,
    required RemoveAdsEntitlement removeAds,
    required PendingPurchaseTracker tracker,
    required AnalyticsService analytics,
    required IdGenerator ids,
    required Clock clock,
    required Logger logger,
    ConnectivityMonitor? connectivity,
    StoreProduct? Function(ProductId id) priceOf = _noPrice,
    Delay delay = _wait,
    List<Duration> retryBackoff = kVerifyRetryBackoff,
  }) : _iap = iap,
       _verifier = verifier,
       _outbox = outbox,
       _balance = balance,
       _install = install,
       _config = config,
       _removeAds = removeAds,
       _tracker = tracker,
       _analytics = analytics,
       _ids = ids,
       _clock = clock,
       _logger = logger,
       _priceOf = priceOf,
       _delay = delay,
       _backoff = retryBackoff {
    _subscriptions = [
      iap.deliveries.listen((p) => unawaited(process(p))),
      iap.events.listen((e) => unawaited(_onEvent(e))),
      if (connectivity != null)
        connectivity.online
            .where((online) => online)
            .listen(
              (_) => unawaited(
                drainOutbox(reason: SyncReason.connectivityRegained),
              ),
            ),
    ];
  }

  final IapService _iap;
  final PurchaseVerifier _verifier;
  final PurchaseOutbox _outbox;
  final BalanceRepository _balance;
  final InstallRepository _install;
  final RemoteConfigRepository _config;
  final RemoveAdsEntitlement _removeAds;
  final PendingPurchaseTracker _tracker;
  final AnalyticsService _analytics;
  final IdGenerator _ids;
  final Clock _clock;
  final Logger _logger;
  final StoreProduct? Function(ProductId id) _priceOf;
  final Delay _delay;
  final List<Duration> _backoff;

  late final List<StreamSubscription<Object?>> _subscriptions;
  final StreamController<PurchaseUpdate> _updates =
      StreamController<PurchaseUpdate>.broadcast();
  final Map<String, Future<PurchaseOutcome>> _inFlight = {};
  final Set<String> _retrying = {};
  final Set<String> _delayReported = {};
  final Set<String> _stuckReported = {};
  bool _disposed = false;

  /// Every purchase outcome, including deliveries outside [buy].
  Stream<PurchaseUpdate> get updates => _updates.stream;

  /// Whether [productId] awaits store approval ("Waiting for approval").
  bool isPending(ProductId productId) => _tracker.isPending(productId);

  /// Opens the store sheet for [productId] with this install's
  /// `purchaseBinding` and, for a delivered transaction, verifies it.
  Future<Result<PurchaseOutcome>> buy(ProductId productId) async {
    if (_tracker.isPending(productId)) {
      return const Result.ok(PurchaseOutcome.pending());
    }
    final install = await _install.getOrCreate();
    final PurchaseBinding binding;
    switch (install) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(:final value):
        binding = value.purchaseBinding ?? const PurchaseBinding();
    }
    final bought = await _iap.buy(productId, binding: binding);
    switch (bought) {
      case Err(failure: PurchaseCancelledFailure()):
      case Ok(value: StoreBuyCancelled()):
        return Result.ok(await _cancelled(productId));
      case Err(:final failure):
        _tracker.settle(productId);
        await _logFailed(productId, failure);
        return Result.err(failure);
      case Ok(value: StoreBuyPurchased(:final purchase)):
        return Result.ok(await process(purchase));
      case Ok(value: StoreBuyPending()):
        await _markPending(productId);
        return Result.ok(_emit(productId, const PurchaseOutcome.pending()));
      case Ok(value: StoreBuyAlreadyOwned()):
        if (TaroProducts.byId(productId)?.isConsumable == false) {
          await _removeAds.markOwned(source: RemoveAdsSource.ownershipCheck);
        }
        return Result.ok(
          _emit(productId, const PurchaseOutcome.alreadyOwned()),
        );
    }
  }

  /// Handles one delivered transaction (from [buy] or
  /// `IapService.deliveries`). Concurrent deliveries of the same
  /// `txnKey` share one run.
  Future<PurchaseOutcome> process(StorePurchase purchase) =>
      _guard(purchase, () => _process(purchase));

  /// Retries every open outbox row (`SyncCoordinator`: launch after
  /// registration, resume, connectivity regained). Rows older than
  /// `store.verifyRetryWindowHours` log `iap_verify_stuck` and are retried
  /// on [SyncReason.launch] only. Returns the outcome per `txnKey`.
  Future<Result<Map<String, PurchaseOutcome>>> drainOutbox({
    required SyncReason reason,
  }) async {
    final rows = await _outbox.pending();
    switch (rows) {
      case Err(:final failure):
        _logger.warning('outbox read failed: ${failure.code}');
        return Result.err(failure);
      case Ok(value: final entries):
        final outcomes = <String, PurchaseOutcome>{};
        for (final entry in entries) {
          if (_isExpired(entry)) {
            await _reportStuck(entry);
            if (reason != SyncReason.launch) continue;
          }
          outcomes[entry.txnKey] = await _guard(
            entry.purchase,
            () => _verify(entry, scheduleRetry: false),
          );
        }
        return Result.ok(outcomes);
    }
  }

  /// User-initiated "Restore purchases" (Remove Banner Ads only; packs are
  /// consumed and cannot be restored). Restored transactions arrive on the
  /// store deliveries.
  Future<Result<void>> restore() => _iap.restore();

  /// Stops listening and cancels pending retries.
  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _updates.close();
  }

  // Delivery -----------------------------------------------------------------

  Future<PurchaseOutcome> _guard(
    StorePurchase purchase,
    Future<PurchaseOutcome> Function() body,
  ) {
    final running = _inFlight[purchase.txnKey];
    if (running != null) return running;
    final run = body()
        .then((outcome) => _emit(purchase.productId, outcome))
        .whenComplete(() {
          // The removed future is this run: returning or awaiting it here
          // would wait for itself.
          unawaited(_inFlight.remove(purchase.txnKey));
        });
    _inFlight[purchase.txnKey] = run;
    return run;
  }

  Future<PurchaseOutcome> _process(StorePurchase purchase) async {
    final product = TaroProducts.byId(purchase.productId);
    if (product != null && !product.isConsumable) {
      return _processNonConsumable(purchase);
    }
    final entry = await _outbox.enqueue(
      purchase,
      idempotencyKey: _ids.uuidV4(),
      now: _clock.now(),
    );
    switch (entry) {
      case Err(:final failure):
        // Never verified without an outbox row; the store redelivers it.
        _logger.warning('outbox write failed: ${failure.code}');
        return const PurchaseOutcome.verificationDelayed();
      case Ok(:final value):
        return _verify(value, scheduleRetry: true);
    }
  }

  Future<PurchaseOutcome> _processNonConsumable(StorePurchase purchase) async {
    await _removeAds.markOwned(
      source: purchase.isRestored
          ? RemoveAdsSource.restore
          : RemoveAdsSource.purchase,
    );
    await _finish(purchase);
    _tracker.settle(purchase.productId);
    if (purchase.isRestored) return const PurchaseOutcome.alreadyOwned();
    await _logCompleted(purchase.productId, credits: 0, isFirstPurchase: false);
    return const PurchaseOutcome.granted(credits: 0, isFirstPurchase: false);
  }

  // Verification -------------------------------------------------------------

  Future<PurchaseOutcome> _verify(
    OutboxEntry entry, {
    required bool scheduleRetry,
  }) async {
    switch (entry.status) {
      case OutboxStatus.granted:
      case OutboxStatus.finished:
        // The Worker already granted it; the store still has it open.
        return _finishGranted(entry, const PurchaseOutcome.alreadyGranted());
      case OutboxStatus.awaitingVerification:
      case OutboxStatus.rejected:
        break;
    }
    final purchase = entry.purchase;
    final productId = purchase.productId;
    final started = _clock.now();
    final result = await _verifier.verify(
      purchase,
      idempotencyKey: entry.idempotencyKey,
    );
    final now = _clock.now();
    final ms = now.difference(started).inMilliseconds;
    final attempt = entry.attempts + 1;
    switch (result) {
      case Ok(value: GrantResult(status: GrantStatus.pending)):
        await _outbox.recordAttempt(entry.txnKey, now: now);
        await _logVerify(productId, IapVerifyStatus.pending, ms, attempt);
        await _markPending(productId);
        return const PurchaseOutcome.pending();
      case Ok(:final value):
        await _outbox.markGranted(entry.txnKey, now: now);
        final balance = value.balance;
        if (balance != null) await _balance.apply(balance);
        _tracker.settle(productId);
        final granted = value.status == GrantStatus.granted;
        await _logVerify(
          productId,
          granted ? IapVerifyStatus.granted : IapVerifyStatus.alreadyGranted,
          ms,
          attempt,
        );
        if (!granted) {
          return _finishGranted(entry, const PurchaseOutcome.alreadyGranted());
        }
        await _logCompleted(
          productId,
          credits: value.creditsGranted,
          isFirstPurchase: value.isFirstPurchase,
        );
        return _finishGranted(
          entry,
          PurchaseOutcome.granted(
            credits: value.creditsGranted,
            isFirstPurchase: value.isFirstPurchase,
          ),
        );
      case Err(:final PurchaseFailure failure):
        // It can never be granted: finish it so the store stops
        // redelivering (for sandbox_cap no real money was taken, RC63).
        await _finish(purchase);
        await _outbox.markRejected(entry.txnKey, now: now);
        _tracker.settle(productId);
        await _logVerify(productId, IapVerifyStatus.rejected, ms, attempt);
        if (failure.reason == kSandboxCapReason) {
          _logger.info('sandbox cap reached; finished without a grant');
        } else {
          _logger.warning('purchase rejected: ${failure.code}');
        }
        await _logFailed(productId, failure);
        return PurchaseOutcome.failed(failure);
      case Err(:final PurchaseAlreadyClaimedFailure failure):
        // Bound to another install: left unfinished for a transfer (RC84).
        await _outbox.markRejected(entry.txnKey, now: now);
        _tracker.settle(productId);
        await _logVerify(
          productId,
          IapVerifyStatus.alreadyClaimed,
          ms,
          attempt,
        );
        await _logFailed(productId, failure);
        return PurchaseOutcome.failed(failure);
      case Err(:final failure):
        // Transport, server or auth trouble: never finish (04 §6.2).
        await _outbox.recordAttempt(
          entry.txnKey,
          now: now,
          error: failure.code,
        );
        await _logVerify(productId, IapVerifyStatus.error, ms, attempt);
        _logger.info('verification deferred: ${failure.code}');
        if (_delayReported.add(entry.txnKey)) {
          await _analytics.log(
            PurchaseVerificationDelayedEvent(product: _alias(productId)),
          );
        }
        if (scheduleRetry) _scheduleRetry(entry.txnKey);
        return const PurchaseOutcome.verificationDelayed();
    }
  }

  Future<PurchaseOutcome> _finishGranted(
    OutboxEntry entry,
    PurchaseOutcome outcome,
  ) async {
    if (await _finish(entry.purchase)) {
      await _outbox.markFinished(entry.txnKey, now: _clock.now());
    }
    return outcome;
  }

  Future<bool> _finish(StorePurchase purchase) async {
    final finished = await _iap.finish(purchase);
    if (finished case Err(:final failure)) {
      _logger.warning('finish deferred: ${failure.code}');
      return false;
    }
    return true;
  }

  // Retries ------------------------------------------------------------------

  void _scheduleRetry(String txnKey) {
    if (!_retrying.add(txnKey)) return;
    unawaited(_retry(txnKey).whenComplete(() => _retrying.remove(txnKey)));
  }

  Future<void> _retry(String txnKey) async {
    for (final wait in _backoff) {
      await _delay(wait);
      if (_disposed) return;
      final entry = await _openRow(txnKey);
      if (entry == null || _isExpired(entry)) return;
      final outcome = await _guard(
        entry.purchase,
        () => _verify(entry, scheduleRetry: false),
      );
      if (outcome is! PurchaseVerificationDelayed) return;
    }
  }

  Future<OutboxEntry?> _openRow(String txnKey) async {
    final rows = await _outbox.pending();
    return switch (rows) {
      Ok(:final value) => value.where((r) => r.txnKey == txnKey).firstOrNull,
      Err() => null,
    };
  }

  bool _isExpired(OutboxEntry entry) {
    final window = Duration(hours: _config.current.storeVerifyRetryWindowHours);
    return _clock.now().difference(entry.createdAt) > window;
  }

  Future<void> _reportStuck(OutboxEntry entry) async {
    if (!_stuckReported.add(entry.txnKey)) return;
    final hours = _clock.now().difference(entry.createdAt).inHours;
    _logger.warning('iap_verify_stuck after ${hours}h');
    await _analytics.log(
      IapVerifyStuckEvent(
        product: _alias(entry.purchase.productId),
        hours: hours,
      ),
    );
  }

  // Store events -------------------------------------------------------------

  Future<void> _onEvent(IapEvent event) async {
    switch (event) {
      case IapPending(:final productId):
        await _markPending(productId);
      case IapRestored(:final productIds):
        await _analytics.log(
          RestoreCompletedEvent(
            result: productIds.contains(TaroProducts.removeAds.id)
                ? RestoreResult.removeAds
                : RestoreResult.nothing,
          ),
        );
      case IapPurchased():
      case IapCancelled():
      case IapFailed():
      case IapEntitlementChanged():
        break;
    }
  }

  Future<void> _markPending(ProductId productId) async {
    final wasPending = _tracker.isPending(productId);
    _tracker.markPending(productId);
    if (wasPending) return;
    await _analytics.log(PurchasePendingEvent(product: _alias(productId)));
  }

  Future<PurchaseOutcome> _cancelled(ProductId productId) async {
    _tracker.settle(productId);
    await _analytics.log(PurchaseCancelledEvent(product: _alias(productId)));
    return _emit(productId, const PurchaseOutcome.cancelled());
  }

  PurchaseOutcome _emit(ProductId productId, PurchaseOutcome outcome) {
    if (!_updates.isClosed) _updates.add(PurchaseUpdate(productId, outcome));
    return outcome;
  }

  // Analytics ----------------------------------------------------------------

  /// The analytics alias; ids outside the catalogue never reach the store
  /// sheet, so they are reported as the smallest pack.
  AnalyticsProduct _alias(ProductId productId) {
    final product = TaroProducts.byId(productId);
    return product == null
        ? AnalyticsProduct.packS
        : AnalyticsProduct.fromProduct(product);
  }

  Future<void> _logVerify(
    ProductId productId,
    IapVerifyStatus status,
    int ms,
    int attempt,
  ) => _analytics.log(
    IapVerifyResultEvent(
      product: _alias(productId),
      status: status,
      ms: ms,
      attempt: attempt,
    ),
  );

  Future<void> _logFailed(ProductId productId, Failure failure) =>
      _analytics.log(
        PurchaseFailedEvent(
          product: _alias(productId),
          error: PurchaseErrorKind.fromFailure(failure),
        ),
      );

  Future<void> _logCompleted(
    ProductId productId, {
    required int credits,
    required bool isFirstPurchase,
  }) {
    final listing = _priceOf(productId);
    return _analytics.log(
      PurchaseCompletedEvent(
        product: _alias(productId),
        valueMicros: listing == null ? 0 : (listing.rawPrice * 1e6).round(),
        currency: AnalyticsCurrency.fromCode(listing?.currencyCode ?? ''),
        credits: credits,
        isFirstPurchase: isFirstPurchase,
      ),
    );
  }
}
