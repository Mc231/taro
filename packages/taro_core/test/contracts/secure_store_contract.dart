import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `SecureStore` contract (02 §5, §6.2): a key-value store whose
/// `delete` is idempotent. [create] returns an empty store.
void runSecureStoreContract(SecureStore Function() create) {
  group('SecureStore contract', () {
    late SecureStore store;

    setUp(() => store = create());

    test('reads null for an absent key', () async {
      expect(expectOk(await store.read('taro.install_id')), isNull);
    });

    test('reads back what was written', () async {
      expectOk(await store.write('taro.install_id', 'abc'));
      expect(expectOk(await store.read('taro.install_id')), 'abc');
    });

    test('a second write replaces the value', () async {
      await store.write('taro.install_id', 'abc');
      await store.write('taro.install_id', 'def');
      expect(expectOk(await store.read('taro.install_id')), 'def');
    });

    test('keys are independent', () async {
      await store.write('taro.install_id', 'id');
      await store.write('taro.install_secret', 'secret');
      await store.delete('taro.install_id');
      expect(expectOk(await store.read('taro.install_id')), isNull);
      expect(expectOk(await store.read('taro.install_secret')), 'secret');
    });

    test('delete removes the value and is idempotent', () async {
      await store.write('taro.session_token', 'jwt');
      expectOk(await store.delete('taro.session_token'));
      expectOk(await store.delete('taro.session_token'));
      expect(expectOk(await store.read('taro.session_token')), isNull);
    });

    test('keeps values with non-ASCII and empty content', () async {
      await store.write('a', 'Ключ – 鍵 – مفتاح');
      await store.write('b', '');
      expect(expectOk(await store.read('a')), 'Ключ – 鍵 – مفتاح');
      expect(expectOk(await store.read('b')), '');
    });
  });
}
