import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/placeholder_art.dart';
import '../../../helpers/pump_taro_ui_widget.dart';
import '../guidelines.dart';

Widget _cell(Widget child) =>
    Center(child: SizedBox(width: 110, height: 120, child: child));

void main() {
  testWidgets('numeral, art, name; one button node; tap and focus', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpTaroUiWidget(
      tester,
      _cell(
        CardGridTile(
          image: const PlaceholderArt(glyph: TaroIcons.majorStar),
          numeral: 'I',
          name: 'The Magician',
          semanticsLabel: 'The Magician, Major Arcana, card 2 of 22',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('I'), findsOneWidget);
    expect(find.text('The Magician'), findsOneWidget);
    await tester.tap(find.byType(CardGridTile));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(CardGridTile)),
      isSemantics(
        label: 'The Magician, Major Arcana, card 2 of 22',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await expectMeetsGuidelines(tester);
    // Keyboard focus shows the focus ring.
    tester.binding.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final shape =
        tester
                .widget<Material>(
                  find.descendant(
                    of: find.byType(CardGridTile),
                    matching: find.byType(Material),
                  ),
                )
                .shape!
            as RoundedRectangleBorder;
    expect(shape.side.color, TaroColorTokens.light.border.focus);
    handle.dispose();
  });

  testWidgets('loading art is a skeleton; broken art is blank; no numeral', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      _cell(
        const CardGridTile(
          image: PendingArt(),
          name: 'Page of Cups',
          semanticsLabel: 'Page of Cups',
          onTap: null,
        ),
      ),
    );
    expect(find.byType(SkeletonBlock), findsOneWidget);
    await pumpTaroUiWidget(
      tester,
      _cell(
        const CardGridTile(
          image: BrokenArt(),
          name: 'Page of Cups',
          semanticsLabel: 'Page of Cups',
          onTap: null,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SkeletonBlock), findsNothing);
  });

  group('TaroIcons and SuitGlyph', () {
    testWidgets('every glyph paints; decorative unless labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        Wrap(
          children: [
            for (final g in TaroIcons.values) TaroIcon(g),
            const TaroIcon(TaroIcons.cup, semanticsLabel: 'Cups', size: 32),
          ],
        ),
      );
      expect(find.byType(TaroIcon), findsNWidgets(TaroIcons.values.length + 1));
      expect(find.bySemanticsLabel('Cups'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TaroIcon).first),
        const Size.square(24),
      );
      handle.dispose();
    });

    test('every glyph has paths; the painter repaints on change', () {
      for (final g in TaroIcons.values) {
        expect(TaroGlyphPainter.pathsOf(g), isNotEmpty, reason: '$g');
      }
      const a = TaroGlyphPainter(TaroIcons.cup, color: Color(0xFF000000));
      expect(
        a.shouldRepaint(
          const TaroGlyphPainter(TaroIcons.cup, color: Color(0xFF000000)),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const TaroGlyphPainter(TaroIcons.sword, color: Color(0xFF000000)),
        ),
        isTrue,
      );
    });

    testWidgets('suits map to glyphs and suit/chart colours', (tester) async {
      late BuildContext ctx;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return Row(
              children: [
                for (final s in TaroSuit.values) SuitGlyph(s),
                const SuitGlyph(
                  TaroSuit.cups,
                  size: SuitGlyphSize.sm,
                  semanticsLabel: 'Cups',
                ),
              ],
            );
          },
        ),
        themeMode: ThemeMode.dark,
      );
      const dark = TaroColorTokens.dark;
      expect(TaroSuit.major.glyph, TaroIcons.majorStar);
      expect(TaroSuit.wands.glyph, TaroIcons.wand);
      expect(TaroSuit.cups.glyph, TaroIcons.cup);
      expect(TaroSuit.swords.glyph, TaroIcons.sword);
      expect(TaroSuit.pentacles.glyph, TaroIcons.pentacle);
      expect(TaroSuit.major.colorIn(ctx), dark.suit.major);
      expect(TaroSuit.wands.colorIn(ctx), dark.suit.wands);
      expect(TaroSuit.cups.colorIn(ctx), dark.suit.cups);
      expect(TaroSuit.swords.colorIn(ctx), dark.suit.swords);
      expect(TaroSuit.pentacles.colorIn(ctx), dark.suit.pentacles);
      expect(TaroSuit.major.chartColorIn(ctx), dark.chart.suit.major);
      expect(TaroSuit.wands.chartColorIn(ctx), dark.chart.suit.wands);
      expect(TaroSuit.cups.chartColorIn(ctx), dark.chart.suit.cups);
      expect(TaroSuit.swords.chartColorIn(ctx), dark.chart.suit.swords);
      expect(TaroSuit.pentacles.chartColorIn(ctx), dark.chart.suit.pentacles);
      expect(tester.getSize(find.byType(TaroIcon).last), const Size.square(16));
    });
  });
}
