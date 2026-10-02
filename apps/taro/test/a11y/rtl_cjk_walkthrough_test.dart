import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:taro/common/reading_mini_spread.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/screen_builders.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../features/flow_view_support.dart';
import 'a11y_support.dart';

/// Sprint 19.4 (01 §13): the Arabic walkthrough (mirroring, numerals,
/// bundled card names, the spread's x-mirroring with the card art never
/// mirrored) and a Japanese reading without clipping, on the real screens
/// with the bundled `ar` / `ja` deck text.

const List<(String, String, bool)> _cards = [
  ('past', 'cups_03', false),
  ('present', 'major_17', true),
  ('future', 'pentacles_08', false),
];

Draw _draw() => Draw(
  spreadId: const SpreadId('three_ppf'),
  spreadVersion: 1,
  drawnAt: DateTime.utc(2026, 9, 27, 18, 41),
  cards: [
    for (final (position, card, reversed) in _cards)
      DrawnCard(
        positionId: PositionId(position),
        cardId: CardId(card),
        reversed: reversed,
      ),
  ],
);

/// A reading written in [locale] from the bundled card text (the meanings
/// stand in for the AI text: real script, real length).
Reading _reading(String locale, Map<(CardId, String), CardText> texts) {
  CardText text(String id) => texts[(CardId(id), locale)]!;
  return aReading()
      .withId('walk-reading')
      .withLocale(locale)
      .withDraw(_draw())
      .withQuestion(text('major_17').reflectionQuestions.first)
      .withContent(
        ReadingContent.fromWire({
          'title': text('major_17').name,
          'overview': text('major_17').meaningUpright,
          'cards': [
            for (final (position, card, reversed) in _cards)
              {
                'positionId': position,
                'cardId': card,
                'reversed': reversed,
                'interpretation': reversed
                    ? text(card).meaningReversed
                    : text(card).meaningUpright,
              },
          ],
          'synthesis': text('cups_03').meaningUpright,
          'reflectionPrompts': text('pentacles_08').reflectionQuestions,
        }),
      )
      .build();
}

Future<TaroFakes> _pump(
  WidgetTester tester,
  ScreenId screen,
  String locale, {
  double textScale = 1,
  ScreenArgs args = const ScreenArgs(),
}) async {
  final texts = await bundledCardTexts(tester, locale, [
    for (final (_, card, _) in _cards) CardId(card),
  ]);
  final fakes = aiReadyFakes();
  fakes.content.texts.addAll(texts);
  fakes.journal.putReading(_reading(locale, texts));
  await pumpRouted(
    tester,
    Builder(builder: (context) => buildScreen(context, screen, args)),
    fakes: fakes,
    locale: Locale(locale),
    textScale: textScale,
  );
  return fakes;
}

const ScreenArgs _s09 = ScreenArgs(path: {'id': 'walk-reading'});

/// The centre x of the mini-spread face whose label names [position].
double _faceX(WidgetTester tester, String position) {
  final face = find.descendant(
    of: find.byType(ReadingMiniSpread),
    matching: find.byWidgetPredicate(
      (w) => w is TaroCardFace && w.semanticsLabel.contains(position),
    ),
  );
  return tester.getCenter(face).dx;
}

/// No card art is mirrored: no ancestor transform flips x, and no image
/// follows the text direction.
void _expectArtNeverMirrored(WidgetTester tester) {
  final faces = find.byType(TaroCardFace);
  expect(faces, findsWidgets);
  for (final element in faces.evaluate()) {
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Transform) {
        expect(widget.transform.entry(0, 0), greaterThanOrEqualTo(0));
      }
      return true;
    });
  }
  for (final image in tester.widgetList<Image>(
    find.descendant(of: faces, matching: find.byType(Image)),
  )) {
    expect(image.matchTextDirection, isFalse);
  }
}

void main() {
  group('Arabic walkthrough', () {
    testWidgets('S05: right-to-left, the date in intl ar numerals', (
      tester,
    ) async {
      final fakes = await _pump(tester, ScreenId.s05, 'ar');
      expect(
        Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl,
      );
      final today = fakes.clock.now();
      expect(
        find.text(DateFormat.MMMMEEEEd('ar').format(today)),
        findsOneWidget,
      );
      expectNoClipping('S05 ar');
    });

    testWidgets('S09: Arabic card names, the spread mirrored, the art not', (
      tester,
    ) async {
      await _pump(tester, ScreenId.s09, 'ar', args: _s09);
      final l10n = await TaroLocalizations.delegate.load(const Locale('ar'));
      final texts = await bundledCardTexts(tester, 'ar', [
        const CardId('major_17'),
      ]);
      final star = texts[(const CardId('major_17'), 'ar')]!.name;
      expect(
        tester
            .widgetList<TaroCardFace>(find.byType(TaroCardFace))
            .any((f) => f.semanticsLabel.contains(star)),
        isTrue,
      );
      // The app bar's leading "Done" sits on the right (start) in RTL.
      final back = tester.getCenter(
        find.bySemanticsLabel(l10n.readingDone).first,
      );
      expect(back.dx, greaterThan(tester.view.physicalSize.width / 2));
      // `past` sits on the right in RTL (x → 1 - x).
      expect(
        _faceX(tester, l10n.spread_three_ppf_pos_past_name),
        greaterThan(_faceX(tester, l10n.spread_three_ppf_pos_future_name)),
      );
      _expectArtNeverMirrored(tester);
      await expectNoClippingWhileScrolling(tester, 'S09 ar');
    });

    testWidgets('control: in English `past` sits on the left', (
      tester,
    ) async {
      await _pump(tester, ScreenId.s09, 'en', args: _s09);
      final l10n = await TaroLocalizations.delegate.load(const Locale('en'));
      expect(
        _faceX(tester, l10n.spread_three_ppf_pos_past_name),
        lessThan(_faceX(tester, l10n.spread_three_ppf_pos_future_name)),
      );
    });

    testWidgets('S13: the Arabic card name after the reveal', (tester) async {
      await _pump(tester, ScreenId.s13, 'ar');
      await tester.tap(find.byType(TaroCardBack));
      await tester.pumpAndSettle();
      _expectArtNeverMirrored(tester);
      await expectNoClippingWhileScrolling(tester, 'S13 ar');
    });

    testWidgets('S07: right-to-left question flow without clipping', (
      tester,
    ) async {
      await _pump(
        tester,
        ScreenId.s07,
        'ar',
        args: const ScreenArgs(query: {'spread': 'three_ppf'}),
      );
      expect(
        Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.rtl,
      );
      await expectNoClippingWhileScrolling(tester, 'S07 ar');
    });
  });

  group('Japanese reading', () {
    for (final scale in [1.0, kAndroidMaxTextScale]) {
      testWidgets('S09 at ${(scale * 100).round()} %: no clipping', (
        tester,
      ) async {
        await _pump(tester, ScreenId.s09, 'ja', args: _s09, textScale: scale);
        final texts = await bundledCardTexts(tester, 'ja', [
          const CardId('major_17'),
        ]);
        final star = texts[(const CardId('major_17'), 'ja')]!;
        // The bundled Japanese overview is on the page in full.
        await revealFound(tester, find.text(star.meaningUpright));
        expect(find.text(star.meaningUpright), findsOneWidget);
        await expectNoClippingWhileScrolling(tester, 'S09 ja $scale');
      });
    }
  });
}
