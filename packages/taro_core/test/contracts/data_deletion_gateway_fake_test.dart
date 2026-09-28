import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements DataDeletionGatewayHarness {
  final FakeDataDeletionGateway gateway = FakeDataDeletionGateway();

  @override
  DataDeletionGateway get subject => gateway;

  @override
  void serverFailsNext(Failure failure) =>
      gateway.failNext(failure, on: 'eraseServerData');
}

void main() {
  runDataDeletionGatewayContract(_Harness.new);

  test('failNext fails the queue methods', () async {
    final gateway = FakeDataDeletionGateway();
    for (final m in ['queue', 'queued', 'clearQueue']) {
      gateway.failNext(const Failure.storage(), on: m);
    }
    expect((await gateway.queue(idempotencyKey: 'k')).isErr, isTrue);
    expect((await gateway.queued()).isErr, isTrue);
    expect((await gateway.clearQueue()).isErr, isTrue);
    expectOk(await gateway.eraseServerData(idempotencyKey: 'k'));
    expect(gateway.erased, ['k']);
  });
}
