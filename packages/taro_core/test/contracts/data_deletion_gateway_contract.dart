import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// What the `DataDeletionGateway` contract needs besides the port.
abstract interface class DataDeletionGatewayHarness {
  /// The gateway under test (nothing queued).
  DataDeletionGateway get subject;

  /// The next `DELETE /v1/installs/me` fails with [failure].
  void serverFailsNext(Failure failure);
}

/// The `DataDeletionGateway` contract (CS15, RC37, 02 §6.1).
void runDataDeletionGatewayContract(
  DataDeletionGatewayHarness Function() create,
) {
  group('DataDeletionGateway contract', () {
    late DataDeletionGatewayHarness harness;
    late DataDeletionGateway gateway;

    setUp(() {
      harness = create();
      gateway = harness.subject;
    });

    test('nothing is queued at first', () async {
      expect(expectOk(await gateway.queued()), isNull);
    });

    test('queue keeps the idempotency key until cleared', () async {
      expectOk(await gateway.queue(idempotencyKey: 'erase-1'));
      expect(expectOk(await gateway.queued()), 'erase-1');
      expectOk(await gateway.clearQueue());
      expect(expectOk(await gateway.queued()), isNull);
    });

    test('a newer queued key replaces the old one', () async {
      await gateway.queue(idempotencyKey: 'erase-1');
      await gateway.queue(idempotencyKey: 'erase-2');
      expect(expectOk(await gateway.queued()), 'erase-2');
    });

    test('erasure is idempotent per key', () async {
      expectOk(await gateway.eraseServerData(idempotencyKey: 'erase-1'));
      expectOk(await gateway.eraseServerData(idempotencyKey: 'erase-1'));
    });

    test('a failed erasure leaves the queue untouched', () async {
      await gateway.queue(idempotencyKey: 'erase-1');
      harness.serverFailsNext(const Failure.network());
      expect(
        expectErr(await gateway.eraseServerData(idempotencyKey: 'erase-1')),
        isA<NetworkFailure>(),
      );
      expect(expectOk(await gateway.queued()), 'erase-1');
    });
  });
}
