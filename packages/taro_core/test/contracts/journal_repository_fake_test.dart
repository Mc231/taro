import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runJournalRepositoryContract(FakeJournalRepository.new);

  test('search matches card IDs; blank text finds nothing', () async {
    final journal = FakeJournalRepository();
    final reading = aReading().build();
    journal.journal.putReading(reading);
    final card = reading.cards.first.cardId.value;
    expect(expectOk(await journal.search(card)), [
      JournalItem.reading(reading),
    ]);
    expect(expectOk(await journal.search('   ')), isEmpty);
  });

  test('failNext fails each method', () async {
    final journal = FakeJournalRepository();
    for (final m in ['search', 'snapshot', 'replaceAll', 'deleteAll']) {
      journal.failNext(const Failure.storage(), on: m);
    }
    expect((await journal.search('x')).isErr, isTrue);
    expect((await journal.snapshot()).isErr, isTrue);
    expect((await journal.replaceAll(aBackup().data())).isErr, isTrue);
    expect((await journal.deleteAll()).isErr, isTrue);
  });
}
