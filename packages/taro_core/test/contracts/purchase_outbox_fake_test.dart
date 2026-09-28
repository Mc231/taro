import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runPurchaseOutboxContract(FakePurchaseOutbox.new);

  test('unknown rows and failNext are failures', () async {
    final outbox = FakePurchaseOutbox();
    expect(
      expectErr(await outbox.markGranted('nope', now: kTestNow)),
      const Failure.storage(),
    );
    outbox
      ..failNext(const Failure.storage(), on: 'enqueue')
      ..failNext(const Failure.storage(), on: 'pending');
    expect(
      (await outbox.enqueue(
        aStorePurchase(),
        idempotencyKey: 'k',
        now: kTestNow,
      )).isErr,
      isTrue,
    );
    expect((await outbox.pending()).isErr, isTrue);
  });

  test('seed inserts a row directly', () async {
    final row = OutboxEntry(
      purchase: aStorePurchase(),
      idempotencyKey: 'k',
      status: OutboxStatus.granted,
      createdAt: kTestNow,
      updatedAt: kTestNow,
    );
    final outbox = FakePurchaseOutbox()..seed(row);
    expect(expectOk(await outbox.pending()), [row]);
    expect(outbox.calls, ['pending']);
  });
}
