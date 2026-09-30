import 'package:taro/services/iap/store_ownership.dart';
import 'package:taro_core/taro_core.dart';

/// The `IapService` when the flavor sets `iapEnabled = false` (02 §5): no
/// products, nothing to buy, restore and finish succeed as no-ops.
///
/// Its ownership query never answers authoritatively, so a cached Remove
/// Banner Ads entitlement is kept (MO7: never revoke on silence).
final class NoOpIapService implements IapService, StoreOwnership {
  @override
  Future<Result<List<StoreProduct>>> products(Set<ProductId> ids) async =>
      const Result.ok([]);

  @override
  Future<Result<StoreBuyResult>> buy(
    ProductId id, {
    required PurchaseBinding binding,
  }) async => const Result.err(Failure.productUnavailable());

  @override
  Future<Result<void>> restore() async => const Result.ok(null);

  @override
  Future<Result<void>> finish(StorePurchase purchase) async =>
      const Result.ok(null);

  @override
  Future<Result<Set<ProductId>>> queryOwnership() async =>
      const Result.err(Failure.productUnavailable());

  @override
  Stream<StorePurchase> get deliveries => const Stream.empty();

  @override
  Stream<IapEvent> get events => const Stream.empty();

  @override
  Set<ProductId> get pending => const {};
}
