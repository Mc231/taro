import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
// The plugin's own codec, so the mock decodes ConsentRequestParameters.
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';
import 'package:taro/services/consent/ump_consent_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

final _channel = MethodChannel(
  'plugins.flutter.io/google_mobile_ads/ump',
  StandardMethodCodec(UserMessagingCodec()),
);

/// Android UMP status codes (the plugin maps them per platform).
const _unknown = 0;
const _notRequired = 1;
const _required = 2;
const _obtained = 3;

/// The native UMP SDK: [region] decides the status on the first update;
/// the form, while required, ends in `obtained` with [canRequestAfterForm].
final class _UmpPlatform {
  _UmpPlatform({this.region = _required});

  int region;
  int status = _unknown;
  bool canRequestAds = false;
  bool canRequestAfterForm = true;
  int privacyStatus = 1;
  bool failUpdate = false;
  bool failForm = false;
  bool failState = false;
  int formsShown = 0;
  int privacyShown = 0;
  final List<gma.ConsentRequestParameters> updates = [];

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'ConsentInformation#requestConsentInfoUpdate':
        final args = call.arguments as Map<Object?, Object?>;
        updates.add(args['params']! as gma.ConsentRequestParameters);
        if (failUpdate) throw PlatformException(code: '2', message: 'net');
        if (status == _unknown) {
          status = region;
          canRequestAds = region == _notRequired;
        }
        return null;
      case 'UserMessagingPlatform#loadAndShowConsentFormIfRequired':
        if (failForm) throw PlatformException(code: '5', message: 'form');
        if (status == _required) {
          formsShown++;
          status = _obtained;
          canRequestAds = canRequestAfterForm;
        }
        return null;
      case 'UserMessagingPlatform#showPrivacyOptionsForm':
        privacyShown++;
        if (failForm) throw PlatformException(code: '6');
        return null;
      case 'ConsentInformation#getConsentStatus':
        if (failState) throw PlatformException(code: 'state');
        return status;
      case 'ConsentInformation#canRequestAds':
        return canRequestAds;
      case 'ConsentInformation#getPrivacyOptionsRequirementStatus':
        return privacyStatus;
    }
    throw MissingPluginException(call.method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late _UmpPlatform platform;
  late CapturingLogger logger;

  void install(_UmpPlatform p) {
    platform = p;
    messenger.setMockMethodCallHandler(_channel, p.handle);
  }

  setUp(() {
    logger = CapturingLogger();
    install(_UmpPlatform());
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  group('contract', () {
    runConsentServiceContract(() {
      install(_UmpPlatform());
      return UmpConsentService(logger: CapturingLogger());
    });
    runConsentServiceContract(() {
      install(_UmpPlatform(region: _notRequired));
      return UmpConsentService(logger: CapturingLogger());
    });
  });

  test('EEA: the form is shown once, then ads may be requested', () async {
    final ump = UmpConsentService(logger: logger);
    final before = await ump.current();
    expect(before.status, AdsConsentStatus.unknown);
    expect(before.canRequestAds, isFalse);
    final gathered = await ump.gather();
    expect(
      gathered,
      const AdsConsent(
        status: AdsConsentStatus.obtained,
        canRequestAds: true,
        privacyOptionsRequired: true,
      ),
    );
    await ump.gather();
    expect(platform.formsShown, 1);
    expect(platform.updates, hasLength(2));
    expect(platform.updates.first.tagForUnderAgeOfConsent, isFalse);
    expect(platform.updates.first.consentDebugSettings, isNull);
  });

  test('a form answered without consent keeps ads off', () async {
    platform
      ..canRequestAfterForm = false
      ..privacyStatus = 0;
    final gathered = await UmpConsentService(logger: logger).gather();
    expect(gathered.status, AdsConsentStatus.obtained);
    expect(gathered.canRequestAds, isFalse);
    expect(gathered.privacyOptionsRequired, isFalse);
  });

  test('outside regulated regions no form is shown', () async {
    install(_UmpPlatform(region: _notRequired));
    final gathered = await UmpConsentService(logger: logger).gather();
    expect(gathered.status, AdsConsentStatus.notRequired);
    expect(gathered.canRequestAds, isTrue);
    expect(platform.formsShown, 0);
  });

  test('a failed update skips the form and returns the cached state', () async {
    platform
      ..failUpdate = true
      ..status = _obtained
      ..canRequestAds = true;
    final gathered = await UmpConsentService(logger: logger).gather();
    expect(gathered.status, AdsConsentStatus.obtained);
    expect(gathered.canRequestAds, isTrue);
    expect(platform.formsShown, 0);
    expect(logger.logged('ump update failed: 2'), isTrue);
  });

  test('a form error is logged; consent stays required', () async {
    platform.failForm = true;
    final gathered = await UmpConsentService(logger: logger).gather();
    expect(gathered.status, AdsConsentStatus.required);
    expect(gathered.canRequestAds, isFalse);
    expect(logger.logged('ump consent form failed: 5'), isTrue);
  });

  test('an unreadable state answers the default (no ads)', () async {
    platform.failState = true;
    expect(
      await UmpConsentService(logger: logger).current(),
      const AdsConsent(),
    );
    expect(logger.logged('ump state unavailable'), isTrue);
  });

  test('privacy options open the UMP form; errors are logged', () async {
    final ump = UmpConsentService(logger: logger);
    await ump.showPrivacyOptions();
    platform.failForm = true;
    await ump.showPrivacyOptions();
    expect(platform.privacyShown, 2);
    expect(logger.logged('ump privacy options failed: 6'), isTrue);
  });

  group('debug geography', () {
    test('is ignored unless allowed (prod)', () async {
      await UmpConsentService(logger: logger).gather(debugEea: true);
      expect(platform.updates.single.consentDebugSettings, isNull);
    });

    test('forces the EEA in non-prod builds', () async {
      await UmpConsentService(
        logger: logger,
        allowDebugGeography: true,
        debugTestDeviceIds: const ['HASH'],
      ).gather(debugEea: true);
      final debug = platform.updates.single.consentDebugSettings!;
      expect(debug.debugGeography, gma.DebugGeography.debugGeographyEea);
      expect(debug.testIdentifiers, ['HASH']);
    });
  });

  group('injected SDK calls', () {
    test('a throwing update or form is logged, not thrown', () async {
      final ump = UmpConsentService(
        logger: logger,
        info: _ThrowingInfo(),
        showPrivacyOptionsForm: () => throw StateError('no activity'),
      );
      expect(await ump.gather(), const AdsConsent());
      await ump.showPrivacyOptions();
      expect(logger.logged('ump update threw'), isTrue);
      expect(logger.logged('ump privacy options threw'), isTrue);
    });

    test('the form call runs after a successful update', () async {
      var shown = 0;
      final ump = UmpConsentService(
        logger: logger,
        loadAndShowIfRequired: () async {
          shown++;
          return null;
        },
      );
      await ump.gather();
      expect(shown, 1);
      expect(platform.formsShown, 0);
    });
  });

  test('mapConsentStatus covers every SDK status by name', () {
    for (final status in gma.ConsentStatus.values) {
      expect(mapConsentStatus(status).name, status.name);
    }
  });

  group('NoOpConsentService', () {
    runConsentServiceContract(NoOpConsentService.new);

    test('ads may always be requested', () async {
      // Non-const: the constructor line must run (06 QA2 per-file floor).
      // ignore: prefer_const_constructors
      final noOp = NoOpConsentService();
      const expected = AdsConsent(
        status: AdsConsentStatus.notRequired,
        canRequestAds: true,
      );
      expect(await noOp.gather(debugEea: true), expected);
      expect(await noOp.current(), expected);
      await noOp.showPrivacyOptions();
    });
  });
}

final class _ThrowingInfo implements gma.ConsentInformation {
  @override
  void requestConsentInfoUpdate(
    gma.ConsentRequestParameters params,
    gma.OnConsentInfoUpdateSuccessListener successListener,
    gma.OnConsentInfoUpdateFailureListener failureListener,
  ) => throw StateError('sdk missing');

  @override
  Future<bool> canRequestAds() => throw StateError('sdk missing');

  @override
  Future<gma.ConsentStatus> getConsentStatus() =>
      throw StateError('sdk missing');

  @override
  Future<gma.PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() => throw StateError('sdk missing');

  @override
  Future<bool> isConsentFormAvailable() => throw StateError('sdk missing');

  @override
  Future<void> reset() => throw StateError('sdk missing');
}
