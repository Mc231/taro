import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runSettingsRepositoryContract(FakeSettingsRepository.new);

  test('shares the journal and honours failNext', () async {
    final journal = InMemoryJournal();
    final settings = FakeSettingsRepository(
      journal: journal,
      initial: const UserSettings(themeMode: ThemeMode.light),
    )..failNext(const Failure.storage());
    expect(journal.settings.themeMode, ThemeMode.light);
    expect(
      (await settings.update(
        (s) => s.copyWith(themeMode: ThemeMode.dark),
      )).isErr,
      isTrue,
    );
    expect(settings.current.themeMode, ThemeMode.light);
  });
}
