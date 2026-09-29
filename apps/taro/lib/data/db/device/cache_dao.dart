import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';

part 'cache_dao.g.dart';

/// The single-row caches and device markers of `taro_device.db`: balance
/// (display-only, AR8), remote config, consent and `sync_state`.
@DriftAccessor(include: {'device.drift'})
class CacheDao extends DatabaseAccessor<DeviceDatabase> with _$CacheDaoMixin {
  /// Creates the DAO.
  CacheDao(super.attachedDatabase);

  // ---- balance_cache --------------------------------------------------

  /// The cached balance, or `null` (fresh install, OS restore).
  Future<BalanceCacheRow?> balance() => select(balanceCache).getSingleOrNull();

  /// Emits the cached balance (or `null`) and every change.
  Stream<BalanceCacheRow?> watchBalance() =>
      select(balanceCache).watchSingleOrNull();

  /// Stores [row] when [accept] approves the currently cached row (or its
  /// absence), atomically; returns whether it was stored.
  ///
  /// The repository passes the RC67 rule (`ledgerVersion` newer, or equal
  /// with a newer `serverTime`), so a late `GET /v1/balance` never
  /// overwrites a newer balance.
  Future<bool> replaceBalanceIf(
    BalanceCacheCompanion row,
    bool Function(BalanceCacheRow? cached) accept,
  ) => transaction(() async {
    if (!accept(await balance())) return false;
    await into(
      balanceCache,
    ).insertOnConflictUpdate(row.copyWith(id: const Value(1)));
    return true;
  });

  /// Removes the cached balance.
  Future<void> clearBalance() => delete(balanceCache).go();

  // ---- remote_config_cache --------------------------------------------

  /// The cached remote config, or `null`.
  Future<RemoteConfigCacheRow?> remoteConfig() =>
      select(remoteConfigCache).getSingleOrNull();

  /// Stores [row] as the cached remote config.
  Future<void> putRemoteConfig(RemoteConfigCacheCompanion row) => into(
    remoteConfigCache,
  ).insertOnConflictUpdate(row.copyWith(id: const Value(1)));

  /// Removes the cached remote config.
  Future<void> clearRemoteConfig() => delete(remoteConfigCache).go();

  // ---- consent_state --------------------------------------------------

  /// The stored consent, or `null` (never asked on this device).
  Future<ConsentStateRow?> consent() => select(consentStates).getSingleOrNull();

  /// Emits the stored consent (or `null`) and every change.
  Stream<ConsentStateRow?> watchConsent() =>
      select(consentStates).watchSingleOrNull();

  /// Stores [row] as the consent state.
  Future<void> putConsent(ConsentStatesCompanion row) => into(
    consentStates,
  ).insertOnConflictUpdate(row.copyWith(id: const Value(1)));

  /// Removes the stored consent.
  Future<void> clearConsent() => delete(consentStates).go();

  // ---- sync_state -----------------------------------------------------

  /// The marker [key], or `null`.
  Future<String?> syncValue(String key) async => (await (select(
    syncState,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  /// Stores [value] under [key].
  Future<void> putSyncValue(String key, String value) => into(
    syncState,
  ).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));

  /// Removes [key]; returns whether it existed.
  Future<bool> removeSyncValue(String key) async =>
      await (delete(syncState)..where((s) => s.key.equals(key))).go() == 1;
}
