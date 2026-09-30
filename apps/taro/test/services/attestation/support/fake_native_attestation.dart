import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The native side of `taro_attestation` behind a method-channel mock: an
/// iPhone (App Attest + DeviceCheck) or an Android phone (Play Integrity
/// Standard + ANDROID_ID). Methods of the other platform answer
/// `notImplemented` (a `MissingPluginException` on the Dart side).
final class FakeNativeAttestation {
  /// An iPhone; [supported] = App Attest available.
  FakeNativeAttestation.ios({this.supported = true}) : android = false;

  /// An Android phone with Play services ([supported]).
  FakeNativeAttestation.android({this.supported = true, this.androidId = id})
    : android = true;

  /// The ANDROID_ID of [FakeNativeAttestation.android] by default.
  static const String id = '9774d56d682e549c';

  /// The platform channel.
  static const MethodChannel channel = MethodChannel('taro_attestation');

  /// Whether this is the Android side.
  final bool android;

  /// What `isSupported` answers.
  bool supported;

  /// What `androidId` answers.
  String? androidId;

  /// Every call, oldest first.
  final List<MethodCall> calls = [];

  final Map<String, List<String>> _failures = {};

  /// The next [count] calls of [method] fail with the channel error [code].
  void failNext(String method, String code, {int count = 1}) =>
      _failures.putIfAbsent(method, () => []).addAll(List.filled(count, code));

  /// Calls of [method].
  List<MethodCall> callsOf(String method) =>
      calls.where((c) => c.method == method).toList();

  /// Installs the handler; removed on tear-down.
  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(channel, _handle);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final pending = _failures[call.method];
    if (pending != null && pending.isNotEmpty) {
      throw PlatformException(code: pending.removeAt(0), message: 'native');
    }
    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    return android ? _android(call.method, args) : _ios(call.method, args);
  }

  Object? _ios(String method, Map<Object?, Object?> args) => switch (method) {
    'isSupported' => supported,
    'generateKey' => 'key-${callsOf('generateKey').length}',
    'attestKey' => Uint8List.fromList([0xA1, 0x01, 0xFF]),
    'generateAssertion' => Uint8List.fromList([0xB2, 0xFE]),
    'deviceCheckToken' => Uint8List.fromList([0x0D, 0x0C, 0xFB]),
    _ => throw MissingPluginException(),
  };

  Object? _android(String method, Map<Object?, Object?> args) =>
      switch (method) {
        'isSupported' => supported,
        'prepareStandard' => null,
        'requestStandardToken' => 'token.${args['requestHash']}',
        'androidId' => androidId,
        _ => throw MissingPluginException(),
      };
}
