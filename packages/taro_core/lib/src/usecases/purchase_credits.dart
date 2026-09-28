import 'package:taro_core/src/model/entitlement.dart';
import 'package:taro_core/src/model/install_identity.dart';
import 'package:taro_core/src/monetization/taro_products.dart';
import 'package:taro_core/src/ports/balance_repository.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/entitlement_cache.dart';
import 'package:taro_core/src/ports/iap_service.dart';
import 'package:taro_core/src/ports/id_generator.dart';
import 'package:taro_core/src/ports/install_repository.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/purchase_outbox.dart';
import 'package:taro_core/src/ports/purchase_outcome.dart';
import 'package:taro_core/src/ports/purchase_verifier.dart';
import 'package:taro_core/src/ports/remote_config_repository.dart';
import 'package:taro_core/src/ports/store_purchase.dart';
import 'package:taro_core/src/ports/sync_reason.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

/// Buying, verifying and finishing store purchases (02 §9.5, 04 §6.2).
///
/// A consumable is written to the outbox **before** verification and
/// finished only **after** the Worker grant (rule 8). The client never
/// adds credits itself: the balance comes from the grant (rule 7).
/// Remove Banner Ads is a non-consumable: no Worker call, the entitlement
/// is cached and the transaction finished.
final class PurchaseCredits {
  /// Creates the use case.
  PurchaseCredits({
    required IapService iap,
    required PurchaseVerifier verifier,
    required PurchaseOutbox outbox,
    required EntitlementCache entitlements,
    required BalanceRepository balance,
    required InstallRepository install,
    required RemoteConfigRepository config,
    required IdGenerator ids,
    required Clock clock,
    required Logger logger,
  }) : _iap = iap,
       _verifier = verifier,
       _outbox = outbox,
       _entitlements = entitlements,
       _balance = balance,
       _install = install,
       _config = config,
       _ids = ids,
       _clock = clock,
       _logger = logger;

  final IapService _iap;
  final PurchaseVerifier _verifier;
  final PurchaseOutbox _outbox;
  final EntitlementCache _entitlements;
  final BalanceRepository _balance;
  final InstallRepository _install;
  final RemoteConfigRepository _config;
  final IdGenerator _ids;
  final Clock _clock;
  final Logger _logger;

  final Set<String> _inFlight = {};

