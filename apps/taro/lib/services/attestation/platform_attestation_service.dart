import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:taro_attestation/taro_attestation.dart';
import 'package:taro_core/taro_core.dart';

/// The [AttestationService] over the `taro_attestation` plugin (02 §5,
/// §6.4; 03 §3.3, §3.4, §3.7; RC87).
///
/// - **iOS:** registration generates a new App Attest key and attests it
///   over `SHA256(challenge ‖ installId ‖ deviceCheckToken?)`; each [attest]
///   route asserts over the per-call hash (`aa1.<base64 assertion>`); the
///   device signal is a DeviceCheck token (base64).
/// - **Android:** Play Integrity **Standard** only. [warmUp] prepares the
///   token provider once per launch; registration requests a token with
///   `requestHash = base64url(SHA256(challenge ‖ installId ‖ deviceKey))`,
///   each call with `requestHash = base64url(clientDataHash)`
///   (`pi1.<token>`); the device signal is
///   `deviceKey = base64url(SHA256("taro-device-v1" ‖ ANDROID_ID))`, computed
///   here so the raw ANDROID_ID never leaves the device.
/// - **Unsupported** (simulator, no Play services, no cloud project number,
///   another OS): [isSupported] is false, [attest] answers a `none` blob and
///   [assert_] the `none` header (low trust, 02 §6.4).
///
/// Plugin errors become `AttestationFailure(kind)`; nothing throws. Logs
/// name the operation and the kind only, never a key, token or ID.
final class PlatformAttestationService implements AttestationService {
  /// A service for [platform] (default: the current one) over [plugin].
  /// [cloudProjectNumber] is the Google Cloud project of Play Integrity
  /// (`FlavorConfig.playCloudProjectNumber`; unused on iOS).
  PlatformAttestationService({
    required String cloudProjectNumber,
    TaroAttestation plugin = const TaroAttestation(),
    TargetPlatform? platform,
    Logger? logger,
  }) : _plugin = plugin,
       _platform = platform ?? defaultTargetPlatform,
       _cloudProjectNumber = int.tryParse(cloudProjectNumber.trim()),
       _logger = logger;

  /// Domain prefix of the Android device key (03 §3.7).
  static const String deviceKeyDomain = 'taro-device-v1';

  final TaroAttestation _plugin;
  final TargetPlatform _platform;
  final int? _cloudProjectNumber;
  final Logger? _logger;

  bool _supported = false;
  Future<void>? _warmUp;
  Future<bool>? _preparing;
  bool _prepared = false;
  String? _deviceKey;

  bool get _isIos => _platform == TargetPlatform.iOS;
  bool get _isAndroid => _platform == TargetPlatform.android;

  /// Whether platform attestation is available; settled by [warmUp], which
  /// every other call awaits first (`false` until then).
  @override
  bool get isSupported => _supported;

  /// Probes support once: App Attest on iOS; on Android, prepares the
  /// Standard token provider (02 §9.1 step 7 "attestation warm-up"). A
  /// transient prepare failure keeps Android supported and is retried by
  /// the next call.
  Future<void> warmUp() => _warmUp ??= _probe();

  Future<void> _probe() async {
    if (_isIos) {
      _supported = await _nativeSupport();
    } else if (_isAndroid) {
      final number = _cloudProjectNumber;
      if (number == null || number <= 0) {
        _logger?.warning('attestation: no Play cloud project number');
        return;
      }
      _supported = await _nativeSupport();
      if (_supported) await _prepare();
    }
  }

  Future<bool> _nativeSupport() async {
    try {
      return await _plugin.isSupported();
    } on TaroAttestationException catch (e) {
      _log('isSupported', e);
      return false;
    }
  }

  /// Prepares the Standard provider (single flight). An `unsupported` or
  /// `rejected` answer turns Android attestation off for this launch.
  Future<bool> _prepare() async {
    if (_prepared) return true;
    final running = _preparing ??= () async {
      try {
        await _plugin.prepareStandard(_cloudProjectNumber!);
        return _prepared = true;
      } on TaroAttestationException catch (e) {
        _log('prepareStandard', e);
        if (e.kind == AttestationErrorKind.unsupported ||
            e.kind == AttestationErrorKind.rejected) {
          _supported = false;
        }
        return false;
      }
    }();
    try {
      return await running;
    } finally {
      _preparing = null;
    }
  }

