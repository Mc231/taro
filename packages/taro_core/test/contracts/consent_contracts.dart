import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// The `ConsentService` (UMP) contract (02 §9.7, RC19). [create] returns a
/// service for a device whose form, when shown, is answered.
void runConsentServiceContract(ConsentService Function() create) {
  group('ConsentService contract', () {
    late ConsentService consent;

    setUp(() => consent = create());

    test('current does not change the state', () async {
      final a = await consent.current();
      final b = await consent.current();
      expect(b, a);
    });

    test('gather resolves consent and current then agrees', () async {
      final gathered = await consent.gather();
      expect(gathered.status, isNot(AdsConsentStatus.unknown));
      expect(await consent.current(), gathered);
    });

    test(
      'ads can be requested only with obtained or unneeded consent',
      () async {
        final gathered = await consent.gather();
        if (gathered.canRequestAds) {
          expect(
            gathered.status,
            anyOf(
              AdsConsentStatus.obtained,
              AdsConsentStatus.notRequired,
            ),
          );
        }
      },
    );

    test('gather is idempotent once resolved', () async {
      final first = await consent.gather();
      expect(await consent.gather(), first);
    });

    test('showPrivacyOptions completes', () async {
      await consent.gather();
      await consent.showPrivacyOptions();
    });
  });
}

/// The `TrackingAuthorization` (ATT) contract (02 §9.7). [create] returns
/// an undecided device.
void runTrackingAuthorizationContract(
  TrackingAuthorization Function() create,
) {
  group('TrackingAuthorization contract', () {
    late TrackingAuthorization att;

    setUp(() => att = create());

    test('status does not prompt', () async {
      final a = await att.status();
      expect(await att.status(), a);
    });

    test('request decides once; status then agrees', () async {
      final decided = await att.request();
      expect(await att.status(), decided);
      expect(await att.request(), decided);
    });
  });
}
