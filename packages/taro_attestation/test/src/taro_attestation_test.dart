import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taro_attestation/taro_attestation.dart';

/// Records the facade's calls and answers with fixed values.
class _RecordingPlatform
    with MockPlatformInterfaceMixin
    implements TaroAttestationPlatform {
  final List<String> calls = [];

  @override
  Future<bool> isSupported() async {
    calls.add('isSupported');
    return true;
  }

  @override
  Future<String> generateKey() async {
    calls.add('generateKey');
    return 'key';
  }

  @override
  Future<Uint8List> attestKey(String keyId, Uint8List clientDataHash) async {
    calls.add('attestKey $keyId ${clientDataHash.length}');
    return Uint8List.fromList([1]);
  }

  @override
  Future<Uint8List> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  ) async {
    calls.add('generateAssertion $keyId ${clientDataHash.length}');
    return Uint8List.fromList([2]);
  }

  @override
  Future<Uint8List> deviceCheckToken() async {
    calls.add('deviceCheckToken');
    return Uint8List.fromList([3]);
  }

  @override
  Future<void> prepareStandard(int cloudProjectNumber) async {
    calls.add('prepareStandard $cloudProjectNumber');
  }

  @override
  Future<String> requestStandardToken(String requestHash) async {
    calls.add('requestStandardToken $requestHash');
    return 'token';
  }

  @override
  Future<String?> androidId() async {
    calls.add('androidId');
    return 'a1';
  }
}

