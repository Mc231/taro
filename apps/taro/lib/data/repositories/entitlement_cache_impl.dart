import 'dart:async';

import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/device/entitlements_dao.dart';
import 'package:taro/data/repositories/serial_value.dart';
import 'package:taro_core/taro_core.dart';

/// [EntitlementCache] over the drift `entitlements` table of
/// `taro_device.db` (04 §6.4, MO7, RC37), row [removeAdsKey].
///
/// [read] is synchronous: the row is loaded by [open] and every [write]
/// updates memory after drift. The cache is only ever changed by the
/// entitlement controller, which writes `notOwned` only on a definitive
/// store answer (MO7); "Delete all data" keeps the table. A value read back
/// after a restart has `source: EntitlementSource.cache`.
final class EntitlementCacheImpl implements EntitlementCache {
  EntitlementCacheImpl._(this._dao, this._logger);

  /// `entitlements.key` of Remove Banner Ads (GLOSSARY §3).
  static const removeAdsKey = 'remove_ads';

  /// Opens the cache with the stored entitlement loaded (`unknown` when
  /// the row is missing or unreadable).
  static Future<EntitlementCacheImpl> open({
    required EntitlementsDao dao,
    required Logger logger,
  }) async {
    final cache = EntitlementCacheImpl._(dao, logger);
    try {
      final row = await dao.byKey(removeAdsKey);
      if (row != null) cache._value.set(cache._decode(row));
    } on Object catch (error) {
      logger.warning('entitlement cache unreadable', error: error);
    }
    return cache;
  }

  final EntitlementsDao _dao;
  final Logger _logger;
  final SerialValue<Entitlement> _value = SerialValue(Entitlement.unknown);

  @override
  Entitlement read() => _value.value;

  /// Emits the cached entitlement and every write.
  Stream<Entitlement> watch() => _value.watch();

  @override
  Future<Result<void>> write(Entitlement entitlement) =>
      _value.serial(() async {
        try {
          await _dao.put(
            EntitlementsCompanion.insert(
              key: removeAdsKey,
              state: entitlement.removeAds.name,
              source: entitlement.source.name,
              verifiedAt: Value(entitlement.verifiedAt),
            ),
          );
          _value.set(entitlement);
          return const Result.ok(null);
        } on Object catch (error) {
          _logger.severe('entitlement cache write failed', error: error);
          return const Result.err(Failure.storage());
        }
      });

  /// Completes [watch] streams.
  Future<void> close() => _value.close();

  Entitlement _decode(EntitlementRow row) {
    final state = EntitlementState.values.asNameMap()[row.state];
    if (state == null) {
      _logger.warning('entitlement row has an unknown state');
      return Entitlement.unknown;
    }
    return Entitlement(
      removeAds: state,
      source: EntitlementSource.cache,
      verifiedAt: row.verifiedAt,
    );
  }
}
