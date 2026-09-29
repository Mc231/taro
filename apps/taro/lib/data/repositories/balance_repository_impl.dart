import 'dart:async';
import 'dart:convert';

import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/serial_value.dart';
import 'package:taro_core/taro_core.dart';

/// `GET /v1/balance` (`WorkerClient.fetchBalance`).
typedef BalanceFetcher = Future<Result<CreditBalance>> Function();

/// [BalanceRepository] over the Worker and the drift `balance_cache`
/// (02 §5, 04 §6.5, AR8).
///
/// The client never computes a balance (rule 7): the cache changes only
/// through [apply], which every Worker response carrying a balance goes
/// through (sync, hold, reading, purchase, reward, timezone). [apply] keeps
/// the RC67 order: a response replaces the cache only when its
/// `ledgerVersion` is greater, or equal with a newer `serverTime`
/// (`CreditBalance.shouldReplace`); anything older, including a
/// `GET /v1/balance` sent before a reading and answered after it, is
/// ignored. The check and the write run in one drift transaction, and
/// every apply runs on one serial queue.
final class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl._(this._dao, this._fetch, this._logger);

  /// Opens the repository with the cached balance loaded, then keeps
  /// [cached] and [watch] in step with the drift row (so "Delete all data"
  /// clearing the cache is seen).
  static Future<BalanceRepositoryImpl> open({
    required CacheDao cache,
    required BalanceFetcher fetch,
    required Logger logger,
  }) async {
    final repo = BalanceRepositoryImpl._(cache, fetch, logger);
    repo._value.set(await repo._load());
    repo._value.follow(
      cache.watchBalance(),
      repo._load,
      onError: (error, stack) =>
          logger.warning('balance cache reload failed', error: error),
    );
    return repo;
  }

  final CacheDao _dao;
  final BalanceFetcher _fetch;
  final Logger _logger;
  final SerialValue<CreditBalance?> _value = SerialValue(null);
  Future<Result<CreditBalance>>? _inflight;

  @override
  CreditBalance? get cached => _value.value;

  @override
  Stream<CreditBalance?> watch() => _value.watch();

  @override
  Future<Result<CreditBalance>> sync({required SyncReason reason}) =>
      _inflight ??= _sync(reason).whenComplete(() => _inflight = null);

  Future<Result<CreditBalance>> _sync(SyncReason reason) async {
    switch (await _fetch()) {
      case Ok(:final value):
        return Result.ok(await apply(value));
      case Err(:final failure):
        _logger.fine('balance sync (${reason.name}) failed: ${failure.code}');
        return Result.err(failure);
    }
  }

  @override
  Future<CreditBalance> apply(CreditBalance balance) => _value.serial(() async {
    try {
      final stored = await _dao.replaceBalanceIf(
        _row(balance),
        (row) => _replaces(balance, row == null ? null : _decode(row)),
      );
      _value.set(stored ? balance : await _load());
    } on Object catch (error) {
      // The cache is display-only: keep the RC67 order in memory.
      _logger.warning('balance cache write failed', error: error);
      if (_replaces(balance, _value.value)) _value.set(balance);
    }
    return _value.value ?? balance;
  });

  /// Stops following the drift row and completes [watch] streams.
  Future<void> close() => _value.close();

  static bool _replaces(CreditBalance incoming, CreditBalance? cached) =>
      cached == null || incoming.shouldReplace(cached);

  Future<CreditBalance?> _load() async {
    final row = await _dao.balance();
    return row == null ? null : _decode(row);
  }

  /// The cached balance, or `null` for an unreadable row (which the next
  /// Worker response then replaces).
  CreditBalance? _decode(BalanceCacheRow row) {
    try {
      final json = jsonDecode(row.json) as Map<String, Object?>;
      return CreditBalance.fromDto(
        json,
        syncedAt: row.syncedAt,
      ).copyWith(serverTime: row.serverTime);
    } on Object catch (error) {
      _logger.warning('balance cache row unreadable', error: error);
      return null;
    }
  }

  static BalanceCacheCompanion _row(CreditBalance balance) =>
      BalanceCacheCompanion.insert(
        json: jsonEncode(balance.toDto()),
        ledgerVersion: balance.ledgerVersion,
        serverTime: balance.serverTime,
        syncedAt: balance.syncedAt,
      );
}
