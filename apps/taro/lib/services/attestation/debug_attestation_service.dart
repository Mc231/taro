import 'package:taro_core/taro_core.dart';

/// The dev/staging [AttestationService] (02 §5, §15; RC86): no platform
/// attestation (simulators and emulators have none), so registration and
/// every attest route go the low-trust `none` way, and every Worker request
/// carries [headerName] with the `DEBUG_ATTESTATION_TOKEN` ([headers]). The
/// Worker honours the token only where its deploy env sets
/// `ALLOW_DEBUG_ATTESTATION` (dev, staging); a header alone never does.
///
/// Reachable only through [select] and [forBuild], which never return it
/// for a prod build (asserted by `debug_attestation_service_test.dart`).
final class DebugAttestationService implements AttestationService {
  DebugAttestationService._(this._token, this._signals);

  /// The debug service of a non-prod build, or `null` in prod or without a
  /// [token]. [signals] supplies the device signal (the platform service,
  /// so an emulator still sends its device key).
  static DebugAttestationService? forBuild({
    required bool isProd,
    required String token,
    AttestationService? signals,
  }) {
    if (isProd || token.trim().isEmpty) return null;
    return DebugAttestationService._(token.trim(), signals);
  }

  /// The attestation service of a build: the debug one when [forBuild]
  /// allows it and [debugToken] is set, else [platform] (always in prod).
  static AttestationService select({
    required bool isProd,
    required String debugToken,
    required AttestationService platform,
  }) =>
      forBuild(isProd: isProd, token: debugToken, signals: platform) ??
      platform;

  /// `X-Taro-Debug-Attestation` (GLOSSARY §4.1).
  static const String headerName = 'X-Taro-Debug-Attestation';

  final String _token;
  final AttestationService? _signals;

  /// The headers to add to every Worker request (registration included).
  Map<String, String> get headers => {headerName: _token};

  @override
  bool get isSupported => false;

  @override
  Future<Result<AttestationBlob>> attest({
    required String challenge,
    required String installId,
    required DeviceSignal signal,
  }) async => Result.ok(
    AttestationBlob(type: AttestationType.none, challenge: challenge),
  );

  @override
  Future<Result<AssertionBlob>> assert_({
    required List<int> clientDataHash,
    String? keyId,
  }) async => const Result.ok(AssertionBlob(header: 'none'));

  @override
  Future<DeviceSignal> deviceSignal() async =>
      await _signals?.deviceSignal() ?? const DeviceSignal();

  @override
  String toString() => 'DebugAttestationService(token: <redacted>)';
}
