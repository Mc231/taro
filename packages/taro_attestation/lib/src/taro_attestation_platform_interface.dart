import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:taro_attestation/src/taro_attestation_method_channel.dart';

/// The interface that platform implementations of the plugin extend.
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

  /// Returns the OS version reported by the native side.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
