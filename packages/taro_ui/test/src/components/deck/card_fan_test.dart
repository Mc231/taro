import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/pump_taro_ui_widget.dart';
import '../guidelines.dart';

class _Fan extends StatefulWidget {
  const _Fan({this.count = 78, this.shuffling = false});

  final int count;
  final bool shuffling;

  @override
  State<_Fan> createState() => _FanState();
}

class _FanState extends State<_Fan> {
  int? focused;
  int draws = 0;
  int confirms = 0;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.bottomCenter,
    child: CardFan(
      cardCount: widget.count,
      semanticsLabel: 'Deck, ${widget.count} cards',
      cardSemanticsLabel: (i) => 'Card ${i + 1} of ${widget.count}',
      drawForMeLabel: 'Draw for me',
      onDrawForMe: () => setState(() => draws++),
      confirmLabel: 'Pick this card',
      onConfirm: () => setState(() => confirms++),
      focusedIndex: focused,
      onFocus: (i) => setState(() => focused = i),
      shuffling: widget.shuffling,
    ),
  );
}

void main() {
  testWidgets('centres the fan; tap focuses; confirm and draw for me', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTaroUiWidget(tester, const _Fan());
    final state = tester.state<_FanState>(find.byType(_Fan));
    expect(find.bySemanticsLabel('Deck, 78 cards'), findsOneWidget);
    // Only the visible cards are built.
    final built = tester.widgetList(find.byType(TaroCardBack)).length;
    expect(built, lessThan(78));
    expect(built, greaterThan(5));
    // Nothing focused: confirm disabled.
    await tester.tap(find.text('Pick this card'));
    expect(state.confirms, 0);
    await tester.tap(find.text('Draw for me'));
    expect(state.draws, 1);
    // Tap the middle card.
    final view = tester.getSize(find.byType(CardFan));
    await tester.tapAt(
      Offset(
        view.width / 2,
        tester.getCenter(find.byType(TaroCardBack).first).dy,
      ),
    );
    await tester.pump();
    expect(state.focused, isNotNull);
    expect(state.focused, inInclusiveRange(30, 48));
    final picked = tester
        .widgetList<TaroCardBack>(find.byType(TaroCardBack))
        .where((b) => b.picked);
    expect(picked, hasLength(1));
    await tester.tap(find.text('Pick this card'));
    expect(state.confirms, 1);
    await expectMeetsGuidelines(tester);
    handle.dispose();
  });

  for (final (locale, towardsEnd) in const [
    (Locale('en'), Offset(-6000, 0)),
    (Locale('ar'), Offset(6000, 0)),
  ]) {
    testWidgets('$locale: the deck runs from the start edge', (tester) async {
      Finder card(int n) => find.byWidgetPredicate(
        (w) => w is TaroCardBack && w.semanticsLabel == 'Card $n of 78',
      );
      await pumpTaroUiWidget(tester, const _Fan(), locale: locale);
      expect(card(1), findsNothing);
      expect(card(78), findsNothing);
      await tester.drag(find.byType(SingleChildScrollView), towardsEnd);
      await tester.pumpAndSettle();
      expect(card(78), findsOneWidget);
      await tester.drag(find.byType(SingleChildScrollView), -towardsEnd * 2);
      await tester.pumpAndSettle();
      expect(card(1), findsOneWidget);
      // Card 2 follows card 1 in reading direction.
      final one = tester.getCenter(card(1)).dx;
      final two = tester.getCenter(card(2)).dx;
      expect(locale.languageCode == 'ar' ? two < one : two > one, isTrue);
    });
  }

  testWidgets('exhausted: no cards, both actions disabled', (tester) async {
    await pumpTaroUiWidget(tester, const _Fan(count: 0));
    final state = tester.state<_FanState>(find.byType(_Fan));
    expect(find.byType(TaroCardBack), findsNothing);
    await tester.tap(find.text('Draw for me'));
    expect(state.draws, 0);
  });

  testWidgets('shuffling animates without reduced motion, then stops', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TaroTheme.light(),
        home: const Scaffold(body: _Fan(shuffling: true)),
      ),
    );
    double firstStart() =>
        tester.getTopLeft(find.byType(TaroCardBack).first).dx;
    final a = firstStart();
    await tester.pump(TaroMotionTokens.light.ritual.shuffle * 0.25);
    expect(firstStart(), isNot(a));
    await tester.pumpWidget(
      MaterialApp(
        theme: TaroTheme.light(),
        home: const Scaffold(body: _Fan()),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shuffling is static under reduced motion', (tester) async {
    await pumpTaroUiWidget(tester, const _Fan(shuffling: true));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('without a confirm label only Draw for me shows', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      CardFan(
        cardCount: 3,
        semanticsLabel: 'Deck',
        cardSemanticsLabel: (i) => 'Card $i',
        drawForMeLabel: 'Draw for me',
        onDrawForMe: null,
      ),
    );
    expect(find.byType(TaroButton), findsOneWidget);
    await tester.tap(find.byType(TaroCardBack).first);
  });
}
