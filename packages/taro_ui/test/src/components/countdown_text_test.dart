import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';

void main() {
  final start = DateTime.utc(2026, 9, 30, 18, 48);
  String format(Duration d) =>
      'in ${d.inHours} h ${d.inMinutes.remainder(60)} min';

  testWidgets('counts down from the server instant and re-syncs once', (
    tester,
  ) async {
    var now = start;
    var reached = 0;
    await pumpTaroUiWidget(
      tester,
      CountdownText(
        target: start.add(const Duration(hours: 5, minutes: 12)),
        now: () => now,
        format: format,
        reachedText: 'Your free reading is ready',
        unknownText: 'Resets at midnight',
        onReached: () => reached++,
      ),
    );
    expect(find.text('in 5 h 12 min'), findsOneWidget);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(kCountdownRefreshInterval);
    expect(find.text('in 5 h 11 min'), findsOneWidget);
    now = now.add(const Duration(hours: 6));
    await tester.pump(kCountdownRefreshInterval);
    await tester.pump();
    expect(find.text('Your free reading is ready'), findsOneWidget);
    expect(reached, 1);
    // The timer stopped; later frames never report again.
    await tester.pump(kCountdownRefreshInterval * 3);
    expect(reached, 1);
    expect(
      tester.widget<Text>(find.byType(Text)).style!.color,
      TaroColorTokens.light.text.secondary,
    );
  });

  testWidgets('unknown target shows the offline copy and no timer', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      CountdownText(
        target: null,
        now: () => start,
        format: format,
        reachedText: 'ready',
        unknownText: 'Resets at midnight',
        style: const TextStyle(),
        textAlign: TextAlign.center,
      ),
    );
    expect(find.text('Resets at midnight'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a new target restarts the countdown', (tester) async {
    DateTime? target;
    late StateSetter set;
    await pumpTaroUiWidget(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return CountdownText(
            target: target,
            now: () => start,
            format: format,
            reachedText: 'ready',
            unknownText: 'unknown',
          );
        },
      ),
    );
    expect(find.text('unknown'), findsOneWidget);
    set(() => target = start.add(const Duration(minutes: 4)));
    await tester.pump();
    expect(find.text('in 0 h 4 min'), findsOneWidget);
    // A past target without onReached just shows the reached copy.
    set(() => target = start.subtract(const Duration(minutes: 1)));
    await tester.pump();
    await tester.pump();
    expect(find.text('ready'), findsOneWidget);
  });
}
