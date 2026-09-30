import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taro_attestation/src/taro_attestation_method_channel.dart';

/// The interface that platform implementations of the plugin extend.
///
/// Every method throws only `TaroAttestationException`.
abstract class TaroAttestationPlatform extends PlatformInterface {
  /// Constructs a [TaroAttestationPlatform].
  TaroAttestationPlatform() : super(token: _token);

  static final Object _token = Object();

  static TaroAttestationPlatform _instance = MethodChannelTaroAttestation();

  /// The active implementation; defaults to [MethodChannelTaroAttestation].
  static TaroAttestationPlatform get instance => _instance;

  /// Replaces the active implementation (tests and platform packages).
  static set instance(TaroAttestationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// See `TaroAttestation.isSupported`.
  Future<bool> isSupported() => _unimplemented('isSupported');

  /// See `TaroAttestation.generateKey`.
  Future<String> generateKey() => _unimplemented('generateKey');

  /// See `TaroAttestation.attestKey`.
  Future<Uint8List> attestKey(String keyId, Uint8List clientDataHash) =>
      _unimplemented('attestKey');

  /// See `TaroAttestation.generateAssertion`.
  Future<Uint8List> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  ) => _unimplemented('generateAssertion');

  /// See `TaroAttestation.deviceCheckToken`.
  Future<Uint8List> deviceCheckToken() => _unimplemented('deviceCheckToken');

  /// See `TaroAttestation.prepareStandard`.
  Future<void> prepareStandard(int cloudProjectNumber) =>
      _unimplemented('prepareStandard');

  /// See `TaroAttestation.requestStandardToken`.
  Future<String> requestStandardToken(String requestHash) =>
      _unimplemented('requestStandardToken');

  /// See `TaroAttestation.androidId`.
  Future<String?> androidId() => _unimplemented('androidId');

  static Future<T> _unimplemented<T>(String method) =>
      throw UnimplementedError('$method() has not been implemented.');
}
