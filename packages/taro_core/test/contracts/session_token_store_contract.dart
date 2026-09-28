import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `SessionTokenStore` contract (02 §6.2). [create] returns an empty
/// store.
void runSessionTokenStoreContract(SessionTokenStore Function() create) {
  group('SessionTokenStore contract', () {
    late SessionTokenStore store;
    final token = SessionToken(
      token: 'header.payload.signature',
      expiresAt: DateTime.utc(2026, 10, 3, 12),
    );

    setUp(() => store = create());

    test('reads null before the first write', () async {
      expect(expectOk(await store.read()), isNull);
    });

    test('round-trips the token and its expiry', () async {
      expectOk(await store.write(token));
      final read = expectOk(await store.read());
      expect(read, token);
      expect(read!.expiresAt.isUtc, isTrue);
    });

    test('a write replaces the previous token', () async {
      await store.write(token);
      final next = SessionToken(
        token: 'next',
        expiresAt: DateTime.utc(2026, 10, 10),
      );
      await store.write(next);
      expect(expectOk(await store.read()), next);
    });

    test('clear removes it and is idempotent', () async {
      await store.write(token);
      expectOk(await store.clear());
      expectOk(await store.clear());
      expect(expectOk(await store.read()), isNull);
    });
  });
}
