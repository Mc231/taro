@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the monetization, data and brand visuals (Phase 15 Sprint
/// 15.2): light/dark × en/ar at `kPhoneSmall`, 200 % text for the
/// text-heavy ones.
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;

  goldenMatrix(
    'product_offer_tile',
    (v) {
      void buy() {}
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          spacing: 12,
          children: [
            ProductOfferTile(
              title: t(v, '3 readings', '٣ قراءات'),
              price: r'$1.99',
              perReadingPrice: t(v, r'$0.66 per reading', r'0.66 US$ للقراءة'),
              purchaseSemanticsLabel: '3 readings for 1.99 US dollars',
              onBuy: buy,
            ),
            ProductOfferTile(
              title: t(v, '10 readings', '١٠ قراءات'),
              price: r'$4.99',
              perReadingPrice: t(v, r'$0.50 per reading', r'0.50 US$ للقراءة'),
              purchaseSemanticsLabel: '10 readings for 4.99 US dollars',
              state: ProductOfferState.purchasing,
              onBuy: buy,
            ),
            ProductOfferTile(
              title: t(v, '30 readings', '٣٠ قراءة'),
              price: r'$9.99',
              perReadingPrice: t(v, r'$0.33 per reading', r'0.33 US$ للقراءة'),
              bestValueLabel: t(v, 'Best value', 'أفضل قيمة'),
              purchaseSemanticsLabel: '30 readings for 9.99 US dollars',
              onBuy: buy,
            ),
            ProductOfferTile(
              title: t(v, 'Remove Banner Ads', 'إزالة إعلانات البانر'),
              body: t(
                v,
                'One-time purchase. Optional reward videos stay available.',
                'شراء لمرة واحدة. تبقى فيديوهات المكافأة الاختيارية متاحة.',
              ),
              price: r'$3.99',
              purchaseSemanticsLabel: 'Remove banner ads for 3.99 US dollars',
              outlined: true,
              onBuy: buy,
            ),
            ProductOfferTile(
              title: t(v, '10 readings', '١٠ قراءات'),
              price: r'$4.99',
              purchaseSemanticsLabel: '10 readings for 4.99 US dollars',
              state: ProductOfferState.pending,
              statusLabel: t(v, 'Waiting for approval', 'بانتظار الموافقة'),
              onBuy: buy,
            ),
            ProductOfferTile(
              title: t(v, 'Remove Banner Ads', 'إزالة إعلانات البانر'),
              price: r'$3.99',
              purchaseSemanticsLabel: 'Remove banner ads',
              state: ProductOfferState.owned,
              statusLabel: t(
                v,
                'Banner ads removed',
                'أُزيلت إعلانات البانر',
              ),
              onBuy: buy,
            ),
            const ProductOfferTile.loading(),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix('banner_container', (v) {
    return Column(
      children: [
        const Spacer(),
        BannerContainer(height: 50, label: t(v, 'Ad', 'إعلان')),
        const BannerContainer(height: 50, child: Center(child: FlutterLogo())),
      ],
    );
  }, phoneSizes: const [kPhoneSmall]);

  goldenMatrix(
    'patterns_chart',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 16,
        children: [
          PatternsChart(
            title: t(v, 'Patterns · last 30 days', 'الأنماط · آخر 30 يومًا'),
            trailing: t(v, '28 cards drawn', 'سُحبت 28 بطاقة'),
            highlight: t(
              v,
              'Most drawn: The Star, 5 times',
              'الأكثر سحبًا: النجمة، 5 مرات',
            ),
            caption: t(
              v,
              'Patterns in your draws, not predictions.',
              'أنماط في سحوباتك، لا تنبؤات.',
            ),
            semanticsLabel: 'Suit balance',
            entries: [
              PatternsChartEntry(
                suit: TaroSuit.major,
                label: t(v, 'Major 9', 'الكبرى 9'),
                count: 9,
              ),
              PatternsChartEntry(
                suit: TaroSuit.wands,
                label: t(v, 'Wands 4', 'العصي 4'),
                count: 4,
              ),
              PatternsChartEntry(
                suit: TaroSuit.cups,
                label: t(v, 'Cups 7', 'الكؤوس 7'),
                count: 7,
              ),
              PatternsChartEntry(
                suit: TaroSuit.swords,
                label: t(v, 'Swords 3', 'السيوف 3'),
                count: 3,
              ),
              PatternsChartEntry(
                suit: TaroSuit.pentacles,
                label: t(v, 'Pentacles 5', 'النجوم 5'),
                count: 5,
              ),
            ],
          ),
          PatternsChart(
            title: t(v, 'Patterns · last 30 days', 'الأنماط · آخر 30 يومًا'),
            semanticsLabel: 'Suit balance',
            entries: const [],
            emptyMessage: t(
              v,
              'Draw a few more cards to see your patterns.',
              'اسحب بطاقات أكثر لترى أنماطك.',
            ),
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'balance_pill',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          BalancePill(
            state: BalancePillState.free,
            label: t(v, '1 free reading', 'قراءة مجانية واحدة'),
            onTap: () {},
          ),
          BalancePill(
            state: BalancePillState.credits,
            label: t(
              v,
              '3 readings · 1 free today',
              '٣ قراءات · واحدة مجانية اليوم',
            ),
            onTap: () {},
          ),
          BalancePill(
            state: BalancePillState.zero,
            label: t(v, '0 readings', '٠ قراءات'),
            onTap: () {},
          ),
          BalancePill(
            state: BalancePillState.stale,
            label: t(v, '3 readings', '٣ قراءات'),
            onTap: () {},
          ),
          BalancePill(
            state: BalancePillState.unverified,
            label: t(
              v,
              'Readings unavailable on this device',
              'القراءات غير متاحة على هذا الجهاز',
            ),
            actionLabel: t(v, 'Retry', 'إعادة'),
            onTap: () {},
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_brand_mark',
    (v) => Center(
      child: TaroBrandMark(
        semanticsLabel: 'Taro',
        wordmark: t(v, 'Taro', 'تارو'),
      ),
    ),
    phoneSizes: const [kPhoneSmall],
  );
}
