import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/help/controller/crisis_resources_controller.dart';
import 'package:taro/features/help/view/crisis_resources_screen.dart';
import 'package:taro/features/learn/view/learn_top_bar.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro/features/update/view/update_required_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../features/flow_view_support.dart';

/// Android E2E report (docs/qa/ANDROID_E2E_REPORT.md): layout bugs found
/// at 200 % text and in long locales, each pinned by a widget test.

/// The labels in [finder] broken between two non-space characters.
List<String> _midWordBreaks(Finder finder) {
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
          !_breakable(text[i]) &&
          !_breakable(text[i - 1])) {
        broken.add(text);
        break;
      }
      previous = top;
    }
  }
  return broken;
}

/// Whitespace or a zero-width space (an explicit break opportunity).
bool _breakable(String char) => char.trim().isEmpty || char == '\u200B';

/// Whether [finder] sits inside a vertical scroll view (scrolls with the
/// content instead of being pinned over it).
bool _scrolls(Finder finder) => find
    .ancestor(
      of: finder,
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .evaluate()
    .isNotEmpty;

DrawView _view({
  int placed = 3,
  int revealed = 0,
  String spread = 'three_ppf',
}) => DrawView(
  spread: aSpread(spread).build(),
  draw: aDraw(spreadId: spread),
  classic: false,
  placed: placed,
  revealed: revealed,
  reducedMotion: true,
  readingId: const ReadingId('r-1'),
  question: 'What should I focus on this week?',
);

Widget _draw(DrawState state) => DrawLayout(
  state: state,
  onClose: noop,
  onShuffled: noop,
  onPick: noop,
  onDrawForMe: noop,
  onReveal: noop,
  onRevealAll: noop,
  onRetry: noop,
  onFinishLater: noop,
  onOpenOptions: noop,
);

void main() {
  late TaroLocalizations l10n;
  late TaroLocalizations de;

  setUpAll(() async {
    l10n = await enL10n();
    de = await TaroLocalizations.delegate.load(const Locale('de'));
  });

  group('BUG-03: S08 at 200 % text', () {
    testWidgets('picking: the deck fan scrolls after the slots', (
      tester,
    ) async {
      await pumpTaro(
        tester,
        _draw(DrawState.picking(_view(placed: 1))),
        fakes: aiReadyFakes(),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(_scrolls(find.byType(CardFan)), isTrue);
      expect(tester.takeException(), isNull);
    });

    for (final spread in ['three_ppf', 'celtic_cross']) {
      testWidgets('revealing $spread: "Reveal all" scrolls after the content', (
        tester,
      ) async {
        await pumpTaro(
          tester,
          _draw(
            DrawState.revealing(
              _view(
                spread: spread,
                placed: spread == 'celtic_cross' ? 10 : 3,
              ),
            ),
          ),
          fakes: aiReadyFakes(),
          textScale: 2,
        );
        await tester.pumpAndSettle();
        expect(_scrolls(find.text(l10n.drawRevealAll)), isTrue);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at 100 % "Reveal all" stays pinned', (tester) async {
      await pumpTaro(
        tester,
        _draw(DrawState.revealing(_view())),
        fakes: aiReadyFakes(),
      );
      await tester.pumpAndSettle();
      expect(_scrolls(find.text(l10n.drawRevealAll)), isFalse);
    });
  });

  group('BUG-06 / BUG-08: S08 reveal in German', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('"Tap to reveal" stays inside the card at ${scale}x', (
        tester,
      ) async {
        await pumpTaro(
          tester,
          _draw(DrawState.revealing(_view())),
          fakes: aiReadyFakes(),
          locale: const Locale('de'),
          textScale: scale,
        );
        await tester.pumpAndSettle();
        final hint = find.text(de.drawTapToReveal);
        final cards = [
          for (final e in find.byType(TaroCardBack).evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        if (scale > kSpreadReflowTextScale) {
          // The list layout puts it beside the card, clear of every card.
          expect(hint, findsOneWidget);
          final hintRect = tester.getRect(hint);
          expect(cards.any((c) => c.overlaps(hintRect)), isFalse);
        } else if (hint.evaluate().isNotEmpty) {
          // Over the card when it fits at a readable size (V2-12).
          final hintRect = tester.getRect(hint);
          expect(
            cards.any(
              (c) =>
                  c.inflate(0.5).contains(hintRect.topLeft) &&
                  c.inflate(0.5).contains(hintRect.bottomRight),
            ),
            isTrue,
            reason: 'hint $hintRect inside a card',
          );
        }
        expect(_midWordBreaks(hint), isEmpty);
      });
    }

    testWidgets('"Vergangenheit" is never broken mid-word', (tester) async {
      await pumpTaro(
        tester,
        _draw(DrawState.revealing(_view())),
        fakes: aiReadyFakes(),
        locale: const Locale('de'),
        size: const Size(411, 914),
      );
      await tester.pumpAndSettle();
      final past = find.text(de.spread_three_ppf_pos_past_name);
      expect(past, findsWidgets);
      expect(_midWordBreaks(past), isEmpty);
    });
  });

  group('BUG-04: S02 at 200 % text', () {
    testWidgets('"Get started" scrolls after the feature bullets', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        WelcomeLayout(onGetStarted: () {}),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      expect(_scrolls(find.text(l10n.welcomeGetStarted)), isTrue);
      final bullet = tester.getRect(find.text(l10n.welcomeFeatureJournal));
      final button = tester.getRect(find.text(l10n.welcomeGetStarted));
      expect(bullet.bottom, lessThan(button.top));
    });

    testWidgets('at 100 % "Get started" stays pinned', (tester) async {
      await pumpTaroWidget(tester, WelcomeLayout(onGetStarted: () {}));
      await tester.pumpAndSettle();
      expect(_scrolls(find.text(l10n.welcomeGetStarted)), isFalse);
    });
  });

  group('BUG-12: S17/S18 top bar at 200 % text', () {
    testWidgets('the caption fits between Back and the arrows', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        Scaffold(
          appBar: LearnTopBar(
            onBack: () {},
            caption: 'Major Arcana · 18 of 22',
            actions: [
              TaroIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                semanticsLabel: 'Previous',
                onPressed: () {},
              ),
              TaroIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                semanticsLabel: 'Next',
                onPressed: () {},
              ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
        textScale: 2,
      );
      final caption = find.text('Major Arcana · 18 of 22');
      final paragraph = tester.renderObject<RenderParagraph>(caption);
      expect(paragraph.didExceedMaxLines, isFalse);
      // Nothing is cut at the bar's bottom edge.
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(
          paragraph.getMinIntrinsicHeight(paragraph.size.width) - 0.5,
        ),
      );
      final bar = tester.getRect(find.byType(LearnTopBar));
      final text = tester.getRect(caption);
      expect(text.bottom, lessThanOrEqualTo(bar.bottom));
      final next = tester.getRect(find.bySemanticsLabel('Previous'));
      expect(text.right, lessThanOrEqualTo(next.left));
    });
  });

  group('BUG-14: S30 at 200 % text', () {
    testWidgets('"Update" scrolls after the journal panel', (tester) async {
      await pumpTaroWidget(
        tester,
        UpdateRequiredLayout(
          state: const UpdateRequiredState.content(
            platform: AppPlatform.android,
            installedVersion: '1.0.0',
            minVersion: '1.1.0',
          ),
          onOpenStore: () {},
        ),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l10n.updateButton), 200);
      expect(_scrolls(find.text(l10n.updateButton)), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('BUG-17: S27 at 200 % text', () {
    testWidgets('the helpline host is not broken inside a word', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        CrisisResourcesLayout(
          state: CrisisResourcesState.content(
            country: 'US',
            resources: aCrisisDirectory().select(country: 'US'),
            hasLocalLines: true,
            countries: const ['US'],
          ),
          onClose: noop,
          onRetry: noop,
          onChooseCountry: noop1,
          onOpen: (_) {},
        ),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      final host = find.textContaining('findahelpline');
      await tester.scrollUntilVisible(host, 200);
      expect(_midWordBreaks(host), isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
