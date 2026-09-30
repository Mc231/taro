import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'paywall_catalog.freezed.dart';

/// How long the rewarded option stays greyed out after a no-fill (01 §9.4
/// F3: "the option greys out for 60 s").
const Duration kRewardedNoFillCooldown = Duration(seconds: 60);

/// The store listing shown on S10 and S11 (04 §11: the same `ProductOffer`
/// list on both surfaces).
@freezed
abstract class PaywallCatalog with _$PaywallCatalog {
  /// Creates a catalog.
  const factory PaywallCatalog({
    /// The reading packs in `store.packs` order, with store prices.
    required List<ProductOffer> packs,

    /// Remove Banner Ads, when listed and `store.removeAdsEnabled`.
    ProductOffer? removeAds,

    /// The pack with the lowest per-reading price, when
    /// `store.showBestValueBadge` and it is strictly the lowest (04 §11).
    ProductId? bestValue,
  }) = _PaywallCatalog;
}

/// The pack area of S10 (01 §8.3: packs loading / loaded / store
/// unavailable; RC66 `purchasesBlocked`).
@freezed
sealed class PaywallPacks with _$PaywallPacks {
  /// Store prices are loading (skeleton).
  const factory PaywallPacks.loading() = PaywallPacksLoading;

  /// Prices loaded.
  const factory PaywallPacks.loaded(PaywallCatalog catalog) =
      PaywallPacksLoaded;

  /// The store is unavailable or listed nothing (retry).
  const factory PaywallPacks.unavailable() = PaywallPacksUnavailable;

  /// Pack purchases are blocked (`blocked`, `refundDebt`, or the
  /// `store.enabled` kill switch as `storeDisabled`): pack buttons hidden,
  /// free and rewarded paths stay (RC66).
  const factory PaywallPacks.purchasesBlocked(PurchasesBlockedReason reason) =
      PaywallPacksBlocked;
}

/// The rewarded row of S10 / S11 (RC34, RC35, RC57).
@freezed
sealed class RewardedOption with _$RewardedOption {
  /// "Watch an ad for [amount] reading(s)"; [leftToday] rewards remain.
  const factory RewardedOption.available({
    required int amount,
    required int leftToday,
  }) = RewardedOptionAvailable;

  /// Cooling down until [until] ("Another ad reward is available in …").
  const factory RewardedOption.coolingDown({required DateTime until}) =
      RewardedOptionCoolingDown;

  /// Today's cap is used ("You've used today's ad rewards").
  const factory RewardedOption.capped() = RewardedOptionCapped;

  /// The last ad did not fill; disabled until [until] (60 s).
  const factory RewardedOption.noFill({required DateTime until}) =
      RewardedOptionNoFill;

  /// Not offered: disabled by config, ads consent, or a free reading left
  /// (the row is hidden).
  const factory RewardedOption.hidden() = RewardedOptionHidden;

  const RewardedOption._();

  /// Whether the row can be tapped.
  bool get isAvailable => this is RewardedOptionAvailable;

  /// When the row should be re-evaluated, if it waits for a time.
  DateTime? get waitsUntil => switch (this) {
    RewardedOptionCoolingDown(:final until) => until,
    RewardedOptionNoFill(:final until) => until,
    _ => null,
  };
}

/// The instant until which the rewarded row is greyed out after a no-fill
/// (set by `RewardedController`, read by S10 and S11).
final class RewardedNoFillController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Records a no-fill at [now].
  void recordNoFill(DateTime now) => state = now.add(kRewardedNoFillCooldown);
}

/// See [RewardedNoFillController].
final rewardedNoFillProvider =
    NotifierProvider<RewardedNoFillController, DateTime?>(
      RewardedNoFillController.new,
    );

/// The rewarded row and, when it is not offered, why (for
/// `rewarded_offer_shown.ineligible_reason`).
typedef RewardedEvaluation = ({
  RewardedOption option,
  RewardUnavailableReason? reason,
});

