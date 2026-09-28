import 'package:taro_core/src/model/user_settings.dart';
import 'package:taro_core/src/result/result.dart';

/// User settings (`settings` in `taro_journal.db`, exported in backups;
/// 02 §5).
abstract interface class SettingsRepository {
  /// The current settings (defaults before the first write).
  UserSettings get current;

  /// Emits the settings and every change.
  Stream<UserSettings> watch();

  /// Applies [change] atomically and returns the new settings.
  Future<Result<UserSettings>> update(
    UserSettings Function(UserSettings current) change,
  );
}
