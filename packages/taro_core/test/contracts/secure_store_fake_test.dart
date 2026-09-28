import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runSecureStoreContract(InMemorySecureStore.new);

  test('failNext simulates an unusable store', () async {
    final store = InMemorySecureStore({'a': '1'})
      ..failNext(const Failure.storage(), on: 'read');
    expect(expectErr(await store.read('a')), const Failure.storage());
    expect(expectOk(await store.read('a')), '1');
    store
      ..failNext(const Failure.storage(), on: 'write')
      ..failNext(const Failure.storage(), on: 'delete');
    expect(expectErr(await store.write('a', '2')), const Failure.storage());
    expect(expectErr(await store.delete('a')), const Failure.storage());
    expect(store.values, {'a': '1'});
  });
}
