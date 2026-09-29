/// The secure-storage keys (02 §6.2, GLOSSARY §12). Values are never
/// exported, logged or sent to analytics.
abstract final class SecureKeys {
  /// The install UUIDv4.
  static const String installId = 'taro.install_id';

  /// 32 random bytes, base64url; sent only in `POST /v1/installs` (RC54).
  static const String installSecret = 'taro.install_secret';

  /// The Worker `installToken` and its `expiresAt` (JSON).
  static const String sessionToken = 'taro.session_token';

  /// The App Attest key ID (iOS only).
  static const String attestKeyId = 'taro.attest_key_id';

  /// The registration `purchaseBinding` (JSON, RC9, RC85).
  static const String purchaseBinding = 'taro.purchase_binding';

  /// Every key, in the 02 §6.2 order.
  static List<String> get all => const [
    installId,
    installSecret,
    sessionToken,
    purchaseBinding,
    attestKeyId,
  ];
}
