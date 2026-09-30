import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

/// Paths that only run with animations on (the pump helper turns reduced
/// motion on) and the runtime (non-const) constructors.
void main() {
  Future<void> pumpAnimated(WidgetTester tester, Widget child) =>
      tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  testWidgets('tab strip scrolls and switch animates with motion on', (
    tester,
  ) async {
    var index = 0;
    var on = false;
    await pumpAnimated(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            TaroTabStrip(
              labels: const [
                'Disclaimer',
                'Terms of use',
                'Privacy policy',
                'Open-source licences',
              ],
              selectedIndex: index,
              onSelected: (i) => setState(() => index = i),
            ),
            SettingsTile.toggle(
              title: 'Haptics',
              switchValue: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Privacy policy'));
    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();
    expect(index, 2);
    expect(on, isTrue);
  });

  testWidgets('weekday toggles through the semantics tap action', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var days = <int>{};
    await pumpAnimated(
      tester,
      StatefulBuilder(
        builder: (context, setState) => WeekdayPicker(
          selected: days,
          shortLabels: List.filled(7, 'd'),
          fullLabels: [for (var i = 1; i <= 7; i++) 'Day $i'],
          onChanged: (v) => setState(() => days = v),
        ),
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Day 2'));
    await tester.pump();
    expect(days, {2});
    expect(
      tester.getSemantics(find.bySemanticsLabel('Day 2')),
      isSemantics(isSelected: true),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Day 2'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('runtime constructors build', (tester) async {
    final n = DateTime(2026).year - 2023; // 3, not a constant
    final label = 'Label $n';
    await pumpAnimated(
      tester,
      Column(
        children: [
          StepIndicator(current: n - 1, total: n, semanticsLabel: label),
          IconBulletList(items: [IconBulletItem(title: label)]),
          NotificationPreview(
            appName: label,
            time: label,
            title: label,
            body: label,
          ),
          SegmentedChoice<int>(
            segments: [
              TaroSegment(value: 1, label: label),
              TaroSegment(value: n, label: '$label!'),
            ],
            selected: n,
            onChanged: (_) {},
          ),
          TaroLargeTitle(label),
          TaroDialog.progress(title: label),
          TaroTabBar(
            items: [
              TaroTabItem(icon: Icons.home, label: label),
              TaroTabItem(icon: Icons.book, label: '$label.'),
            ],
            currentIndex: 0,
            onSelected: (_) {},
          ),
          AiGeneratedLabel(label: label),
          AiGeneratedLabel.classic(label: '$label?', explanation: label),
          ReadingTextView(
            sections: [ReadingTextSection(body: label)],
          ),
          ReadingTextView.loading(loadingLabel: label),
          CountdownText(
            target: DateTime.utc(2030),
            now: () => DateTime.utc(2026),
            format: (d) => '${d.inDays}',
            reachedText: label,
            unknownText: label,
          ),
        ],
      ),
    );
    expect(find.text(label), findsWidgets);
  });
}
