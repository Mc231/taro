import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro_core/taro_core.dart';

import '../data/content/disk_asset_bundle.dart';

/// Android's largest font scale (200 %, 01 §12).
const double kAndroidMaxTextScale = 2;

/// iOS AX5 (Accessibility Extra Extra Extra Large): body 53 pt over the
/// default 17 pt, the largest Dynamic Type size (01 §12).
const double kIosAx5TextScale = 53 / 17;

/// The platform maxima Sprint 19.4 checks every key screen at.
const List<double> kMaxTextScales = [kAndroidMaxTextScale, kIosAx5TextScale];

/// Expects that nothing in the current frame overflowed (a `FlutterError`)
/// and that no paragraph was cut by `maxLines` (ellipsis or clip).
void expectNoClipping(String reason) {
  expect(
    TestWidgetsFlutterBinding.instance.takeException(),
    isNull,
    reason: reason,
  );
  final binding = TestWidgetsFlutterBinding.instance;
  final clipped = <String>[];
  void visit(RenderObject node) {
    if (node is RenderParagraph && node.didExceedMaxLines) {
      clipped.add(node.text.toPlainText());
    }
    node.visitChildren(visit);
  }

  binding.renderViews.forEach(visit);
  expect(clipped, isEmpty, reason: '$reason: clipped text');
}

/// Scrolls every vertical page scrollable from its top to its end a
/// viewport at a time, checking [expectNoClipping] at each stop, so lazily
/// built rows are laid out too.
Future<void> expectNoClippingWhileScrolling(
  WidgetTester tester,
  String reason,
) async {
  expectNoClipping(reason);
  final scrollables = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  for (var i = 0; i < scrollables.evaluate().length; i++) {
    final state = tester.state<ScrollableState>(scrollables.at(i));
    final position = state.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      continue;
    }
    position.jumpTo(0);
    await tester.pump();
    while (position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        (position.pixels + position.viewportDimension * 0.8).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      await tester.pump();
      expectNoClipping('$reason at ${position.pixels.round()}');
    }
    position.jumpTo(0);
    await tester.pump();
  }
}

/// The bundled card text of [ids] in [locale] (`assets/deck/<locale>.json`),
/// keyed for `FakeContentRepository.texts`.
Future<Map<(CardId, String), CardText>> bundledCardTexts(
  WidgetTester tester,
  String locale,
  Iterable<CardId> ids,
) async {
  final content = AssetContentRepository.fromBundle(
    DiskAssetBundle(),
    runner: inlineRunner,
  );
  final texts = <(CardId, String), CardText>{};
  for (final id in ids) {
    final text = await tester.runAsync(() => content.cardText(id, locale));
    texts[(id, locale)] = text!.valueOrNull!;
  }
  return texts;
}

/// The settle time of every ticker after a trigger: pumps 10 ms frames
/// until no frame is scheduled (at most 5 s) and returns the elapsed time.
Future<Duration> settleTime(WidgetTester tester) async {
  const step = Duration(milliseconds: 10);
  var elapsed = Duration.zero;
  await tester.pump();
  while (tester.binding.hasScheduledFrame &&
      elapsed < const Duration(seconds: 5)) {
    await tester.pump(step);
    elapsed += step;
  }
  return elapsed;
}

/// The longest reduced-motion ritual (01 §12, §14.4): a 200 ms cross-fade,
/// plus one 10 ms frame of [settleTime] granularity.
const Duration kReducedRitualBudget = Duration(milliseconds: 210);
