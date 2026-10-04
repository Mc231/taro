import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/golden/golden_sizes.dart';
import '../../../helpers/pump_taro_ui_widget.dart';
import '../../../helpers/spread_samples.dart';

/// QA round 2: position labels and the reveal hint stay readable on the
/// real spread layouts in long locales and on tablets (V2-01, V2-11,
/// V2-12).

/// Celtic Cross position names per locale (the app ARBs, in draw order).
const Map<String, List<String>> _celtic = {
  'en': [
    'Present', 'Challenge', 'Foundation', 'Recent Past', 'Potential', //
    'Near Future', 'Self', 'Environment', 'Hopes and Fears', 'Outcome',
  ],
  'de': [
    'Gegenwart', 'Herausforderung', 'Grundlage', 'Jüngste Vergangenheit', //
    'Potenzial', 'Nahe Zukunft', 'Selbst', 'Umfeld',
    'Hoffnungen und Ängste', 'Ergebnis',
  ],
  'uk': [
    'Теперішнє', 'Виклик', 'Основа', 'Недавнє минуле', 'Потенціал', //
    'Найближче майбутнє', 'Я', 'Оточення', 'Надії та страхи', 'Результат',
  ],
  'ja': [
    '現在', '課題', '基盤', '最近の過去', '可能性', //
    '近い未来', '自分自身', '環境', '希望と不安', '結果',
  ],
  'ar': [
    'الحاضر', 'التحدي', 'الأساس', 'الماضي القريب', 'الإمكانات', //
    'المستقبل القريب', 'الذات', 'المحيط', 'الآمال والمخاوف', 'النتيجة',
  ],
};

/// Past · Present · Future per locale.
const Map<String, List<String>> _ppf = {
  'en': ['Past', 'Present', 'Future'],
  'de': ['Vergangenheit', 'Gegenwart', 'Zukunft'],
  'uk': ['Минуле', 'Теперішнє', 'Майбутнє'],
  'ja': ['過去', '現在', '未来'],
  'ar': ['الماضي', 'الحاضر', 'المستقبل'],
};

/// "Tap to reveal" per locale (the app ARBs).
const Map<String, String> _hint = {
  'en': 'Tap to reveal',
  'de': 'Zum Aufdecken tippen',
  'uk': 'Торкніться',
  'ja': 'タップ',
  'ar': 'النقر للكشف',
};

/// Every paragraph drawn inside the canvas.
Iterable<RenderParagraph> _paragraphs(WidgetTester tester) =>
    tester.renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(SpreadCanvas),
        matching: find.byType(RichText),
      ),
    );

/// The drawn font size of [p] (its style scaled by its text scaler).
double _drawnSize(RenderParagraph p) {
  final size = p.text.style?.fontSize ?? 14;
  return p.textScaler.scale(size);
}

double _minReadable(WidgetTester tester) => tester
    .element(find.byType(SpreadCanvas))
    .tokens
    .typography
    .caption
    .fontSize!;

Rect _rectOf(RenderParagraph p) =>
    MatrixUtils.transformRect(p.getTransformTo(null), Offset.zero & p.size);

Widget _cross(List<String> names, {double? width}) => SingleChildScrollView(
  child: Center(
    child: SizedBox(
      width: width,
      child: SpreadCanvas(
        slots: [
          for (var i = 0; i < 10; i++)
            SpreadCanvasSlot(
              layout: SpreadSamples.celticCross[i],
              label: names[i],
              number: i + 1,
              card: i < 7 ? const TaroCardBack() : null,
            ),
        ],
      ),
    ),
  ),
);

