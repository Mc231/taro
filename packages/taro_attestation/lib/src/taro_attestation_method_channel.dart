import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:taro_attestation/src/attestation_error.dart';
import 'package:taro_attestation/src/taro_attestation_platform_interface.dart';

/// [TaroAttestationPlatform] over the `taro_attestation` method channel.
///
/// The native side answers errors with a `PlatformException` whose code is
/// an [AttestationErrorKind] name (`unsupported`, `keyInvalidated`,
/// `rejected`, `quota`, `transient`). A method the platform does not
/// implement (an iOS method on Android and vice versa) or a missing plugin
/// is `unsupported`; an unknown code or an empty answer is `transient`.
class MethodChannelTaroAttestation extends TaroAttestationPlatform {
  /// The method channel used to talk to the native side.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('taro_attestation');

  @override
  Future<bool> isSupported() async =>
      await _invoke<bool>('isSupported') ?? false;

  @override
  Future<String> generateKey() async =>
      _required(await _invoke<String>('generateKey'));

  @override
  Future<Uint8List> attestKey(String keyId, Uint8List clientDataHash) async =>
      _required(
        await _invoke<Uint8List>('attestKey', {
          'keyId': keyId,
          'clientDataHash': clientDataHash,
        }),
      );

  @override
  Future<Uint8List> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  ) async => _required(
    await _invoke<Uint8List>('generateAssertion', {
      'keyId': keyId,
      'clientDataHash': clientDataHash,
    }),
  );

  @override
  Future<Uint8List> deviceCheckToken() async =>
      _required(await _invoke<Uint8List>('deviceCheckToken'));

  @override
  Future<void> prepareStandard(int cloudProjectNumber) =>
      _invoke<void>('prepareStandard', {
        'cloudProjectNumber': cloudProjectNumber,
      });

  @override
  Future<String> requestStandardToken(String requestHash) async => _required(
    await _invoke<String>('requestStandardToken', {
      'requestHash': requestHash,
    }),
  );

  @override
  Future<String?> androidId() async {
    final id = await _invoke<String>('androidId');
    return id == null || id.isEmpty ? null : id;
  }

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw TaroAttestationException(
        AttestationErrorKind.fromCode(e.code),
        e.message,
      );
    } on MissingPluginException catch (e) {
      throw TaroAttestationException(
        AttestationErrorKind.unsupported,
        e.message,
      );
    }
  }

  static T _required<T>(T? value) {
    if (value == null) {
      throw const TaroAttestationException(
        AttestationErrorKind.transient,
        'empty native answer',
      );
    }
    return value;
  }
}
