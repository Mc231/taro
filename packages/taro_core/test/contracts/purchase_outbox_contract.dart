import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// The `PurchaseOutbox` contract (02 §6.1, 04 §6.2, rule 8). [create]
/// returns an empty outbox.
void runPurchaseOutboxContract(PurchaseOutbox Function() create) {
  group('PurchaseOutbox contract', () {
    late PurchaseOutbox outbox;
    final t0 = DateTime.utc(2026, 9, 26, 9);
    final t1 = t0.add(const Duration(minutes: 1));

    setUp(() => outbox = create());

    Future<OutboxEntry> enqueue(String txnKey, {DateTime? at}) async =>
        expectOk(
          await outbox.enqueue(
            aStorePurchase(txnKey: txnKey),
            idempotencyKey: 'key-$txnKey',
            now: at ?? t0,
          ),
        );

    test('enqueue writes an awaitingVerification row', () async {
      final row = await enqueue('txn-1');
      expect(row.txnKey, 'txn-1');
      expect(row.idempotencyKey, 'key-txn-1');
      expect(row.status, OutboxStatus.awaitingVerification);
      expect(row.attempts, 0);
      expect(row.createdAt, t0);
      expect(expectOk(await outbox.pending()), [row]);
    });

    test('enqueue of a known transaction keeps the first row', () async {
      final first = await enqueue('txn-1');
      final again = expectOk(
        await outbox.enqueue(
          aStorePurchase(),
          idempotencyKey: 'another-key',
          now: t1,
        ),
      );
      expect(again.idempotencyKey, first.idempotencyKey);
      expect(again.createdAt, t0);
      expect(expectOk(await outbox.pending()), hasLength(1));
    });

    test('pending lists open rows oldest first', () async {
      await enqueue('txn-b', at: t1);
      await enqueue('txn-a');
      final pending = expectOk(await outbox.pending());
      expect([for (final r in pending) r.txnKey], ['txn-a', 'txn-b']);
    });

    test('a granted row stays open until it is finished', () async {
      await enqueue('txn-1');
      expectOk(await outbox.markGranted('txn-1', now: t1));
      final open = expectOk(await outbox.pending());
      expect(open.single.status, OutboxStatus.granted);
      expect(open.single.updatedAt, t1);
      expectOk(await outbox.markFinished('txn-1', now: t1));
      expect(expectOk(await outbox.pending()), isEmpty);
    });

    test('a rejected row is closed', () async {
      await enqueue('txn-1');
      expectOk(await outbox.markRejected('txn-1', now: t1));
      expect(expectOk(await outbox.pending()), isEmpty);
    });

    test('recordAttempt counts attempts and keeps the last error', () async {
      await enqueue('txn-1');
      await outbox.recordAttempt('txn-1', now: t1, error: 'NETWORK');
      await outbox.recordAttempt('txn-1', now: t1, error: 'TIMEOUT');
      final row = expectOk(await outbox.pending()).single;
      expect(row.attempts, 2);
      expect(row.lastError, 'TIMEOUT');
      expect(row.status, OutboxStatus.awaitingVerification);
      expect(row.idempotencyKey, 'key-txn-1');
    });
  });
}
