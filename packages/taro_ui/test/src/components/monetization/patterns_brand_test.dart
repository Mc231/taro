import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/pump_taro_ui_widget.dart';
import '../guidelines.dart';

const _entries = [
  PatternsChartEntry(suit: TaroSuit.major, label: 'Major 9', count: 9),
  PatternsChartEntry(suit: TaroSuit.wands, label: 'Wands 4', count: 4),
  PatternsChartEntry(suit: TaroSuit.cups, label: 'Cups 7', count: 7),
  PatternsChartEntry(suit: TaroSuit.swords, label: 'Swords 0', count: 0),
  PatternsChartEntry(suit: TaroSuit.pentacles, label: 'Pentacles 5', count: 5),
];

void main() {
  group('PatternsChart', () {
    testWidgets('bars by count; legend with glyph and name; one summary', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Padding(
          padding: EdgeInsetsDirectional.all(16),
          child: PatternsChart(
            title: 'Patterns · last 30 days',
            trailing: '25 cards drawn',
            highlight: 'Most drawn: The Star, 5 times',
            caption: 'Patterns in your draws, not predictions.',
            entries: _entries,
            semanticsLabel: 'Suit balance: Major Arcana 9, Wands 4',
          ),
        ),
      );
      final bars = tester.widgetList<Expanded>(
        find.descendant(
          of: find.byType(PatternsChart),
          matching: find.byType(Expanded),
        ),
      );
      expect(bars.map((e) => e.flex), [9, 4, 7, 5]);
      expect(find.byType(SuitGlyph), findsNWidgets(5));
      expect(find.text('Swords 0'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(PatternsChart)),
        isSemantics(label: 'Suit balance: Major Arcana 9, Wands 4'),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('RTL: the bar grows from the right', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const PatternsChart(
          title: 't',
          entries: _entries,
          semanticsLabel: 's',
        ),
        locale: const Locale('ar'),
      );
      final bars = find.descendant(
        of: find.byType(PatternsChart),
        matching: find.byType(Expanded),
      );
      expect(
        tester.getCenter(bars.first).dx,
        greaterThan(tester.getCenter(bars.last).dx),
      );
    });

    testWidgets('too few readings shows the empty copy', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const PatternsChart(
          title: 't',
          entries: _entries,
          semanticsLabel: 's',
          emptyMessage: 'Draw a few more cards to see patterns.',
          showEmpty: true,
        ),
      );
      expect(
        find.text('Draw a few more cards to see patterns.'),
        findsOneWidget,
      );
      expect(find.byType(SuitGlyph), findsNothing);
      await pumpTaroUiWidget(
        tester,
        const PatternsChart(
          title: 't',
          entries: [
            PatternsChartEntry(suit: TaroSuit.cups, label: 'Cups 0', count: 0),
          ],
          semanticsLabel: 's',
        ),
      );
      expect(find.byType(SuitGlyph), findsNothing);
    });
  });

  group('TaroBrandMark', () {
    testWidgets('mark + wordmark is one image node', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroBrandMark(semanticsLabel: 'Taro', wordmark: 'Taro'),
        ),
      );
      expect(find.text('Taro'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TaroBrandMark)),
        isSemantics(label: 'Taro', isImage: true),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('mark only, sized from size.card.*', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroBrandMark(semanticsLabel: 'Taro', size: TaroCardSize.sm),
        ),
        themeMode: ThemeMode.dark,
      );
      expect(find.byType(Text), findsNothing);
      final tokens = TaroTokens.dark();
      expect(
        tester.getSize(find.byType(TaroBrandMark)),
        TaroCardSize.sm.sizeOf(tokens),
      );
    });
  });
}