void main() {
  group('V2-01: Celtic Cross labels on the real layout', () {
    final sizes = {
      'phone320': (const Size(320, 640), null),
      'phoneSmall': (kPhoneSmall, null),
      // The tablet column is capped at layout.maxContentWidth.
      'tablet': (kTabletIpad13, 600.0),
    };
    for (final MapEntry(key: locale, value: names) in _celtic.entries) {
      for (final MapEntry(key: label, value: (size, width)) in sizes.entries) {
        testWidgets('$locale $label: every label readable, none overlap', (
          tester,
        ) async {
          await pumpTaroUiWidget(
            tester,
            _cross(names, width: width),
            locale: Locale(locale),
            size: size,
          );
          final min = _minReadable(tester);
          final paragraphs = _paragraphs(tester).toList();
          for (final p in paragraphs) {
            expect(
              _drawnSize(p),
              greaterThanOrEqualTo(min - 0.01),
              reason: '"${p.text.toPlainText()}" is drawn too small',
            );
          }
          // Every position is named on screen, the crossing card too.
          for (final name in names) {
            expect(
              find.descendant(
                of: find.byType(SpreadCanvas),
                matching: find.textContaining(name),
              ),
              findsWidgets,
              reason: name,
            );
          }
          final rects = [for (final p in paragraphs) _rectOf(p).deflate(0.5)];
          for (var i = 0; i < rects.length; i++) {
            for (var j = i + 1; j < rects.length; j++) {
              expect(
                rects[i].overlaps(rects[j]),
                isFalse,
                reason:
                    '"${paragraphs[i].text.toPlainText()}" overlaps '
                    '"${paragraphs[j].text.toPlainText()}"',
              );
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('V2-11: neighbouring labels keep a visible gap', () {
    for (final MapEntry(key: locale, value: names) in _ppf.entries) {
      testWidgets(locale, (tester) async {
        await pumpTaroUiWidget(
          tester,
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: SpreadCanvas(
              cardSize: TaroCardSize.md,
              slots: [
                for (var i = 0; i < 3; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.threePpf[i],
                    label: names[i],
                    number: i + 1,
                    card: const TaroCardBack(),
                  ),
              ],
            ),
          ),
          locale: Locale(locale),
          // A small phone at the largest scale before the list reflow.
          size: const Size(360, 780),
          textScale: 1.45,
        );
        final gap = tester.element(find.byType(SpreadCanvas)).tokens.space.s3;
        // Under the cards and in a legend alike, text side by side keeps
        // a visible gap.
        final paragraphs = _paragraphs(tester).toList();
        final rects = [for (final p in paragraphs) _rectOf(p)];
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            final (a, b) = (rects[i], rects[j]);
            if (a.bottom <= b.top || b.bottom <= a.top) continue;
            final apart = a.left < b.left ? b.left - a.right : a.left - b.right;
            expect(
              apart,
              greaterThanOrEqualTo(gap - 0.01),
              reason:
                  '"${paragraphs[i].text.toPlainText()}" and '
                  '"${paragraphs[j].text.toPlainText()}"',
            );
          }
        }
      });
    }
  });

  group('V2-12: the reveal hint keeps a readable size', () {
    for (final MapEntry(key: locale, value: hint) in _hint.entries) {
      testWidgets('$locale three cards: shown inside the card', (
        tester,
      ) async {
        await pumpTaroUiWidget(
          tester,
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: SpreadCanvas(
              cardSize: TaroCardSize.md,
              slots: [
                for (var i = 0; i < 3; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.threePpf[i],
                    label: _ppf[locale]![i],
                    number: i + 1,
                    card: TaroCardBack(picked: i == 0),
                    hint: i == 0 ? hint : null,
                  ),
              ],
            ),
          ),
          locale: Locale(locale),
          size: const Size(411, 914),
        );
        final text = find.text(hint);
        expect(text, findsOneWidget);
        final p = tester.renderObject<RenderParagraph>(text);
        expect(_drawnSize(p), greaterThanOrEqualTo(_minReadable(tester)));
        final card = tester.getRect(find.byType(TaroCardBack).first);
        expect(
          card.inflate(0.5).contains(tester.getRect(text).topLeft),
          isTrue,
        );
        expect(
          card.inflate(0.5).contains(tester.getRect(text).bottomRight),
          isTrue,
        );
      });

      testWidgets('$locale Celtic Cross: readable or left out', (tester) async {
        await pumpTaroUiWidget(
          tester,
          SingleChildScrollView(
            child: SpreadCanvas(
              slots: [
                for (var i = 0; i < 10; i++)
                  SpreadCanvasSlot(
                    layout: SpreadSamples.celticCross[i],
                    label: _celtic[locale]![i],
                    number: i + 1,
                    card: TaroCardBack(picked: i == 0),
                    hint: i == 0 ? hint : null,
                  ),
              ],
            ),
          ),
          locale: Locale(locale),
        );
        final text = find.text(hint);
        if (text.evaluate().isNotEmpty) {
          final p = tester.renderObject<RenderParagraph>(text);
          expect(_drawnSize(p), greaterThanOrEqualTo(_minReadable(tester)));
        }
      });
    }

    testWidgets('a hint that cannot fit at a readable size is left out', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const SpreadCanvas(
          cardSize: TaroCardSize.thumb,
          slots: [
            SpreadCanvasSlot(
              layout: SpreadSlotLayout(x: 0.5, y: 0.5),
              label: 'Card',
              number: 1,
              card: TaroCardBack(),
              hint: 'Unbreakablehintword',
            ),
          ],
        ),
      );
      expect(find.text('Unbreakablehintword'), findsNothing);
    });
  });
}
