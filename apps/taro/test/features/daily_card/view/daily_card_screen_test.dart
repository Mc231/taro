import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro/features/daily_card/view/daily_card_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

DailyCardView _view({String? note, bool reversed = false}) {
  final card = aDailyCard()
      .withCard('major_17')
      .reversed(reversed)
      .withNote(note)
      .build();
  return DailyCardView(
    card: card,
    text: aCardText(card.cardId),
    deckCard: deckCardFor(card.cardId),
  );
}

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    DailyCardState state,
  ) async {
    final calls = <String>[];
    await pumpTaroWidget(
      tester,
      DailyCardLayout(
        state: state,
        today: DateTime(2026, 9, 27, 9),
        onClose: () => calls.add('close'),
        onReveal: () => calls.add('reveal'),
        onRetry: () => calls.add('retry'),
        onReflectDeeper: () => calls.add('deeper'),
        onEditNote: () => calls.add('edit'),
        onCancelNote: () => calls.add('cancel'),
        onSaveNote: (note) => calls.add('save:$note'),
        onToggleFavourite: () => calls.add('favourite'),
        onAnswerReminder: ({required accepted}) =>
            calls.add('reminder:$accepted'),
      ),
    );
    return calls;
  }

  testWidgets('loading: skeleton', (tester) async {
    await pumpLayout(tester, const DailyCardState.loading());
    expect(find.byType(TaroLoadingView), findsOneWidget);
  });

  testWidgets('notDrawn: the card back, no face; tap to reveal; back', (
    tester,
  ) async {
    final calls = await pumpLayout(tester, const DailyCardState.notDrawn());
    expect(find.text(l10n.dailyNotDrawnPrompt), findsOneWidget);
    expect(find.text(l10n.dailyNotDrawnBody), findsOneWidget);
    expect(find.text(l10n.dailyNotDrawnBadge), findsOneWidget);
    expect(find.text(l10n.dailyOverline), findsOneWidget);
    expect(find.byType(TaroCardBack), findsOneWidget);
    expect(find.byType(TaroCardFace), findsNothing);
    expect(find.byType(BannerSlot), findsNothing);
    expect(find.bySemanticsLabel(l10n.dailyCardBackSemantics), findsOneWidget);
    await tapFound(tester, find.byType(TaroCardBack));
    await tapFound(tester, find.text(l10n.dailyBackToToday));
    await tester.tap(find.byTooltip(l10n.commonBack));
    expect(calls, ['reveal', 'close', 'close']);
  });

  testWidgets('revealing: the back is disabled, still no face', (
    tester,
  ) async {
    final calls = await pumpLayout(tester, const DailyCardState.revealing());
    expect(find.byType(TaroCardFace), findsNothing);
    expect(
      tester.widget<TaroCardBack>(find.byType(TaroCardBack)).enabled,
      isFalse,
    );
    await tester.tap(find.byType(TaroCardBack), warnIfMissed: false);
    expect(calls, isEmpty);
  });

  testWidgets('notDrawn → drawn: the flip, then the texts and an '
      'announcement', (tester) async {
    final view = _view();
    Future<void> pump(DailyCardState state) => pumpTaroWidget(
      tester,
      DailyCardLayout(
        state: state,
        today: DateTime(2026, 9, 27, 9),
        onClose: () {},
        onReveal: () {},
        onRetry: () {},
        onReflectDeeper: () {},
        onEditNote: () {},
        onCancelNote: () {},
        onSaveNote: (_) {},
        onToggleFavourite: () {},
        onAnswerReminder: ({required accepted}) {},
      ),
    );
    await pump(const DailyCardState.notDrawn());
    await pump(const DailyCardState.revealing());
    await pump(DailyCardState.drawn(view));
    await tester.pump();
    expect(find.text(view.shortMeaning), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(view.shortMeaning), findsOneWidget);
    expect(find.byType(TaroCardFace), findsOneWidget);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains(l10n.dailyRevealedAnnouncement(view.text.name)),
    );
  });

  testWidgets('drawn: header and keyword semantics, Latin numerals', (
    tester,
  ) async {
    final view = _view();
    await pumpLayout(tester, DailyCardState.drawn(view));
    expect(
      find.bySemanticsLabel(
        l10n.dailyKeywordsSemantics(view.keywords.join(', ')),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(l10n.dailyHeaderSemantics(''))),
      findsOneWidget,
    );
    expect(find.textContaining('XVII'), findsOneWidget);
    expect(find.text(view.reflectionQuestion!), findsOneWidget);
  });

  testWidgets('drawn: face, name, keywords, meaning, actions', (
    tester,
  ) async {
    final view = _view(note: 'Calm');
    final calls = await pumpLayout(tester, DailyCardState.drawn(view));
    expect(find.byType(TaroCardFace), findsOneWidget);
    expect(find.text(view.text.name), findsOneWidget);
    expect(find.text(view.shortMeaning), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text(l10n.commonSavedOnDevice), findsOneWidget);
    expect(find.text(l10n.dailyAddNote), findsNothing);
    for (final k in view.keywords) {
      expect(find.text(k), findsOneWidget);
    }
    await tapFound(tester, find.text(l10n.dailyReflectDeeper));
    await tapFound(tester, find.text('Calm'));
    await tester.tap(find.byTooltip(l10n.commonFavourite));
    await tester.tap(find.byTooltip(l10n.commonBack));
    expect(calls, ['deeper', 'edit', 'favourite', 'close']);
  });

  testWidgets('drawn without a note: Add a note', (tester) async {
    final calls = await pumpLayout(tester, DailyCardState.drawn(_view()));
    await tapFound(tester, find.text(l10n.dailyAddNote));
    expect(calls, ['edit']);
  });

  testWidgets('drawn reversed: the reversed meta', (tester) async {
    await pumpLayout(tester, DailyCardState.drawn(_view(reversed: true)));
    expect(find.textContaining(l10n.commonReversed), findsWidgets);
  });

  testWidgets('noteEditing: editor with save and cancel', (tester) async {
    final calls = await pumpLayout(
      tester,
      DailyCardState.noteEditing(_view(note: 'Old')),
    );
    expect(find.byType(TaroTextField), findsOneWidget);
    expect(find.text(l10n.dailyReflectDeeper), findsNothing);
    await tester.enterText(find.byType(TextField), 'New note');
    await tapFound(tester, find.text(l10n.commonDone));
    await tapFound(tester, find.text(l10n.commonCancel));
    expect(calls, ['save:New note', 'cancel']);
  });

  testWidgets('reminderOffer: Yes / No', (tester) async {
    final calls = await pumpLayout(
      tester,
      DailyCardState.reminderOffer(_view()),
    );
    expect(find.text(l10n.dailyReminderOfferTitle), findsOneWidget);
    await tapFound(tester, find.text(l10n.dailyReminderOfferYes));
    await tapFound(tester, find.text(l10n.dailyReminderOfferNo));
    expect(calls, ['reminder:true', 'reminder:false']);
  });

  testWidgets('failed: error view with retry', (tester) async {
    final calls = await pumpLayout(
      tester,
      const DailyCardState.failed(Failure.storage()),
    );
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
    await tapFound(tester, find.text(l10n.commonRetry));
    expect(calls, ['retry']);
  });

  group('screen', () {
    Future<TaroFakes> pumpDaily(WidgetTester tester) async {
      final fakes = TaroFakes();
      await pumpFlow(
        tester,
        path: RoutePaths.daily,
        builder: (_) => const DailyCardScreen(),
        fakes: fakes,
      );
      return fakes;
    }

    testWidgets('reveal → reminder offer → No → Reflect deeper opens S07 '
        'with the card preset', (tester) async {
      final fakes = await pumpDaily(tester);
      await tapFound(tester, find.byType(TaroCardBack));
      expect(find.byType(TaroCardFace), findsOneWidget);
      await tapFound(tester, find.text(l10n.dailyReminderOfferNo));
      expect(find.text(l10n.dailyReminderOfferTitle), findsNothing);
      final card = fakes.journal.dailyCards.values.single;
      await tapFound(tester, find.text(l10n.dailyReflectDeeper));
      expectRoute(
        RoutePaths.readingQuestion(
          'single',
          source: 'daily_card',
          cardId: card.cardId.value,
          reversed: card.reversed,
        ),
      );
    });

    testWidgets('note, favourite and close are wired', (tester) async {
      final fakes = await pumpDaily(tester);
      await tapFound(tester, find.byType(TaroCardBack));
      await tapFound(tester, find.text(l10n.dailyReminderOfferYes));
      await tapFound(tester, find.text(l10n.dailyAddNote));
      await tester.enterText(find.byType(TextField), 'Steady');
      await tapFound(tester, find.text(l10n.commonDone));
      expect(fakes.journal.dailyCards.values.single.note, 'Steady');
      await tester.tap(find.byTooltip(l10n.commonFavourite));
      await tester.pumpAndSettle();
      expect(fakes.journal.dailyCards.values.single.favourite, isTrue);
      await tapFound(tester, find.text('Steady'));
      await tapFound(tester, find.text(l10n.commonCancel));
      await tester.tap(find.byTooltip(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });

    testWidgets('a storage failure retries', (tester) async {
      final fakes = TaroFakes();
      fakes.dailyCards.failNext(const Failure.storage(), on: 'drawToday');
      await pumpFlow(
        tester,
        path: RoutePaths.daily,
        builder: (_) => const DailyCardScreen(),
        fakes: fakes,
      );
      await tapFound(tester, find.byType(TaroCardBack));
      expect(find.text(l10n.errorStorageTitle), findsOneWidget);
      await tapFound(tester, find.text(l10n.commonRetry));
      expect(find.text(l10n.dailyNotDrawnPrompt), findsOneWidget);
    });
  });
}
