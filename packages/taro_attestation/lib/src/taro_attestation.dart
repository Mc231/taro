import 'package:taro_attestation/src/taro_attestation_platform_interface.dart';

/// Entry point of the attestation plugin.
///
/// Skeleton from Phase 2: only the template round-trip exists; the
/// attestation API lands in Phase 12.
class TaroAttestation {
  /// Returns the OS version reported by the native side.
  Future<String?> getPlatformVersion() {
    return TaroAttestationPlatform.instance.getPlatformVersion();
  }
}
