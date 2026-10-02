@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';
import '../helpers/placeholder_art.dart';
import '../helpers/spread_samples.dart';

/// Goldens of the deck components (Phase 15 Sprint 15.2): light/dark ×
/// en/ar at `kPhoneSmall`; `kTabletIpad13` for the layout-level
/// `SpreadCanvas` and `CardFan` (RC24); 200 % text where text leads.
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;
  bool ar(GoldenVariant v) => v.locale.languageCode == 'ar';

  goldenMatrix('taro_card', (v) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          TaroCardFace(
            image: const PlaceholderArt(),
            size: TaroCardSize.sm,
            semanticsLabel: 'Three of Cups',
            numeral: 'III',
            name: t(v, 'Three of Cups', 'ثلاثة كؤوس'),
          ),
          TaroCardFace(
            image: const PlaceholderArt(glyph: TaroIcons.sword),
            size: TaroCardSize.sm,
            semanticsLabel: 'Two of Swords, reversed',
            reversed: true,
            reversedLabel: t(v, 'Reversed', 'مقلوبة'),
            numeral: 'II',
            name: t(v, 'Two of Swords', 'اثنان من السيوف'),
          ),
          const TaroCardFace(
            image: PlaceholderArt(glyph: TaroIcons.majorStar),
            size: TaroCardSize.sm,
            semanticsLabel: 'The Star',
            highlighted: true,
          ),
          const TaroCardFace(
            image: PendingArt(),
            size: TaroCardSize.sm,
            semanticsLabel: 'Loading',
          ),
          const TaroCardBack(),
          TaroCardBack(
            semanticsLabel: 'Card back',
            picked: true,
            onTap: () {},
          ),
          TaroCardBack(
            semanticsLabel: 'Card back',
            enabled: false,
            onTap: () {},
          ),
          const TaroCardBack(size: TaroCardSize.thumb),
        ],
      ),
    );
  }, phoneSizes: const [kPhoneSmall]);

  goldenMatrix('taro_card_back_art', (v) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: TaroCardBackArt(
        image: const PlaceholderArt(glyph: TaroIcons.majorStar),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            const TaroCardBack(),
            TaroCardBack(
              semanticsLabel: 'Card back',
              picked: true,
              onTap: () {},
            ),
            TaroCardBack(
              semanticsLabel: 'Card back',
              enabled: false,
              onTap: () {},
            ),
            const TaroCardBack(size: TaroCardSize.thumb),
            const TaroCardBack(art: PendingArt()),
          ],
        ),
      ),
    );
  }, phoneSizes: const [kPhoneSmall]);

  final ppf = ['Past', 'Present', 'Future'];
  final ppfAr = ['الماضي', 'الحاضر', 'المستقبل'];

  goldenMatrix(
    'spread_canvas',
    (v) {
      final names = ar(v) ? ppfAr : ppf;
      final cross = ar(v)
          ? SpreadSamples.celticCrossNamesAr
          : SpreadSamples.celticCrossNames;
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          spacing: 32,
          children: [
            SpreadCanvas(
              slots: [
                for (var i = 0; i < 3; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.threePpf[i],
                    label: names[i],
                    number: i + 1,
                    card: switch (i) {
                      0 => const TaroCardFace(
                        image: PlaceholderArt(),
                        semanticsLabel: 'Three of Cups',
                      ),
                      1 => const TaroCardBack(picked: true),
                      _ => null,
                    },
                  ),
              ],
            ),
            SpreadCanvas(
              slots: [
                for (var i = 0; i < 10; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.celticCross[i],
                    label: cross[i],
                    number: i + 1,
                    card: i < 7 ? const TaroCardBack() : null,
                  ),
              ],
            ),
            SpreadCanvas(
              mode: SpreadCanvasMode.compactRow,
              slots: [
                for (var i = 0; i < 3; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.threePpf[i],
                    label: names[i],
                    number: i + 1,
                    card: const TaroCardFace(
                      image: PlaceholderArt(),
                      semanticsLabel: 'card',
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
    keyScreen: true,
    largeText: true,
  );

  goldenMatrix(
    'card_fan',
    (v) => Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 24),
        child: CardFan(
          cardCount: 76,
          semanticsLabel: 'Deck, 76 cards',
          cardSemanticsLabel: (i) => 'Card ${i + 1}',
          drawForMeLabel: t(v, 'Draw for me', 'اسحب لي'),
          onDrawForMe: () {},
          confirmLabel: t(v, 'Pick this card', 'اختر هذه البطاقة'),
          onConfirm: () {},
          focusedIndex: 37,
          onFocus: (_) {},
        ),
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
    keyScreen: true,
  );

  const spreads = [
    SpreadSamples.single,
    SpreadSamples.threePpf,
    SpreadSamples.relationship,
    SpreadSamples.celticCross,
  ];

  goldenMatrix(
    'spread_diagram',
    (v) {
      final cross = ar(v)
          ? SpreadSamples.celticCrossNamesAr
          : SpreadSamples.celticCrossNames;
      return SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final (i, layout) in spreads.indexed)
                  SizedBox(
                    width: 104,
                    child: SpreadDiagram(
                      layout: layout,
                      semanticsLabel: 'layout',
                      selected: i == 1,
                    ),
                  ),
              ],
            ),
            SpreadDiagram(
              layout: SpreadSamples.celticCross,
              semanticsLabel: 'Celtic Cross layout',
              size: SpreadDiagramSize.large,
              legend: [
                for (final name in cross.take(3))
                  SpreadDiagramLegendEntry(
                    title: name,
                    description: t(
                      v,
                      'where you stand right now',
                      'أين تقف الآن',
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix('card_grid_tile', (v) {
    const glyphs = [
      TaroIcons.majorStar,
      TaroIcons.wand,
      TaroIcons.cup,
      TaroIcons.sword,
      TaroIcons.pentacle,
      TaroIcons.card,
    ];
    final names = ar(v)
        ? [
            'الأحمق',
            'الساحر',
            'الكاهنة العليا',
            'الإمبراطورة',
            'الإمبراطور',
            'الحبر الأعظم',
          ]
        : [
            'The Fool',
            'The Magician',
            'The High Priestess',
            'The Empress',
            'The Emperor',
            'The Hierophant',
          ];
    const numerals = ['0', 'I', 'II', 'III', 'IV', 'V'];
    return GridView.count(
      padding: const EdgeInsetsDirectional.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        for (var i = 0; i < 6; i++)
          CardGridTile(
            image: PlaceholderArt(glyph: glyphs[i]),
            numeral: numerals[i],
            name: names[i],
            semanticsLabel: names[i],
            onTap: () {},
          ),
      ],
    );
  }, phoneSizes: const [kPhoneSmall]);

  goldenMatrix('suit_glyph', (v) {
    final names = ar(v)
        ? ['الأركانا الكبرى', 'العصي', 'الكؤوس', 'السيوف', 'النجوم']
        : ['Major Arcana', 'Wands', 'Cups', 'Swords', 'Pentacles'];
    return Builder(
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            for (final suit in TaroSuit.values)
              Row(
                spacing: 8,
                children: [
                  SuitGlyph(suit),
                  SuitGlyph(suit, size: SuitGlyphSize.sm),
                  Text(
                    names[suit.index],
                    style: context.tokens.typography.label.copyWith(
                      color: context.tokens.color.text.primary,
                    ),
                  ),
                ],
              ),
            Wrap(
              spacing: 16,
              children: [
                for (final g in TaroIcons.values)
                  TaroIcon(
                    g,
                    size: 32,
                    color: context.tokens.color.text.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }, phoneSizes: const [kPhoneSmall]);

  // TaroCardFlip: at rest (back), mid-flip with full motion (Y rotation),
  // mid cross-fade under reduced motion (01 §14.4) and revealed. The
  // mid-animation frames need a timed pump, so this golden is registered
  // by hand instead of through goldenMatrix (which settles animations).
  group('taro_card_flip', () {
    for (final variant in goldenVariants(phoneSizes: const [kPhoneSmall])) {
      testWidgets(variant.name, (tester) async {
        final revealed = ValueNotifier(false);
        addTearDown(revealed.dispose);
        Widget flip({required bool motion, bool? fixed}) {
          final card = ValueListenableBuilder<bool>(
            valueListenable: revealed,
            builder: (context, value, _) => TaroCardFlip(
              back: const TaroCardBack(),
              face: TaroCardFace(
                image: const PlaceholderArt(),
                size: TaroCardSize.sm,
                semanticsLabel: 'Three of Cups',
                numeral: 'III',
                name: t(variant, 'Three of Cups', 'ثلاثة كؤوس'),
              ),
              revealed: fixed ?? value,
              haptics: false,
            ),
          );
          if (!motion) return card;
          return Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: false),
              child: card,
            ),
          );
        }

        await pumpTaroUiGolden(
          tester,
          SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                flip(motion: false, fixed: false),
                flip(motion: true),
                flip(motion: false),
                flip(motion: false, fixed: true),
              ],
            ),
          ),
          variant,
        );
        await tester.pumpAndSettle();
        revealed.value = true;
        await tester.pump();
        // Mid-animation: 100 ms into the 600 ms `motion.ritual.flip` and
        // the midpoint of its reduced 200 ms cross-fade.
        await tester.pump(const Duration(milliseconds: 100));
        await expectLater(
          find.byType(WidgetsApp),
          matchesGoldenFile(goldenPath('taro_card_flip', variant)),
        );
        await tester.pumpAndSettle();
      }, tags: const ['golden']);
    }
  });
}
