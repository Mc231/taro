import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/secure/keys.dart';

void main() {
  test('the keys are the GLOSSARY §12 names', () {
    expect(SecureKeys.all, [
      'taro.install_id',
      'taro.install_secret',
      'taro.session_token',
      'taro.purchase_binding',
      'taro.attest_key_id',
    ]);
    expect(SecureKeys.installId, 'taro.install_id');
    expect(SecureKeys.installSecret, 'taro.install_secret');
    expect(SecureKeys.sessionToken, 'taro.session_token');
    expect(SecureKeys.purchaseBinding, 'taro.purchase_binding');
    expect(SecureKeys.attestKeyId, 'taro.attest_key_id');
  });
}
