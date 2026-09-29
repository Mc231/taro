import 'package:json_annotation/json_annotation.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro_core/taro_core.dart';

part 'install_dtos.g.dart';

/// `POST /v1/attest/challenge` response (03 §3.2).
@JsonSerializable(createToJson: false, checked: true)
final class ChallengeDto {
  /// Creates the DTO.
  const ChallengeDto({
    required this.challenge,
    required this.expiresAt,
    required this.powBits,
  });

  /// Decodes the wire JSON.
  factory ChallengeDto.fromJson(JsonObject json) =>
      _$ChallengeDtoFromJson(json);

  /// The stateless challenge (base64url).
  final String challenge;

  /// When it lapses (UTC).
  @UtcInstantConverter()
  final DateTime expiresAt;

  /// Proof-of-work difficulty for a `type: none` registration.
  final int powBits;
}

/// `attestation` of the registration body (03 §3.3; OpenAPI
/// `RegistrationAttestation`, one of three shapes by [type]).
@JsonSerializable(createFactory: false, includeIfNull: false)
final class RegistrationAttestationDto {
  /// Creates the DTO.
  const RegistrationAttestationDto({
    required this.type,
    required this.challenge,
    this.keyId,
    this.attestationObject,
    this.integrityToken,
    this.reason,
    this.pow,
    this.previousKeyAssertion,
  });

  /// Builds the body from a platform [blob]: the payload goes to
  /// `attestationObject` (App Attest) or `integrityToken` (Play Integrity).
  /// A `none` blob needs [reason] and, for a solved challenge, [pow].
  factory RegistrationAttestationDto.fromBlob(
    AttestationBlob blob, {
    String? reason,
    String? pow,
    String? previousKeyAssertion,
  }) => RegistrationAttestationDto(
    type: blob.type.wire,
    challenge: blob.challenge,
    keyId: blob.type == AttestationType.appAttest ? blob.keyId : null,
    attestationObject: blob.type == AttestationType.appAttest
        ? blob.payload
        : null,
    integrityToken: blob.type == AttestationType.playIntegrity
        ? blob.payload
        : null,
    reason: blob.type == AttestationType.none ? reason ?? 'unsupported' : null,
    pow: blob.type == AttestationType.none ? pow : null,
    previousKeyAssertion: previousKeyAssertion,
  );

  /// `app_attest | play_integrity | none`.
  final String type;

  /// The challenge answered.
  final String challenge;

  /// App Attest key ID.
  final String? keyId;

  /// App Attest attestation object (base64).
  final String? attestationObject;

  /// Play Integrity standard token.
  final String? integrityToken;

  /// `unsupported | error | timeout` for `type: none`.
  final String? reason;

  /// The proof of work for `type: none`.
  final String? pow;

  /// iOS: an assertion by the previous key (RC54).
  final String? previousKeyAssertion;

  /// The wire JSON.
  JsonObject toJson() => _$RegistrationAttestationDtoToJson(this);
}

/// `POST /v1/installs` body (03 §3.3). [installSecret] is sent only here
/// (RC54) and never logged.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
final class RegisterRequestDto {
  /// Creates the DTO.
  const RegisterRequestDto({
    required this.installId,
    required this.installSecret,
    required this.platform,
    required this.appVersion,
    required this.locale,
    required this.timezone,
    required this.attestation,
    this.deviceCheckToken,
    this.deviceKey,
  });

  /// The install UUID.
  final String installId;

  /// 32 random bytes, base64url.
  final String installSecret;

  /// `ios | android`.
  final String platform;

  /// `1.2.0+14`.
  final String appVersion;

  /// One of the 12 locales.
  final String locale;

  /// IANA zone.
  final String timezone;

  /// iOS DeviceCheck token (03 §3.7).
  final String? deviceCheckToken;

  /// Android device key (03 §3.7).
  final String? deviceKey;

  /// The attestation.
  final RegistrationAttestationDto attestation;

  /// The wire JSON.
  JsonObject toJson() => _$RegisterRequestDtoToJson(this);

  @override
  String toString() => 'RegisterRequestDto(<redacted>)';
}

/// `purchaseBinding` (RC9, RC85).
@JsonSerializable(createToJson: false, checked: true)
final class PurchaseBindingDto {
  /// Creates the DTO.
  const PurchaseBindingDto({this.appleAccountToken, this.playAccountId});

  /// Decodes the wire JSON.
  factory PurchaseBindingDto.fromJson(JsonObject json) =>
      _$PurchaseBindingDtoFromJson(json);

  /// StoreKit `appAccountToken` (iOS).
  final String? appleAccountToken;

  /// Play `obfuscatedAccountId` (Android).
  final String? playAccountId;

  /// The domain value.
  PurchaseBinding toDomain() => PurchaseBinding(
    appleAccountToken: appleAccountToken,
    playAccountId: playAccountId,
  );
}

Trust _trust(String wire) => wireEnum(Trust.values.asNameMap(), wire, 'trust');

/// `POST /v1/installs/token` response (03 §3.4).
@JsonSerializable(createToJson: false, checked: true)
final class InstallTokenDto {
  /// Creates the DTO.
  const InstallTokenDto({
    required this.installToken,
    required this.expiresAt,
    required this.trust,
  });

  /// Decodes the wire JSON.
  factory InstallTokenDto.fromJson(JsonObject json) =>
      _$InstallTokenDtoFromJson(json);

  /// The JWT. Never logged.
  final String installToken;

  /// Its expiry (UTC).
  @UtcInstantConverter()
  final DateTime expiresAt;

  /// `high | low`.
  final String trust;

  /// The stored token.
  SessionToken toSessionToken() =>
      SessionToken(token: installToken, expiresAt: expiresAt);

  /// The trust level.
  Trust toTrust() => _trust(trust);

  @override
  String toString() => 'InstallTokenDto(<redacted>, $expiresAt, $trust)';
}

/// `POST /v1/installs` response (03 §3.3).
@JsonSerializable(createToJson: false, checked: true)
final class RegistrationResponseDto {
  /// Creates the DTO.
  const RegistrationResponseDto({
    required this.installToken,
    required this.expiresAt,
    required this.trust,
    required this.purchaseBinding,
    required this.balance,
    required this.config,
  });

  /// Decodes the wire JSON.
  factory RegistrationResponseDto.fromJson(JsonObject json) =>
      _$RegistrationResponseDtoFromJson(json);

  /// The JWT. Never logged.
  final String installToken;

  /// Its expiry (UTC).
  @UtcInstantConverter()
  final DateTime expiresAt;

  /// `high | low`.
  final String trust;

  /// The store-account binding.
  final PurchaseBindingDto purchaseBinding;

  /// The balance.
  final BalanceDto balance;

  /// The `PublicConfigDto` document (parsed by `RemoteConfig.fromJson`).
  final Map<String, dynamic> config;

  /// The stored token.
  SessionToken toSessionToken() =>
      SessionToken(token: installToken, expiresAt: expiresAt);

  /// The trust level.
  Trust toTrust() => _trust(trust);

  @override
  String toString() => 'RegistrationResponseDto(<redacted>, $trust)';
}

/// `PUT /v1/installs/me/timezone` body (03 §3.5).
@JsonSerializable(createFactory: false)
final class TimezoneRequestDto {
  /// Creates the DTO.
  const TimezoneRequestDto({required this.timezone});

  /// IANA zone.
  final String timezone;

  /// The wire JSON.
  JsonObject toJson() => _$TimezoneRequestDtoToJson(this);
}
