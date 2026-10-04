import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/golden/golden_sizes.dart';
import '../../../helpers/placeholder_art.dart';
import '../../../helpers/pump_taro_ui_widget.dart';
import '../../../helpers/spread_samples.dart';
import '../guidelines.dart';

List<SpreadCanvasSlot> _ppf({int filled = 2}) => [
  for (final (i, name) in const ['Past', 'Present', 'Future'].indexed)
    SpreadCanvasSlot(
      layout: SpreadSamples.threePpf[i],
      label: name,
      number: i + 1,
      emptySemanticsLabel: 'Position ${i + 1}, $name, empty',
      card: i < filled
          ? TaroCardBack(semanticsLabel: 'Card back, $name')
          : null,
    ),
];

void main() {
  group('SpreadSlotLayout', () {
    test('mirrors x in RTL only', () {
      const slot = SpreadSlotLayout(x: 0.2, y: 0.3, rotationDeg: 90);
      expect(slot.resolve(TextDirection.ltr), same(slot));
      final rtl = slot.resolve(TextDirection.rtl);
      expect(rtl.x, closeTo(0.8, 1e-9));
      expect(rtl.y, 0.3);
      expect(rtl.rotationDeg, 90);
      expect(slot.isCrossing, isTrue);
      expect(const SpreadSlotLayout(x: 0, y: 0).isCrossing, isFalse);
      expect(
        const SpreadSlotLayout(x: 0, y: 0, rotationDeg: -270).isCrossing,
        isTrue,
      );
    });

    test('value equality and toString', () {
      expect(
        const SpreadSlotLayout(x: 0.5, y: 0.5),
        const SpreadSlotLayout(x: 0.5, y: 0.5),
      );
      expect(
        const SpreadSlotLayout(x: 0.5, y: 0.5).hashCode,
        const SpreadSlotLayout(x: 0.5, y: 0.5).hashCode,
      );
      expect(
        const SpreadSlotLayout(x: 0.5, y: 0.5),
        isNot(const SpreadSlotLayout(x: 0.5, y: 0.4)),
      );
      expect(
        const SpreadSlotLayout(x: 0.5, y: 0.5).toString(),
        contains('0.5'),
      );
    });
  });

  group('SpreadGeometry', () {
    test('a row keeps the nominal card and one slot of height', () {
      final g = SpreadGeometry.compute(
        slots: SpreadSamples.threePpf,
        width: 343,
        cardWidth: 72,
        aspectRatio: 0.58,
        labelExtent: 20,
        gap: 12,
      );
      expect(g.cardSize.width, 72);
      expect(g.size.height, closeTo(72 / 0.58 + 20, 0.001));
      expect(g.centers.first.dx, closeTo(36 + 0.123 * 271, 0.01));
      expect(g.centers.last.dx, closeTo(36 + 0.877 * 271, 0.01));
    });

    test('cards on a row shrink to fit; columns never overlap', () {
      final g = SpreadGeometry.compute(
        slots: SpreadSamples.celticCross,
        width: 343,
        cardWidth: 104,
        aspectRatio: 0.58,
        labelExtent: 20,
        gap: 12,
      );
      final w = g.cardSize.width;
      expect(w, lessThan(104));
      final slotHeight = g.cardSize.height + 20;
      // The staff (slots 6–9) stacks without overlap.
      for (var i = 6; i < 9; i++) {
        expect(
          (g.centers[i].dy - g.centers[i + 1].dy).abs(),
          greaterThanOrEqualTo(slotHeight - 0.001),
        );
      }
      // Recent past and present sit side by side.
      expect(
        (g.centers[0].dx - g.centers[3].dx).abs(),
        greaterThanOrEqualTo(w + 12 - 0.001),
      );
      // The crossing card shares the present card's centre.
      expect(g.centers[1], g.centers[0]);
    });

    test('no slots is an empty strip', () {
      final g = SpreadGeometry.compute(
        slots: const [],
        width: 100,
        cardWidth: 40,
        aspectRatio: 0.5,
      );
      expect(g.size, const Size(100, 80));
      expect(g.centers, isEmpty);
    });
  });

  group('SpreadCanvas', () {
    testWidgets('lays out slots with labels; empty slot is numbered', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: SpreadCanvas(
            slots: _ppf(),
            semanticsLabel: 'Past, Present, Future spread',
          ),
        ),
      );
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Position 3, Future, empty'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Card back, Past'), findsOneWidget);
      final past = tester.getCenter(find.text('Past'));
      final future = tester.getCenter(find.text('Future'));
      expect(past.dx, lessThan(future.dx));
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('RTL mirrors x; the art is not mirrored', (tester) async {
      await pumpTaroUiWidget(
        tester,
        SpreadCanvas(slots: _ppf(filled: 3)),
        locale: const Locale('ar'),
      );
      final past = tester.getCenter(find.text('Past'));
      final future = tester.getCenter(find.text('Future'));
      expect(past.dx, greaterThan(future.dx));
      expect(
        find.byWidgetPredicate(
          (w) => w is Transform && w.transform.storage[0] < 0,
        ),
        findsNothing,
      );
    });

    testWidgets('an empty slot without a semantics label uses its name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const SpreadCanvas(
          slots: [
            SpreadCanvasSlot(
              layout: SpreadSlotLayout(x: 0.5, y: 0.5),
              label: 'Focus',
              number: 1,
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Focus'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Celtic Cross: the crossing card is rotated, unlabelled', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        SingleChildScrollView(
          child: SpreadCanvas(
            slots: [
              for (var i = 0; i < 10; i++)
                SpreadCanvasSlot(
                  layout: SpreadSamples.celticCross[i],
                  label: SpreadSamples.celticCrossNames[i],
                  number: i + 1,
                  card: i < 2
                      ? TaroCardFace(
                          image: const PlaceholderArt(),
                          semanticsLabel: SpreadSamples.celticCrossNames[i],
                        )
                      : null,
                ),
            ],
          ),
        ),
      );
      // Numbered under the cards, named in the legend (V2-01): the
      // crossing card gets its number under the card it crosses.
      expect(find.text('1 · 2'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      final rotated = tester
          .widgetList<Transform>(find.byType(Transform))
          .where((t) => t.transform.storage[1].abs() > 0.99);
      expect(rotated, hasLength(1));
    });

    testWidgets('reflows to a vertical list above 1.5× text', (tester) async {
      await pumpTaroUiWidget(tester, SpreadCanvas(slots: _ppf()), textScale: 2);
      final past = tester.getCenter(find.text('Past'));
      final future = tester.getCenter(find.text('Future'));
      expect(past.dy, lessThan(future.dy));
      expect(
        find.descendant(
          of: find.byType(SpreadCanvas),
          matching: find.byType(CustomMultiChildLayout),
        ),
        findsNothing,
      );
      await expectMeetsGuidelines(tester);
    });

    testWidgets('compact row: thumbs, no labels', (tester) async {
      await pumpTaroUiWidget(
        tester,
        SpreadCanvas(slots: _ppf(), mode: SpreadCanvasMode.compactRow),
      );
      expect(find.text('Past'), findsNothing);
      final size = tester.getSize(find.byType(FittedBox).first);
      expect(size.width, TaroTokens.light().size.card.thumb);
    });

    testWidgets('the dashed outline repaints with the theme', (tester) async {
      const canvas = SpreadCanvas(
        slots: [
          SpreadCanvasSlot(
            layout: SpreadSlotLayout(x: 0.5, y: 0.5),
            label: 'Focus',
            number: 1,
          ),
        ],
      );
      CustomPainter painter() => tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(SpreadCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
      await pumpTaroUiWidget(tester, canvas);
      final light = painter();
      await pumpTaroUiWidget(tester, canvas, themeMode: ThemeMode.dark);
      await tester.pumpAndSettle();
      final dark = painter();
      expect(dark.shouldRepaint(light), isTrue);
      expect(dark.shouldRepaint(dark), isFalse);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('relayouts when the slots move', (tester) async {
      await pumpTaroUiWidget(tester, SpreadCanvas(slots: _ppf()));
      final before = tester.getCenter(find.text('Past'));
      await pumpTaroUiWidget(
        tester,
        const SpreadCanvas(
          slots: [
            SpreadCanvasSlot(
              layout: SpreadSlotLayout(x: 0.5, y: 0.5),
              label: 'Past',
              number: 1,
            ),
          ],
        ),
      );
      expect(tester.getCenter(find.text('Past')), isNot(before));
    });
  });

  group('SpreadDiagram', () {
    testWidgets('small: one semantics node, numbered outlines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: SpreadDiagram(
            layout: SpreadSamples.threePpf,
            semanticsLabel: 'Three cards in a row',
            selected: true,
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(SpreadDiagram)),
        isSemantics(label: 'Three cards in a row', isImage: true),
      );
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(SpreadDiagram),
                matching: find.byType(CustomMultiChildLayout),
              ),
            )
            .width,
        lessThanOrEqualTo(TaroTokens.light().size.card.md),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('large with legend, mirrored in RTL', (tester) async {
      Future<Offset> centerOf(String n, Locale locale) async {
        await pumpTaroUiWidget(
          tester,
          const SingleChildScrollView(
            child: SpreadDiagram(
              layout: SpreadSamples.celticCross,
              semanticsLabel: 'Celtic Cross layout',
              size: SpreadDiagramSize.large,
              legend: [
                SpreadDiagramLegendEntry(
                  title: 'Present',
                  description: 'where you stand right now',
                ),
                SpreadDiagramLegendEntry(title: 'Challenge'),
              ],
            ),
          ),
          locale: locale,
          size: kPhoneLarge,
        );
        return tester.getCenter(find.text(n).first);
      }

      final ltr = await centerOf('10', const Locale('en'));
      expect(find.text('where you stand right now'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      final rtl = await centerOf('10', const Locale('ar'));
      expect(rtl.dx, lessThan(ltr.dx));
    });

    testWidgets('large without a legend is the diagram only', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const SpreadDiagram(
          layout: SpreadSamples.single,
          semanticsLabel: 'One card',
          size: SpreadDiagramSize.large,
        ),
      );
      expect(find.byType(Divider), findsNothing);
      await pumpTaroUiWidget(
        tester,
        const SpreadDiagram(
          layout: SpreadSamples.relationship,
          semanticsLabel: 'Relationship',
          size: SpreadDiagramSize.large,
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });
  });
}
