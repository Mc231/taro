import 'dart:async';

import 'package:drift/drift.dart';
import 'package:taro/data/db/journal/daily_cards_dao.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro_core/taro_core.dart';

/// [DailyCardRepository] over the drift `daily_cards` table (01 §7.6,
/// §17.3; 02 §5).
///
/// "Today" is the device-local date (`LocalDates.format(clock.nowLocal())`,
/// the device timezone). [drawToday] is idempotent: the card stored for
/// today is returned unchanged; otherwise `DailyCardRules` draws one and
/// `DailyCardsDao.insertIfAbsent` stores it, so two concurrent draws on one
/// day still keep a single card.
final class DailyCardRepositoryImpl implements DailyCardRepository {
  /// Creates the repository. [content] supplies the deck, [settings] the
  /// reversals setting, [random] the CSPRNG.
  DailyCardRepositoryImpl({
    required DailyCardsDao dao,
    required ContentRepository content,
    required SettingsRepository settings,
    required Clock clock,
    required RandomSource random,
    required Logger logger,
  }) : _dao = dao,
       _content = content,
       _settings = settings,
       _clock = clock,
       _rules = DailyCardRules(random),
       _logger = logger;

  final DailyCardsDao _dao;
  final ContentRepository _content;
  final SettingsRepository _settings;
  final Clock _clock;
  final DailyCardRules _rules;
  final Logger _logger;

  String get _today => LocalDates.format(_clock.nowLocal());

  /// Emits today's card (or `null`) on listen and after every change to
  /// `daily_cards`. "Today" is read again on each change, so a draw after
  /// midnight is seen as the new day's card.
  @override
  Stream<DailyCard?> watchToday() {
    StreamSubscription<Object?>? updates;
    late final StreamController<DailyCard?> out;
    Future<void> emit() async {
      try {
        out.add(await _todayCard());
      } on Object catch (error, stack) {
        out.addError(error, stack);
      }
    }

    out = StreamController<DailyCard?>(
      onListen: () {
        updates = _dao.attachedDatabase
            .tableUpdates(TableUpdateQuery.onTable(_dao.dailyCards))
            .listen((_) => emit());
        unawaited(emit());
      },
      onCancel: () => updates?.cancel(),
    );
    return out.stream.distinct();
  }

  Future<DailyCard?> _todayCard() async {
    final row = await _dao.byDate(_today);
    return row == null ? null : _decode(row);
  }

  @override
  Future<Result<DailyCard>> drawToday() async {
    try {
      final today = _today;
      final stored = await _dao.byDate(today);
      if (stored != null) return _decoded(stored);
      final deck = await _content.deck();
      if (deck case Err(:final failure)) return Result.err(failure);
      final pick = _rules.today(
        today: today,
        stored: null,
        deck: deck.valueOrNull!,
        reversalsEnabled: _settings.current.reversalsEnabled,
        now: _clock.now(),
      );
      return _decoded(await _dao.insertIfAbsent(_row(pick.card)));
    } on Object catch (error) {
      _logger.severe('daily card draw failed', error: error);
      return const Result.err(Failure.storage());
    }
  }

  @override
  Future<Result<void>> setNote(String localDate, String? note) =>
      _patch(localDate, DailyCardsCompanion(note: Value(note)));

  @override
  Future<Result<void>> setFavourite(
    String localDate, {
    required bool favourite,
  }) => _patch(localDate, DailyCardsCompanion(favourite: Value(favourite)));

  /// Applies [changes] to the card of [localDate]; a date without a card is
  /// a no-op.
  Future<Result<void>> _patch(
    String localDate,
    DailyCardsCompanion changes,
  ) async {
    try {
      await _dao.patch(
        localDate,
        changes.copyWith(updatedAt: Value(_clock.now())),
      );
      return const Result.ok(null);
    } on Object catch (error) {
      _logger.severe('daily card update failed', error: error);
      return const Result.err(Failure.storage());
    }
  }

  Result<DailyCard> _decoded(DailyCardRow row) {
    final card = _decode(row);
    return card == null ? const Result.err(Failure.storage()) : Result.ok(card);
  }

  /// The card of [row], or `null` (logged) when its card ID is invalid.
  DailyCard? _decode(DailyCardRow row) {
    final cardId = CardId.tryParse(row.cardId);
    if (cardId == null) {
      _logger.warning('daily card row has an invalid card ID');
      return null;
    }
    return DailyCard(
      localDate: row.localDate,
      cardId: cardId,
      reversed: row.reversed,
      drawnAt: row.drawnAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      note: row.note,
      favourite: row.favourite,
    );
  }

  static DailyCardsCompanion _row(DailyCard card) => DailyCardsCompanion.insert(
    localDate: card.localDate,
    cardId: card.cardId.value,
    reversed: card.reversed,
    drawnAt: card.drawnAt,
    note: Value(card.note),
    favourite: Value(card.favourite),
    createdAt: card.createdAt,
    updatedAt: card.updatedAt,
  );
}
