import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/purchase_outbox_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  late DeviceDatabase db;
  late CapturingLogger logger;
  late PurchaseOutboxImpl outbox;

  setUp(() {
    db = DeviceDatabase(NativeDatabase.memory());
    logger = CapturingLogger();
    addTearDown(db.close);
    outbox = PurchaseOutboxImpl(dao: db.outboxDao, logger: logger);
  });

  runPurchaseOutboxContract(() => outbox);

  final t0 = DateTime.utc(2026, 9, 26, 9);

  test('an iOS row keeps the JWS; an Android row keeps the token', () async {
    final ios = aStorePurchase(
      txnKey: 'ios-1',
    ).copyWith(signedTransaction: 'jws.payload.sig');
    final android = aStorePurchase(
      txnKey: 'sha-token',
      platform: StorePlatform.android,
    );
    expectOk(await outbox.enqueue(ios, idempotencyKey: 'k1', now: t0));
    expectOk(await outbox.enqueue(android, idempotencyKey: 'k2', now: t0));
    final rows = expectOk(await outbox.pending());
    expect(rows.map((r) => r.purchase), [ios, android]);
    expect(
      (await db.outboxDao.byTxnKey('sha-token'))!.verificationData,
      'token-sha-token',
    );
  });

  test(
    'the row is written before verification and survives a restart',
    () async {
      await outbox.enqueue(aStorePurchase(), idempotencyKey: 'k', now: t0);
      final restarted = PurchaseOutboxImpl(dao: db.outboxDao, logger: logger);
      final row = expectOk(await restarted.pending()).single;
      expect(row.status, OutboxStatus.awaitingVerification);
      expect(row.idempotencyKey, 'k');
    },
  );

  test('finished rows are pruned 30 days after they finish', () async {
    await outbox.enqueue(
      aStorePurchase(txnKey: 'old'),
      idempotencyKey: 'a',
      now: t0,
    );
    await outbox.markFinished('old', now: t0);
    await outbox.enqueue(
      aStorePurchase(txnKey: 'new'),
      idempotencyKey: 'b',
      now: t0,
    );
    final later = t0.add(const Duration(days: 31));
    await outbox.markFinished('new', now: later);
    expect(await db.outboxDao.byTxnKey('old'), isNull);
    expect((await db.outboxDao.byTxnKey('new'))!.status, 'finished');
    expect(
      expectOk(
        await outbox.pruneFinished(now: later.add(const Duration(days: 31))),
      ),
      1,
    );
  });

  test('changes to an unknown row are storage failures', () async {
    for (final result in [
      await outbox.markGranted('nope', now: t0),
      await outbox.markFinished('nope', now: t0),
      await outbox.markRejected('nope', now: t0),
      await outbox.recordAttempt('nope', now: t0, error: 'NETWORK'),
    ]) {
      expect(expectErr(result), isA<StorageFailure>());
    }
    expect(logger.logged('outbox markGranted: no such row'), isTrue);
    expect(logger.logged('outbox recordAttempt: no such row'), isTrue);
  });

  test('database errors are storage failures, logged without data', () async {
    await db.customStatement('DROP TABLE purchase_outbox');
    final purchase = aStorePurchase().copyWith(signedTransaction: 'secret-jws');
    expect(
      expectErr(await outbox.enqueue(purchase, idempotencyKey: 'k', now: t0)),
      isA<StorageFailure>(),
    );
    expect(expectErr(await outbox.pending()), isA<StorageFailure>());
    expect(
      expectErr(await outbox.pruneFinished(now: t0)),
      isA<StorageFailure>(),
    );
    expect(logger.logged('outbox enqueue failed'), isTrue);
    expect(logger.logged('secret-jws'), isFalse);
    expect(logger.records.any((r) => r.error != null), isFalse);
  });
}
