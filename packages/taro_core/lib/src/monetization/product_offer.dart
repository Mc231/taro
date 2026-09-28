import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'product_offer.freezed.dart';

/// ISO 4217 currencies whose minor unit is not 2 decimals.
const Map<String, int> _nonDefaultDecimals = {
  // 0 decimals.
  'BIF': 0, 'CLP': 0, 'DJF': 0, 'GNF': 0, 'ISK': 0, 'JPY': 0, 'KMF': 0,
  'KRW': 0, 'PYG': 0, 'RWF': 0, 'UGX': 0, 'UYI': 0, 'VND': 0, 'VUV': 0,
  'XAF': 0, 'XOF': 0, 'XPF': 0,
  // 3 decimals.
  'BHD': 3, 'IQD': 3, 'JOD': 3, 'KWD': 3, 'LYD': 3, 'OMR': 3, 'TND': 3,
  // 4 decimals.
  'CLF': 4, 'UYW': 4,
};

/// The number of minor-unit decimals of [currencyCode] (ISO 4217; 2 for
/// unknown codes).
int currencyDecimals(String currencyCode) =>
    _nonDefaultDecimals[currencyCode.toUpperCase()] ?? 2;

/// A reading pack as shown on S10 / S11 (04 §11, MO18).
///
/// [price] is the store's localized string (never built by the client);
/// the per-reading price is derived from [rawPrice] and [currencyCode], and
/// the "Best value" badge is computed by [bestValue], never asserted.
@freezed
abstract class ProductOffer with _$ProductOffer {
  /// Creates an offer.
  const factory ProductOffer({
    /// The store product ID.
    required ProductId productId,

    /// Localized store price, e.g. "€4.99" (`ProductDetails.price`).
    required String price,

    /// Numeric store price in major units (`ProductDetails.rawPrice`).
    required double rawPrice,

    /// ISO 4217 code (`ProductDetails.currencyCode`).
    required String currencyCode,

    /// Readings in the pack (Worker-injected `store.packs[].credits`).
    required int credits,

    /// Display order (`store.packs[].sortOrder`).
    @Default(0) int sortOrder,
  }) = _ProductOffer;

  const ProductOffer._();

  /// The per-reading price in minor units, rounded half up; `null` when the
  /// pack has no credits.
  int? get perReadingMinorUnits {
    if (credits <= 0) return null;
    final scale = _pow10(currencyDecimals(currencyCode));
    // Round the price to whole minor units first so float noise in rawPrice
    // (4.99 → 4.9899…) cannot move the result.
    final priceMinor = (rawPrice * scale).round();
    return (priceMinor / credits).round();
  }

  /// The per-reading price in major units at the currency's precision
  /// (JPY 100, KWD 0.2, USD 0.66); `null` when the pack has no credits.
  double? get perReadingPrice {
    final minor = perReadingMinorUnits;
    if (minor == null) return null;
    return minor / _pow10(currencyDecimals(currencyCode));
  }

  /// The pack with the unique lowest per-reading price among [offers], or
  /// `null` when there are fewer than two priced packs, the currencies
  /// differ, or the lowest price is shared (MO18: never asserted).
  static ProductId? bestValue(Iterable<ProductOffer> offers) {
    final priced = [
      for (final o in offers)
        if (o.perReadingMinorUnits != null) o,
    ];
    if (priced.length < 2) return null;
    final currency = priced.first.currencyCode.toUpperCase();
    if (priced.any((o) => o.currencyCode.toUpperCase() != currency)) {
      return null;
    }
    priced.sort(
      (a, b) => a.perReadingMinorUnits!.compareTo(b.perReadingMinorUnits!),
    );
    if (priced[0].perReadingMinorUnits == priced[1].perReadingMinorUnits) {
      return null;
    }
    return priced.first.productId;
  }

  /// [offers] sorted by [sortOrder], then product ID.
  static List<ProductOffer> sorted(Iterable<ProductOffer> offers) =>
      [...offers]..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0
            ? bySort
            : a.productId.value.compareTo(b.productId.value);
      });
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
