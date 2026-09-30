import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The user settings (theme, language override, reversals, haptics,
/// reminder; 02 §7): the stored value at once, then every change.
final class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    final subscription = repository.watch().listen((settings) {
      state = settings;
    });
    ref.onDispose(subscription.cancel);
    return repository.current;
  }

  /// Applies [change] and persists it.
  Future<Result<UserSettings>> update(
    UserSettings Function(UserSettings current) change,
  ) => ref.read(settingsRepositoryProvider).update(change);
}

/// The app-wide settings (`settingsProvider`, 02 §7).
final settingsProvider = NotifierProvider<SettingsController, UserSettings>(
  SettingsController.new,
);
