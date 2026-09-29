import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements ReadingRepositoryHarness {
  final FakeReadingRepository repo = FakeReadingRepository();

  @override
  ReadingRepository get subject => repo;

  @override
  void failNextWorkerCall(Failure failure) => repo.failNextWorkerCall(failure);

  @override
  void advance(Duration by) => repo.clock.advance(by);
}

void main() {
  runReadingRepositoryContract(_Harness.new);

  group('FakeReadingRepository hooks', () {
    late FakeReadingRepository repo;

    setUp(() => repo = FakeReadingRepository());

    test('refuseNext, completeNextWith and stayPendingNext', () async {
      final content = aReadingContent(title: 'Scripted');
      repo
        ..refuseNext()
        ..completeNextWith(content)
        ..stayPendingNext();
      final pending = aReading().pending().build();
      final refused = expectOk(await repo.submit(pending));
      expect(refused.status, const ReadingStatus.refused());
      final completed = expectOk(await repo.submit(pending));
      expect(completed.content, content);
      final stillPending = expectOk(await repo.submit(pending));
      expect(stillPending.status, const ReadingStatus.pending());
      expect(repo.submitted, hasLength(3));
    });

    test('AI failures are stored as refunded failures', () async {
      repo.failNextWorkerCall(const Failure.aiUnavailable());
      final pending = aReading().pending().build();
      expect((await repo.submit(pending)).isErr, isTrue);
      final stored = repo.journal.readings[pending.id]!;
      expect(
        stored.status,
        const ReadingStatus.failed(Failure.aiUnavailable(), refunded: true),
      );
    });

    test('holds use the balance repository or an override', () async {
      final balance = FakeBalanceRepository(
        cached: aCreditBalance().withFreeRemaining(0).withPaid(2).build(),
      );
      final withBalance = FakeReadingRepository(balance: balance);
      final spread = aSpread().build();
      final hold = expectOk(
        await withBalance.hold(kTestReadingId, spread, locale: 'en'),
      );
      expect(hold.chargeSource, ChargeSource.paid);
      withBalance.holdSource = ChargeSource.bonus;
      expect(
        expectOk(
          await withBalance.hold(kTestReadingId, spread, locale: 'en'),
        ).chargeSource,
        ChargeSource.bonus,
      );
      expect(withBalance.holds, hasLength(2));
    });

    test('resume of an unknown or delivered reading', () async {
      expect(
        expectErr(await repo.resume(kTestReadingId)),
        const Failure.contract(wireCode: 'NOT_FOUND'),
      );
      final done = aReading().build();
      repo.journal.putReading(done);
      expect(expectOk(await repo.resume(done.id)), done);
    });

    test('local failNext fails each local method', () async {
      final r = aReading().build();
      for (final m in [
        'saveClassic',
        'get',
        'pending',
        'setNote',
        'delete',
        'undoDelete',
        'flushPendingAcks',
      ]) {
        repo.failNext(const Failure.storage(), on: m);
      }
      expect((await repo.saveClassic(r)).isErr, isTrue);
      expect((await repo.get(r.id)).isErr, isTrue);
      expect((await repo.pending()).isErr, isTrue);
      expect((await repo.setNote(r.id, 'x')).isErr, isTrue);
      expect((await repo.delete(r.id)).isErr, isTrue);
      expect((await repo.undoDelete(r.id)).isErr, isTrue);
      expect((await repo.flushPendingAcks()).isErr, isTrue);
    });
  });
}
