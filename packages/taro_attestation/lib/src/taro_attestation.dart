import 'dart:typed_data';

import 'package:taro_attestation/src/taro_attestation_platform_interface.dart';

/// Device attestation (02 AR9, §6.4; RC87).
///
/// iOS: App Attest ([generateKey], [attestKey], [generateAssertion]) and
/// DeviceCheck ([deviceCheckToken]). Android: the Play Integrity
/// **Standard** API ([prepareStandard], [requestStandardToken]; there is no
/// Classic API) and `Settings.Secure.ANDROID_ID` ([androidId]).
///
/// Every method throws only `TaroAttestationException`; a method of the
/// other platform throws it with `AttestationErrorKind.unsupported`.
class TaroAttestation {
  /// The plugin over `TaroAttestationPlatform.instance`.
  const TaroAttestation();

  static TaroAttestationPlatform get _platform =>
      TaroAttestationPlatform.instance;

  /// Whether platform attestation is available: `DCAppAttestService`
  /// `isSupported` on iOS (false on the simulator); on Android the Standard
  /// API exists on every supported OS version, and [prepareStandard] proves
  /// that Play services can serve it.
  Future<bool> isSupported() => _platform.isSupported();

  /// A new App Attest key in the Secure Enclave; returns its key ID
  /// (base64).
  Future<String> generateKey() => _platform.generateKey();

  /// Attests [keyId] with Apple over the 32-byte [clientDataHash]; returns
  /// the CBOR attestation object.
  Future<Uint8List> attestKey(String keyId, Uint8List clientDataHash) =>
      _platform.attestKey(keyId, clientDataHash);

  /// Signs the 32-byte [clientDataHash] with the attested [keyId]; returns
  /// the CBOR assertion. A key the OS no longer knows fails with
  /// `keyInvalidated`.
  Future<Uint8List> generateAssertion(String keyId, Uint8List clientDataHash) =>
      _platform.generateAssertion(keyId, clientDataHash);

  /// An ephemeral DeviceCheck token for the Worker's two-bit query
  /// (03 §3.7).
  Future<Uint8List> deviceCheckToken() => _platform.deviceCheckToken();

  /// Warms up and caches a Standard integrity token provider for the
  /// Google Cloud [cloudProjectNumber] (once per launch, 02 §6.4).
  Future<void> prepareStandard(int cloudProjectNumber) =>
      _platform.prepareStandard(cloudProjectNumber);

  /// A Standard integrity token whose `requestHash` is [requestHash]
  /// (base64url, at most 500 characters). Needs [prepareStandard] first; an
  /// invalidated provider is prepared again once by the native side.
  Future<String> requestStandardToken(String requestHash) =>
      _platform.requestStandardToken(requestHash);

  /// `Settings.Secure.ANDROID_ID` (scoped to the app-signing key, user and
  /// device since Android 8), or `null` when the OS reports none. The raw
  /// value never leaves the device (03 §3.7).
  Future<String?> androidId() => _platform.androidId();
}
