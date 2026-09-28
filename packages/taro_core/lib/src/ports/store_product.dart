import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'store_product.freezed.dart';

/// A product as the store lists it, with the localized price (04 §6.1).
@freezed
abstract class StoreProduct with _$StoreProduct {
  /// Creates a store product.
  const factory StoreProduct({
    /// The fully qualified product ID.
    required ProductId id,

    /// The store's localized title.
    required String title,

    /// The store's localized price string, for example `€3.99`.
    required String price,

    /// The numeric price in [currencyCode].
    required double rawPrice,

    /// ISO 4217 currency code.
    required String currencyCode,
  }) = _StoreProduct;
}
