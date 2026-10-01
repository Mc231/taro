@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro/features/daily_card/view/daily_card_screen.dart';

import 'golden_app_support.dart';

final DateTime _today = DateTime(2026, 9, 27, 9);

DailyCardLayout _layout(DailyCardState state) => DailyCardLayout(
  state: state,
  today: _today,
  onClose: () {},
  onReveal: () {},
  onRetry: () {},
  onReflectDeeper: () {},
  onEditNote: () {},
  onCancelNote: () {},
  onSaveNote: (_) {},
  onToggleFavourite: () {},
  onAnswerReminder: ({required accepted}) {},
);

void main() {
  final card = aDailyCard().withCard('major_17').on('2026-09-27').build();
  final view = DailyCardView(
    card: card,
    // The Star, from the canvas sample (docs/design/screens/S13).
    text: aCardText(card.cardId).copyWith(
      name: 'The Star',
      keywordsUpright: const ['Hope', 'Renewal', 'Quiet faith'],
      shortUpright:
          'After a storm, the Star invites you to rest and let things '
          'refill slowly. Hope here is gentle and practical, not a leap.',
      reflectionQuestions: const [
        'What small thing helps you feel restored today?',
      ],
    ),
    deckCard: deckCardFor(card.cardId),
  );

  goldenMatrix(
    's13_daily_card_not_drawn',
    (_) => _layout(const DailyCardState.notDrawn()),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );

  goldenMatrix(
    's13_daily_card_drawn',
    (_) => _layout(DailyCardState.drawn(view)),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );
}
