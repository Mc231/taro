import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'install_identity.freezed.dart';

/// Registration trust level (03 §3.3).
enum Trust {
  /// Attested install.
  high,

  /// Unattested install with low-trust caps.
  low,
}

/// Store-account binding values returned at registration (RC9, MO15).
@freezed
abstract class PurchaseBinding with _$PurchaseBinding {
  /// Creates the binding.
  const factory PurchaseBinding({
    /// StoreKit `appAccountToken` (UUIDv5, iOS).
    String? appleAccountToken,

    /// Play `obfuscatedAccountId` (HMAC, Android).
    String? playAccountId,
  }) = _PurchaseBinding;
}

/// This install's identity (02 §4). The install secret is never part of it.
@freezed
abstract class InstallIdentity with _$InstallIdentity {
  /// Creates the identity.
  const factory InstallIdentity({
    /// The install ID (never logged).
    required InstallId installId,

    /// When registration with the Worker succeeded.
    DateTime? registeredAt,

    /// The IANA timezone sent at registration.
    String? registeredTimezone,

    /// Trust level from registration.
    Trust? trust,

    /// Purchase binding from registration.
    PurchaseBinding? purchaseBinding,

    /// App Attest key ID (iOS).
    String? attestationKeyId,
  }) = _InstallIdentity;

  const InstallIdentity._();

  /// Whether the install is registered with the Worker.
  bool get isRegistered => registeredAt != null;
}
