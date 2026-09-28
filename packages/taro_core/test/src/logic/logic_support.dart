import 'package:taro_core/src/model/models.dart';
import 'package:taro_core/src/result/result_barrel.dart';

// The logic sub-barrels plus the shared random-source fakes.
export 'package:taro_core/src/logic/logic.dart';
export 'package:taro_core/src/model/models.dart';
export 'package:taro_core/src/ports/random_source.dart';
export 'package:taro_core/src/result/result_barrel.dart';

export '../../fakes/random_sources.dart';

/// A consistent card for [id].
DeckCard cardFor(CardId id) {
  final parts = id.value.split('_');
  final number = int.parse(parts[1]);
  final suit = parts[0] == 'major' ? null : Suit.values.byName(parts[0]);
  return DeckCard(
    id: id,
    arcana: suit == null ? Arcana.major : Arcana.minor,
    suit: suit,
    number: number,
    artKey: id.value,
  );
}

/// The full, valid 78-card deck.
final Deck deck = Deck.validated(
  id: 'rws_original',
  version: 1,
  cards: [for (final id in kCardIds) cardFor(id)],
  artSet: 'rws',
);

/// A spread with [count] positions `p1`…`pN` (orders 1..N).
SpreadDefinition spreadOf(
  int count, {
  String id = 'three_ppf',
  bool allowsReversals = true,
  bool enabled = true,
  List<int>? orders,
}) => SpreadDefinition(
  id: SpreadId(id),
  version: 2,
  positions: [
    for (var i = 0; i < count; i++)
      SpreadPosition(
        id: PositionId('p${i + 1}'),
        order: orders?[i] ?? i + 1,
        x: 0.5,
        y: 0.5,
      ),
  ],
  allowsReversals: allowsReversals,
  enabled: enabled,
);

/// A balance built field by field (defaults: one free reading left).
CreditBalance aBalance({
  int limit = 1,
  int remaining = 1,
  bool paused = false,
  int bonus = 0,
  int paid = 0,
  bool canRead = true,
  CanReadReason? canReadReason,
  ChargeSource? nextSource = ChargeSource.free,
  bool rewardedAvailable = true,
  bool rewardedEnabled = true,
  DateTime? cooldownEndsAt,
  DateTime? resetsAt,
  DateTime? serverTime,
  DateTime? syncedAt,
}) => CreditBalance(
  free: FreeAllowance(
    limit: limit,
    used: limit - remaining,
    remaining: remaining,
    localDate: '2026-09-26',
    resetsAt: resetsAt ?? DateTime.utc(2026, 9, 26, 22),
    timezone: 'Europe/Berlin',
    paused: paused,
  ),
  bonus: bonus,
  paid: paid,
  canRead: canRead,
  canReadReason: canReadReason,
  nextSource: nextSource,
  rewarded: RewardedStatus(
    enabled: rewardedEnabled,
    amount: 1,
    dailyCap: 3,
    grantedToday: 0,
    available: rewardedAvailable,
    cooldownEndsAt: cooldownEndsAt,
  ),
  paidBlocked: paid < 0,
  purchasesAllowed: true,
  purchasesBlockedReason: null,
  ledgerVersion: 1,
  serverTime: serverTime ?? DateTime.utc(2026, 9, 26, 9),
  syncedAt: syncedAt ?? DateTime.utc(2026, 9, 26, 9),
);
