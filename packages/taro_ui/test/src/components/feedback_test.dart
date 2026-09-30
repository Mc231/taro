import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

void main() {
  group('TaroCoachmark', () {
    testWidgets('bubble: live title, Got it dismisses, arrows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var dismissed = 0;
      for (final arrow in TaroCoachmarkArrow.values) {
        await pumpTaroUiWidget(
          tester,
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: TaroCoachmark(
              title: 'Your first AI reading today is free',
              body: 'Start here when a question is on your mind.',
              dismissLabel: 'Got it',
              arrow: arrow,
              onDismiss: () => dismissed++,
            ),
          ),
          themeMode: ThemeMode.dark,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
        await tester.tap(find.text('Got it'));
        expect(
          find.byType(CustomPaint).evaluate().length,
          greaterThanOrEqualTo(arrow == TaroCoachmarkArrow.none ? 0 : 1),
        );
      }
      expect(dismissed, 3);
      expect(
        tester.getSemantics(find.text('Your first AI reading today is free')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('layer dims around the target, places the bubble, dismisses', (
      tester,
    ) async {
      final target = GlobalKey();
      var visible = true;
      var dismissed = 0;
      Future<void> pump(
        Alignment where, {
        Locale locale = const Locale('en'),
      }) => pumpTaroUiWidget(
        tester,
        StatefulBuilder(
          builder: (context, setState) => TaroCoachmarkLayer(
            visible: visible,
            targetKey: target,
            coachmark: TaroCoachmark(
              title: 'Free today',
              body: 'One free reading every day.',
              dismissLabel: 'Got it',
              onDismiss: () => setState(() {
                dismissed++;
                visible = false;
              }),
            ),
            child: Align(
              alignment: where,
              child: SizedBox(
                key: target,
                width: 200,
                height: 80,
                child: const Text('Start a reading'),
              ),
            ),
          ),
        ),
        locale: locale,
      );

      // Target in the lower half: the bubble sits above, arrow down.
      await pump(Alignment.bottomCenter);
      await tester.pumpAndSettle();
      final bubble = tester.widget<TaroCoachmark>(
        find.byType(TaroCoachmark),
      );
      expect(bubble.arrow, TaroCoachmarkArrow.down);
      expect(
        tester.getBottomLeft(find.byType(TaroCoachmark)).dy,
        lessThan(tester.getTopLeft(find.text('Start a reading')).dy),
      );
      // A scrim tap dismisses.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
      expect(find.byType(TaroCoachmark), findsNothing);

      // Target in the upper half (RTL): the bubble sits below, arrow up.
      visible = true;
      await pump(Alignment.topCenter, locale: const Locale('ar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TaroCoachmark>(find.byType(TaroCoachmark)).arrow,
        TaroCoachmarkArrow.up,
      );
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(dismissed, 2);
    });

    testWidgets('an unmounted target shows no coachmark', (tester) async {
      await pumpTaroUiWidget(
        tester,
        TaroCoachmarkLayer(
          targetKey: GlobalKey(),
          coachmark: TaroCoachmark(
            title: 't',
            body: 'b',
            dismissLabel: 'ok',
            onDismiss: () {},
          ),
          child: const SizedBox.expand(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TaroCoachmark), findsNothing);
    });
  });

  group('TaroToast', () {
    testWidgets('shows, runs Undo and closes', (tester) async {
      final handle = tester.ensureSemantics();
      var undone = 0;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => TaroToast.show(
              context,
              message: 'Entry deleted',
              actionLabel: 'Undo',
              onAction: () => undone++,
            ),
            child: const Text('delete'),
          ),
        ),
        themeMode: ThemeMode.dark,
      );
      await tester.tap(find.text('delete'));
      await tester.pumpAndSettle();
      expect(find.text('Entry deleted'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Entry deleted')),
        isSemantics(isLiveRegion: true),
      );
      await expectMeetsGuidelines(tester);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Entry deleted'), findsNothing);
      handle.dispose();
    });

    testWidgets('a plain toast closes after its duration', (tester) async {
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => TaroToast.show(context, message: '+10 readings'),
            child: const Text('buy'),
          ),
        ),
      );
      await tester.tap(find.text('buy'));
      await tester.pumpAndSettle();
      expect(find.text('+10 readings'), findsOneWidget);
      expect(find.byType(TaroButton), findsNothing);
      await tester.pump(kTaroToastDuration);
      await tester.pumpAndSettle();
      expect(find.text('+10 readings'), findsNothing);
      expect(kTaroToastUndoDuration, greaterThan(kTaroToastDuration));
    });
  });
}
