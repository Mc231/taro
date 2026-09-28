import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runConsentServiceContract(
    () => FakeConsentService(status: AdsConsentStatus.required),
  );
  runConsentServiceContract(FakeConsentService.new);

  test('the form is shown only while consent is required', () async {
    final ump = FakeConsentService(status: AdsConsentStatus.required);
    expect((await ump.current()).canRequestAds, isFalse);
    final gathered = await ump.gather(debugEea: true);
    expect(gathered.canRequestAds, isTrue);
    await ump.gather();
    await ump.showPrivacyOptions();
    expect(ump.formsShown, 1);
    expect(ump.privacyOptionsShown, 1);
    expect(ump.debugEeaRequests, [true, false]);
  });
}
