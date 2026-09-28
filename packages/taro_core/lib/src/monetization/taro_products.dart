import 'package:meta/meta.dart';
import 'package:taro_core/src/result/ids.dart';

/// Store product kind (04 §4).
enum ProductKind {
  /// Consumable reading pack.
  consumable,

  /// Non-consumable (Remove Banner Ads).
  nonConsumable,
}

/// A store product known to the client: ID, kind and analytics alias only.
///
/// Credit counts never live in the client (MO2, RC3): the UI shows the
/// Worker-injected `store.packs[].credits`.
@immutable
final class TaroProduct {
  /// Creates a product. `tools/check_iap_ids.py` parses these calls.
  const TaroProduct({
    required String id,
    required this.kind,
    required this.alias,
  }) : _id = id;

  final String _id;

  /// The fully qualified store product ID.
  ProductId get id => ProductId(_id);

  /// Consumable or non-consumable.
  final ProductKind kind;

  /// Analytics alias (`product` param, GLOSSARY §3).
  final String alias;

  /// Whether this is a consumable pack.
  bool get isConsumable => kind == ProductKind.consumable;

  @override
  bool operator ==(Object other) =>
      other is TaroProduct &&
      other._id == _id &&
      other.kind == kind &&
      other.alias == alias;

  @override
  int get hashCode => Object.hash(_id, kind, alias);

  @override
  String toString() => 'TaroProduct($_id, ${kind.name}, $alias)';
}

/// The v1 product catalogue (04 §4, GLOSSARY §3; RC3). Same IDs on both
/// stores. A size change means a new product ID.
abstract final class TaroProducts {
  /// 3 readings.
  static const TaroProduct readings3 = TaroProduct(
    id: 'com.vshyrochuk.taro.readings_3',
    kind: ProductKind.consumable,
    alias: 'pack_s',
  );

  /// 10 readings.
  static const TaroProduct readings10 = TaroProduct(
    id: 'com.vshyrochuk.taro.readings_10',
    kind: ProductKind.consumable,
    alias: 'pack_m',
  );

  /// 30 readings.
  static const TaroProduct readings30 = TaroProduct(
    id: 'com.vshyrochuk.taro.readings_30',
    kind: ProductKind.consumable,
    alias: 'pack_l',
  );

  /// Remove Banner Ads (RC80); never sent to the Worker.
  static const TaroProduct removeAds = TaroProduct(
    id: 'com.vshyrochuk.taro.remove_ads',
    kind: ProductKind.nonConsumable,
    alias: 'remove_ads',
  );

  /// Every product, consumables in default `store.packs` order first.
  static const List<TaroProduct> all = [
    readings3,
    readings10,
    readings30,
    removeAds,
  ];

  /// The consumable packs.
  static const List<TaroProduct> consumables = [
    readings3,
    readings10,
    readings30,
  ];

  /// The product with [id], or `null` if it is not in the catalogue.
  static TaroProduct? byId(ProductId id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
