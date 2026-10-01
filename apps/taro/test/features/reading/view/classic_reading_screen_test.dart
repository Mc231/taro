import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/features/reading/controller/classic_reading_controller.dart';
import 'package:taro/features/reading/view/classic_reading_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

ClassicReadingView _view({bool aiAvailable = false}) {
  final reading = aReading().classic().build();
  final spread = aSpread().build();
  return ClassicReadingView(
    reading: reading,
    aiAvailable: aiAvailable,
    positions: [
      for (final card in reading.cards)
        ClassicPosition(
          card: card,
          text: aCardText(card.cardId),
          position: spread.position(card.positionId),
        ),
    ],
  );
}

void main() {
  late TaroLocalizations l10n;

  var faces = 0;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    ClassicReadingState state,
  ) async {
    final calls = <String>[];
    await pumpTaroWidget(
      tester,
      ClassicReadingLayout(
        state: state,
        onDone: () => calls.add('done'),
        onOpenDisclaimer: () => calls.add('disclaimer'),
        onAddNote: () => calls.add('note'),
        onTryAi: (spread) => calls.add('ai:${spread.value}'),
      ),
    );
    await tester.pumpAndSettle();
    faces = find.byType(TaroCardFace).evaluate().length;
    await revealFound(tester, find.byType(DisclaimerFooter));
    expect(find.byType(DisclaimerFooter), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
    expect(find.byTooltip(l10n.reportReadingTitle), findsNothing);
    expect(find.byTooltip(l10n.commonMore), findsNothing);
    expect(find.byType(ReadingRatingControl), findsNothing);
    return calls;
  }

  testWidgets('loadingFromStorage: skeleton + disclaimer', (tester) async {
    await pumpLayout(tester, const ClassicReadingState.loadingFromStorage());
    expect(find.byType(ReadingTextView), findsOneWidget);
  });

  testWidgets('content: "Classic reading" label, meanings, no AI offer', (
    tester,
  ) async {
    final view = _view();
    final calls = await pumpLayout(tester, ClassicReadingState.content(view));
    expect(find.text(l10n.aiLabel), findsNothing);
    expect(find.text(l10n.classicTryAi), findsNothing);
    expect(faces, view.positions.length);
    await revealFound(tester, find.text(view.positions.first.meaning));
    await tester.tap(find.text(l10n.commonAddNote));
    await tester.tap(find.byTooltip(l10n.readingDone));
    expect(calls, ['note', 'done']);
  });

  testWidgets('content: "Try an AI reading" when the gate allows', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      ClassicReadingState.content(_view(aiAvailable: true)),
    );
    await tapFound(tester, find.text(l10n.classicTryAi));
    expect(calls, ['ai:three_ppf']);
  });

  testWidgets('text scale 2.0: no overflow', (tester) async {
    await pumpTaroWidget(
      tester,
      ClassicReadingLayout(
        state: ClassicReadingState.content(_view(aiAvailable: true)),
        onDone: noop,
        onOpenDisclaimer: noop,
        onAddNote: noop,
        onTryAi: noop1,
      ),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('notFound and failed keep the disclaimer', (tester) async {
    await pumpLayout(tester, const ClassicReadingState.notFound());
    expect(find.text(l10n.readingNotFound), findsOneWidget);
    await pumpLayout(
      tester,
      const ClassicReadingState.failed(Failure.storage()),
    );
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
  });

  group('screen', () {
    testWidgets('loads the stored reading; Try an AI reading opens S07', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      final reading = aReading().withId('c-1').classic().build();
      fakes.journal.putReading(reading);
      await pumpFlow(
        tester,
        path: '/classic/:id',
        location: '/classic/c-1',
        builder: (state) =>
            ClassicReadingScreen(id: ReadingId(state.pathParameters['id']!)),
        fakes: fakes,
      );
      expect(find.text(l10n.classicLabel), findsOneWidget);
      await tapFound(tester, find.text(l10n.classicTryAi));
      expectRoute(RoutePaths.readingQuestion('three_ppf'));
    });

    testWidgets('the disclaimer link opens S29; Done goes Home', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.journal.putReading(aReading().withId('c-2').classic().build());
      await pumpFlow(
        tester,
        path: '/classic/:id',
        location: '/classic/c-2',
        builder: (state) =>
            ClassicReadingScreen(id: ReadingId(state.pathParameters['id']!)),
        fakes: fakes,
      );
      await tapFound(tester, find.text(l10n.readingFullDisclaimer));
      expectRoute(RoutePaths.legal('disclaimer'));
    });

    testWidgets('Add note opens the note editor', (tester) async {
      final fakes = aiReadyFakes();
      fakes.journal.putReading(aReading().withId('c-4').classic().build());
      await pumpFlow(
        tester,
        path: '/classic/:id',
        location: '/classic/c-4',
        builder: (state) =>
            ClassicReadingScreen(id: ReadingId(state.pathParameters['id']!)),
        fakes: fakes,
      );
      await tester.tap(find.text(l10n.commonAddNote));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.journalEntry('c-4'));
    });

    testWidgets('Done goes Home', (tester) async {
      final fakes = aiReadyFakes();
      fakes.journal.putReading(aReading().withId('c-3').classic().build());
      await pumpFlow(
        tester,
        path: '/classic/:id',
        location: '/classic/c-3',
        builder: (state) =>
            ClassicReadingScreen(id: ReadingId(state.pathParameters['id']!)),
        fakes: fakes,
      );
      await tester.tap(find.byTooltip(l10n.readingDone));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });
  });
}