/// Evaluates the rewarded row: the `EarnReward` eligibility rules (config,
/// ads consent, `free.remaining == 0`, cap, cooldown; RC34, RC35) plus the
/// local no-fill pause.
RewardedEvaluation evaluateRewarded({
  required EarnReward earnReward,
  required CreditBalance? balance,
  required DateTime? noFillUntil,
  required DateTime now,
}) {
  final reason = earnReward.unavailableReason();
  if (balance == null && reason == null) {
    return (
      option: const RewardedOption.hidden(),
      reason: RewardUnavailableReason.disabled,
    );
  }
  switch (reason) {
    case null:
      if (noFillUntil != null && noFillUntil.isAfter(now)) {
        return (
          option: RewardedOption.noFill(until: noFillUntil),
          reason: RewardUnavailableReason.noFill,
        );
      }
      final rewarded = balance!.rewarded;
      final left = rewarded.dailyCap - rewarded.grantedToday;
      return (
        option: RewardedOption.available(
          amount: rewarded.amount,
          leftToday: left < 0 ? 0 : left,
        ),
        reason: null,
      );
    case RewardUnavailableReason.cooldown:
      return (
        option: RewardedOption.coolingDown(
          until: balance!.rewarded.cooldownEndsAt!,
        ),
        reason: reason,
      );
    case RewardUnavailableReason.cap:
      return (option: const RewardedOption.capped(), reason: reason);
    case RewardUnavailableReason.noFill:
    case RewardUnavailableReason.disabled:
    case RewardUnavailableReason.consent:
      return (option: const RewardedOption.hidden(), reason: reason);
  }
}

/// Why pack purchases are blocked, if they are: the `store.enabled` kill
/// switch first, then the Worker's `purchasesAllowed` (RC66).
PurchasesBlockedReason? packsBlockedReason(
  RemoteConfig config,
  CreditBalance? balance,
) {
  if (!config.storeEnabled) return PurchasesBlockedReason.storeDisabled;
  if (balance == null || balance.purchasesAllowed) return null;
  return balance.purchasesBlockedReason ?? PurchasesBlockedReason.blocked;
}

/// The `iap_products_loaded.result` of a listing of [listed] out of
/// [requested] products.
IapLoadResult _loadResult(int listed, int requested) {
  if (listed == 0) return IapLoadResult.empty;
  return listed < requested ? IapLoadResult.partial : IapLoadResult.ok;
}

/// Queries the store for the enabled packs (and Remove Banner Ads when
/// `store.removeAdsEnabled`) and builds the [PaywallCatalog]; logs
/// `iap_products_loaded`. Credits per pack come from the Worker-injected
/// `store.packs[].credits` only (RC3): the client never hard-codes them.
Future<Result<PaywallCatalog>> loadPaywallCatalog(Ref ref) async {
  final config = ref.read(remoteConfigRepositoryProvider).current;
  final clock = ref.read(clockProvider);
  final analytics = ref.read(analyticsServiceProvider);
  final packs = config.enabledPacks;
  final ids = <ProductId>{
    for (final pack in packs) pack.productId,
    if (config.storeRemoveAdsEnabled) TaroProducts.removeAds.id,
  };
  final started = clock.now();
  final listed = await ref.read(iapServiceProvider).products(ids);
  final ms = clock.now().difference(started).inMilliseconds;
  switch (listed) {
    case Err(:final failure):
      await analytics.log(
        IapProductsLoadedEvent(count: 0, ms: ms, result: IapLoadResult.error),
      );
      return Result.err(failure);
    case Ok(value: final products):
      await analytics.log(
        IapProductsLoadedEvent(
          count: products.length,
          ms: ms,
          result: _loadResult(products.length, ids.length),
        ),
      );
      final byId = {for (final p in products) p.id: p};
      final offers = ProductOffer.sorted([
        for (final pack in packs)
          if (byId[pack.productId] case final product?)
            ProductOffer(
              productId: product.id,
              price: product.price,
              rawPrice: product.rawPrice,
              currencyCode: product.currencyCode,
              credits: pack.credits ?? 0,
              sortOrder: pack.sortOrder,
            ),
      ]);
      final removeAds = byId[TaroProducts.removeAds.id];
      return Result.ok(
        PaywallCatalog(
          packs: offers,
          removeAds: removeAds == null || !config.storeRemoveAdsEnabled
              ? null
              : ProductOffer(
                  productId: removeAds.id,
                  price: removeAds.price,
                  rawPrice: removeAds.rawPrice,
                  currencyCode: removeAds.currencyCode,
                  credits: 0,
                ),
          bestValue: config.storeShowBestValueBadge
              ? ProductOffer.bestValue(offers)
              : null,
        ),
      );
  }
}

/// The analytics alias of [productId] (`pack_s` … `remove_ads`, 04 §14).
AnalyticsProduct analyticsProductOf(ProductId productId) {
  final product = TaroProducts.byId(productId);
  return product == null
      ? AnalyticsProduct.packS
      : AnalyticsProduct.fromProduct(product);
}
