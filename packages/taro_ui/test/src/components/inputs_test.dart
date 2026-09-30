import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsetsDirectional.all(16),
  child: child,
);

void main() {
  group('TaroIconButton', () {
    testWidgets('taps, labels, meets the guidelines, 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          Center(
            child: TaroIconButton(
              icon: Icons.close_rounded,
              semanticsLabel: 'Close',
              onPressed: () => taps++,
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TaroIconButton));
        await expectMeetsGuidelines(tester);
      }
      expect(taps, 2);
      expect(tester.getSize(find.byType(TaroIconButton)), const Size(48, 48));
      expect(
        tester.getSemantics(find.byType(TaroIconButton)),
        isSemantics(
          label: 'Close',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('toggle shows the selected glyph and toggled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        TaroIconButton(
          icon: Icons.star_border_rounded,
          selectedIcon: Icons.star_rounded,
          semanticsLabel: 'Favourite',
          toggled: true,
          onPressed: () {},
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.star_rounded);
      expect(icon.color, TaroColorTokens.light.accent.primary);
      expect(
        tester.getSemantics(find.byType(TaroIconButton)),
        isSemantics(label: 'Favourite', hasToggledState: true, isToggled: true),
      );
      handle.dispose();
    });

    testWidgets('disabled is dimmed, has no tooltip and no tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const TaroIconButton(
          icon: Icons.ios_share_rounded,
          semanticsLabel: 'Export',
          onPressed: null,
        ),
      );
      expect(find.byType(Tooltip), findsNothing);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        TaroOpacityTokens.light.disabled,
      );
      expect(
        tester.getSemantics(find.byType(TaroIconButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('focus draws the focus ring', (tester) async {
      await pumpTaroUiWidget(
        tester,
        TaroIconButton(
          icon: Icons.more_horiz_rounded,
          semanticsLabel: 'More',
          onPressed: () {},
        ),
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border is Border &&
              ((w.decoration as BoxDecoration).border! as Border).top.color ==
                  TaroColorTokens.light.border.focus,
        ),
        findsOneWidget,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('the back glyph mirrors in RTL', (tester) async {
      await pumpTaroUiWidget(
        tester,
        TaroIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          semanticsLabel: 'رجوع',
          onPressed: () {},
        ),
        locale: const Locale('ar'),
      );
      // Icon applies a mirroring transform for matchTextDirection glyphs.
      expect(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
    });
  });

  group('TaroChip', () {
    testWidgets('suggestion taps; filter toggles with selected semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      var selected = false;
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            StatefulBuilder(
              builder: (context, setState) => Wrap(
                spacing: 8,
                children: [
                  TaroChip.suggestion(
                    label: 'A decision at work',
                    leading: const Icon(Icons.lightbulb_outline_rounded),
                    onPressed: () => log.add('suggestion'),
                  ),
                  TaroChip.filter(
                    label: 'Favourites',
                    selected: selected,
                    onSelected: (v) => setState(() => selected = v),
                  ),
                ],
              ),
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('A decision at work'));
        await tester.tap(find.text('Favourites'));
        await tester.pump();
        await expectMeetsGuidelines(tester);
      }
      expect(log, ['suggestion', 'suggestion']);
      expect(selected, isFalse); // toggled twice
      await tester.tap(find.text('Favourites'));
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(TaroChip).last),
        isSemantics(label: 'Favourites', isButton: true, isSelected: true),
      );
      expect(
        tester.getSize(find.byType(TaroChip).first).height,
        greaterThanOrEqualTo(48),
      );
      handle.dispose();
    });

    testWidgets('a chip without a callback is disabled', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const Column(
          children: [
            TaroChip.suggestion(label: 'Off', onPressed: null),
            TaroChip.filter(label: 'Cups', selected: true, onSelected: null),
          ],
        ),
      );
      expect(find.byType(Opacity), findsNWidgets(2));
    });
  });

  group('TaroRadioTile', () {
    testWidgets('row and card select, announce checked in a group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? group = 'merge';
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  TaroRadioTile<String>(
                    value: 'merge',
                    groupValue: group,
                    title: 'Merge',
                    subtitle: 'Keep both journals.',
                    style: TaroRadioTileStyle.card,
                    onChanged: (v) => setState(() => group = v),
                  ),
                  TaroRadioTile<String>(
                    value: 'replace',
                    groupValue: group,
                    title: 'Replace',
                    subtitle: 'Use only the file.',
                    onChanged: (v) => setState(() => group = v),
                  ),
                  const TaroRadioTile<String>(
                    value: 'x',
                    groupValue: null,
                    title: 'Unavailable',
                    onChanged: null,
                  ),
                ],
              ),
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Replace'));
      await tester.pump();
      expect(group, 'replace');
      expect(
        tester.getSemantics(find.byType(TaroRadioTile<String>).at(1)),
        isSemantics(
          label: 'Replace\nUse only the file.',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(TaroRadioTile<String>).last),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('WeekdayPicker', () {
    const short = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const full = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    test('orders days from the first weekday', () {
      const picker = WeekdayPicker(
        selected: {},
        onChanged: null,
        shortLabels: short,
        fullLabels: full,
        firstWeekday: DateTime.sunday,
      );
      expect(picker.orderedDays, [7, 1, 2, 3, 4, 5, 6]);
    });

    testWidgets('toggles days and announces full names', (tester) async {
      final handle = tester.ensureSemantics();
      var days = <int>{DateTime.wednesday};
      await pumpTaroUiWidget(
        tester,
        _pad(
          StatefulBuilder(
            builder: (context, setState) => WeekdayPicker(
              selected: days,
              shortLabels: short,
              fullLabels: full,
              onChanged: (v) => setState(() => days = v),
            ),
          ),
        ),
      );
      await expectMeetsGuidelines(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wednesday')),
        isSemantics(isButton: true, isSelected: true, hasTapAction: true),
      );
      await tester.tap(find.bySemanticsLabel('Friday'));
      await tester.pump();
      expect(days, {DateTime.wednesday, DateTime.friday});
      await tester.tap(find.bySemanticsLabel('Wednesday'));
      await tester.pump();
      expect(days, {DateTime.friday});
      handle.dispose();
    });

    testWidgets('disabled picker is dimmed', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const WeekdayPicker(
          selected: {1},
          onChanged: null,
          shortLabels: short,
          fullLabels: full,
        ),
      );
      expect(find.byType(Opacity), findsOneWidget);
    });
  });

  group('TaroAccordion', () {
    testWidgets('expands and collapses with expanded semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <bool>[];
      await pumpTaroUiWidget(
        tester,
        _pad(
          TaroAccordion.text(
            title: 'Why did my reading fail?',
            body: 'Nothing was used.',
            onExpansionChanged: log.add,
          ),
        ),
      );
      expect(find.text('Nothing was used.'), findsNothing);
      expect(
        tester.getSemantics(find.text('Why did my reading fail?')),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false),
      );
      await tester.tap(find.text('Why did my reading fail?'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing was used.'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Why did my reading fail?')),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      await expectMeetsGuidelines(tester);
      // Reduced motion (the pump helper): no size animation.
      expect(find.byType(AnimatedSize), findsNothing);
      await tester.tap(find.text('Why did my reading fail?'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing was used.'), findsNothing);
      expect(log, [true, false]);
      handle.dispose();
    });

    testWidgets('animates the size without reduced motion; controlled', (
      tester,
    ) async {
      var open = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TaroAccordion(
                title: 'Q',
                expanded: open,
                onExpansionChanged: (v) => setState(() => open = v),
                child: const Text('A'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedSize), findsOneWidget);
      await tester.tap(find.text('Q'));
      await tester.pumpAndSettle();
      expect(open, isTrue);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('initiallyExpanded shows the answer', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const TaroAccordion(
          title: 'Q',
          initiallyExpanded: true,
          child: Text('A'),
        ),
      );
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('TaroTabStrip', () {
    const labels = [
      'Disclaimer',
      'Terms of use',
      'Privacy policy',
      'Open-source licences',
    ];

    testWidgets('selects tabs with tab semantics and scrolls into view', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var index = 0;
      await pumpTaroUiWidget(
        tester,
        StatefulBuilder(
          builder: (context, setState) => TaroTabStrip(
            labels: labels,
            selectedIndex: index,
            onSelected: (i) => setState(() => index = i),
          ),
        ),
        themeMode: ThemeMode.dark,
      );
      await expectMeetsGuidelines(tester);
      final node = tester.getSemantics(find.text('Disclaimer'));
      expect(node.getSemanticsData().role, SemanticsRole.tab);
      expect(node, isSemantics(isSelected: true, hasTapAction: true));
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
      expect(index, 2);
      expect(
        tester.getSemantics(find.text('Privacy policy')),
        isSemantics(isSelected: true),
      );
      // Selecting the last tab scrolls it on screen.
      await tester.tap(find.text('Open-source licences'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final right = tester.getRect(find.text('Open-source licences')).right;
      expect(right, lessThanOrEqualTo(375));
      handle.dispose();
    });

    testWidgets('an out-of-range update does not scroll', (tester) async {
      var index = 0;
      late StateSetter set;
      await pumpTaroUiWidget(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return TaroTabStrip(
              labels: labels,
              selectedIndex: index,
              onSelected: (_) {},
            );
          },
        ),
      );
      set(() => index = 9);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('StepIndicator', () {
    testWidgets('is one node with the step label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: StepIndicator(
            current: 2,
            total: 3,
            semanticsLabel: 'Step 2 of 3',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
      final dots = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(StepIndicator),
          matching: find.byType(Container),
        ),
      );
      expect(dots, hasLength(3));
      handle.dispose();
    });
  });
}
