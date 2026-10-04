import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/features/journal/view/journal_entry_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

final Reading _complete = aReading().withId('r-complete').build();
final Reading _pending = aReading().withId('r-pending').pending().build();
final Reading _failed = aReading()
    .withId('r-failed')
    .failed(const Failure.network(), refunded: true)
    .build();
final Reading _classic = aReading()
    .withId('r-classic')
    .classic()
    .withQuestion(null)
    .build();
final DailyCard _daily = aDailyCard()
    .on('2026-09-25')
    .withCard('major_17')
    .reversed()
    .build();

JournalEntryView _view(
  JournalItem item, {
  String note = 'note text',
  NoteStatus status = NoteStatus.saved,
}) => JournalEntryView(item: item, note: note, noteStatus: status);

CardText _text(String id, String name) => CardText(
  cardId: CardId(id),
  locale: 'en',
  name: name,
  keywordsUpright: const ['hope'],
  keywordsReversed: const ['doubt'],
  shortUpright: 'Hope returns.',
  shortReversed: 'Hope feels far.',
  meaningUpright: 'Upright meaning.',
  meaningReversed: 'Reversed meaning.',
  aspects: const CardAspects(
    relationshipsUpright: 'r',
    relationshipsReversed: 'r',
    workUpright: 'w',
    workReversed: 'w',
    growthUpright: 'g',
    growthReversed: 'g',
  ),
  reflectionQuestions: const ['What gives you hope?', 'b', 'c'],
  sourceHash: 'h',
  reviewStatus: ReviewStatus.reviewed,
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await enL10n();
  });

  group('S15 layout', () {
    late List<String> calls;

    setUp(() => calls = []);

    Future<void> pump(
      WidgetTester tester,
      JournalEntryState state, {
      Map<CardId, CardText> texts = const {},
      double textScale = 1,
    }) => pumpTaroWidget(
      tester,
      JournalEntryLayout(
        state: state,
        cardTexts: texts,
        onNoteChanged: (text) => calls.add('note:$text'),
        onNoteDone: () => calls.add('done'),
        onToggleFavourite: () => calls.add('favourite'),
        onShare: (include) => calls.add('share:$include'),
        onReport: (id) => calls.add('report:${id.value}'),
        onDelete: () => calls.add('delete'),
        onUndo: () => calls.add('undo'),
        onFinish: (id) => calls.add('finish:${id.value}'),
        onFullReading: (r) => calls.add('full:${r.id.value}'),
        onOpenDisclaimer: () => calls.add('disclaimer'),
        onBack: () => calls.add('back'),
        onRetry: () => calls.add('retry'),
      ),
      textScale: textScale,
    );

    testWidgets('loading, deleted, notFound, storageError + disclaimer', (
      tester,
    ) async {
      await pump(tester, const JournalEntryState.loading());
      expect(find.byType(DisclaimerFooter), findsOneWidget);
      await pump(
        tester,
        JournalEntryState.deleted(undoUntil: DateTime.utc(2026)),
      );
      expect(find.byType(DisclaimerFooter), findsOneWidget);
      await tapText(tester, l10n.commonUndo);
      await tapText(tester, l10n.commonBack);
      await pump(tester, const JournalEntryState.notFound());
      expect(find.text(l10n.readingNotFound), findsOneWidget);
      await tester.tap(find.widgetWithText(TaroButton, l10n.commonBack));
      await pump(tester, const JournalEntryState.storageError());
      await tapText(tester, l10n.commonRetry);
      expect(calls, ['undo', 'back', 'back', 'retry']);
    });

    testWidgets('an AI reading: bar actions, text, full reading, note', (
      tester,
    ) async {
      await pump(
        tester,
        JournalEntryState.content(_view(JournalItem.reading(_complete))),
      );
      expect(find.byType(TaroCardFace), findsNWidgets(3));
      expect(find.text(l10n.aiLabel), findsOneWidget);
      expect(find.text(_complete.content!.title), findsOneWidget);
      expect(
        // BUG-11: the question keeps its own direction in an RTL UI.
        find.text(
          l10n.readingQuestionQuoted(firstStrongIsolate(kTestQuestion)),
        ),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(l10n.commonFavourite));
      await tester.tap(find.text(l10n.commonShare));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.shareIncludeQuestion));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TaroButton, l10n.commonShare).last);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonMore));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportReadingTitle));
      await tester.pumpAndSettle();
      await tapText(tester, l10n.entryFullReading);
      await tapText(tester, l10n.readingFullDisclaimer);
      await tester.enterText(find.byType(TextField), 'thoughts');
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      await tapText(tester, l10n.entryDelete);
      expect(calls, [
        'favourite',
        'share:true',
        'report:r-complete',
        'full:r-complete',
        'disclaimer',
        'note:thoughts',
        'done',
        'delete',
      ]);
    });

    testWidgets('the note follows app edits but not the user echo', (
      tester,
    ) async {
      final item = JournalItem.reading(_complete);
      await pump(
        tester,
        JournalEntryState.content(_view(item, note: 'a')),
      );
      await tester.enterText(find.byType(TextField), 'ab');
      await pump(
        tester,
        JournalEntryState.content(
          _view(item, note: 'ab', status: NoteStatus.editing),
        ),
      );
      expect(find.text(l10n.commonSaving), findsOneWidget);
      await pump(
        tester,
        JournalEntryState.content(
          _view(item, note: 'ab\n\nWhy?\n\n', status: NoteStatus.failed),
        ),
      );
      expect(find.text('ab\n\nWhy?\n\n'), findsOneWidget);
      expect(find.text(l10n.failureStorage), findsOneWidget);
    });

    testWidgets('pending: backs + Finish; failed: Try again', (tester) async {
      await pump(
        tester,
        JournalEntryState.pending(_view(JournalItem.reading(_pending))),
      );
      expect(find.byType(TaroCardBack), findsNWidgets(3));
      expect(find.byType(TaroCardFace), findsNothing);
      expect(find.text(l10n.entryPendingNotice), findsOneWidget);
      expect(find.text(l10n.commonShare), findsNothing);
      await tapText(tester, l10n.journalFinishReading);
      await pump(
        tester,
        JournalEntryState.failed(
          _view(JournalItem.reading(_failed)),
          refunded: true,
        ),
      );
      expect(find.text(l10n.entryFailedNotice), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(calls, ['finish:r-pending', 'finish:r-failed']);
    });

    testWidgets('classic: its label, no Report; daily card meaning', (
      tester,
    ) async {
      await pump(
        tester,
        JournalEntryState.content(_view(JournalItem.reading(_classic))),
      );
      expect(find.text(l10n.classicLabel), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.commonMore), findsNothing);
      await tapText(tester, l10n.entryFullReading);

      await pump(
        tester,
        JournalEntryState.content(_view(JournalItem.dailyCard(_daily))),
        texts: {const CardId('major_17'): _text('major_17', 'The Star')},
      );
      expect(find.text('The Star'), findsOneWidget);
      expect(find.text('Hope feels far.'), findsOneWidget);
      expect(find.text('What gives you hope?'), findsOneWidget);
      expect(find.text(l10n.entryDelete), findsNothing);
      expect(find.text(l10n.commonShare), findsNothing);
      await pump(
        tester,
        JournalEntryState.content(_view(JournalItem.dailyCard(_daily))),
      );
      expect(find.text(l10n.commonDailyCard), findsWidgets);
      expect(calls, ['full:r-classic']);
    });

    testWidgets('200 % text does not overflow', (tester) async {
      await pump(
        tester,
        JournalEntryState.content(_view(JournalItem.reading(_complete))),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('S15 with fakes', () {
    late TaroFakes fakes;

    setUp(() {
      fakes = TaroFakes();
      fakes.journal
        ..putReading(_complete)
        ..putReading(_pending)
        ..putReading(_classic)
        ..putDailyCard(_daily);
    });

    testWidgets('note autosave, favourite, share, full reading', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        JournalEntryScreen(id: _complete.id.value),
        fakes: fakes,
        pushed: true,
      );
      await tester.enterText(find.byType(TextField), 'thoughts');
      await tester.pump(kJournalNoteAutosaveDelay);
      await tester.pumpAndSettle();
      expect(fakes.journal.readings[_complete.id]!.note, 'thoughts');
      await tester.tap(find.bySemanticsLabel(l10n.commonFavourite));
      await tester.pumpAndSettle();
      expect(fakes.journal.readings[_complete.id]!.favourite, isTrue);
      await tester.tap(find.text(l10n.commonShare));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TaroButton, l10n.commonShare).last);
      await tester.pumpAndSettle();
      expect(fakes.files.shared, hasLength(1));
      await tapText(tester, l10n.entryFullReading);
      expectRoute(RoutePaths.reading(_complete.id.value));
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('delete asks, pops with Undo, and Undo restores', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _complete.id.value),
        fakes: fakes,
        pushed: true,
      );
      await tapText(tester, l10n.entryDelete);
      await tapText(tester, l10n.commonCancel);
      expect(fakes.journal.readings, contains(_complete.id));
      await tapText(tester, l10n.entryDelete);
      await tapText(tester, l10n.commonDelete);
      expectRoute('/');
      expect(fakes.journal.readings, isNot(contains(_complete.id)));
      await tester.tap(find.text(l10n.commonUndo));
      await tester.pumpAndSettle();
      expect(fakes.journal.readings, contains(_complete.id));
      expect(
        fakes.analytics.events
            .whereType<JournalEntryDeletedEvent>()
            .single
            .undone,
        isTrue,
      );
    });

    testWidgets('a deep-linked delete stays; the toast ends with the window', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _complete.id.value),
        fakes: fakes,
      );
      await tapText(tester, l10n.entryDelete);
      await tapText(tester, l10n.commonDelete);
      expect(find.text(l10n.journalDeleted), findsNWidgets(2));
      await tester.pump(ReadingRepository.undoWindow);
      await tester.pumpAndSettle();
      expect(find.text(l10n.readingNotFound), findsOneWidget);
      expect(find.text(l10n.commonUndo), findsNothing);
    });

    testWidgets('"Write about this" pre-fills the note once', (tester) async {
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _complete.id.value, prompt: 'What now?'),
        fakes: fakes,
      );
      expect(find.text('What now?\n\n'), findsOneWidget);
      await tester.pump(kJournalNoteAutosaveDelay);
      await tester.pumpAndSettle();
      expect(fakes.journal.readings[_complete.id]!.note, 'What now?\n\n');
    });

    testWidgets('pending finish, daily card, not found, storage retry', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _pending.id.value),
        fakes: fakes,
      );
      await tapText(tester, l10n.journalFinishReading);
      expectRoute('/reading/draw?resume=${_pending.id.value}');

      await pumpRouted(
        tester,
        const JournalEntryScreen(id: '2026-09-25'),
        fakes: fakes,
      );
      expect(find.byType(TaroCardFace), findsOneWidget);
      expect(find.text(l10n.entryDelete), findsNothing);

      await pumpRouted(
        tester,
        const JournalEntryScreen(id: 'missing'),
        fakes: fakes,
      );
      expect(find.text(l10n.readingNotFound), findsOneWidget);

      // iOS-R3-02: a date with no daily card says so, not "this reading".
      await pumpRouted(
        tester,
        const JournalEntryScreen(id: '2020-01-01'),
        fakes: fakes,
      );
      expect(find.text(l10n.dailyCardNotFound), findsOneWidget);
      expect(find.text(l10n.readingNotFound), findsNothing);

      fakes.readings.failNext(const Failure.storage(), on: 'setFavourite');
      await pumpRouted(
        tester,
        JournalEntryScreen(id: _classic.id.value),
        fakes: fakes,
      );
      await tester.tap(find.bySemanticsLabel(l10n.commonFavourite));
      await tester.pumpAndSettle();
      await tapText(tester, l10n.commonRetry);
      expect(find.text(l10n.classicLabel), findsOneWidget);
    });
  });
}
