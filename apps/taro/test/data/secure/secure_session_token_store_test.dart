import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro/data/secure/secure_session_token_store.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  runSessionTokenStoreContract(
    () => SecureSessionTokenStore(
      InMemorySecureStore(),
      logger: CapturingLogger(),
    ),
  );

  late InMemorySecureStore secure;
  late CapturingLogger logger;
  late SecureSessionTokenStore store;

  setUp(() {
    secure = InMemorySecureStore();
    logger = CapturingLogger();
    store = SecureSessionTokenStore(secure, logger: logger);
  });

  test('stores JSON under taro.session_token with a UTC expiry', () async {
    await store.write(
      SessionToken(
        token: 'jwt',
        expiresAt: DateTime.utc(2026, 10, 3, 10),
      ),
    );
    expect(jsonDecode(secure.values[SecureKeys.sessionToken]!), {
      'token': 'jwt',
      'expiresAt': '2026-10-03T10:00:00.000Z',
    });
  });

  for (final raw in ['not json', '{"token": 1}', '[]']) {
    test('an unreadable value ($raw) reads as no token', () async {
      secure.values[SecureKeys.sessionToken] = raw;
      expect(expectOk(await store.read()), isNull);
      expect(logger.logged('stored session token unreadable'), isTrue);
      expect(logger.messages.join(), isNot(contains(raw)));
    });
  }

  test('storage failures pass through', () async {
    secure
      ..failNext(const Failure.storage(), on: 'read')
      ..failNext(const Failure.storage(), on: 'write')
      ..failNext(const Failure.storage(), on: 'delete');
    expect(expectErr(await store.read()), const Failure.storage());
    expect(
      expectErr(
        await store.write(
          SessionToken(token: 't', expiresAt: DateTime.utc(2026)),
        ),
      ),
      const Failure.storage(),
    );
    expect(expectErr(await store.clear()), const Failure.storage());
  });
}
