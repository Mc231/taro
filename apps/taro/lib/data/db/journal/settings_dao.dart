import 'package:drift/drift.dart';
import 'package:taro/data/db/journal/journal_database.dart';

part 'settings_dao.g.dart';

/// User settings as key/JSON pairs (`settings`, `taro_journal.db`).
@DriftAccessor(include: {'journal.drift'})
class SettingsDao extends DatabaseAccessor<JournalDatabase>
    with _$SettingsDaoMixin {
  /// Creates the DAO.
  SettingsDao(super.attachedDatabase);

  /// The JSON value of [key], or `null`.
  Future<String?> read(String key) async => (await _byKey(
    key,
  ).getSingleOrNull())?.valueJson;

  /// Emits the JSON value of [key] (or `null`) and every change.
  Stream<String?> watch(String key) =>
      _byKey(key).watchSingleOrNull().map((row) => row?.valueJson);

  /// Every setting as key → JSON.
  Future<Map<String, String>> readAll() async => {
    for (final row in await select(settings).get()) row.key: row.valueJson,
  };

  /// Emits every setting as key → JSON, and every change.
  Stream<Map<String, String>> watchAll() => select(settings).watch().map(
    (rows) => {for (final row in rows) row.key: row.valueJson},
  );

  /// Stores [valueJson] under [key].
  Future<void> write(String key, String valueJson) =>
      into(
        settings,
      ).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, valueJson: valueJson),
      );

  /// Replaces every setting with [values] in one transaction.
  Future<void> replaceAll(Map<String, String> values) => transaction(() async {
    await delete(settings).go();
    await batch(
      (b) => b.insertAll(settings, [
        for (final MapEntry(:key, :value) in values.entries)
          SettingsCompanion.insert(key: key, valueJson: value),
      ]),
    );
  });

  /// Removes [key]; returns whether it existed.
  Future<bool> remove(String key) async =>
      await (delete(settings)..where((s) => s.key.equals(key))).go() == 1;

  SimpleSelectStatement<Settings, SettingRow> _byKey(String key) =>
      select(settings)..where((s) => s.key.equals(key));
}
