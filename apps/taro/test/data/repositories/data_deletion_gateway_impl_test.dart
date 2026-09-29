import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/repositories/data_deletion_gateway_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/fake_worker_server.dart';

final class _Harness implements DataDeletionGatewayHarness {
  _Harness() : h = RepositoryHarness() {
    subject = DataDeletionGatewayImpl(
      client: h.client,
      cache: h.device.cacheDao,
      logger: h.logger,
    );
  }

  final RepositoryHarness h;

  @override
  late final DataDeletionGatewayImpl subject;

  @override
  void serverFailsNext(Failure failure) => h.server.failNext(failure);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runDataDeletionGatewayContract(_Harness.new);

  group('DataDeletionGatewayImpl', () {
    late _Harness harness;

    setUp(() => harness = _Harness());
    tearDown(() => harness.h.close());

    test('sends DELETE with the given key', () async {
      expectOk(
        await harness.subject.eraseServerData(idempotencyKey: 'erase-7'),
      );
      expect(harness.h.server.erasures, ['erase-7']);
    });

    test('the queue lives in sync_state and survives a new gateway', () async {
      await harness.subject.queue(idempotencyKey: 'erase-1');
      expect(
        await harness.h.device.cacheDao.syncValue(
          DataDeletionGatewayImpl.queueKey,
        ),
        'erase-1',
      );
      final again = DataDeletionGatewayImpl(
        client: harness.h.client,
        cache: harness.h.device.cacheDao,
        logger: CapturingLogger(),
      );
      expect(expectOk(await again.queued()), 'erase-1');
    });

    test('a broken database is a StorageFailure', () async {
      await harness.h.device.customStatement('DROP TABLE sync_state');
      expect(
        expectErr(await harness.subject.queue(idempotencyKey: 'k')),
        isA<StorageFailure>(),
      );
      expect(expectErr(await harness.subject.queued()), isA<StorageFailure>());
      expect(
        expectErr(await harness.subject.clearQueue()),
        isA<StorageFailure>(),
      );
      expect(
        harness.h.logger.records.map((r) => r.message),
        contains('erasure queue storage failed'),
      );
    });
  });
}
