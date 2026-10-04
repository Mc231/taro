import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/golden/golden_sizes.dart';
import '../../helpers/pump_taro_ui_widget.dart';

/// QA round 2 (docs/qa/round2/REPORT.md): pinned-bottom fade (V2-03),
/// rows at 200 % text (V2-04), chip rows (V2-05), tablet app bar (V2-09).

/// The fade over [of], if any.
TaroEdgeFade? _fade(WidgetTester tester, Finder of) {
  final found = find.ancestor(of: of, matching: find.byType(TaroEdgeFade));
  return found.evaluate().isEmpty
      ? null
      : tester.widget<TaroEdgeFade>(found.first);
}

Widget _scaffold({required int lines}) => TaroScaffold(
  body: ListView(
    children: [
      for (var i = 0; i < lines; i++)
        SizedBox(height: 40, child: Text('Line $i')),
    ],
  ),
  bottom: TaroButton.primary(label: 'Continue', onPressed: () {}),
);

void main() {
  group('V2-03: content under a pinned bottom fades out', () {
    final fade = find.byKey(const ValueKey('taroScaffoldBottomFade'));

    testWidgets('fades the bottom edge while more content follows', (
      tester,
    ) async {
      await pumpTaroUiWidget(tester, _scaffold(lines: 40));
      await tester.pump();
      expect(fade, findsOneWidget);
      // Over the bottom of the body, right above the pinned button.
      final button = tester.getRect(find.text('Continue'));
      expect(tester.getRect(fade).bottom, lessThanOrEqualTo(button.top));
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(fade, findsNothing);
      // The body was not rebuilt: it stays scrolled to the end.
      expect(find.text('Line 39'), findsOneWidget);
      expect(find.text('Line 0'), findsNothing);
    });

    testWidgets('content that fits is not faded', (tester) async {
      await pumpTaroUiWidget(tester, _scaffold(lines: 2));
      await tester.pump();
      expect(fade, findsNothing);
    });
  });

  group('V2-04: a row with a trailing button at 200 % text', () {
    testWidgets('the price drops under the title', (tester) async {
      await pumpTaroUiWidget(
        tester,
        SingleChildScrollView(
          child: ProductOfferTile(
            title: 'Remove Banner Ads',
            body: 'One-time purchase.',
            price: r'$3.99',
            purchaseSemanticsLabel: r'Buy for $3.99',
            onBuy: () {},
          ),
        ),
        textScale: 2,
      );
      final title = tester.getRect(find.text('Remove Banner Ads'));
      final price = tester.getRect(find.text(r'$3.99'));
      expect(price.top, greaterThanOrEqualTo(title.bottom));
      // The title keeps the tile's full width.
      final tile = tester.getRect(find.byType(ProductOfferTile));
      expect(title.width, greaterThan(tile.width / 2));
    });

    testWidgets('at 100 % the price stays beside the title', (tester) async {
      await pumpTaroUiWidget(
        tester,
        ProductOfferTile(
          title: 'Remove Banner Ads',
          price: r'$3.99',
          purchaseSemanticsLabel: r'Buy for $3.99',
          onBuy: () {},
        ),
      );
      final title = tester.getRect(find.text('Remove Banner Ads'));
      final price = tester.getRect(find.text(r'$3.99'));
      expect(price.left, greaterThan(title.right));
    });
  });

  group('V2-05: a horizontal chip row shows it scrolls', () {
    Widget row() => TaroScrollRow(
      spacing: 8,
      children: [
        for (var i = 0; i < 8; i++)
          TaroChip.filter(
            label: 'Daily card $i',
            selected: i == 0,
            onSelected: (_) {},
          ),
      ],
    );

    testWidgets('the end fades while chips are past the edge', (
      tester,
    ) async {
      await pumpTaroUiWidget(tester, row(), textScale: 2);
      await tester.pump();
      final fade = _fade(tester, find.text('Daily card 0'));
      expect(fade?.end, isTrue);
      expect(fade?.start, isFalse);
      await tester.drag(find.text('Daily card 0'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(_fade(tester, find.text('Daily card 0'))?.start, isTrue);
    });

    testWidgets('a row that fits does not fade', (tester) async {
      await pumpTaroUiWidget(
        tester,
        TaroScrollRow(
          children: [
            TaroChip.filter(label: 'All', selected: true, onSelected: (_) {}),
          ],
        ),
      );
      await tester.pump();
      final fade = _fade(tester, find.text('All'));
      expect(fade?.start ?? false, isFalse);
      expect(fade?.end ?? false, isFalse);
    });
  });

  group('V2-09: the app bar sits over the centred column on tablets', () {
    testWidgets('actions end at the content column, not the screen edge', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        TaroScaffold(
          appBar: TaroAppBar(
            leadingLabel: 'Back',
            onLeading: () {},
            actions: [
              TaroButton.tertiary(label: 'Add note', onPressed: () {}),
            ],
          ),
          body: const SizedBox.expand(),
        ),
        size: const Size(1280, 800),
      );
      final tokens = tester.element(find.byType(TaroAppBar)).tokens;
      final column = tokens.layout.maxContentWidth + 2 * tokens.layout.gutter;
      final edge = (1280 + column) / 2;
      final action = tester.getRect(find.text('Add note'));
      expect(action.right, lessThanOrEqualTo(edge));
      final back = tester.getRect(find.bySemanticsLabel('Back'));
      expect(back.left, greaterThanOrEqualTo((1280 - column) / 2));
    });

    testWidgets('on a phone the bar keeps the full width', (tester) async {
      await pumpTaroUiWidget(
        tester,
        TaroScaffold(
          appBar: TaroAppBar(
            leadingLabel: 'Back',
            onLeading: () {},
            actions: [
              TaroButton.tertiary(label: 'Add note', onPressed: () {}),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      );
      expect(
        tester.getRect(find.text('Add note')).right,
        greaterThan(kPhoneSmall.width - 48),
      );
    });
  });
}
