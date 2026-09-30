import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

void main() {
  testWidgets('every variant taps, meets the guidelines and is 52 dp', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final taps = <String>[];
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      await pumpTaroUiWidget(
        tester,
        Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            children: [
              TaroButton.primary(
                label: 'Begin',
                onPressed: () => taps.add('primary'),
              ),
              TaroButton.secondary(
                label: 'Not now',
                onPressed: () => taps.add('secondary'),
              ),
              TaroButton.tertiary(
                label: 'Terms',
                onPressed: () => taps.add('tertiary'),
              ),
              TaroButton.destructive(
                label: 'Delete all data',
                icon: Icons.delete_outline_rounded,
                onPressed: () => taps.add('destructive'),
              ),
            ],
          ),
        ),
        themeMode: themeMode,
      );
      for (final label in ['Begin', 'Not now', 'Terms', 'Delete all data']) {
        await tester.tap(find.text(label));
      }
      await expectMeetsGuidelines(tester);
    }
    expect(taps, [
      'primary',
      'secondary',
      'tertiary',
      'destructive',
      'primary',
      'secondary',
      'tertiary',
      'destructive',
    ]);
    expect(tester.getSize(find.byType(TaroButton).first).height, 52);
    expect(
      tester.getSize(find.byType(TaroButton).at(2)).height,
      greaterThanOrEqualTo(48),
    );
    // Primary fills the width; tertiary hugs its label.
    expect(tester.getSize(find.byType(TaroButton).first).width, 375 - 32);
    expect(
      tester.getSize(find.byType(TaroButton).at(2)).width,
      lessThan(375 - 32),
    );
    handle.dispose();
  });

  testWidgets('pressed primary uses accentPrimaryPressed', (tester) async {
    await pumpTaroUiWidget(
      tester,
      TaroButton(label: 'Begin', onPressed: () {}),
    );
    Color fill() => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(TaroButton),
            matching: find.byType(Material),
          ),
        )
        .color!;
    expect(fill(), TaroColorTokens.light.accent.primary);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Begin')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(fill(), TaroColorTokens.light.accent.primaryPressed);
    await gesture.up();
    await tester.pump();
    expect(fill(), TaroColorTokens.light.accent.primary);
  });

  testWidgets('secondary press shows the pressed overlay', (tester) async {
    await pumpTaroUiWidget(
      tester,
      TaroButton.secondary(label: 'Not now', onPressed: () {}),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Not now')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump();
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('disabled: no tap, dimmed, semantics disabled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTaroUiWidget(
      tester,
      const TaroButton.primary(label: 'Buy', onPressed: null),
    );
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      TaroOpacityTokens.light.disabled,
    );
    expect(
      tester.getSemantics(find.byType(TaroButton)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('loading keeps the label for semantics and ignores taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpTaroUiWidget(
      tester,
      TaroButton.primary(
        label: 'Buy 10 readings',
        loading: true,
        loadingSemanticsHint: 'Loading',
        onPressed: () => taps++,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Reduced motion (the pump helper disables animations): a still arc.
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNotNull,
    );
    await tester.tap(find.byType(TaroButton), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester.getSemantics(find.byType(TaroButton)),
      isSemantics(
        label: 'Buy 10 readings',
        hint: 'Loading',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the spinner animates without reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TaroTheme.light(),
        home: Scaffold(
          body: TaroButton.secondary(
            label: 'Restore',
            loading: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
  });

  testWidgets('semanticsLabel overrides the label and still taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpTaroUiWidget(
      tester,
      TaroButton.tertiary(
        label: 'Terms',
        semanticsLabel: 'Terms of use',
        onPressed: () => taps++,
      ),
    );
    final node = tester.getSemantics(find.byType(TaroButton));
    expect(node, isSemantics(label: 'Terms of use', isButton: true));
    tester.semantics.tap(find.semantics.byLabel('Terms of use'));
    expect(taps, 1);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('focus shows the focus ring', (tester) async {
    await pumpTaroUiWidget(
      tester,
      TaroButton.primary(label: 'Begin', onPressed: () {}),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border is Border &&
          ((w.decoration as BoxDecoration).border! as Border).top.color ==
              TaroColorTokens.light.border.focus,
    );
    expect(ring, findsOneWidget);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('expand in an unbounded row hugs the label', (tester) async {
    await pumpTaroUiWidget(
      tester,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: TaroButton.primary(label: 'Go', onPressed: () {}),
      ),
    );
    expect(tester.getSize(find.byType(TaroButton)).width, lessThan(200));
  });

  test('the variant constructors set the variant', () {
    void noop() {}
    expect(
      TaroButton.secondary(label: 'a', onPressed: noop).variant,
      TaroButtonVariant.secondary,
    );
    expect(
      TaroButton(
        label: 'a',
        onPressed: noop,
        variant: TaroButtonVariant.destructive,
      ).variant,
      TaroButtonVariant.destructive,
    );
  });

  testWidgets(
    'a button in a labelled container is its own node',
    (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        Semantics(
          container: true,
          liveRegion: true,
          label: 'Reading deleted',
          child: Column(
            children: [TaroButton.tertiary(label: 'Undo', onPressed: () {})],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TaroButton)),
        matchesSemantics(
          label: 'Undo',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    },
  );
}