  /// Opens the store sheet for [productId] and, for a delivered
  /// transaction, verifies it.
  ///
  /// Packs are offered only while `purchasesAllowed` (RC66): otherwise
  /// `PurchasesBlockedFailure`. Store errors are returned as failures;
  /// a cancelled sheet is [PurchaseOutcome.cancelled].
  Future<Result<PurchaseOutcome>> buy(ProductId productId) async {
    final config = _config.current;
    final product = TaroProducts.byId(productId);
    if (product == null || !config.storeEnabled) {
      return const Result.ok(PurchaseOutcome.notAvailable());
    }
    if (product.isConsumable) {
      final packEnabled = config.enabledPacks.any(
        (p) => p.productId == productId,
      );
      if (!packEnabled) return const Result.ok(PurchaseOutcome.notAvailable());
      final cached = _balance.cached;
      if (cached != null && !cached.purchasesAllowed) {
        return Result.err(
          Failure.purchasesBlocked(
            reason:
                cached.purchasesBlockedReason ?? PurchasesBlockedReason.blocked,
          ),
        );
      }
    } else {
      if (!config.storeRemoveAdsEnabled) {
        return const Result.ok(PurchaseOutcome.notAvailable());
      }
      if (_entitlements.read().removesAds) {
        return const Result.ok(PurchaseOutcome.alreadyOwned());
      }
    }
    if (_iap.pending.contains(productId)) {
      return const Result.ok(PurchaseOutcome.pending());
    }
    final install = await _install.getOrCreate();
    if (install case Err(:final failure)) return Result.err(failure);
    final binding =
        install.valueOrNull!.purchaseBinding ?? const PurchaseBinding();
    final bought = await _iap.buy(productId, binding: binding);
    switch (bought) {
      case Err(failure: PurchaseCancelledFailure()):
        return const Result.ok(PurchaseOutcome.cancelled());
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: StoreBuyPurchased(:final purchase)):
        return Result.ok(await process(purchase));
      case Ok(value: StoreBuyPending()):
        return const Result.ok(PurchaseOutcome.pending());
      case Ok(value: StoreBuyCancelled()):
        return const Result.ok(PurchaseOutcome.cancelled());
      case Ok(value: StoreBuyAlreadyOwned()):
        await _cacheRemoveAds();
        return const Result.ok(PurchaseOutcome.alreadyOwned());
    }
  }

  /// Handles one delivered transaction (from [buy] or
  /// `IapService.deliveries`). Concurrent deliveries of the same
  /// transaction are dropped as [PurchaseOutcome.verificationDelayed].
  Future<PurchaseOutcome> process(StorePurchase purchase) async {
    final product = TaroProducts.byId(purchase.productId);
    if (product != null && !product.isConsumable) {
      await _cacheRemoveAds();
      await _finish(purchase);
      return purchase.isRestored
          ? const PurchaseOutcome.alreadyOwned()
          : const PurchaseOutcome.granted(credits: 0, isFirstPurchase: false);
    }
    if (!_inFlight.add(purchase.txnKey)) {
      return const PurchaseOutcome.verificationDelayed();
    }
    try {
      final entry = await _outbox.enqueue(
        purchase,
        idempotencyKey: _ids.uuidV4(),
        now: _clock.now(),
      );
      return switch (entry) {
        // Not verified without an outbox row; the store redelivers it.
        Err(:final failure) => _delayed('outbox write failed', failure),
        Ok(:final value) => await _verify(value),
      };
    } finally {
      _inFlight.remove(purchase.txnKey);
    }
  }

  /// Retries every open outbox row (launch, resume, connectivity; 02 §9.2).
  /// After `store.verifyRetryWindowHours` a row is retried on launch only.
  /// Returns the outcome per `txnKey`.
  Future<Result<Map<String, PurchaseOutcome>>> flushOutbox({
    required SyncReason reason,
  }) async {
    final open = await _outbox.pending();
    return open.then((entries) async {
      final window = Duration(
        hours: _config.current.storeVerifyRetryWindowHours,
      );
      final now = _clock.now();
      final outcomes = <String, PurchaseOutcome>{};
      for (final entry in entries) {
        final expired = now.difference(entry.createdAt) > window;
        if (expired && reason != SyncReason.launch) continue;
        if (expired) _logger.warning('iap_verify_stuck');
        if (!_inFlight.add(entry.txnKey)) continue;
        try {
          outcomes[entry.txnKey] = await _verify(entry);
        } finally {
          _inFlight.remove(entry.txnKey);
        }
      }
      return Result.ok(outcomes);
    });
  }

  /// User-initiated "Restore purchases" (Remove Banner Ads only; packs are
  /// consumed and cannot be restored).
  Future<Result<void>> restore() => _iap.restore();

  Future<PurchaseOutcome> _verify(OutboxEntry entry) async {
    switch (entry.status) {
      case OutboxStatus.granted:
        return _finishGranted(entry, const PurchaseOutcome.alreadyGranted());
      case OutboxStatus.finished:
        return const PurchaseOutcome.alreadyGranted();
      case OutboxStatus.rejected:
        return const PurchaseOutcome.failed(
          Failure.purchase(wireCode: 'PURCHASE_INVALID'),
        );
      case OutboxStatus.awaitingVerification:
        break;
    }
    final result = await _verifier.verify(
      entry.purchase,
      idempotencyKey: entry.idempotencyKey,
    );
    final now = _clock.now();
    switch (result) {
      case Ok(value: GrantResult(status: GrantStatus.pending)):
        await _outbox.recordAttempt(entry.txnKey, now: now);
        return const PurchaseOutcome.pending();
      case Ok(:final value):
        await _outbox.markGranted(entry.txnKey, now: now);
        final balance = value.balance;
        if (balance != null) await _balance.apply(balance);
        return _finishGranted(
          entry,
          value.status == GrantStatus.granted
              ? PurchaseOutcome.granted(
                  credits: value.creditsGranted,
                  isFirstPurchase: value.isFirstPurchase,
                )
              : const PurchaseOutcome.alreadyGranted(),
        );
      case Err(:final PurchaseFailure failure):
        // It can never be granted: finish it so the store stops redelivering.
        await _finish(entry.purchase);
        await _outbox.markRejected(entry.txnKey, now: now);
        _logger.warning('purchase rejected: ${failure.code}');
        return PurchaseOutcome.failed(failure);
      case Err(:final PurchaseAlreadyClaimedFailure failure):
        // Bound to another install: left unfinished for a transfer (RC84).
        await _outbox.markRejected(entry.txnKey, now: now);
        return PurchaseOutcome.failed(failure);
      case Err(:final failure):
        // Transport, auth or server trouble: never finish (04 §6.2).
        await _outbox.recordAttempt(
          entry.txnKey,
          now: now,
          error: failure.code,
        );
        return _delayed('verification delayed', failure);
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

  Future<void> _cacheRemoveAds() async {
    final written = await _entitlements.write(
      Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
        verifiedAt: _clock.now(),
      ),
    );
    if (written case Err(:final failure)) {
      _logger.warning('entitlement cache write failed: ${failure.code}');
    }
  }

  PurchaseOutcome _delayed(String message, Failure failure) {
    _logger.info('$message: ${failure.code}');
    return const PurchaseOutcome.verificationDelayed();
  }
}