  @override
  Future<Result<AttestationBlob>> attest({
    required String challenge,
    required String installId,
    required DeviceSignal signal,
  }) async {
    await warmUp();
    if (!_supported) {
      return Result.ok(
        AttestationBlob(type: AttestationType.none, challenge: challenge),
      );
    }
    try {
      if (_isIos) {
        final keyId = await _plugin.generateKey();
        final object = await _plugin.attestKey(
          keyId,
          _sha256('$challenge$installId${signal.deviceCheckToken ?? ''}'),
        );
        return Result.ok(
          AttestationBlob(
            type: AttestationType.appAttest,
            challenge: challenge,
            payload: base64.encode(object),
            keyId: keyId,
          ),
        );
      }
      final token = await _standardToken(
        _base64Url(_sha256('$challenge$installId${signal.deviceKey ?? ''}')),
      );
      return Result.ok(
        AttestationBlob(
          type: AttestationType.playIntegrity,
          challenge: challenge,
          payload: token,
        ),
      );
    } on TaroAttestationException catch (e) {
      return Result.err(_failure('attest', e));
    }
  }

  @override
  Future<Result<AssertionBlob>> assert_({
    required List<int> clientDataHash,
    String? keyId,
  }) async {
    await warmUp();
    if (!_supported) return const Result.ok(AssertionBlob(header: 'none'));
    try {
      if (_isIos) {
        // No stored key: the install was registered without App Attest
        // (low trust), and the Worker accepts `none` from a low-trust
        // install (03 §3.4, BE4). A high-trust install answers it with
        // ATTESTATION_REQUIRED, so the Worker still decides.
        if (keyId == null || keyId.isEmpty) {
          return const Result.ok(AssertionBlob(header: 'none'));
        }
        final assertion = await _plugin.generateAssertion(
          keyId,
          Uint8List.fromList(clientDataHash),
        );
        return Result.ok(
          AssertionBlob(header: 'aa1.${base64.encode(assertion)}'),
        );
      }
      final token = await _standardToken(_base64Url(clientDataHash));
      return Result.ok(AssertionBlob(header: 'pi1.$token'));
    } on TaroAttestationException catch (e) {
      return Result.err(_failure('assert', e));
    }
  }

  /// A Standard token for [requestHash], preparing the provider first when
  /// the warm-up did not (a transient failure earlier in this launch).
  Future<String> _standardToken(String requestHash) async {
    if (!await _prepare()) {
      throw const TaroAttestationException(
        AttestationErrorKind.transient,
        'integrity provider not prepared',
      );
    }
    return _plugin.requestStandardToken(requestHash);
  }

  @override
  Future<DeviceSignal> deviceSignal() async {
    try {
      if (_isIos) {
        final token = await _plugin.deviceCheckToken();
        return DeviceSignal(deviceCheckToken: base64.encode(token));
      }
      if (_isAndroid) {
        final deviceKey = _deviceKey ??= await _androidDeviceKey();
        return DeviceSignal(deviceKey: deviceKey);
      }
    } on TaroAttestationException catch (e) {
      _log('deviceSignal', e);
    }
    return const DeviceSignal();
  }

  Future<String?> _androidDeviceKey() async {
    final androidId = await _plugin.androidId();
    return androidId == null ? null : deviceKeyOf(androidId);
  }

  /// `base64url(SHA-256("taro-device-v1" ‖ androidId))`, unpadded (03 §3.7).
  static String deviceKeyOf(String androidId) =>
      _base64Url(_sha256('$deviceKeyDomain$androidId'));

  static Uint8List _sha256(String value) =>
      Uint8List.fromList(sha256.convert(utf8.encode(value)).bytes);

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  Failure _failure(String operation, TaroAttestationException e) {
    _log(operation, e);
    return Failure.attestation(kind: failureKindOf(e.kind));
  }

  void _log(String operation, TaroAttestationException e) =>
      _logger?.warning('attestation $operation failed: ${e.kind.name}');

  /// The `taro_core` kind of a plugin error kind (the same five values).
  static AttestationFailureKind failureKindOf(AttestationErrorKind kind) =>
      switch (kind) {
        AttestationErrorKind.unsupported => AttestationFailureKind.unsupported,
        AttestationErrorKind.keyInvalidated =>
          AttestationFailureKind.keyInvalidated,
        AttestationErrorKind.rejected => AttestationFailureKind.rejected,
        AttestationErrorKind.quota => AttestationFailureKind.quota,
        AttestationErrorKind.transient => AttestationFailureKind.transient,
      };
}
