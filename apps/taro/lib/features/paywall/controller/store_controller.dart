import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro_core/taro_core.dart';

part 'store_controller.freezed.dart';

/// S11 Store / paywall (04 §11, 01 §8.3).
@freezed
sealed class StoreState with _$StoreState {
  /// Store prices are loading (skeleton; header, close, legal links and
  /// disclosure render at once).
  const factory StoreState.loading() = StoreLoading;

  /// Products listed: packs, Remove Banner Ads, rewarded offer, restore.
  const factory StoreState.ready({
    required StoreView view,
    required StorePurchasePhase phase,
  }) = StoreReady;

  /// The store listed none of the products ("Purchases aren't available on
  /// this device"; retry; free path and restore stay).
  const factory StoreState.storeUnavailable() = StoreUnavailable;

  /// The product query failed (retry).
  const factory StoreState.productsFailed(ErrorKind kind) = StoreProductsFailed;
}

/// What S11 shows around the purchase buttons.
@freezed
abstract class StoreView with _$StoreView {
  /// Creates a view.
  const factory StoreView({
    /// Packs and Remove Banner Ads with store prices.
    required PaywallCatalog catalog,

    /// The rewarded row (S11 is the second entry point, RC34).
    required RewardedOption rewarded,

    /// Remove Banner Ads is owned ("Banner ads removed ✓", no button).
    required bool removeAdsOwned,

    /// Offline: the store needs the network; a warning is shown.
    required bool offline,

    /// Paid readings are blocked (03 §5.1 `paidBlocked` notice).
    required bool paidBlocked,

    /// Pack buttons hidden: `blocked`, `refundDebt` or the `store.enabled`
    /// kill switch (`storeDisabled`); free, rewarded and restore stay
    /// (RC66).
    PurchasesBlockedReason? purchasesBlocked,
  }) = _StoreView;
}

/// The purchase in progress on S11 (one at a time; other buttons stay
/// enabled, 04 §12.4).
@freezed
sealed class StorePurchasePhase with _$StorePurchasePhase {
  /// Nothing in progress.
  const factory StorePurchasePhase.idle() = StorePhaseIdle;

  /// The store sheet is open for [productId] (that button spins).
  const factory StorePurchasePhase.purchasing(ProductId productId) =
      StorePhasePurchasing;

  /// Ask to Buy / Play pending: "Waiting for approval".
  const factory StorePurchasePhase.pending(ProductId productId) =
      StorePhasePending;

  /// The store delivered it; the Worker verifies ("Confirming your
  /// purchase…").
  const factory StorePurchasePhase.verifying(ProductId productId) =
      StorePhaseVerifying;

  /// The Worker was unreachable: "Your purchase is safe. We'll add your
  /// readings when you're back online." (retried on resume, 04 §12.2).
  const factory StorePurchasePhase.verificationDeferred(ProductId productId) =
      StorePhaseVerificationDeferred;

  /// Granted ([credits] readings; 0 for Remove Banner Ads): toast, then
  /// back to S07 with Begin enabled, nothing auto-starts (RC58).
  const factory StorePurchasePhase.granted(
    ProductId productId, {
    required int credits,
  }) = StorePhaseGranted;

  /// Failed ([reason]); retry. [transferEligible] adds the transfer hint for
  /// `PURCHASE_ALREADY_CLAIMED` (RC84).
  const factory StorePurchasePhase.failed(
    ProductId productId, {
    required PurchaseErrorKind reason,
    @Default(false) bool transferEligible,
  }) = StorePhaseFailed;

  /// Cancelled in the store sheet: silent return.
  const factory StorePurchasePhase.cancelled(ProductId productId) =
      StorePhaseCancelled;

  const StorePurchasePhase._();

  /// Whether a buy is running (buttons of other products stay enabled but
  /// a second buy is refused, 04 §12.4).
  bool get isBusy =>
      this is StorePhasePurchasing || this is StorePhaseVerifying;

  /// The product this phase is about; every case but `idle` overrides it
  /// with its `productId` field.
  ProductId? get productId => null;
}

