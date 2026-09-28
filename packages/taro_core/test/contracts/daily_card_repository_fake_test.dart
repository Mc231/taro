import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements DailyCardRepositoryHarness {
  final FakeClock clock = FakeClock();
  late final FakeDailyCardRepository repo = FakeDailyCardRepository(
    clock: clock,
  );

  @override
  DailyCardRepository get subject => repo;

  @override
  void advanceToNextLocalDay() => clock.advance(const Duration(days: 1));

  @override
  void advanceWithinDay() => clock.advance(const Duration(hours: 1));
}

void main() {
  runDailyCardRepositoryContract(_Harness.new);

  test('draws from the scripted source; reversals follow settings', () async {
    final journal = InMemoryJournal()
      ..putSettings(const UserSettings(reversalsEnabled: false));
    final repo = FakeDailyCardRepository(
      journal: journal,
      random: ScriptedRandomSource([5]),
    );
    final card = expectOk(await repo.drawToday());
    expect(card.cardId, kCardIds[5]);
    expect(card.reversed, isFalse);
    expect(card.localDate, kTestLocalDate);
  });

  test('changes to a missing day are no-ops; failNext fails', () async {
    final repo = FakeDailyCardRepository();
    expectOk(await repo.setNote('2020-01-01', 'x'));
    expect(repo.journal.dailyCards, isEmpty);
    repo.failNext(const Failure.storage());
    expect((await repo.drawToday()).isErr, isTrue);
  });
}
