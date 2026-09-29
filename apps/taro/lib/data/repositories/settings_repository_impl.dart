import 'dart:async';
import 'dart:convert';

import 'package:taro/data/db/journal/settings_dao.dart';
import 'package:taro/data/repositories/serial_value.dart';
import 'package:taro_core/taro_core.dart';

/// [SettingsRepository] over the drift `settings` table of
/// `taro_journal.db` (02 §5, §6.1).
///
/// One row per key: the backup `settings` keys (`theme`,
/// `reversalsEnabled`, `hapticsEnabled`, `reminder`, `localeOverride`;
/// JSON values as in `UserSettings.toBackupJson`) plus the device-local
/// [reduceMotionKey], which the backup codec leaves out. A missing or
/// invalid key reads as its default. Updates run one after another; a
/// change written outside the repository (backup import, "Delete all
/// data") is reloaded into [current].
final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl._(this._dao, this._logger);

  /// The key of `UserSettings.reduceMotion` (not exported).
  static const reduceMotionKey = 'reduceMotion';

  /// Opens the repository with the stored settings loaded.
  static Future<SettingsRepositoryImpl> open({
    required SettingsDao dao,
    required Logger logger,
  }) async {
    final repo = SettingsRepositoryImpl._(dao, logger);
    repo._value.set(await repo._load());
    repo._value.follow(
      dao.watchAll(),
      repo._load,
      onError: (error, stack) =>
          logger.warning('settings reload failed', error: error),
    );
    return repo;
  }

  final SettingsDao _dao;
  final Logger _logger;
  final SerialValue<UserSettings> _value = SerialValue(const UserSettings());

  @override
  UserSettings get current => _value.value;

  @override
  Stream<UserSettings> watch() => _value.watch();

  @override
  Future<Result<UserSettings>> update(
    UserSettings Function(UserSettings current) change,
  ) => _value.serial(() async {
    try {
      final next = change(_value.value);
      await _dao.replaceAll(encode(next));
      _value.set(next);
      return Result.ok(next);
    } on Object catch (error) {
      _logger.severe('settings update failed', error: error);
      return const Result.err(Failure.storage());
    }
  });

  /// Stops following the table and completes [watch] streams.
  Future<void> close() => _value.close();

  Future<UserSettings> _load() async => decode(await _dao.readAll(), _logger);

  /// The rows of [settings]: key → JSON value.
  static Map<String, String> encode(UserSettings settings) => {
    for (final MapEntry(:key, :value) in settings.toBackupJson().entries)
      key: jsonEncode(value),
    if (settings.reduceMotion != null)
      reduceMotionKey: jsonEncode(settings.reduceMotion),
  };

  /// The settings of [rows]; each missing or invalid key takes its default
  /// (logged by key name only).
  static UserSettings decode(Map<String, String> rows, Logger logger) {
    var json = const UserSettings().toBackupJson();
    bool? reduceMotion;
    for (final MapEntry(:key, :value) in rows.entries) {
      try {
        final decoded = jsonDecode(value);
        if (key == reduceMotionKey) {
          if (decoded is! bool?) throw const FormatException('not a bool');
          reduceMotion = decoded;
          continue;
        }
        final candidate = {...json, key: decoded};
        UserSettings.fromBackupJson(candidate);
        json = candidate;
      } on FormatException {
        logger.warning('settings key "$key" invalid; default used');
      }
    }
    return UserSettings.fromBackupJson(json, reduceMotion: reduceMotion);
  }
}
