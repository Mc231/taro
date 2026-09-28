import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `SettingsRepository` contract (02 §5). [create] returns a
/// repository with the first-launch settings.
void runSettingsRepositoryContract(SettingsRepository Function() create) {
  group('SettingsRepository contract', () {
    late SettingsRepository settings;

    setUp(() => settings = create());

    test('starts with the defaults', () {
      expect(settings.current, const UserSettings());
    });

    test('update applies the change and returns the new settings', () async {
      final next = expectOk(
        await settings.update(
          (s) => s.copyWith(
            themeMode: ThemeMode.dark,
            reminder: const ReminderSettings(enabled: true, time: '21:30'),
          ),
        ),
      );
      expect(next.themeMode, ThemeMode.dark);
      expect(next.reminder.time, '21:30');
      expect(settings.current, next);
    });

    test('watch emits the current settings, then every change', () async {
      final seen = <UserSettings>[];
      final sub = settings.watch().listen(seen.add);
      await settle();
      await settings.update((s) => s.copyWith(reversalsEnabled: false));
      await settle();
      await sub.cancel();
      expect(seen.first, const UserSettings());
      expect(seen.last.reversalsEnabled, isFalse);
    });

    test('concurrent updates are applied one after another', () async {
      await Future.wait([
        settings.update((s) => s.copyWith(hapticsEnabled: false)),
        settings.update((s) => s.copyWith(localeOverride: 'uk')),
      ]);
      expect(settings.current.hapticsEnabled, isFalse);
      expect(settings.current.localeOverride, 'uk');
    });
  });
}
