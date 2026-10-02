import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/features/reading/controller/classic_reading_controller.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/view/classic_reading_screen.dart';
import 'package:taro/features/reading/view/reading_result_screen.dart';
import 'package:taro_core/taro_core.dart';

import '../../flow_view_support.dart';

/// Apple 1.1.6 and Play "Ads policy" evidence (05 §1, §2, §3;
/// `docs/compliance/APPLE_MATRIX.md`): every state of the reading screens
/// (S09 AI reading, S32 Classic reading) carries the `DisclaimerFooter` and
/// never a `BannerSlot`. One case per sealed state, so a new state that
/// forgets the footer fails here.
void main() {
  final aiReading = aReading().build();
  final aiView = ReadingResultView(
    reading: aiReading,
    cardTexts: {for (final c in aiReading.cards) c.cardId: aCardText(c.cardId)},
  );
  final classicReading = aReading().classic().build();
  final spread = aSpread().build();
  final classicView = ClassicReadingView(
    reading: classicReading,
    positions: [
      for (final card in classicReading.cards)
        ClassicPosition(
          card: card,
          text: aCardText(card.cardId),
          position: spread.position(card.positionId),
        ),
    ],
  );

  final aiStates = <String, ReadingResultState>{
    'loadingFromStorage': const ReadingResultState.loadingFromStorage(),
    'content': ReadingResultState.content(aiView),
    'ratingGiven': ReadingResultState.ratingGiven(aiView),
    'sharing': ReadingResultState.sharing(aiView),
    'notFound': const ReadingResultState.notFound(),
    'failed': const ReadingResultState.failed(Failure.storage()),
  };
  final classicStates = <String, ClassicReadingState>{
    'loadingFromStorage': const ClassicReadingState.loadingFromStorage(),
    'content': ClassicReadingState.content(classicView),
    'notFound': const ClassicReadingState.notFound(),
    'failed': const ClassicReadingState.failed(Failure.storage()),
  };

  Future<void> expectDisclaimerNoBanner(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await revealFound(tester, find.byType(DisclaimerFooter));
    expect(find.byType(DisclaimerFooter), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
  }

  for (final MapEntry(key: name, value: state) in aiStates.entries) {
    testWidgets('S09 $name: disclaimer, no banner', (tester) async {
      await pumpTaroWidget(
        tester,
        ReadingResultLayout(
          state: state,
          onDone: () {},
          onOpenDisclaimer: () {},
          onRate: (_, _) {},
          onToggleFavourite: () {},
          onReport: () {},
          onAddNote: () {},
          onWriteAbout: (_) {},
          onShare: (_, {required includeQuestion}) {},
        ),
      );
      await expectDisclaimerNoBanner(tester);
    });
  }

  for (final MapEntry(key: name, value: state) in classicStates.entries) {
    testWidgets('S32 $name: disclaimer, no banner', (tester) async {
      await pumpTaroWidget(
        tester,
        ClassicReadingLayout(
          state: state,
          onDone: () {},
          onOpenDisclaimer: () {},
          onAddNote: () {},
          onTryAi: (_) {},
        ),
      );
      await expectDisclaimerNoBanner(tester);
    });
  }
}