class _BarePlatform extends TaroAttestationPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = TaroAttestationPlatform.instance;
  final hash = Uint8List.fromList(List.filled(32, 9));

  tearDown(() => TaroAttestationPlatform.instance = initialPlatform);

  test('MethodChannelTaroAttestation is the default instance', () {
    expect(initialPlatform, isA<MethodChannelTaroAttestation>());
  });

  test('TaroAttestation delegates every call to the platform', () async {
    final platform = _RecordingPlatform();
    TaroAttestationPlatform.instance = platform;
    const plugin = TaroAttestation();

    expect(await plugin.isSupported(), isTrue);
    expect(await plugin.generateKey(), 'key');
    expect(await plugin.attestKey('k', hash), [1]);
    expect(await plugin.generateAssertion('k', hash), [2]);
    expect(await plugin.deviceCheckToken(), [3]);
    await plugin.prepareStandard(42);
    expect(await plugin.requestStandardToken('h'), 'token');
    expect(await plugin.androidId(), 'a1');
    expect(platform.calls, [
      'isSupported',
      'generateKey',
      'attestKey k 32',
      'generateAssertion k 32',
      'deviceCheckToken',
      'prepareStandard 42',
      'requestStandardToken h',
      'androidId',
    ]);
  });

  test('the base platform implements nothing', () {
    final bare = _BarePlatform();
    expect(bare.isSupported, throwsUnimplementedError);
    expect(bare.generateKey, throwsUnimplementedError);
    expect(() => bare.attestKey('k', hash), throwsUnimplementedError);
    expect(() => bare.generateAssertion('k', hash), throwsUnimplementedError);
    expect(bare.deviceCheckToken, throwsUnimplementedError);
    expect(() => bare.prepareStandard(1), throwsUnimplementedError);
    expect(() => bare.requestStandardToken('h'), throwsUnimplementedError);
    expect(bare.androidId, throwsUnimplementedError);
  });

  group('AttestationErrorKind', () {
    test('parses every native code', () {
      for (final kind in AttestationErrorKind.values) {
        expect(AttestationErrorKind.fromCode(kind.name), kind);
      }
    });

    test('an unknown code is transient', () {
      expect(
        AttestationErrorKind.fromCode('somethingElse'),
        AttestationErrorKind.transient,
      );
    });

    test('the exception names its kind and message', () {
      expect(
        const TaroAttestationException(AttestationErrorKind.quota).toString(),
        'TaroAttestationException(quota)',
      );
      expect(
        const TaroAttestationException(
          AttestationErrorKind.rejected,
          'bad input',
        ).toString(),
        'TaroAttestationException(rejected): bad input',
      );
    });
  });

  group('MethodChannelTaroAttestation', () {
    final platform = MethodChannelTaroAttestation();
    const channel = MethodChannel('taro_attestation');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;

    void answer(Object? Function(MethodCall call) handler) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });
    }

    setUp(() => calls = []);
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('sends each method with its arguments', () async {
      answer(
        (call) => switch (call.method) {
          'isSupported' => true,
          'generateKey' => 'key-1',
          'attestKey' => Uint8List.fromList([1, 2]),
          'generateAssertion' => Uint8List.fromList([3]),
          'deviceCheckToken' => Uint8List.fromList([4]),
          'prepareStandard' => null,
          'requestStandardToken' => 'pi-token',
          'androidId' => '9774d56d682e549c',
          _ => throw MissingPluginException(),
        },
      );

      expect(await platform.isSupported(), isTrue);
      expect(await platform.generateKey(), 'key-1');
      expect(await platform.attestKey('key-1', hash), [1, 2]);
      expect(await platform.generateAssertion('key-1', hash), [3]);
      expect(await platform.deviceCheckToken(), [4]);
      await platform.prepareStandard(123456789012);
      expect(await platform.requestStandardToken('abc_-'), 'pi-token');
      expect(await platform.androidId(), '9774d56d682e549c');

      expect(calls.map((c) => c.method), [
        'isSupported',
        'generateKey',
        'attestKey',
        'generateAssertion',
        'deviceCheckToken',
        'prepareStandard',
        'requestStandardToken',
        'androidId',
      ]);
      expect(calls[2].arguments, {'keyId': 'key-1', 'clientDataHash': hash});
      expect(calls[3].arguments, {'keyId': 'key-1', 'clientDataHash': hash});
      expect(calls[5].arguments, {'cloudProjectNumber': 123456789012});
      expect(calls[6].arguments, {'requestHash': 'abc_-'});
    });

    test('a null isSupported answer is false', () async {
      answer((_) => null);
      expect(await platform.isSupported(), isFalse);
    });

    test('a null or empty ANDROID_ID is null', () async {
      answer((_) => null);
      expect(await platform.androidId(), isNull);
      answer((_) => '');
      expect(await platform.androidId(), isNull);
    });

    group('an empty answer is transient', () {
      final cases = <String, Future<Object?> Function()>{
        'generateKey': platform.generateKey,
        'attestKey': () => platform.attestKey('k', hash),
        'generateAssertion': () => platform.generateAssertion('k', hash),
        'deviceCheckToken': platform.deviceCheckToken,
        'requestStandardToken': () => platform.requestStandardToken('h'),
      };
      for (final MapEntry(key: method, value: call) in cases.entries) {
        test(method, () async {
          answer((_) => null);
          await expectLater(
            call(),
            throwsA(
              isA<TaroAttestationException>()
                  .having((e) => e.kind, 'kind', AttestationErrorKind.transient)
                  .having((e) => e.message, 'message', 'empty native answer'),
            ),
          );
        });
      }
    });

    // Every native error code of every method maps to its kind (Sprint
    // 12.1: "every error mapping").
    final methods = <String, Future<Object?> Function()>{
      'isSupported': platform.isSupported,
      'generateKey': platform.generateKey,
      'attestKey': () => platform.attestKey('k', hash),
      'generateAssertion': () => platform.generateAssertion('k', hash),
      'deviceCheckToken': platform.deviceCheckToken,
      'prepareStandard': () => platform.prepareStandard(1),
      'requestStandardToken': () => platform.requestStandardToken('h'),
      'androidId': platform.androidId,
    };
    final codes = <String, AttestationErrorKind>{
      for (final kind in AttestationErrorKind.values) kind.name: kind,
      'invalidArgs': AttestationErrorKind.transient,
      'UNKNOWN': AttestationErrorKind.transient,
    };
    for (final MapEntry(key: method, value: call) in methods.entries) {
      group(method, () {
        for (final MapEntry(key: code, value: kind) in codes.entries) {
          test('PlatformException($code) -> ${kind.name}', () async {
            answer(
              (_) => throw PlatformException(code: code, message: 'native'),
            );
            await expectLater(
              call(),
              throwsA(
                isA<TaroAttestationException>()
                    .having((e) => e.kind, 'kind', kind)
                    .having((e) => e.message, 'message', 'native'),
              ),
            );
          });
        }

        test('not implemented natively -> unsupported', () async {
          answer((_) => throw MissingPluginException('not here'));
          await expectLater(
            call(),
            throwsA(
              isA<TaroAttestationException>().having(
                (e) => e.kind,
                'kind',
                AttestationErrorKind.unsupported,
              ),
            ),
          );
        });
      });
    }

    test('no registered plugin -> unsupported', () async {
      messenger.setMockMethodCallHandler(channel, null);
      await expectLater(
        platform.generateKey(),
        throwsA(
          isA<TaroAttestationException>().having(
            (e) => e.kind,
            'kind',
            AttestationErrorKind.unsupported,
          ),
        ),
      );
    });
  });
}
