import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `BalanceRepository` contract needs besides the port.
abstract interface class BalanceRepositoryHarness {
  /// The repository under test (nothing cached).
  BalanceRepository get subject;

  /// `GET /v1/balance` answers [balance] from now on.
  void serverReturns(CreditBalance balance);

  /// The next `GET /v1/balance` fails with [failure].
  void serverFailsNext(Failure failure);

  /// `GET /v1/balance` requests that reached the Worker.
  int get requests;

  /// Holds requests open until [release] (for the "share one request"
  /// check).
  void holdRequests();

  /// Releases held requests.
  void release();
}

/// The `BalanceRepository` contract (02 §5, 04 §6.5, rule 7, RC67).
void runBalanceRepositoryContract(BalanceRepositoryHarness Function() create) {
  group('BalanceRepository contract', () {
    late BalanceRepositoryHarness harness;
    late BalanceRepository balance;

    final v1 = aCreditBalance().withLedgerVersion(1).withPaid(3).build();
    final v2 = aCreditBalance().withLedgerVersion(2).withPaid(5).build();

    setUp(() {
      harness = create();
      balance = harness.subject;
    });

    test('nothing is cached before the first sync', () {
      expect(balance.cached, isNull);
    });

    test('sync fetches, caches and emits the Worker balance', () async {
      harness.serverReturns(v1);
      final seen = <CreditBalance?>[];
      final sub = balance.watch().listen(seen.add);
      await settle();
      final synced = expectOk(await balance.sync(reason: SyncReason.launch));
      await settle();
      await sub.cancel();
      expect(synced.ledgerVersion, 1);
      expect(synced.paid, 3);
      expect(balance.cached?.ledgerVersion, 1);
      expect(seen.first, isNull);
      expect(seen.last?.ledgerVersion, 1);
    });

    test('a failed sync keeps the cache and returns the failure', () async {
      harness.serverReturns(v1);
      await balance.sync(reason: SyncReason.launch);
      harness.serverFailsNext(const Failure.network());
      final failure = expectErr(await balance.sync(reason: SyncReason.resume));
      expect(failure, isA<NetworkFailure>());
      expect(balance.cached?.ledgerVersion, 1);
    });

    test('concurrent syncs share one request', () async {
      harness
        ..serverReturns(v1)
        ..holdRequests();
      final a = balance.sync(reason: SyncReason.resume);
      final b = balance.sync(reason: SyncReason.connectivityRegained);
      harness.release();
      final results = await Future.wait([a, b]);
      expect(harness.requests, 1);
      expect(expectOk(results[0]), expectOk(results[1]));
    });

    test('apply accepts a newer ledger version', () async {
      harness.serverReturns(v1);
      await balance.sync(reason: SyncReason.launch);
      final current = await balance.apply(v2);
      expect(current.ledgerVersion, 2);
      expect(balance.cached?.paid, 5);
    });

    test('apply ignores an older ledger version (RC67)', () async {
      harness.serverReturns(v2);
      await balance.sync(reason: SyncReason.launch);
      final current = await balance.apply(v1);
      expect(current.ledgerVersion, 2);
      expect(balance.cached?.ledgerVersion, 2);
    });

    test('an equal version with a newer serverTime replaces it', () async {
      harness.serverReturns(v1);
      await balance.sync(reason: SyncReason.launch);
      final later = v1.copyWith(
        bonus: 1,
        serverTime: v1.serverTime.add(const Duration(seconds: 5)),
      );
      expect((await balance.apply(later)).bonus, 1);
    });

    test('a sync answer older than the cache does not replace it', () async {
      harness.serverReturns(v1);
      await balance.sync(reason: SyncReason.launch);
      await balance.apply(v2);
      await balance.sync(reason: SyncReason.manual);
      expect(balance.cached?.ledgerVersion, 2);
    });
  });
}
