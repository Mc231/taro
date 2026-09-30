import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/view/reading_result_screen.dart';
import 'package:taro/features/reading/view/report_reading_sheet.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

ReadingResultView _view(Reading reading) => ReadingResultView(
  reading: reading,
  cardTexts: {for (final c in reading.cards) c.cardId: aCardText(c.cardId)},
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    ReadingResultState state,
  ) async {
    final calls = <String>[];
    await pumpTaroWidget(
      tester,
      ReadingResultLayout(
        state: state,
        onDone: () => calls.add('done'),
        onOpenDisclaimer: () => calls.add('disclaimer'),
        onRate: (rating, reason) => calls.add('rate:${rating.name}:$reason'),
        onToggleFavourite: () => calls.add('favourite'),
        onReport: () => calls.add('report'),
        onWriteAbout: () => calls.add('write'),
        onShare: (_, {required includeQuestion}) =>
            calls.add('share:$includeQuestion'),
      ),
    );
    await tester.pumpAndSettle();
    // Every S09 state carries the disclaimer (05 §3); never a banner.
    await revealFound(tester, find.byType(DisclaimerFooter));
    expect(find.byType(DisclaimerFooter), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
    return calls;
  }

  testWidgets('loadingFromStorage: skeleton + disclaimer', (tester) async {
    await pumpLayout(tester, const ReadingResultState.loadingFromStorage());
    expect(find.byType(ReadingTextView), findsOneWidget);
  });

  testWidgets('content: AI label, title, positions, synthesis, actions', (
    tester,
  ) async {
    final reading = aReading().withQuestion('What now?').build();
    final calls = await pumpLayout(
      tester,
      ReadingResultState.content(_view(reading)),
    );
    await revealFound(tester, find.text(l10n.aiLabel));
    expect(find.text(l10n.aiLabel), findsOneWidget);
    expect(find.text(reading.content!.title), findsOneWidget);
    expect(find.text(l10n.readingQuestionQuoted('What now?')), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.commonFavourite));
    await tester.tap(find.byTooltip(l10n.reportReadingTitle));
    await tapFound(tester, find.text(l10n.readingFullDisclaimer));
    await tapFound(tester, find.bySemanticsLabel(l10n.readingRateUp));
    await tapFound(tester, find.widgetWithText(TaroButton, l10n.readingDone));
    expect(calls, [
      'favourite',
      'report',
      'disclaimer',
      'rate:up:null',
      'done',
    ]);
  });

  testWidgets('content: reflection prompts offer "Write about this"', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      ReadingResultState.content(_view(aReading().build())),
    );
    await tapFound(tester, find.text(l10n.readingWriteAboutThis));
    expect(calls, ['write']);
  });

  testWidgets('ratingGiven (down): reason chips and thanks', (tester) async {
    final reading = aReading().withRating(Rating.down).build();
    final calls = await pumpLayout(
      tester,
      ReadingResultState.ratingGiven(_view(reading)),
    );
    await tapFound(tester, find.text(l10n.readingReasonTone));
    expect(find.text(l10n.readingRatingThanks), findsOneWidget);
    expect(calls, ['rate:down:RatingReason.tone']);
  });

  testWidgets('reported: "Reported", no report action', (tester) async {
    await pumpLayout(
      tester,
      ReadingResultState.content(_view(aReading().reported().build())),
    );
    expect(find.byTooltip(l10n.reportReadingTitle), findsNothing);
    await revealFound(tester, find.text(l10n.readingReported));
  });

  testWidgets('sharing: the share action is busy', (tester) async {
    await pumpLayout(
      tester,
      ReadingResultState.sharing(_view(aReading().build())),
    );
    final share = tester.widget<TaroIconButton>(
      find.byWidgetPredicate(
        (w) => w is TaroIconButton && w.semanticsLabel == l10n.commonShare,
      ),
    );
    expect(share.onPressed, isNull);
  });

  testWidgets('share sheet: the question is opt-in', (tester) async {
    final calls = await pumpLayout(
      tester,
      ReadingResultState.content(
        _view(aReading().withQuestion('Q?').build()),
      ),
    );
    await tester.tap(find.byTooltip(l10n.commonShare));
    await tester.pumpAndSettle();
    expect(find.text(l10n.shareIncludeQuestion), findsOneWidget);
    await tapFound(tester, find.text(l10n.shareIncludeQuestion));
    await tapFound(tester, find.widgetWithText(TaroButton, l10n.commonShare));
    expect(calls, ['share:true']);
  });

  testWidgets('notFound: empty view + disclaimer', (tester) async {
    final calls = await pumpLayout(
      tester,
      const ReadingResultState.notFound(),
    );
    expect(find.text(l10n.readingNotFound), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonBackToToday));
    expect(calls, ['done']);
  });

  testWidgets('failed: error view + disclaimer', (tester) async {
    await pumpLayout(
      tester,
      const ReadingResultState.failed(Failure.storage()),
    );
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
  });

  test('fromRoute parses the id and origin', () {
    final screen = ReadingResultScreen.fromRoute(
      const {'id': 'r-9'},
      const {'origin': 'journal'},
    );
    expect(screen.args.id, const ReadingId('r-9'));
    expect(screen.args.origin, ReadingViewOrigin.journal);
    expect(
      ReadingResultScreen.fromRoute(const {}, const {}).args.origin,
      ReadingViewOrigin.fresh,
    );
  });

  group('screen', () {
    Future<TaroFakes> open(WidgetTester tester, Reading reading) async {
      final fakes = aiReadyFakes();
      fakes.journal.putReading(reading);
      await pumpFlow(
        tester,
        path: RoutePaths.readingPattern,
        location: RoutePaths.reading(reading.id.value),
        builder: (state) => ReadingResultScreen.fromRoute(
          state.pathParameters,
          state.uri.queryParameters,
        ),
        fakes: fakes,
      );
      return fakes;
    }

    testWidgets('rate, favourite, share, write about, report, done', (
      tester,
    ) async {
      final reading = aReading().withId('r-1').withQuestion('Q?').build();
      final fakes = await open(tester, reading);
      await tapFound(tester, find.bySemanticsLabel(l10n.readingRateDown));
      await tapFound(tester, find.text(l10n.readingReasonMismatch));
      expect(
        fakes.journal.readings[reading.id]!.ratingReason,
        RatingReason.mismatch,
      );
      await tester.tap(find.byTooltip(l10n.commonFavourite));
      await tester.pumpAndSettle();
      expect(fakes.journal.readings[reading.id]!.favourite, isTrue);
      await tester.tap(find.byTooltip(l10n.commonShare));
      await tester.pumpAndSettle();
      await tapFound(
        tester,
        find.widgetWithText(TaroButton, l10n.commonShare),
      );
      expect(eventsOf<ReadingSharedEvent>(fakes), hasLength(1));
      await tester.tap(find.byTooltip(l10n.reportReadingTitle));
      await tester.pumpAndSettle();
      expect(find.byType(ReportReadingSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(ReportReadingSheet))).pop();
      await tester.pumpAndSettle();
      await tapFound(tester, find.text(l10n.readingWriteAboutThis));
      expectRoute(RoutePaths.journalEntry('r-1'));
    });

    testWidgets('Done goes Home; the disclaimer link opens S29', (
      tester,
    ) async {
      await open(tester, aReading().withId('r-2').build());
      await tapFound(tester, find.text(l10n.readingFullDisclaimer));
      expectRoute(RoutePaths.legal('disclaimer'));
    });

    testWidgets('Done goes Home', (tester) async {
      await open(tester, aReading().withId('r-3').build());
      await tapFound(
        tester,
        find.widgetWithText(TaroButton, l10n.readingDone),
      );
      expectRoute(RoutePaths.home);
    });
  });
}
