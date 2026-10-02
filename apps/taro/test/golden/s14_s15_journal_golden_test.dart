@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_entry_screen.dart';
import 'package:taro/features/journal/view/journal_list_screen.dart';
import 'package:taro_core/taro_core.dart';

import 'golden_app_support.dart';

/// Sunday 27 September 2026, evening (the canvas `Journal` artboard).
final DateTime _now = DateTime(2026, 9, 27, 21, 40);

final Reading _rebuilding = aReading()
    .withId('r-rebuilding')
    .onLocalDate('2026-09-26')
    .withQuestion('How can I rebuild after a hard year at work?')
    .favourite()
    .withNote('The Eight of Pentacles feels right.')
    .build();
final Reading _pending = aReading()
    .withId('r-pending')
    .onLocalDate('2026-09-25')
    .withSpread('relationship')
    .withQuestion('What am I not seeing in this relationship?')
    .pending()
    .build();
final Reading _classic = aReading()
    .withId('r-classic')
    .onLocalDate('2026-08-25')
    .withSpread('two_paths')
    .withQuestion('Should I take the Lisbon offer?')
    .classic()
    .build();
final List<DailyCard> _dailies = [
  for (final (day, card) in [
    ('2026-09-27', 'major_17'),
    ('2026-09-24', 'major_17'),
    ('2026-09-21', 'cups_03'),
    ('2026-09-18', 'pentacles_08'),
  ])
    aDailyCard().on(day).withCard(card).build(),
];

const Map<CardId, String> _names = {
  CardId('major_17'): 'The Star',
  CardId('cups_03'): 'Three of Cups',
  CardId('pentacles_08'): 'Eight of Pentacles',
  CardId('major_00'): 'The Fool',
};

JournalListLayout _list(JournalListState state) => JournalListLayout(
  state: state,
  filters: const JournalFilters(),
  now: () => _now,
  cardNames: _names,
  banner: const BannerSlot(BannerScreen.journalList),
  onType: (_) {},
  onSpread: (_) {},
  onClearCard: () {},
  onSearch: (_) {},
  onClearFilters: () {},
  onOpen: (_) {},
  onFinish: (_) {},
  onDelete: (_) {},
  onOpenCard: (_) {},
  onRange: (_) {},
  onStartReading: () {},
  onOpenDaily: () {},
  onRetry: () {},
);

JournalListState _content() => JournalListState.content(
  months: [
    JournalMonth(
      yearMonth: '2026-09',
      items: [
        JournalItem.dailyCard(_dailies.first),
        JournalItem.reading(_rebuilding),
        JournalItem.reading(_pending),
      ],
    ),
    JournalMonth(
      yearMonth: '2026-08',
      items: [JournalItem.reading(_classic)],
    ),
  ],
  filters: const JournalFilters(),
  patterns: JournalPatterns.compute(
    readings: [_rebuilding, _pending, _classic],
    dailyCards: _dailies,
    today: '2026-09-27',
  ),
);

TaroFakes _fakes() {
  final fakes = goldenFakes(clock: FakeClock(_now));
  fakes.journal
    ..putReading(_rebuilding)
    ..putReading(_pending)
    ..putReading(_classic);
  _dailies.forEach(fakes.journal.putDailyCard);
  return fakes;
}

void main() {
  goldenMatrix(
    's14_journal_content',
    (_) => _list(_content()),
    keyScreen: true,
    accessibility: true,
    extraLocales: const [Locale('de'), Locale('ja')],
    pump: pumpAppGolden(_fakes),
  );

  goldenMatrix(
    's14_journal_empty',
    (_) => _list(const JournalListState.empty()),
    keyScreen: true,
    accessibility: true,
    extraLocales: const [Locale('de'), Locale('ja')],
    pump: pumpAppGolden(_fakes),
  );

  goldenMatrix(
    's15_journal_entry_content',
    (_) => JournalEntryScreen(id: _rebuilding.id.value),
    pump: pumpAppGolden(_fakes),
  );
}
