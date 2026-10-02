import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/reading_mini_spread.dart';
import 'package:taro/routing/screen_builders.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../features/flow_view_support.dart';
import 'a11y_support.dart';

/// Sprint 19.4 (01 §12): S05, S07, S09, S10, S11 and S13 at the platform
/// maximum text sizes (Android 200 %, iOS AX5) lay out without an overflow
/// or a `maxLines` cut anywhere on the page, and the spread's cards reflow
/// into a vertical list above 1.5×.

/// The canvas reading (`docs/design/samples/readings/three_ppf.json`), the
/// longest committed three-card sample.
Reading _sampleReading() {
  final sample =
      jsonDecode(
            File(
              '../../docs/design/samples/readings/three_ppf.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final request = sample['request']! as Map<String, Object?>;
  final response = sample['response']! as Map<String, Object?>;
  return aReading()
      .withId('scale-reading')
      .withDraw(
        Draw(
          spreadId: const SpreadId('three_ppf'),
          spreadVersion: 1,
          drawnAt: DateTime.utc(2026, 9, 27, 18, 41),
          cards: [
            for (final c in request['cards']! as List<Object?>)
              DrawnCard.fromJson(c! as Map<String, Object?>),
          ],
        ),
      )
      .withQuestion(request['question']! as String)
      .withContent(
        ReadingContent.fromWire(response['reading']! as Map<String, Object?>),
      )
      .build();
}

const Map<ScreenId, ScreenArgs> _args = {
  ScreenId.s07: ScreenArgs(query: {'spread': 'three_ppf'}),
  ScreenId.s09: ScreenArgs(path: {'id': 'scale-reading'}),
};

/// The modal screens get their Material from the sheet route.
const Set<ScreenId> _modals = {ScreenId.s10};

const List<ScreenId> _screens = [
  ScreenId.s05,
  ScreenId.s07,
  ScreenId.s09,
  ScreenId.s10,
  ScreenId.s11,
  ScreenId.s13,
];

Future<TaroFakes> _pump(
  WidgetTester tester,
  ScreenId screen,
  double scale,
) async {
  final reading = _sampleReading();
  final fakes = aiReadyFakes()..journal.putReading(reading);
  await pumpRouted(
    tester,
    Builder(
      builder: (context) {
        final built = buildScreen(
          context,
          screen,
          _args[screen] ?? const ScreenArgs(),
        );
        return _modals.contains(screen) ? Scaffold(body: built) : built;
      },
    ),
    fakes: fakes,
    textScale: scale,
  );
  return fakes;
}

void main() {
  for (final scale in kMaxTextScales) {
    final label = '${(scale * 100).round()} %';
    for (final screen in _screens) {
      testWidgets('${screen.wire} at $label text: no overflow, no clipping', (
        tester,
      ) async {
        await _pump(tester, screen, scale);
        // The content state, not a skeleton or an error.
        expect(find.byType(TaroLoadingView), findsNothing);
        expect(find.byType(TaroErrorView), findsNothing);
        await expectNoClippingWhileScrolling(tester, '${screen.wire} $label');
      });
    }

    testWidgets('S13 revealed at $label text: no overflow, no clipping', (
      tester,
    ) async {
      await _pump(tester, ScreenId.s13, scale);
      await tester.tap(find.byType(TaroCardBack));
      await tester.pumpAndSettle();
      expect(find.byType(TaroCardFace), findsOneWidget);
      await expectNoClippingWhileScrolling(tester, 'S13 drawn $label');
    });

    testWidgets('S09 at $label text: the spread reflows to a vertical list', (
      tester,
    ) async {
      await _pump(tester, ScreenId.s09, scale);
      final faces = find.descendant(
        of: find.byType(ReadingMiniSpread),
        matching: find.byType(TaroCardFace),
      );
      expect(faces, findsNWidgets(3));
      final rects = [
        for (var i = 0; i < 3; i++) tester.getRect(faces.at(i)),
      ];
      for (var i = 1; i < rects.length; i++) {
        // One card per row, in slot order, all at the same start edge.
        expect(rects[i].top, greaterThanOrEqualTo(rects[i - 1].bottom));
        expect(rects[i].left, moreOrLessEquals(rects[0].left));
      }
    });
  }

  testWidgets('S09 at 150 % text keeps the spread layout (no reflow)', (
    tester,
  ) async {
    await _pump(tester, ScreenId.s09, 1.5);
    final faces = find.descendant(
      of: find.byType(ReadingMiniSpread),
      matching: find.byType(TaroCardFace),
    );
    final first = tester.getRect(faces.at(0));
    final second = tester.getRect(faces.at(1));
    // Side by side: the three-card spread is one row.
    expect(second.top, lessThan(first.bottom));
    expectNoClipping('S09 150 %');
  });
}
