import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taro_attestation/taro_attestation.dart';

class _FakePlatform
    with MockPlatformInterfaceMixin
    implements TaroAttestationPlatform {
  @override
  Future<String?> getPlatformVersion() async => '42';
}

class _BarePlatform extends TaroAttestationPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialPlatform = TaroAttestationPlatform.instance;

  tearDown(() => TaroAttestationPlatform.instance = initialPlatform);

  test('MethodChannelTaroAttestation is the default instance', () {
    expect(initialPlatform, isA<MethodChannelTaroAttestation>());
  });

  test('TaroAttestation delegates to the platform instance', () async {
    TaroAttestationPlatform.instance = _FakePlatform();
    expect(await TaroAttestation().getPlatformVersion(), '42');
  });

  test('base platform throws UnimplementedError', () {
    expect(
      () => _BarePlatform().getPlatformVersion(),
      throwsUnimplementedError,
    );
  });

  group('MethodChannelTaroAttestation', () {
    final platform = MethodChannelTaroAttestation();
    const channel = MethodChannel('taro_attestation');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      messenger.setMockMethodCallHandler(channel, (call) async => 'iOS 26');
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('getPlatformVersion invokes the channel', () async {
      expect(await platform.getPlatformVersion(), 'iOS 26');
    });
  });
}
