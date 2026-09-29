import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/install/install_secret.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  test('32 random bytes, base64url without padding', () {
    final secret = generateInstallSecret(SeededRandomSource(1));
    expect(secret, hasLength(43));
    expect(secret, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(base64Url.decode('$secret='), hasLength(kInstallSecretBytes));
  });

  test('comes from the random source', () {
    expect(
      generateInstallSecret(SeededRandomSource(1)),
      generateInstallSecret(SeededRandomSource(1)),
    );
    expect(
      generateInstallSecret(SeededRandomSource(1)),
      isNot(generateInstallSecret(SeededRandomSource(2))),
    );
  });
}
