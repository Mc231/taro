import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/services/review/review_prompt_ledger.dart';

void main() {
  test('the keys are the GLOSSARY §12 names', () {
    expect(SecureKeys.all, [
      'taro.install_id',
      'taro.install_secret',
      'taro.session_token',
      'taro.purchase_binding',
      'taro.attest_key_id',
      'taro.review_prompt',
      'taro.home_first_run_done',
      'taro.update_notice_version',
    ]);
    expect(SecureKeys.installId, 'taro.install_id');
    expect(SecureKeys.installSecret, 'taro.install_secret');
    expect(SecureKeys.sessionToken, 'taro.session_token');
    expect(SecureKeys.purchaseBinding, 'taro.purchase_binding');
    expect(SecureKeys.attestKeyId, 'taro.attest_key_id');
    expect(SecureKeys.reviewPrompt, 'taro.review_prompt');
  });

  test('the review ledger writes under the same key', () {
    expect(SecureStoreReviewPromptLedger.key, SecureKeys.reviewPrompt);
  });

  test('the S05 notices write under the same keys', () {
    expect(HomeNoticeKeys.firstRunDone, SecureKeys.homeFirstRunDone);
    expect(HomeNoticeKeys.updateNoticeVersion, SecureKeys.updateNoticeVersion);
  });
}
