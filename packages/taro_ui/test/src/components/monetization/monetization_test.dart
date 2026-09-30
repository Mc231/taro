import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/pump_taro_ui_widget.dart';
import '../guidelines.dart';

void main() {
  group('bestValueOfferIndex', () {
    test('the unique lowest per-reading price wins', () {
      expect(bestValueOfferIndex([66, 50, 33]), 2);
      expect(bestValueOfferIndex([0.33, 0.5, 0.66]), 0);
      expect(bestValueOfferIndex([50, 33, 40]), 1);
    });

    test('no badge for a tie or fewer than two offers', () {
      expect(bestValueOfferIndex([50, 33, 33]), isNull);
      expect(bestValueOfferIndex([33, 33, 50]), isNull);
      expect(bestValueOfferIndex([33]), isNull);
      expect(bestValueOfferIndex(const []), isNull);
      // A later, lower price clears an earlier tie.
      expect(bestValueOfferIndex([50, 50, 33]), 2);
    });
  });

  group('ProductOfferTile', () {
    testWidgets('content: price button with the full sentence; badge', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var buys = 0;
      await pumpTaroUiWidget(
        tester,
        Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: ProductOfferTile(
            title: '30 readings',
            price: r'$9.99',
            perReadingPrice: r'$0.33 per reading',
            bestValueLabel: 'Best value',
            purchaseSemanticsLabel:
                '30 readings for 9.99 US dollars, 33 cents per reading',
            onBuy: () => buys++,
          ),
        ),
      );
      expect(find.text('Best value'), findsOneWidget);
      expect(find.text(r'$0.33 per reading'), findsOneWidget);
      await tester.tap(find.byType(TaroButton));
      expect(buys, 1);
      expect(
        find.bySemanticsLabel(
          '30 readings for 9.99 US dollars, 33 cents per reading',
        ),
        findsOneWidget,
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('purchasing: this button spins and ignores taps', (
      tester,
    ) async {
      var buys = 0;
      await pumpTaroUiWidget(
        tester,
        ProductOfferTile(
          title: '10 readings',
          price: r'$4.99',
          purchaseSemanticsLabel: '10 readings for 4.99 US dollars',
          purchasingSemanticsHint: 'Purchasing',
          state: ProductOfferState.purchasing,
          onBuy: () => buys++,
        ),
      );
      expect(
        tester.widget<TaroButton>(find.byType(TaroButton)).loading,
        isTrue,
      );
      await tester.tap(find.byType(TaroButton));
      expect(buys, 0);
    });

    testWidgets('pending and owned replace the button with a status', (
      tester,
    ) async {
      for (final state in [
        ProductOfferState.pending,
        ProductOfferState.owned,
      ]) {
        await pumpTaroUiWidget(
          tester,
          ProductOfferTile(
            title: 'Remove Banner Ads',
            body: 'One-time purchase.',
            price: r'$3.99',
            purchaseSemanticsLabel: 'Remove banner ads for 3.99 US dollars',
            state: state,
            statusLabel: state.name,
            outlined: true,
            onBuy: () {},
          ),
        );
        expect(find.byType(TaroButton), findsNothing);
        expect(find.text(state.name), findsOneWidget);
        expect(find.text('One-time purchase.'), findsOneWidget);
      }
    });

    testWidgets('outlined uses the secondary button; pending w/o status', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        ProductOfferTile(
          title: 'Remove Banner Ads',
          price: r'$3.99',
          purchaseSemanticsLabel: 'Remove banner ads for 3.99 US dollars',
          state: ProductOfferState.pending,
          outlined: true,
          onBuy: () {},
        ),
      );
      expect(
        tester.widget<TaroButton>(find.byType(TaroButton)).variant,
        TaroButtonVariant.secondary,
      );
    });

    testWidgets('loading is a labelled skeleton', (tester) async {
      final handle = tester.ensureSemantics();
      final label = ['Load', 'ing'].join();
      await pumpTaroUiWidget(
        tester,
        ProductOfferTile.loading(loadingSemanticsLabel: label),
      );
      expect(find.byType(SkeletonBlock), findsNWidgets(3));
      expect(find.byType(TaroButton), findsNothing);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('BannerContainer', () {
    testWidgets('fixed height, ad colour, space.adGap ≥ 16 on both sides', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Column(
          children: [
            Spacer(),
            BannerContainer(height: 50, label: 'Ad'),
          ],
        ),
      );
      final tokens = TaroTokens.light();
      expect(tokens.space.adGap, greaterThanOrEqualTo(16));
      expect(find.text('Ad'), findsOneWidget);
      final box = tester.getRect(find.byType(ColoredBox).last);
      expect(box.height, 50);
      expect(
        tester.getSize(find.byType(BannerContainer)).height,
        50 + tokens.space.adGap * 2,
      );
      expect(
        tester.widget<ColoredBox>(find.byType(ColoredBox).last).color,
        tokens.color.ad.container,
      );
      await expectMeetsGuidelines(tester);
    });

    testWidgets('loaded child replaces the marker; collapsed is empty', (
      tester,
    ) async {
      late double gap;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) {
            gap = BannerContainer.separationOf(context);
            return const BannerContainer(
              height: 50,
              label: 'Ad',
              child: Text('creative'),
            );
          },
        ),
      );
      expect(gap, 16);
      expect(find.text('creative'), findsOneWidget);
      expect(find.text('Ad'), findsNothing);
      await pumpTaroUiWidget(
        tester,
        const BannerContainer(height: 50, collapsed: true),
      );
      expect(tester.getSize(find.byType(BannerContainer)), Size.zero);
      await pumpTaroUiWidget(tester, const BannerContainer(height: 50));
      expect(tester.getSize(find.byType(BannerContainer)).height, 82);
    });
  });

  group('BalancePill', () {
    for (final state in BalancePillState.values) {
      testWidgets('$state: a ≥ 48 dp labelled button', (tester) async {
        final handle = tester.ensureSemantics();
        var taps = 0;
        await pumpTaroUiWidget(
          tester,
          Center(
            child: BalancePill(
              state: state,
              label: 'label ${state.name}',
              actionLabel: state == BalancePillState.unverified
                  ? 'Retry'
                  : null,
              semanticsLabel: state == BalancePillState.unverified
                  ? 'Readings unavailable, Retry'
                  : null,
              semanticsHint: 'Opens the store',
              announce: state == BalancePillState.credits,
              onTap: () => taps++,
            ),
          ),
        );
        await tester.tap(find.byType(BalancePill));
        expect(taps, 1);
        expect(tester.getSize(find.byType(BalancePill)).height, 48);
        final label = state == BalancePillState.unverified
            ? 'Readings unavailable, Retry'
            : 'label ${state.name}';
        expect(
          tester.getSemantics(find.byType(BalancePill)),
          isSemantics(
            label: label,
            hint: 'Opens the store',
            isButton: true,
            hasTapAction: true,
            isLiveRegion: state == BalancePillState.credits,
          ),
        );
        final hasDot = find.descendant(
          of: find.byType(BalancePill),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect(
          hasDot,
          state == BalancePillState.free || state == BalancePillState.credits
              ? findsOneWidget
              : findsNothing,
        );
        await expectMeetsGuidelines(tester);
        handle.dispose();
      });
    }

    testWidgets('zero is never red', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const BalancePill(state: BalancePillState.zero, label: '0 readings'),
      );
      final text = tester.widget<Text>(find.text('0 readings'));
      expect(text.style!.color, TaroColorTokens.light.text.primary);
    });
  });
}
