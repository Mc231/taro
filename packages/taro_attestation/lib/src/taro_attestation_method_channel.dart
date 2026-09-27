import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:taro_attestation/src/taro_attestation_platform_interface.dart';

/// [TaroAttestationPlatform] implementation over a method channel.
class MethodChannelTaroAttestation extends TaroAttestationPlatform {
  /// The method channel used to talk to the native side.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('taro_attestation');

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }
}
