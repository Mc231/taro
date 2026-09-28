import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

ProductOffer offer(
  String suffix, {
  required double rawPrice,
  required int credits,
  String currencyCode = 'USD',
  int sortOrder = 0,
}) => ProductOffer(
  productId: ProductId('com.vshyrochuk.taro.$suffix'),
  price: '$currencyCode $rawPrice',
  rawPrice: rawPrice,
  currencyCode: currencyCode,
  credits: credits,
  sortOrder: sortOrder,
);

void main() {
  group('TaroProducts (04 §4, GLOSSARY §3)', () {
    test('IDs, kinds and aliases, no credits', () {
      expect(
        TaroProducts.all.map((p) => (p.id.value, p.kind, p.alias)),
        [
          (
            'com.vshyrochuk.taro.readings_3',
            ProductKind.consumable,
            'pack_s',
          ),
          (
            'com.vshyrochuk.taro.readings_10',
            ProductKind.consumable,
            'pack_m',
          ),
          (
            'com.vshyrochuk.taro.readings_30',
            ProductKind.consumable,
            'pack_l',
          ),
          (
            'com.vshyrochuk.taro.remove_ads',
            ProductKind.nonConsumable,
            'remove_ads',
          ),
        ],
      );
      expect(TaroProducts.consumables.every((p) => p.isConsumable), isTrue);
      expect(TaroProducts.removeAds.isConsumable, isFalse);
    });

    test('byId', () {
      expect(
        TaroProducts.byId(const ProductId('com.vshyrochuk.taro.readings_10')),
        TaroProducts.readings10,
      );
      expect(TaroProducts.byId(const ProductId('readings_10')), isNull);
    });

    test('value equality and toString', () {
      const copy = TaroProduct(
        id: 'com.vshyrochuk.taro.readings_3',
        kind: ProductKind.consumable,
        alias: 'pack_s',
      );
      expect(copy, TaroProducts.readings3);
      expect(copy.hashCode, TaroProducts.readings3.hashCode);
      expect(copy, isNot(TaroProducts.readings10));
      expect(copy.toString(), contains('readings_3'));
    });
  });

  group('IapCatalog.validate', () {
    test('accepts the shipped catalogue', () {
      expect(IapCatalog.validate, returnsNormally);
      expect(IapCatalog.problemsOf(TaroProducts.all), isEmpty);
    });

    test('throws on an unqualified ID', () {
      const bad = TaroProduct(
        id: 'readings_3',
        kind: ProductKind.consumable,
        alias: 'pack_s',
      );
      expect(
        () => IapCatalog.validate([bad, TaroProducts.removeAds]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('readings_3 is not fully qualified'),
          ),
        ),
      );
    });

    test('rejects duplicates and a wrong non-consumable set', () {
      expect(
        IapCatalog.problemsOf([TaroProducts.readings3, TaroProducts.readings3]),
        [
          'duplicate product IDs',
          'Remove Ads must be the only non-consumable',
        ],
      );
      const extra = TaroProduct(
        id: 'com.vshyrochuk.taro.premium',
        kind: ProductKind.nonConsumable,
        alias: 'premium',
      );
      expect(IapCatalog.problemsOf([extra]), [
        'Remove Ads must be the only non-consumable',
      ]);
      expect(IapCatalog.problemsOf([extra, TaroProducts.removeAds]), [
        'Remove Ads must be the only non-consumable',
      ]);
    });
  });

  group('currencyDecimals', () {
    test('ISO 4217 minor units', () {
      expect(currencyDecimals('JPY'), 0);
      expect(currencyDecimals('krw'), 0);
      expect(currencyDecimals('KWD'), 3);
      expect(currencyDecimals('CLF'), 4);
      expect(currencyDecimals('EUR'), 2);
      expect(currencyDecimals('USD'), 2);
      expect(currencyDecimals('XYZ'), 2);
    });
  });

  group('ProductOffer per-reading price (MO18)', () {
    final table = <String, (ProductOffer, int, double)>{
      'USD 1.99 / 3': (
        offer('readings_3', rawPrice: 1.99, credits: 3),
        66,
        0.66,
      ),
      'USD 4.99 / 10': (
        offer('readings_10', rawPrice: 4.99, credits: 10),
        50,
        0.5,
      ),
      'USD 9.99 / 30': (
        offer('readings_30', rawPrice: 9.99, credits: 30),
        33,
        0.33,
      ),
      'EUR 2.29 / 3': (
        offer('readings_3', rawPrice: 2.29, credits: 3, currencyCode: 'EUR'),
        76,
        0.76,
      ),
      'JPY 300 / 3': (
        offer('readings_3', rawPrice: 300, credits: 3, currencyCode: 'JPY'),
        100,
        100,
      ),
      'JPY 1000 / 30': (
        offer('readings_30', rawPrice: 1000, credits: 30, currencyCode: 'JPY'),
        33,
        33,
      ),
      'KWD 0.600 / 3': (
        offer('readings_3', rawPrice: 0.6, credits: 3, currencyCode: 'KWD'),
        200,
        0.2,
      ),
      'KWD 1.450 / 10': (
        offer('readings_10', rawPrice: 1.45, credits: 10, currencyCode: 'KWD'),
        145,
        0.145,
      ),
    };
    for (final MapEntry(key: name, value: row) in table.entries) {
      test(name, () {
        expect(row.$1.perReadingMinorUnits, row.$2);
        expect(row.$1.perReadingPrice, closeTo(row.$3, 1e-9));
      });
    }

    test('no per-reading price without credits', () {
      final free = offer('readings_3', rawPrice: 1.99, credits: 0);
      expect(free.perReadingMinorUnits, isNull);
      expect(free.perReadingPrice, isNull);
    });

    test('value equality and copyWith', () {
      final a = offer('readings_3', rawPrice: 1.99, credits: 3);
      expect(a, offer('readings_3', rawPrice: 1.99, credits: 3));
      expect(a.copyWith(credits: 4), isNot(a));
    });
  });

  group('ProductOffer.bestValue (computed, never asserted)', () {
    List<ProductOffer> packs(String currency, List<double> prices) => [
      offer(
        'readings_3',
        rawPrice: prices[0],
        credits: 3,
        currencyCode: currency,
      ),
      offer(
        'readings_10',
        rawPrice: prices[1],
        credits: 10,
        currencyCode: currency,
      ),
      offer(
        'readings_30',
        rawPrice: prices[2],
        credits: 30,
        currencyCode: currency,
      ),
    ];
    const best30 = ProductId('com.vshyrochuk.taro.readings_30');

    test('USD, EUR, JPY and KWD pick the lowest per-reading price', () {
      expect(ProductOffer.bestValue(packs('USD', [1.99, 4.99, 9.99])), best30);
      expect(ProductOffer.bestValue(packs('EUR', [2.29, 5.49, 10.99])), best30);
      expect(ProductOffer.bestValue(packs('JPY', [300, 800, 1500])), best30);
      expect(ProductOffer.bestValue(packs('KWD', [0.6, 1.45, 2.9])), best30);
    });

    test('follows the data, not the pack size', () {
      expect(
        ProductOffer.bestValue(packs('USD', [0.99, 4.99, 29.99])),
        const ProductId('com.vshyrochuk.taro.readings_3'),
      );
    });

    test('no badge on a tie at the lowest price', () {
      expect(ProductOffer.bestValue(packs('JPY', [300, 1000, 3000])), isNull);
    });

    test('no badge with mixed currencies or fewer than two priced packs', () {
      final mixed = packs('USD', [1.99, 4.99, 9.99]);
      mixed[0] = mixed[0].copyWith(currencyCode: 'EUR');
      expect(ProductOffer.bestValue(mixed), isNull);
      expect(
        ProductOffer.bestValue([offer('readings_3', rawPrice: 1, credits: 3)]),
        isNull,
      );
      expect(
        ProductOffer.bestValue([
          offer('readings_3', rawPrice: 1, credits: 3),
          offer('readings_10', rawPrice: 1, credits: 0),
        ]),
        isNull,
      );
      expect(ProductOffer.bestValue(const []), isNull);
    });

    test('currency codes compare case-insensitively', () {
      final lower = packs('usd', [1.99, 4.99, 9.99]);
      lower[0] = lower[0].copyWith(currencyCode: 'USD');
      expect(ProductOffer.bestValue(lower), best30);
    });
  });

  test('ProductOffer.sorted orders by sortOrder then ID', () {
    final sorted = ProductOffer.sorted([
      offer('readings_30', rawPrice: 1, credits: 30, sortOrder: 1),
      offer('readings_3', rawPrice: 1, credits: 3, sortOrder: 1),
      offer('readings_10', rawPrice: 1, credits: 10),
    ]);
    expect(sorted.map((o) => o.productId.value), [
      'com.vshyrochuk.taro.readings_10',
      'com.vshyrochuk.taro.readings_3',
      'com.vshyrochuk.taro.readings_30',
    ]);
  });
}
