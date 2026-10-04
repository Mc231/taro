import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/golden/golden_sizes.dart';
import '../../helpers/pump_taro_ui_widget.dart';

/// The labels in [finder] that break a line between two non-space
/// characters (inside a word, or anywhere in a label without spaces).
List<String> midWordBreaks(Finder finder) {
  final broken = <String>[];
  for (final element in finder.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final text = paragraph.text.toPlainText();
    double? previous;
    for (var i = 0; i < text.length; i++) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      final top = boxes.isEmpty ? null : boxes.first.top;
      if (top != null &&
          previous != null &&
          (top - previous).abs() > 1 &&
          text[i].trim().isNotEmpty &&
          text[i - 1].trim().isNotEmpty) {
        broken.add(text);
        break;
      }
      previous = top;
    }
  }
  return broken;
}

/// The Celtic Cross layout of `assets/deck/spreads.json` (draw order).
const List<SpreadSlotLayout> _celtic = [
  SpreadSlotLayout(x: 0.356, y: 0.5),
  SpreadSlotLayout(x: 0.356, y: 0.5, rotationDeg: 90),
  SpreadSlotLayout(x: 0.356, y: 0.743),
  SpreadSlotLayout(x: 0.129, y: 0.5),
  SpreadSlotLayout(x: 0.356, y: 0.257),
  SpreadSlotLayout(x: 0.582, y: 0.5),
  SpreadSlotLayout(x: 0.871, y: 0.864),
  SpreadSlotLayout(x: 0.871, y: 0.621),
  SpreadSlotLayout(x: 0.871, y: 0.379),
  SpreadSlotLayout(x: 0.871, y: 0.136),
];

const List<SpreadSlotLayout> _three = [
  SpreadSlotLayout(x: 0.123, y: 0.5),
  SpreadSlotLayout(x: 0.5, y: 0.5),
  SpreadSlotLayout(x: 0.877, y: 0.5),
];

Widget _canvas(
  List<SpreadSlotLayout> layouts,
  List<String> labels, {
  TaroCardSize size = TaroCardSize.sm,
}) => Padding(
  padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
  child: SpreadCanvas(
    cardSize: size,
    slots: [
      for (var i = 0; i < layouts.length; i++)
        SpreadCanvasSlot(
          layout: layouts[i],
          label: labels[i],
          number: i + 1,
          card: const TaroCardBack(),
        ),
    ],
  ),
);

Finder _label(String text) => find.text(text);

void main() {
  group('SpreadCanvas labels never break inside a word (BUG-05, BUG-08)', () {
    const english = [
      'Present',
      'Challenge',
      'Foundation',
      'Recent Past',
      'Potential',
      'Near Future',
      'Self',
      'Environment',
      'Hopes and Fears',
      'Outcome',
    ];
    const german = [
      'Gegenwart',
      'Herausforderung',
      'Grundlage',
      'Jüngste Vergangenheit',
      'Potenzial',
      'Nahe Zukunft',
      'Selbst',
      'Umfeld',
      'Hoffnungen und Ängste',
      'Ergebnis',
    ];
    const japanese = [
      '現在',
      '試練',
      '土台',
      '最近の過去',
      '可能性',
      '近い未来',
      '自分',
      '周囲',
      '希望と恐れ',
      '結果',
    ];
    for (final (name, labels, locale) in [
      ('en', english, const Locale('en')),
      ('de', german, const Locale('de')),
      ('ja', japanese, const Locale('ja')),
      ('ar', english, const Locale('ar')),
    ]) {
      for (final size in [kPhoneSmall, kPhoneLarge]) {
        testWidgets('Celtic Cross, $name, ${size.width.round()} wide', (
          tester,
        ) async {
          await pumpTaroUiWidget(
            tester,
            _canvas(_celtic, labels),
            locale: locale,
            size: size,
          );
          final shown = [
            for (var i = 0; i < labels.length; i++)
              if (i != 1) labels[i],
          ];
          expect(
            midWordBreaks(
              find.byWidgetPredicate(
                (w) => w is Text && shown.contains(w.data),
              ),
            ),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('three cards: "Vergangenheit" stays one word', (
      tester,
    ) async {
      for (final size in [kPhoneSmall, kPhoneLarge]) {
        await pumpTaroUiWidget(
          tester,
          _canvas(_three, const [
            'Vergangenheit',
            'Gegenwart',
            'Zukunft',
          ], size: TaroCardSize.md),
          locale: const Locale('de'),
          size: size,
        );
        expect(midWordBreaks(_label('Vergangenheit')), isEmpty);
      }
    });

    testWidgets('a label that fits keeps the label size', (tester) async {
      await pumpTaroUiWidget(
        tester,
        _canvas(_three, const [
          'Past',
          'Present',
          'Future',
        ], size: TaroCardSize.md),
      );
      final text = tester.widget<Text>(_label('Past'));
      expect(text.textScaler, isNull);
    });
  });

  group('TaroBadge.maxWidth (BUG-06)', () {
    testWidgets('wraps between words, shrinks a long word, stays inside', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Center(
          child: TaroBadge(
            label: 'Zum Aufdecken tippen',
            maxWidth: 60,
            textAlign: TextAlign.center,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(TaroBadge)).width,
        lessThanOrEqualTo(60),
      );
      expect(midWordBreaks(_label('Zum Aufdecken tippen')), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without maxWidth it is one unconstrained line', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const Center(child: TaroBadge(label: 'Tap to reveal')),
      );
      final text = tester.widget<Text>(_label('Tap to reveal'));
      expect(text.textScaler, isNull);
      expect(text.textAlign, isNull);
    });
  });

  group('TaroCoachmarkLayer at 200 % text (BUG-13)', () {
    testWidgets('scrolls the target into view and keeps the bubble inside', (
      tester,
    ) async {
      final target = GlobalKey();
      await pumpTaroUiWidget(
        tester,
        TaroCoachmarkLayer(
          targetKey: target,
          coachmark: TaroCoachmark(
            title: 'Your first AI reading today is free',
            body:
                'Start here when a question is on your mind. You get one '
                'free reading every day.',
            dismissLabel: 'Got it',
            onDismiss: () {},
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 600),
                SizedBox(key: target, height: 160, width: 300),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      final screen =
          Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
      final hole = tester.getRect(find.byKey(target));
      expect(
        screen.top <= hole.top && hole.bottom <= screen.bottom,
        isTrue,
        reason: 'target $hole is on screen $screen',
      );
      final bubble = tester.getRect(find.byType(TaroCoachmark));
      expect(bubble.top, greaterThanOrEqualTo(screen.top));
      expect(bubble.bottom, lessThanOrEqualTo(hole.top));
      expect(find.text('Got it'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