/// Drives S11 over `PurchaseCoordinator` (the single purchase path, 04
/// §6.2, rule 8): the controller never finishes a transaction and never
/// changes a balance itself (AR8).
final class StoreController extends Notifier<StoreState> {
  /// A controller for a store opened from [source].
  StoreController(this.source);

  /// Where S11 was opened from (`store_viewed.source`).
  final StoreSource source;

  late ProviderSubscription<CreditBalance?> _balance;
  late ProviderSubscription<RemoteConfig> _config;
  late ProviderSubscription<Entitlement> _entitlement;
  late ProviderSubscription<bool> _online;
  late ProviderSubscription<DateTime?> _noFill;
  PaywallCatalog? _catalog;
  StorePurchasePhase _phase = const StorePurchasePhase.idle();
  PaywallAction _action = PaywallAction.none;
  DateTime? _openedAt;
  bool _dismissed = false;

  Clock get _clock => ref.read(clockProvider);

  @override
  StoreState build() {
    _balance = ref.listen(balanceProvider, (_, _) => _update());
    _config = ref.listen(remoteConfigProvider, (_, _) => _update());
    _entitlement = ref.listen(entitlementProvider, (_, _) => _update());
    _online = ref.listen(connectivityProvider, (_, _) => _update());
    _noFill = ref.listen(rewardedNoFillProvider, (_, _) => _update());
    final coordinator = ref.read(purchaseCoordinatorProvider);
    final updates = coordinator.updates.listen(_onUpdate);
    final deliveries = ref
        .read(iapServiceProvider)
        .deliveries
        .listen(_onDelivery);
    ref.onDispose(() {
      unawaited(updates.cancel());
      unawaited(deliveries.cancel());
    });
    _openedAt = _clock.now();
    unawaited(_open());
    return const StoreState.loading();
  }

  /// Retries the product query.
  Future<void> retry() async {
    state = const StoreState.loading();
    await _load();
  }

  /// Buys [productId] (each pack is its own button; no preselection).
  Future<void> buy(ProductId productId) async {
    final current = state;
    if (current is! StoreReady || current.phase.isBusy) return;
    final view = current.view;
    final product = TaroProducts.byId(productId);
    if (product == null) return;
    if (product.isConsumable && view.purchasesBlocked != null) return;
    if (!product.isConsumable && view.removeAdsOwned) return;
    _action = PaywallAction.purchase;
    final coordinator = ref.read(purchaseCoordinatorProvider);
    _setPhase(StorePurchasePhase.purchasing(productId));
    final offer = [
      ...view.catalog.packs,
      ?view.catalog.removeAds,
    ].where((o) => o.productId == productId).firstOrNull;
    await ref
        .read(analyticsServiceProvider)
        .log(
          PurchaseStartedEvent(
            product: analyticsProductOf(productId),
            priceMicros: offer == null ? 0 : (offer.rawPrice * 1e6).round(),
            currency: AnalyticsCurrency.fromCode(offer?.currencyCode ?? ''),
          ),
        );
    final result = await coordinator.buy(productId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        _apply(productId, value);
      case Err(:final failure):
        _setPhase(_failed(productId, failure));
    }
  }

  /// Restore purchases (04 §7): Remove Banner Ads comes back through the
  /// entitlement; consumable readings are not restorable.
  Future<void> restore() async {
    await ref.read(purchaseCoordinatorProvider).restore();
  }

  /// The rewarded row was tapped; returns whether S12 may open.
  Future<bool> tapRewarded() async {
    if (state case StoreReady(:final view) when view.rewarded.isAvailable) {
      _action = PaywallAction.reward;
      await ref
          .read(analyticsServiceProvider)
          .log(const RewardedOfferTappedEvent(source: RewardedSource.store));
      return true;
    }
    return false;
  }

  /// Clears a finished phase (after its toast or notice was shown).
  void acknowledge() {
    if (_phase is StorePhaseGranted ||
        _phase is StorePhaseCancelled ||
        _phase is StorePhaseFailed) {
      _setPhase(const StorePurchasePhase.idle());
    }
  }

