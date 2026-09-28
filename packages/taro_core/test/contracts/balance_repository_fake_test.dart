import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements BalanceRepositoryHarness {
  final FakeBalanceRepository repo = FakeBalanceRepository();

  @override
  BalanceRepository get subject => repo;

  @override
  void serverReturns(CreditBalance balance) => repo.server = balance;

  @override
  void serverFailsNext(Failure failure) => repo.failNext(failure, on: 'sync');

  @override
  int get requests => repo.requests;

  @override
  void holdRequests() => repo.pauseSync();

  @override
  void release() => repo.resumeSync();
}

void main() {
  runBalanceRepositoryContract(_Harness.new);

  test('records reasons and applied balances; seed skips the log', () async {
    final repo = FakeBalanceRepository()..seed(aCreditBalance().build());
    await repo.sync(reason: SyncReason.preReading);
    await repo.apply(aCreditBalance().withLedgerVersion(3).build());
    expect(repo.syncReasons, [SyncReason.preReading]);
    expect(repo.applied.single.ledgerVersion, 3);
    expect(repo.calls, ['sync', 'apply']);
  });
}
