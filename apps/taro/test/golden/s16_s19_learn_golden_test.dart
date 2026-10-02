@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/learn/controller/card_detail_controller.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/view/card_detail_screen.dart';
import 'package:taro/features/learn/view/deck_browser_screen.dart';
import 'package:taro_core/taro_core.dart';

import 'golden_app_support.dart';

/// The English card names of the bundled deck.
Map<String, String> _names() {
  final json =
      jsonDecode(File('assets/deck/en.json').readAsStringSync())
          as Map<String, Object?>;
  return {
    for (final card in (json['cards']! as List).cast<Map<String, Object?>>())
      card['cardId']! as String: card['name']! as String,
  };
}

DeckBrowserState _deck() {
  final names = _names();
  final bySection = <DeckSectionKind, List<DeckTile>>{};
  for (final card in aDeck().build().cards) {
    bySection
        .putIfAbsent(DeckSectionKind.of(card), () => [])
        .add(DeckTile(card: card, name: names[card.id.value]!));
  }
  return DeckBrowserState.content(
    sections: [
      for (final kind in DeckSectionKind.values)
        DeckSection(kind: kind, tiles: bySection[kind]!),
    ],
  );
}

/// Three of Cups as `CardDetail.dc.html` draws it.
CardDetailView _threeOfCups() {
  const id = CardId('cups_03');
  return CardDetailView(
    card: deckCardFor(id),
    text: aCardText(id).copyWith(
      name: 'Three of Cups',
      keywordsUpright: const ['Celebration', 'Friendship', 'Belonging'],
      meaningUpright:
          'Three friends raise their cups. The card points to joy that '
          'grows when it is shared, and to the people who help you feel at '
          'home.',
      aspects: const CardAspects(
        relationshipsUpright:
            'Warmth from a wider circle supports your closest bond.',
        relationshipsReversed: '',
        workUpright: 'A team win worth pausing to mark together.',
        workReversed: '',
        growthUpright: 'Let yourself be celebrated, not only helpful.',
        growthReversed: '',
      ),
      reflectionQuestions: const [
        'Who helps you feel at home, and when did you last tell them?',
        'What small win could you celebrate this week?',
        'Which gatherings leave you lighter, and which leave you tired?',
      ],
    ),
    drawnCount: 4,
    position: 3,
    sectionSize: 14,
    previous: const CardId('cups_02'),
    next: const CardId('cups_04'),
  );
}

void main() {
  final deck = _deck();
  final view = _threeOfCups();

  goldenMatrix(
    's16_learn_content',
    (_) => DeckBrowserLayout(
      state: deck,
      banner: const BannerSlot(BannerScreen.learnLibrary),
      onSearch: (_) {},
      onCard: (_) {},
      onSpreads: () {},
      onAbout: () {},
      onRetry: () {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    // One completed AI reading: the `learn_library` banner may show.
    pump: pumpAppGolden(
      () => goldenFakes()..journal.putReading(aReading().build()),
    ),
  );

  goldenMatrix(
    's17_card_detail_upright',
    (_) => CardDetailLayout(
      state: CardDetailState.upright(view),
      onReversed: (_) {},
      onZoom: () {},
      onCloseZoom: () {},
      onCard: (_) {},
      onJournal: () {},
      onBack: () {},
      onRetry: () {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    extraLocales: const [Locale('de'), Locale('ja')],
    pump: pumpAppGolden(goldenFakes),
  );
}