  /// S11 closed: logs `paywall_dismissed` once.
  Future<void> dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await ref
        .read(analyticsServiceProvider)
        .log(
          PaywallDismissedEvent(
            surface: PaywallSurface.store,
            secondsVisible: _clock
                .now()
                .difference(_openedAt ?? _clock.now())
                .inSeconds,
            actionTaken: _action,
          ),
        );
  }

  Future<void> _open() async {
    await ref
        .read(analyticsServiceProvider)
        .log(StoreViewedEvent(source: source));
    await _load();
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    final loaded = await loadPaywallCatalog(ref);
    if (!ref.mounted) return;
    switch (loaded) {
      case Err(:final failure):
        state = StoreState.productsFailed(ErrorKind.fromFailure(failure));
      case Ok(:final value) when value.packs.isEmpty && value.removeAds == null:
        state = const StoreState.storeUnavailable();
      case Ok(:final value):
        _catalog = value;
        _update();
    }
  }

  void _onUpdate(PurchaseUpdate update) {
    // Late results of this screen's purchase (Ask to Buy approval,
    // deferred verification retried on resume, 04 §12.2, §12.7).
    if (_phase.productId != update.productId || _phase is StorePhaseIdle) {
      return;
    }
    _apply(update.productId, update.outcome);
  }

  void _onDelivery(StorePurchase purchase) {
    if (purchase.isRestored) return;
    if (_phase case StorePhasePending(
      :final productId,
    ) when productId == purchase.productId) {
      _setPhase(StorePurchasePhase.verifying(productId));
    }
  }

  void _apply(ProductId productId, PurchaseOutcome outcome) {
    _setPhase(switch (outcome) {
      PurchaseGranted(:final credits) => StorePurchasePhase.granted(
        productId,
        credits: credits,
      ),
      PurchaseAlreadyGranted() || PurchaseAlreadyOwned() =>
        StorePurchasePhase.granted(productId, credits: 0),
      PurchaseOutcomePending() => StorePurchasePhase.pending(productId),
      PurchaseOutcomeCancelled() => StorePurchasePhase.cancelled(productId),
      PurchaseVerificationDelayed() => StorePurchasePhase.verificationDeferred(
        productId,
      ),
      PurchaseOutcomeFailed(:final failure) => _failed(productId, failure),
      PurchaseNotAvailable() => StorePurchasePhase.failed(
        productId,
        reason: PurchaseErrorKind.productUnavailable,
      ),
    });
  }

  StorePurchasePhase _failed(ProductId productId, Failure failure) =>
      switch (failure) {
        PurchaseCancelledFailure() => StorePurchasePhase.cancelled(productId),
        PurchasePendingFailure() => StorePurchasePhase.pending(productId),
        PurchaseAlreadyClaimedFailure(:final transferEligible) =>
          StorePurchasePhase.failed(
            productId,
            reason: PurchaseErrorKind.alreadyClaimed,
            transferEligible: transferEligible,
          ),
        _ => StorePurchasePhase.failed(
          productId,
          reason: PurchaseErrorKind.fromFailure(failure),
        ),
      };

  void _setPhase(StorePurchasePhase phase) {
    _phase = phase;
    _update();
  }

  void _update() {
    if (!ref.mounted) return;
    final catalog = _catalog;
    if (catalog == null) return;
    final balance = _balance.read();
    final evaluation = evaluateRewarded(
      earnReward: ref.read(earnRewardProvider),
      balance: balance,
      noFillUntil: _noFill.read(),
      now: _clock.now(),
    );
    state = StoreState.ready(
      view: StoreView(
        catalog: catalog,
        rewarded: evaluation.option,
        removeAdsOwned: _entitlement.read().removesAds,
        offline: !_online.read(),
        paidBlocked: balance?.paidBlocked ?? false,
        purchasesBlocked: packsBlockedReason(_config.read(), balance),
      ),
      phase: _phase,
    );
  }
}

/// S11 controllers by opening source (auto-disposed with the screen).
final NotifierProviderFamily<StoreController, StoreState, StoreSource>
storeControllerProvider = NotifierProvider.autoDispose.family(
  StoreController.new,
);
