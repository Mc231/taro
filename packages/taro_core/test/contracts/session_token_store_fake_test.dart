import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runSessionTokenStoreContract(FakeSessionTokenStore.new);

  test('failNext fails each method', () async {
    final store = FakeSessionTokenStore();
    for (final m in ['read', 'write', 'clear']) {
      store.failNext(const Failure.storage(), on: m);
    }
    expect((await store.read()).isErr, isTrue);
    expect(
      (await store.write(SessionToken(token: 't', expiresAt: kTestNow))).isErr,
      isTrue,
    );
    expect((await store.clear()).isErr, isTrue);
    expect(store.calls, ['read', 'write', 'clear']);
  });
}
