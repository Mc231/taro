import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/src/components/deck/taro_card_ornament.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/placeholder_art.dart';
import '../../../helpers/pump_taro_ui_widget.dart';
import '../guidelines.dart';

/// Pumps [child] with animations on (no reduced motion).
Future<void> pumpAnimated(WidgetTester tester, Widget child) =>
    tester.pumpWidget(
      MaterialApp(
        theme: TaroTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('TaroCardSize', () {
    test('maps to size.card.* and the aspect ratio', () {
      final tokens = TaroTokens.light();
      final card = tokens.size.card;
      expect(TaroCardSize.thumb.widthOf(tokens), card.thumb);
      expect(TaroCardSize.sm.widthOf(tokens), card.sm);
      expect(TaroCardSize.md.widthOf(tokens), card.md);
      expect(TaroCardSize.lg.widthOf(tokens), card.lg);
      expect(
        TaroCardSize.md.sizeOf(tokens).height,
        closeTo(card.md / card.aspectRatio, 0.001),
      );
    });

    testWidgets('widthIn reads the ambient tokens', (tester) async {
      late double width;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) {
            width = TaroCardSize.lg.widthIn(context);
            return const SizedBox();
          },
        ),
      );
      expect(width, TaroTokens.light().size.card.lg);
    });
  });

  group('TaroCardFace', () {
    testWidgets('upright: label, numeral, name; art not rotated', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroCardFace(
            image: PlaceholderArt(),
            semanticsLabel: 'Three of Cups, upright, position: Past',
            numeral: 'III',
            name: 'Three of Cups',
          ),
        ),
      );
      expect(find.text('III'), findsOneWidget);
      expect(find.text('Three of Cups'), findsOneWidget);
      expect(find.byType(RotatedBox), findsNothing);
      expect(
        tester.getSemantics(find.byType(TaroCardFace)),
        isSemantics(
          label: 'Three of Cups, upright, position: Past',
          isImage: true,
        ),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('reversed: art rotated 180°, badge text not rotated', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroCardFace(
            image: PlaceholderArt(),
            semanticsLabel: 'Three of Cups, reversed',
            reversed: true,
            reversedLabel: 'Reversed',
            highlighted: true,
          ),
        ),
      );
      final rotated = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotated.quarterTurns, 2);
      expect(
        find.descendant(
          of: find.byType(RotatedBox),
          matching: find.text('Reversed'),
        ),
        findsNothing,
      );
      expect(find.text('Reversed'), findsOneWidget);
    });

    testWidgets('reversed without a badge label shows no badge', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const TaroCardFace(
          image: PlaceholderArt(),
          semanticsLabel: 'x',
          reversed: true,
        ),
      );
      expect(find.byType(RotatedBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TaroCardFace),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });

    testWidgets('art is never mirrored in RTL', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const TaroCardFace(image: PlaceholderArt(), semanticsLabel: 'x'),
        locale: const Locale('ar'),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.matchTextDirection, isFalse);
    });

    testWidgets('loading shows a skeleton; a broken image a sunken box', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const TaroCardFace(image: PendingArt(), semanticsLabel: 'x'),
      );
      expect(find.byType(SkeletonBlock), findsOneWidget);
      await pumpTaroUiWidget(
        tester,
        const TaroCardFace(image: BrokenArt(), semanticsLabel: 'x'),
      );
      await tester.pump();
      expect(find.byType(SkeletonBlock), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == TaroColorTokens.light.bg.sunken,
        ),
        findsOneWidget,
      );
    });

    testWidgets('tappable: a button with a 48 dp target', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpTaroUiWidget(
        tester,
        Center(
          child: TaroCardFace(
            image: const PlaceholderArt(),
            size: TaroCardSize.thumb,
            semanticsLabel: 'The Star',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(TaroCardFace));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(TaroCardFace)),
        isSemantics(label: 'The Star', isButton: true, hasTapAction: true),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });
  });

  group('TaroCardBack', () {
    testWidgets('decorative without a label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(tester, const Center(child: TaroCardBack()));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      handle.dispose();
    });

    testWidgets('pickable: label, tap, picked state, guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpTaroUiWidget(
        tester,
        Center(
          child: TaroCardBack(
            size: TaroCardSize.thumb,
            semanticsLabel: 'Card back, position 2 of 3, double-tap to pick',
            picked: true,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(TaroCardBack));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(TaroCardBack)),
        isSemantics(
          label: 'Card back, position 2 of 3, double-tap to pick',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(tester.getSize(find.byType(GestureDetector)).width, 48);
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('disabled: faded, taps ignored', (tester) async {
      var taps = 0;
      await pumpTaroUiWidget(
        tester,
        Center(
          child: TaroCardBack(
            semanticsLabel: 'Card back',
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(TaroCardBack));
      expect(taps, 0);
      expect(
        tester.widget<Opacity>(find.byType(Opacity)).opacity,
        TaroTokens.light().opacity.disabled,
      );
    });

    Finder ornament() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TaroCardOrnamentPainter,
    );

    testWidgets('raster art replaces the painted ornament', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const Center(child: TaroCardBack(art: PlaceholderArt())),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(ornament(), findsNothing);
    });

    testWidgets('art decodes at the card width in physical pixels', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(devicePixelRatio: 3),
            child: const Center(child: TaroCardBack(art: PlaceholderArt())),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(image, isA<ResizeImage>());
      expect(
        (image as ResizeImage).width,
        (TaroTokens.light().size.card.sm * 3).ceil(),
      );
      expect(image.height, isNull);
      expect(image.imageProvider, const PlaceholderArt());
    });

    testWidgets('pre-sized art is used as given', (tester) async {
      const sized = ResizeImage(PlaceholderArt(), width: 10);
      await pumpTaroUiWidget(
        tester,
        const Center(child: TaroCardBack(art: sized)),
      );
      expect(tester.widget<Image>(find.byType(Image)).image, same(sized));
    });

    testWidgets('the ornament stands in while the art decodes', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Center(child: TaroCardBack(art: PendingArt())),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(ornament(), findsOneWidget);
    });

    testWidgets('the ornament stands in when the art fails', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const Center(child: TaroCardBack(art: BrokenArt())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(ornament(), findsOneWidget);
    });

    testWidgets('backs draw the ambient TaroCardBackArt', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const TaroCardBackArt(
          image: PlaceholderArt(),
          child: Center(
            child: TaroCardBack(
              size: TaroCardSize.thumb,
              semanticsLabel: 'Card back',
            ),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect((image as ResizeImage).imageProvider, const PlaceholderArt());
      expect(ornament(), findsNothing);
      expect(
        tester.getSemantics(find.byType(TaroCardBack)),
        isSemantics(label: 'Card back'),
      );
      handle.dispose();
    });

    testWidgets('own art wins over the scope; a null scope paints', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const TaroCardBackArt(
          image: PlaceholderArt(),
          child: Column(
            children: [
              TaroCardBack(art: PlaceholderArt(glyph: TaroIcons.sword)),
              TaroCardBackArt(image: null, child: TaroCardBack()),
            ],
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(
        (image as ResizeImage).imageProvider,
        const PlaceholderArt(glyph: TaroIcons.sword),
      );
      expect(ornament(), findsOneWidget);
    });

    test('the scope notifies only when the image changes', () {
      const a = TaroCardBackArt(image: PlaceholderArt(), child: SizedBox());
      expect(
        a.updateShouldNotify(
          const TaroCardBackArt(image: PlaceholderArt(), child: SizedBox()),
        ),
        isFalse,
      );
      expect(
        a.updateShouldNotify(
          const TaroCardBackArt(image: null, child: SizedBox()),
        ),
        isTrue,
      );
    });

    test('the ornament painter repaints only on colour changes', () {
      const card = TaroColorTokens.light;
      final a = TaroCardOrnamentPainter(
        field: card.card.back,
        frame: card.card.frame,
      );
      expect(
        a.shouldRepaint(
          TaroCardOrnamentPainter(
            field: card.card.back,
            frame: card.card.frame,
          ),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          TaroCardOrnamentPainter(
            field: card.card.back,
            frame: TaroColorTokens.dark.card.frame,
          ),
        ),
        isTrue,
      );
    });
  });

  group('TaroCardFlip', () {
    const back = TaroCardBack(semanticsLabel: 'Card back');
    const face = TaroCardFace(
      image: PlaceholderArt(),
      semanticsLabel: 'The Star',
    );

    testWidgets('flips in 3D over motion.ritual.flip and plays haptics', (
      tester,
    ) async {
      final haptics = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          haptics.add(call);
          return null;
        },
      );
      var flipped = 0;
      Widget build({required bool revealed}) => TaroCardFlip(
        back: back,
        face: face,
        revealed: revealed,
        staggerIndex: 2,
        onFlipped: () => flipped++,
      );
      await pumpAnimated(tester, build(revealed: false));
      expect(find.byType(TaroCardBack), findsOneWidget);
      expect(find.byType(TaroCardFace), findsNothing);
      await pumpAnimated(tester, build(revealed: true));
      // Stagger: 2 × dealStagger before the flip starts.
      await tester.pump(TaroMotionTokens.light.ritual.dealStagger);
      expect(find.byType(TaroCardBack), findsOneWidget);
      await tester.pump(TaroMotionTokens.light.ritual.dealStagger);
      await tester.pump(TaroMotionTokens.light.ritual.flip * 0.2);
      expect(find.byType(Transform), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(TaroCardFace), findsOneWidget);
      expect(find.byType(TaroCardBack), findsNothing);
      expect(flipped, 1);
      expect(
        haptics.where((c) => c.method == 'HapticFeedback.vibrate'),
        isNotEmpty,
      );
      // Back to face-down without animation.
      await pumpAnimated(tester, build(revealed: false));
      await tester.pump();
      expect(find.byType(TaroCardBack), findsOneWidget);
    });

    testWidgets('reduced motion cross-fades; only the visible side is read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget build({required bool revealed}) => TaroCardFlip(
        back: back,
        face: face,
        revealed: revealed,
        haptics: false,
      );
      await pumpTaroUiWidget(tester, build(revealed: false));
      expect(find.semantics.byLabel('Card back'), findsOneWidget);
      expect(find.semantics.byLabel('The Star'), findsNothing);
      await pumpTaroUiWidget(tester, build(revealed: true));
      await tester.pump(TaroMotionTokens.reduced.ritual.flip * 0.75);
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, hasLength(2));
      expect(opacities.last, greaterThan(0.5));
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('The Star'), findsOneWidget);
      expect(find.semantics.byLabel('Card back'), findsNothing);
      handle.dispose();
    });

    testWidgets('reduced-motion cross-fade keeps both cards top-aligned', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroCardFlip(
            back: TaroCardBack(),
            face: TaroCardFace(
              image: PlaceholderArt(),
              size: TaroCardSize.sm,
              semanticsLabel: 'The Star',
              name: 'The Star',
            ),
            revealed: false,
          ),
        ),
      );
      // The face with its caption is taller than the back; the card
      // rectangles still start at the same top edge.
      expect(
        tester.getTopLeft(find.byType(TaroCardBack)).dy,
        tester.getTopLeft(find.byType(TaroCardFace)).dy,
      );
    });

    testWidgets('starts revealed; a pending stagger is cancelled', (
      tester,
    ) async {
      await pumpAnimated(
        tester,
        const TaroCardFlip(back: back, face: face, revealed: true),
      );
      expect(find.byType(TaroCardFace), findsOneWidget);
      await pumpAnimated(
        tester,
        const TaroCardFlip(back: back, face: face, revealed: false),
      );
      await pumpAnimated(
        tester,
        const TaroCardFlip(
          back: back,
          face: face,
          revealed: true,
          staggerIndex: 3,
          haptics: false,
        ),
      );
      // Disposed while the stagger timer is pending.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(TaroMotionTokens.light.ritual.dealStagger * 3);
    });
  });
}
