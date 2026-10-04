import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/attestation/platform_attestation_service.dart';
import 'package:taro_attestation/taro_attestation.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/capturing_logger.dart';
import 'support/fake_native_attestation.dart';

const _cloudProjectNumber = '123456789012';
const _installId = '3f1c2b1e-0000-4000-8000-000000000001';

List<int> _sha256(String value) => sha256.convert(utf8.encode(value)).bytes;

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Matcher _attestationFailure(AttestationFailureKind kind) =>
    equals(Result<Object?>.err(Failure.attestation(kind: kind)).failureOrNull);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapturingLogger logger;

  setUp(() => logger = CapturingLogger());

  PlatformAttestationService service(
    TargetPlatform platform, {
    String cloudProjectNumber = _cloudProjectNumber,
  }) => PlatformAttestationService(
    cloudProjectNumber: cloudProjectNumber,
    platform: platform,
    logger: logger,
  );

  /// Logs name the operation and kind only (never keys, tokens or IDs).
  void expectCleanLogs() {
    for (final message in logger.messages) {
      expect(message, isNot(contains(_installId)));
      expect(message, isNot(contains(FakeNativeAttestation.id)));
      expect(message, isNot(contains('key-')));
      expect(message, isNot(contains('token')));
    }
  }

  group('contract', () {
    group('iOS with App Attest', () {
      setUp(() => FakeNativeAttestation.ios().install());
      runAttestationServiceContract(() => service(TargetPlatform.iOS));
    });
    group('iOS simulator', () {
      setUp(() => FakeNativeAttestation.ios(supported: false).install());
      runAttestationServiceContract(() => service(TargetPlatform.iOS));
    });
    group('Android with Play services', () {
      setUp(() => FakeNativeAttestation.android().install());
      runAttestationServiceContract(() => service(TargetPlatform.android));
    });
    group('Android without Play services', () {
      setUp(() {
        FakeNativeAttestation.android()
          ..failNext('prepareStandard', 'unsupported')
          ..install();
      });
      runAttestationServiceContract(() => service(TargetPlatform.android));
    });
    group('another OS', () {
      setUp(() => FakeNativeAttestation.ios().install());
      runAttestationServiceContract(() => service(TargetPlatform.linux));
    });
  });

  group('iOS', () {
    late FakeNativeAttestation native;
    late PlatformAttestationService attestation;

    setUp(() {
      native = FakeNativeAttestation.ios()..install();
      attestation = service(TargetPlatform.iOS);
    });

    test('isSupported is settled by the warm-up', () async {
      expect(attestation.isSupported, isFalse);
      await attestation.warmUp();
      await attestation.warmUp();
      expect(attestation.isSupported, isTrue);
      expect(native.callsOf('isSupported'), hasLength(1));
    });

    test('a failing support probe is unsupported', () async {
      native.failNext('isSupported', 'transient');
      await attestation.warmUp();
      expect(attestation.isSupported, isFalse);
      expect(logger.logged('attestation isSupported failed: transient'), true);
    });

    test('attest binds challenge, install ID and DeviceCheck token', () async {
      const signal = DeviceSignal(deviceCheckToken: 'DC+token/=');
      final blob = (await attestation.attest(
        challenge: 'chal-1',
        installId: _installId,
        signal: signal,
      )).valueOrNull!;

      expect(blob.type, AttestationType.appAttest);
      expect(blob.keyId, 'key-1');
      expect(blob.payload, base64.encode([0xA1, 0x01, 0xFF]));
      final attestCall = native.callsOf('attestKey').single;
      expect(attestCall.arguments, {
        'keyId': 'key-1',
        'clientDataHash': Uint8List.fromList(
          _sha256('chal-1${_installId}DC+token/='),
        ),
      });
    });

    test(
      'attest without a DeviceCheck token hashes the empty string',
      () async {
        await attestation.attest(
          challenge: 'c',
          installId: _installId,
          signal: const DeviceSignal(),
        );
        expect(
          native.callsOf('attestKey').single.arguments,
          containsPair(
            'clientDataHash',
            Uint8List.fromList(_sha256('c$_installId')),
          ),
        );
      },
    );

    for (final kind in AttestationErrorKind.values) {
      test('generateKey ${kind.name} -> AttestationFailure', () async {
        native.failNext('generateKey', kind.name);
        final result = await attestation.attest(
          challenge: 'c',
          installId: _installId,
          signal: const DeviceSignal(),
        );
        expect(
          result.failureOrNull,
          _attestationFailure(PlatformAttestationService.failureKindOf(kind)),
        );
        expect(native.callsOf('attestKey'), isEmpty);
        expectCleanLogs();
      });

      test('attestKey ${kind.name} -> AttestationFailure', () async {
        native.failNext('attestKey', kind.name);
        final result = await attestation.attest(
          challenge: 'c',
          installId: _installId,
          signal: const DeviceSignal(),
        );
        expect(
          result.failureOrNull,
          _attestationFailure(PlatformAttestationService.failureKindOf(kind)),
        );
      });

      test('generateAssertion ${kind.name} -> AttestationFailure', () async {
        native.failNext('generateAssertion', kind.name);
        final result = await attestation.assert_(
          clientDataHash: List.filled(32, 1),
          keyId: 'key-9',
        );
        expect(
          result.failureOrNull,
          _attestationFailure(PlatformAttestationService.failureKindOf(kind)),
        );
        expect(
          logger.logged(
            'attestation assert failed: ${kind.name}',
            level: LogLevel.severe,
          ),
          true,
        );
        expectCleanLogs();
      });
    }

    test('assert_ signs the hash with the stored key (aa1.)', () async {
      final hash = List<int>.generate(32, (i) => i);
      final blob = (await attestation.assert_(
        clientDataHash: hash,
        keyId: 'key-9',
      )).valueOrNull!;
      expect(blob.header, 'aa1.${base64.encode([0xB2, 0xFE])}');
      expect(native.callsOf('generateAssertion').single.arguments, {
        'keyId': 'key-9',
        'clientDataHash': Uint8List.fromList(hash),
      });
    });

    test('assert_ without a key sends none (a low-trust install keeps '
        'reading, BE4)', () async {
      for (final keyId in [null, '']) {
        final result = await attestation.assert_(
          clientDataHash: List.filled(32, 1),
          keyId: keyId,
        );
        expect(result.valueOrNull?.header, 'none');
      }
      expect(native.callsOf('generateAssertion'), isEmpty);
    });

    test('deviceSignal is the base64 DeviceCheck token', () async {
      final signal = await attestation.deviceSignal();
      expect(signal.deviceCheckToken, base64.encode([0x0D, 0x0C, 0xFB]));
      expect(signal.deviceKey, isNull);
    });

    test('a DeviceCheck failure is an empty signal', () async {
      native.failNext('deviceCheckToken', 'unsupported');
      expect(await attestation.deviceSignal(), const DeviceSignal());
      expect(
        logger.logged('attestation deviceSignal failed: unsupported'),
        true,
      );
    });

    test('an unsupported device answers none without native calls', () async {
      native.supported = false;
      final blob = (await attestation.attest(
        challenge: 'c',
        installId: _installId,
        signal: const DeviceSignal(),
      )).valueOrNull!;
      expect(
        blob,
        const AttestationBlob(type: AttestationType.none, challenge: 'c'),
      );
      expect(
        (await attestation.assert_(
          clientDataHash: [1],
          keyId: 'k',
        )).valueOrNull,
        const AssertionBlob(header: 'none'),
      );
      expect(native.calls.map((c) => c.method), ['isSupported']);
    });
  });

  group('Android', () {
    late FakeNativeAttestation native;
    late PlatformAttestationService attestation;

    setUp(() {
      native = FakeNativeAttestation.android()..install();
      attestation = service(TargetPlatform.android);
    });

    test('the warm-up prepares the Standard provider once', () async {
      await Future.wait([attestation.warmUp(), attestation.warmUp()]);
      await attestation.assert_(clientDataHash: [1]);
      expect(attestation.isSupported, isTrue);
      expect(native.callsOf('prepareStandard').single.arguments, {
        'cloudProjectNumber': 123456789012,
      });
    });

    test(
      'the device key is base64url(SHA-256("taro-device-v1" ‖ ANDROID_ID))',
      () async {
        final expected = _base64Url(
          _sha256('taro-device-v1${FakeNativeAttestation.id}'),
        );
        final signal = await attestation.deviceSignal();
        expect(signal.deviceKey, expected);
        expect(signal.deviceKey, isNot(contains('=')));
        expect(signal.deviceKey, hasLength(43));
        expect(signal.deviceCheckToken, isNull);
        expect(
          PlatformAttestationService.deviceKeyOf(FakeNativeAttestation.id),
          expected,
        );
        // Cached: ANDROID_ID is read once.
        await attestation.deviceSignal();
        expect(native.callsOf('androidId'), hasLength(1));
      },
    );

    test('a known device-key vector', () {
      // SHA-256("taro-device-v1" ‖ "0123456789abcdef"), base64url unpadded.
      expect(
        PlatformAttestationService.deviceKeyOf('0123456789abcdef'),
        _base64Url(
          sha256.convert(utf8.encode('taro-device-v10123456789abcdef')).bytes,
        ),
      );
    });

    test('no ANDROID_ID is an empty signal', () async {
      native.androidId = null;
      expect(await attestation.deviceSignal(), const DeviceSignal());
    });

    test('an ANDROID_ID failure is an empty signal', () async {
      native.failNext('androidId', 'transient');
      expect(await attestation.deviceSignal(), const DeviceSignal());
      expect(logger.logged('attestation deviceSignal failed: transient'), true);
      expectCleanLogs();
    });

    test(
      'registration binds challenge, install ID and device key (RC87)',
      () async {
        final signal = await attestation.deviceSignal();
        final blob = (await attestation.attest(
          challenge: 'chal-1',
          installId: _installId,
          signal: signal,
        )).valueOrNull!;
        final requestHash = _base64Url(
          _sha256('chal-1$_installId${signal.deviceKey}'),
        );
        expect(blob.type, AttestationType.playIntegrity);
        expect(blob.keyId, isNull);
        expect(blob.payload, 'token.$requestHash');
        expect(
          native.callsOf('requestStandardToken').single.arguments,
          {'requestHash': requestHash},
        );
      },
    );

    test('registration without a device key hashes the empty string', () async {
      final blob = (await attestation.attest(
        challenge: 'c',
        installId: _installId,
        signal: const DeviceSignal(),
      )).valueOrNull!;
      expect(blob.payload, 'token.${_base64Url(_sha256('c$_installId'))}');
    });

    test(
      'each call sends pi1.<token> over base64url(clientDataHash)',
      () async {
        final hash = List<int>.generate(32, (i) => 255 - i);
        final blob = (await attestation.assert_(
          clientDataHash: hash,
        )).valueOrNull!;
        expect(blob.header, 'pi1.token.${_base64Url(hash)}');
      },
    );

    for (final kind in AttestationErrorKind.values) {
      test('requestStandardToken ${kind.name} -> AttestationFailure', () async {
        native.failNext('requestStandardToken', kind.name, count: 2);
        final expected = _attestationFailure(
          PlatformAttestationService.failureKindOf(kind),
        );
        expect(
          (await attestation.assert_(clientDataHash: [1])).failureOrNull,
          expected,
        );
        expect(
          (await attestation.attest(
            challenge: 'c',
            installId: _installId,
            signal: const DeviceSignal(),
          )).failureOrNull,
          expected,
        );
        expectCleanLogs();
      });
    }

    test('a transient warm-up failure is retried by the next call', () async {
      native.failNext('prepareStandard', 'transient');
      await attestation.warmUp();
      expect(attestation.isSupported, isTrue);

      final blob = (await attestation.assert_(clientDataHash: [1])).valueOrNull;
      expect(blob?.header, startsWith('pi1.'));
      expect(native.callsOf('prepareStandard'), hasLength(2));
    });

    test(
      'a call that cannot prepare fails transient without a token request',
      () async {
        native.failNext('prepareStandard', 'quota', count: 2);
        final result = await attestation.assert_(clientDataHash: [1]);
        expect(
          result.failureOrNull,
          _attestationFailure(AttestationFailureKind.transient),
        );
        expect(native.callsOf('requestStandardToken'), isEmpty);
        expect(attestation.isSupported, isTrue);
      },
    );

    test('concurrent calls share one prepare', () async {
      native.failNext('prepareStandard', 'transient');
      await attestation.warmUp();
      await Future.wait([
        attestation.assert_(clientDataHash: [1]),
        attestation.assert_(clientDataHash: [2]),
      ]);
      expect(native.callsOf('prepareStandard'), hasLength(2));
      expect(native.callsOf('requestStandardToken'), hasLength(2));
    });

    for (final code in ['unsupported', 'rejected']) {
      test('a $code warm-up turns attestation off (low trust)', () async {
        native.failNext('prepareStandard', code);
        await attestation.warmUp();
        expect(attestation.isSupported, isFalse);
        expect(
          (await attestation.assert_(clientDataHash: [1])).valueOrNull,
          const AssertionBlob(header: 'none'),
        );
        expect(native.callsOf('requestStandardToken'), isEmpty);
      });
    }

    test('no Play services is unsupported', () async {
      native.supported = false;
      await attestation.warmUp();
      expect(attestation.isSupported, isFalse);
      expect(native.callsOf('prepareStandard'), isEmpty);
    });

    for (final number in ['', ' ', 'abc', '0', '-5']) {
      test('cloud project number "$number" is unsupported', () async {
        final unconfigured = service(
          TargetPlatform.android,
          cloudProjectNumber: number,
        );
        await unconfigured.warmUp();
        expect(unconfigured.isSupported, isFalse);
        expect(native.calls, isEmpty);
        expect(logger.logged('no Play cloud project number'), isTrue);
      });
    }

    test(
      'surrounding spaces in the cloud project number are ignored',
      () async {
        await service(
          TargetPlatform.android,
          cloudProjectNumber: ' 42 ',
        ).warmUp();
        expect(native.callsOf('prepareStandard').single.arguments, {
          'cloudProjectNumber': 42,
        });
      },
    );
  });

  group('another OS', () {
    test('is unsupported, with no device signal', () async {
      final native = FakeNativeAttestation.ios()..install();
      final attestation = service(TargetPlatform.macOS);
      await attestation.warmUp();
      expect(attestation.isSupported, isFalse);
      expect(await attestation.deviceSignal(), const DeviceSignal());
      expect(native.calls, isEmpty);
    });
  });

  test('the default platform and plugin are used when not injected', () async {
    FakeNativeAttestation.ios().install();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final attestation = PlatformAttestationService(cloudProjectNumber: '');
    await attestation.warmUp();
    expect(attestation.isSupported, isTrue);
  });

  test('every plugin error kind maps to the core kind of the same name', () {
    for (final kind in AttestationErrorKind.values) {
      expect(PlatformAttestationService.failureKindOf(kind).name, kind.name);
    }
    expect(
      AttestationErrorKind.values.map((k) => k.name),
      AttestationFailureKind.values.map((k) => k.name),
    );
  });
}
