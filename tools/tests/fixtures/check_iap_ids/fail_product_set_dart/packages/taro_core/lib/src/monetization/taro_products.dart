/// IDs + kind + analytics alias only; credits live in the Worker (04 §4).
abstract final class TaroProducts {
  static const readings3 = TaroProduct(
    id: 'com.vshyrochuk.taro.readings_3',
    kind: ProductKind.consumable,
    alias: 'pack_s',
  );
  static const readings10 = TaroProduct(
    id: 'com.vshyrochuk.taro.readings_10',
    kind: ProductKind.consumable,
    alias: 'pack_m',
  );
  static const removeAds = TaroProduct(
    id: 'com.vshyrochuk.taro.remove_ads',
    kind: ProductKind.nonConsumable,
    alias: 'remove_ads',
  );
}
