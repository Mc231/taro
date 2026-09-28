import 'package:taro_core/src/monetization/taro_products.dart';

/// Startup check of the product catalogue (02 §5, 04 §4, CLAUDE rule 9).
abstract final class IapCatalog {
  /// A fully qualified Taro product ID.
  static final RegExp idPattern = RegExp(
    r'^com\.vshyrochuk\.taro\.[a-z0-9_]+$',
  );

  /// Throws a [StateError] when a product ID in [products] is unqualified or
  /// duplicated, or when Remove Ads is not the only non-consumable.
  static void validate([List<TaroProduct> products = TaroProducts.all]) {
    final problems = problemsOf(products);
    if (problems.isNotEmpty) {
      throw StateError('Invalid IAP catalogue: ${problems.join('; ')}');
    }
  }

  /// Every reason [products] is not a valid catalogue; empty when it is.
  static List<String> problemsOf(List<TaroProduct> products) {
    final ids = [for (final p in products) p.id.value];
    final nonConsumables = [
      for (final p in products)
        if (!p.isConsumable) p.id.value,
    ];
    return [
      for (final id in ids)
        if (!idPattern.hasMatch(id)) '$id is not fully qualified',
      if (ids.toSet().length != ids.length) 'duplicate product IDs',
      if (nonConsumables.length != 1 ||
          nonConsumables.single != TaroProducts.removeAds.id.value)
        'Remove Ads must be the only non-consumable',
    ];
  }
}
