import 'package:taro_core/taro_core.dart';

/// A consistent card for [id].
DeckCard cardFor(CardId id) {
  final parts = id.value.split('_');
  final number = int.parse(parts[1]);
  if (parts[0] == 'major') {
    return DeckCard(
      id: id,
      arcana: Arcana.major,
      suit: null,
      number: number,
      artKey: id.value,
    );
  }
  final suit = Suit.values.byName(parts[0]);
  return DeckCard(
    id: id,
    arcana: Arcana.minor,
    suit: suit,
    number: number,
    artKey: id.value,
    element: Element.values[suit.index],
  );
}

/// The 78 consistent cards.
List<DeckCard> allCards() => [for (final id in kCardIds) cardFor(id)];

/// A `BalanceDto` as in 03 §5.1.
Map<String, Object?> balanceDto({
  int ledgerVersion = 412,
  String serverTime = '2026-09-26T09:12:44Z',
  int paid = 5,
}) => {
  'free': {
    'limit': 1,
    'used': 0,
    'remaining': 1,
    'localDate': '2026-09-26',
    'resetsAt': '2026-09-26T22:00:00Z',
    'timezone': 'Europe/Berlin',
    'paused': false,
  },
  'bonus': 2,
  'paid': paid,
  'canRead': true,
  'canReadReason': null,
  'nextSource': 'free',
  'rewarded': {
    'enabled': true,
    'amount': 1,
    'dailyCap': 3,
    'grantedToday': 1,
    'available': true,
    'cooldownEndsAt': null,
  },
  'paidBlocked': false,
  'purchasesAllowed': true,
  'purchasesBlockedReason': null,
  'ledgerVersion': ledgerVersion,
  'serverTime': serverTime,
};

/// Device time of the fixture sync.
final DateTime syncedAt = DateTime.utc(2026, 9, 26, 9, 12, 45);

/// A balance parsed from [balanceDto].
CreditBalance balance({
  int ledgerVersion = 412,
  String serverTime = '2026-09-26T09:12:44Z',
  int paid = 5,
}) => CreditBalance.fromDto(
  balanceDto(ledgerVersion: ledgerVersion, serverTime: serverTime, paid: paid),
  syncedAt: syncedAt,
);

/// A three-card draw.
Draw threeCardDraw() => Draw(
  spreadId: const SpreadId('three_ppf'),
  spreadVersion: 1,
  cards: const [
    DrawnCard(
      positionId: PositionId('past'),
      cardId: CardId('major_16'),
      reversed: false,
    ),
    DrawnCard(
      positionId: PositionId('present'),
      cardId: CardId('cups_03'),
      reversed: true,
    ),
    DrawnCard(
      positionId: PositionId('future'),
      cardId: CardId('pentacles_14'),
      reversed: false,
    ),
  ],
  drawnAt: DateTime.utc(2026, 9, 25, 8),
);

/// Sample reading content.
const ReadingContent content = ReadingContent(
  title: 'A turning point',
  summary: 'Overview',
  positions: [
    PositionText(positionId: PositionId('past'), text: 'Past text'),
    PositionText(positionId: PositionId('present'), text: 'Present text'),
    PositionText(positionId: PositionId('future'), text: 'Future text'),
  ],
  synthesis: 'Synthesis',
  reflectionPrompts: ['What changes?', 'What stays?'],
);

/// A completed reading whose draw time equals its creation time.
Reading completeReading({
  String id = '0c6e2b1e-1111-4222-8333-444455556666',
  ReadingStatus status = const ReadingStatus.complete(),
}) {
  final created = DateTime.utc(2026, 9, 25, 8);
  return Reading(
    id: ReadingId(id),
    createdAt: created,
    updatedAt: DateTime.utc(2026, 9, 25, 9, 30),
    localDate: '2026-09-25',
    draw: threeCardDraw(),
    status: status,
    contentLocale: 'en',
    question: 'How can I approach the change at work?',
    content: content,
    promptVersion: 'v1',
    note: 'A note',
    favourite: true,
    rating: Rating.up,
    deliveryAcked: true,
  );
}

/// A daily card.
DailyCard dailyCard() => DailyCard(
  localDate: '2026-09-25',
  cardId: const CardId('major_17'),
  reversed: false,
  drawnAt: DateTime.utc(2026, 9, 25, 7),
  createdAt: DateTime.utc(2026, 9, 25, 7),
  updatedAt: DateTime.utc(2026, 9, 25, 7, 5),
  note: 'Hope',
);

/// A crisis resource.
CrisisResource helpline(String name, {String? phone = '0800 111 0 111'}) =>
    CrisisResource(
      name: name,
      phone: phone,
      url: phone == null ? 'https://example.org' : null,
      languages: const ['de'],
      verifiedAt: DateTime.utc(2026, 9),
    );
