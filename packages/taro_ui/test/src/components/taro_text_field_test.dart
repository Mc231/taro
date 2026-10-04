import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsetsDirectional.all(16),
  child: child,
);

void main() {
  test('counts graphemes, not code units', () {
    expect(TaroTextField.graphemeCount('👩‍👩‍👧 ok'), 4);
    expect(TaroTextField.graphemeCount('لا'), 2);
    expect(TaroTextField.isOverLimit('abc', 2), isTrue);
    expect(TaroTextField.isOverLimit('abc', 3), isFalse);
    expect(TaroTextField.isOverLimit('abc', null), isFalse);
    expect(kTaroCounterVisibleFrom, 250);
  });

  // BUG-11: an English question typed in the Arabic UI kept the RTL base
  // direction, so "?" landed on the wrong side.
  testWidgets('follows the direction of the typed text', (tester) async {
    await pumpTaroUiWidget(
      tester,
      _pad(const TaroTextField(label: 'سؤالك')),
      locale: const Locale('ar'),
    );
    TextDirection? direction() =>
        tester.widget<TextField>(find.byType(TextField)).textDirection;
    expect(direction(), isNull);
    await tester.enterText(find.byType(TextField), 'What now?');
    await tester.pump();
    expect(direction(), TextDirection.ltr);
    await tester.enterText(find.byType(TextField), 'ماذا الآن؟');
    await tester.pump();
    expect(direction(), TextDirection.rtl);
    await tester.enterText(find.byType(TextField), '42');
    await tester.pump();
    expect(direction(), isNull);
  });

  testWidgets('label names the field; typing reports changes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <String>[];
    for (final mode in ThemeMode.values.skip(1)) {
      await pumpTaroUiWidget(
        tester,
        _pad(
          TaroTextField(
            label: 'Your question',
            hintText: 'What would you like to reflect on?',
            helperText: 'Open questions work best.',
            onChanged: changes.add,
          ),
        ),
        themeMode: mode,
      );
      await tester.pumpAndSettle();
      await expectMeetsGuidelines(tester);
    }
    await tester.enterText(find.byType(TextField), 'Hello');
    expect(changes, ['Hello']);
    expect(find.text('Open questions work best.'), findsOneWidget);
    final node = tester.getSemantics(find.byType(TextField));
    expect(node, isSemantics(isTextField: true));
    expect(node.label, startsWith('Your question'));
    handle.dispose();
  });

  testWidgets('counter appears from 250 graphemes and flags over-limit', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'a' * 249);
    addTearDown(controller.dispose);
    await pumpTaroUiWidget(
      tester,
      _pad(
        TaroTextField(
          controller: controller,
          style: TaroTextFieldStyle.multiLine,
          maxGraphemes: 300,
          counterFormatter: (count, max) => '$count of $max',
        ),
      ),
    );
    expect(find.textContaining(' of 300'), findsNothing);
    controller.text = 'a' * 250;
    await tester.pump();
    expect(find.text('250 of 300'), findsOneWidget);
    Color counterColor() =>
        tester.widget<Text>(find.textContaining(' of 300')).style!.color!;
    expect(counterColor(), TaroColorTokens.light.text.secondary);
    controller.text = '${'a' * 300}👍';
    await tester.pump();
    expect(find.text('301 of 300'), findsOneWidget);
    expect(counterColor(), TaroColorTokens.light.status.error);
  });

  testWidgets('default counter format and error text', (tester) async {
    await pumpTaroUiWidget(
      tester,
      _pad(
        TaroTextField(
          controller: TextEditingController(text: 'x' * 260),
          maxGraphemes: 500,
          errorText: 'Type DELETE to confirm',
          statusText: 'Saved on this device',
        ),
      ),
    );
    expect(find.text('260 / 500'), findsOneWidget);
    expect(find.text('Type DELETE to confirm'), findsOneWidget);
    expect(find.text('Saved on this device'), findsNothing);
  });

  testWidgets('status caption shows without error or helper', (tester) async {
    await pumpTaroUiWidget(
      tester,
      _pad(const TaroTextField(statusText: 'Saved on this device')),
    );
    expect(find.text('Saved on this device'), findsOneWidget);
  });

  testWidgets('search has a clear button that empties the field', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <String>[];
    String? submitted;
    await pumpTaroUiWidget(
      tester,
      _pad(
        TaroTextField(
          style: TaroTextFieldStyle.search,
          hintText: 'Search questions and notes',
          clearLabel: 'Clear search',
          onChanged: changes.add,
          onSubmitted: (v) => submitted = v,
        ),
      ),
    );
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byType(TaroIconButton), findsNothing);
    await tester.enterText(find.byType(TextField), 'star');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, 'star');
    expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
    await tester.tap(find.byType(TaroIconButton));
    await tester.pump();
    expect(find.text('star'), findsNothing);
    expect(changes, ['star', '']);
    handle.dispose();
  });

  testWidgets('disabled and read-only fields', (tester) async {
    await pumpTaroUiWidget(
      tester,
      _pad(
        Column(
          children: [
            TaroTextField(
              controller: TextEditingController(text: 'Kept question'),
              readOnly: true,
            ),
            const TaroTextField(hintText: 'Off', enabled: false),
          ],
        ),
      ),
    );
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.first.readOnly, isTrue);
    expect(fields.last.enabled, isFalse);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(TextField).last,
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      TaroOpacityTokens.light.disabled,
    );
  });

  testWidgets('swapping the controller keeps listening', (tester) async {
    final a = TextEditingController();
    final b = TextEditingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    late StateSetter set;
    var current = a;
    await pumpTaroUiWidget(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return TaroTextField(
            controller: current,
            maxGraphemes: 300,
            counterVisibleFrom: 3,
          );
        },
      ),
    );
    set(() => current = b);
    await tester.pump();
    b.text = 'abcd';
    await tester.pump();
    expect(find.text('4 / 300'), findsOneWidget);
    // Back to an internal controller.
    set(() => current = a);
    await tester.pump();
    expect(find.text('4 / 300'), findsNothing);
  });

  testWidgets('owns a controller when none is given', (tester) async {
    await pumpTaroUiWidget(
      tester,
      const TaroTextField(maxGraphemes: 10, counterVisibleFrom: 1),
    );
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(find.text('2 / 10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
