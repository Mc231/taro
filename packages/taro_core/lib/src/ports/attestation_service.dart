import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/result.dart';

part 'attestation_service.freezed.dart';

/// `attestation.type` on registration (GLOSSARY §5.1).
enum AttestationType {
  /// iOS App Attest.
  appAttest('app_attest'),

  /// Android Play Integrity (Standard).
  playIntegrity('play_integrity'),

  /// Unsupported device: proof of work, low trust.
  none('none');

  const AttestationType(this.wire);

  /// The wire value.
  final String wire;
}

/// A registration attestation (02 §6.4, 03 §3.3).
@freezed
abstract class AttestationBlob with _$AttestationBlob {
  /// Creates an attestation.
  const factory AttestationBlob({
    /// The attestation kind.
    required AttestationType type,

    /// The challenge it answers.
    required String challenge,

    /// The platform attestation object or integrity token (base64url).
    String? payload,

    /// The App Attest key ID (iOS).
    String? keyId,
  }) = _AttestationBlob;
}

/// A per-call assertion for `X-Taro-Attestation` (03 §3.4).
@freezed
abstract class AssertionBlob with _$AssertionBlob {
  /// Creates an assertion.
  const factory AssertionBlob({
    /// The full header value: `aa1.<assertion>`, `pi1.<token>` or `none`.
    required String header,
  }) = _AssertionBlob;
}

/// The device-scoped abuse signal (03 §3.7).
@freezed
abstract class DeviceSignal with _$DeviceSignal {
  /// Creates a device signal.
  const factory DeviceSignal({
    /// Android `deviceKey`.
    String? deviceKey,

    /// iOS DeviceCheck token.
    String? deviceCheckToken,
  }) = _DeviceSignal;
}

/// Platform attestation (App Attest / Play Integrity, 02 §5, §6.4).
abstract interface class AttestationService {
  /// Attests for registration against [challenge].
  Future<Result<AttestationBlob>> attest({required String challenge});

  /// Asserts one [attest]-protected call over [clientDataHash].
  // Named after 02 §5: `assert` is a reserved word.
  Future<Result<AssertionBlob>> assert_({required List<int> clientDataHash});

  /// The device-scoped abuse signal.
  Future<DeviceSignal> deviceSignal();

  /// Whether platform attestation is available.
  bool get isSupported;
}
