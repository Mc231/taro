import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';

part 'entitlements_dao.g.dart';

/// The `entitlements` cache (Remove Banner Ads, 04 §6.4).
@DriftAccessor(include: {'device.drift'})
class EntitlementsDao extends DatabaseAccessor<DeviceDatabase>
    with _$EntitlementsDaoMixin {
  /// Creates the DAO.
  EntitlementsDao(super.attachedDatabase);

  /// The entitlement [key] (`remove_ads`), or `null`.
  Future<EntitlementRow?> byKey(String key) =>
      (select(entitlements)..where((e) => e.key.equals(key))).getSingleOrNull();

  /// Emits the entitlement [key] (or `null`) and every change.
  Stream<EntitlementRow?> watchByKey(String key) => (select(
    entitlements,
  )..where((e) => e.key.equals(key))).watchSingleOrNull();

  /// Inserts or replaces [row].
  Future<void> put(EntitlementsCompanion row) =>
      into(entitlements).insertOnConflictUpdate(row);

  /// Removes [key] (only on a definitive store "not owned", MO7); returns
  /// whether it existed.
  Future<bool> remove(String key) async =>
      await (delete(entitlements)..where((e) => e.key.equals(key))).go() == 1;
}
