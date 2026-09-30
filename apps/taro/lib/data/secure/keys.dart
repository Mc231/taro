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

  /// The in-app review policy state (JSON, 01 §6.1). Owned by the services
  /// layer (`SecureStoreReviewPromptLedger`), which declares the same literal
  /// because `services/` may not import `data/`.
  static const String reviewPrompt = 'taro.review_prompt';

  /// `1` once the S05 first-run coachmark was dismissed. Owned by
  /// `features/home/` (`HomeNoticeKeys`), which declares the same literal.
  static const String homeFirstRunDone = 'taro.home_first_run_done';

  /// The `app.recommendedVersion` whose S05 update notice was shown (RC73;
  /// `HomeNoticeKeys`).
  static const String updateNoticeVersion = 'taro.update_notice_version';

  /// Every key, in the 02 §6.2 order.
  static List<String> get all => const [
    installId,
    installSecret,
    sessionToken,
    purchaseBinding,
    attestKeyId,
    reviewPrompt,
    homeFirstRunDone,
    updateNoticeVersion,
  ];
}
