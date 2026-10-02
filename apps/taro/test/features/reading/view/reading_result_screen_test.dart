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

  var faces = 0;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    ReadingResultState state, {
    bool reveal = false,
  }) async {
    final calls = <String>[];
    await pumpTaroWidget(
      tester,
      ReadingResultLayout(
        state: state,
        reveal: reveal,
        onDone: () => calls.add('done'),
        onOpenDisclaimer: () => calls.add('disclaimer'),
        onRate: (rating, reason) => calls.add('rate:${rating.name}:$reason'),
        onToggleFavourite: () => calls.add('favourite'),
        onReport: () => calls.add('report'),
        onAddNote: () => calls.add('note'),
        onWriteAbout: (prompt) => calls.add('write'),
        onShare: (_, {required includeQuestion}) =>
            calls.add('share:$includeQuestion'),
      ),
    );
    await tester.pumpAndSettle();
    faces = find.byType(TaroCardFace).evaluate().length;
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

  testWidgets('content: header, AI label, title, positions, synthesis, '
      'actions', (tester) async {
    final reading = aReading().withQuestion('What now?').build();
    final calls = await pumpLayout(
      tester,
      ReadingResultState.content(_view(reading)),
      reveal: true,
    );
    await revealFound(tester, find.text(l10n.aiLabel));
    expect(find.text(l10n.aiLabel), findsOneWidget);
    expect(faces, reading.cards.length);
    expect(find.text(reading.content!.title), findsOneWidget);
    expect(find.text(l10n.readingQuestionQuoted('What now?')), findsOneWidget);
    await tester.tap(find.text(l10n.commonAddNote));
    await tester.tap(find.byTooltip(l10n.readingDone));
    await tapFound(tester, find.text(l10n.readingFullDisclaimer));
    await tapFound(tester, find.byTooltip(l10n.commonFavourite));
    await tapFound(tester, find.bySemanticsLabel(l10n.readingRateUp));
    expect(find.text(l10n.readingRatingThanks), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.commonMore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reportReadingTitle));
    await tester.pumpAndSettle();
    expect(calls, [
      'note',
      'done',
      'disclaimer',
      'favourite',
      'rate:up:null',
      'report',
    ]);
  });

  testWidgets('content: a position section collapses and expands', (
    tester,
  ) async {
    final reading = aReading().build();
    await pumpLayout(tester, ReadingResultState.content(_view(reading)));
    final card = reading.cards.first;
    final body = reading.content!.textFor(card.positionId)!;
    final heading = find.textContaining(' · ').first;
    await revealFound(tester, find.text(body));
    await revealFound(tester, heading);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(find.text(body), findsNothing);
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

  testWidgets('reported: More shows "Reported", disabled', (tester) async {
    final calls = await pumpLayout(
      tester,
      ReadingResultState.content(_view(aReading().reported().build())),
    );
    await tester.tap(find.byTooltip(l10n.commonMore));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reportReadingTitle), findsNothing);
    await tester.tap(find.text(l10n.readingReported));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  testWidgets('a reading that cannot be reported has no More menu', (
    tester,
  ) async {
    final reading = aReading().build();
    await pumpLayout(
      tester,
      ReadingResultState.content(
        _view(reading.copyWith(status: const ReadingStatus.pending())),
      ),
    );
    expect(find.byTooltip(l10n.commonMore), findsNothing);
  });

  testWidgets('text scale 2.0: no overflow, cards reflow', (tester) async {
    await pumpTaroWidget(
      tester,
      ReadingResultLayout(
        state: ReadingResultState.content(_view(aReading().build())),
        onDone: noop,
        onOpenDisclaimer: noop,
        onRate: (_, _) {},
        onToggleFavourite: noop,
        onReport: noop,
        onAddNote: noop,
        onWriteAbout: noop1,
        onShare: (_, {required includeQuestion}) {},
      ),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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

    testWidgets('rate, favourite, share, write about, report, note', (
      tester,
    ) async {
      final reading = aReading().withId('r-1').withQuestion('Q?').build();
      final fakes = await open(tester, reading);
      expect(find.byType(BannerSlot), findsNothing);
      await tapFound(tester, find.bySemanticsLabel(l10n.readingRateDown));
      await tapFound(tester, find.text(l10n.readingReasonMismatch));
      expect(
        fakes.journal.readings[reading.id]!.ratingReason,
        RatingReason.mismatch,
      );
      await tapFound(tester, find.byTooltip(l10n.commonFavourite));
      expect(fakes.journal.readings[reading.id]!.favourite, isTrue);
      await tapFound(tester, find.byTooltip(l10n.commonShare));
      await tapFound(
        tester,
        find.widgetWithText(TaroButton, l10n.commonShare),
      );
      expect(eventsOf<ReadingSharedEvent>(fakes), hasLength(1));
      await tester.tap(find.byTooltip(l10n.commonMore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportReadingTitle));
      await tester.pumpAndSettle();
      expect(find.byType(ReportReadingSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(ReportReadingSheet))).pop();
      await tester.pumpAndSettle();
      await tapFound(tester, find.text(l10n.readingWriteAboutThis));
      // The prompt rides along to pre-fill the S15 note.
      expect(find.textContaining('route:/journal/r-1?prompt='), findsOne);
    });

    testWidgets('the 3rd thumbs-up asks the review prompter (01 §6.1)', (
      tester,
    ) async {
      final reading = aReading().withId('r-4').build();
      final fakes = await open(tester, reading);
      await tapFound(tester, find.bySemanticsLabel(l10n.readingRateUp));
      expect(fakes.review.triggers, [ReviewTrigger.positiveRating]);
    });

    testWidgets('Add note opens the note editor', (tester) async {
      await open(tester, aReading().withId('r-5').build());
      await tester.tap(find.text(l10n.commonAddNote));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.journalEntry('r-5'));
    });

    testWidgets('the disclaimer link opens S29', (tester) async {
      await open(tester, aReading().withId('r-2').build());
      await tapFound(tester, find.text(l10n.readingFullDisclaimer));
      expectRoute(RoutePaths.legal('disclaimer'));
    });

    testWidgets('Done goes Home', (tester) async {
      await open(tester, aReading().withId('r-3').build());
      await tester.tap(find.byTooltip(l10n.readingDone));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });
  });
}
