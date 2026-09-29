// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeDto _$ChallengeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChallengeDto', json, ($checkedConvert) {
      final val = ChallengeDto(
        challenge: $checkedConvert('challenge', (v) => v as String),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        powBits: $checkedConvert('powBits', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$RegistrationAttestationDtoToJson(
  RegistrationAttestationDto instance,
) => <String, dynamic>{
  'type': instance.type,
  'challenge': instance.challenge,
  'keyId': ?instance.keyId,
  'attestationObject': ?instance.attestationObject,
  'integrityToken': ?instance.integrityToken,
  'reason': ?instance.reason,
  'pow': ?instance.pow,
  'previousKeyAssertion': ?instance.previousKeyAssertion,
};

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'installId': instance.installId,
      'installSecret': instance.installSecret,
      'platform': instance.platform,
      'appVersion': instance.appVersion,
      'locale': instance.locale,
      'timezone': instance.timezone,
      'deviceCheckToken': ?instance.deviceCheckToken,
      'deviceKey': ?instance.deviceKey,
      'attestation': instance.attestation.toJson(),
    };

PurchaseBindingDto _$PurchaseBindingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PurchaseBindingDto', json, ($checkedConvert) {
      final val = PurchaseBindingDto(
        appleAccountToken: $checkedConvert(
          'appleAccountToken',
          (v) => v as String?,
        ),
        playAccountId: $checkedConvert('playAccountId', (v) => v as String?),
      );
      return val;
    });

InstallTokenDto _$InstallTokenDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InstallTokenDto', json, ($checkedConvert) {
      final val = InstallTokenDto(
        installToken: $checkedConvert('installToken', (v) => v as String),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        trust: $checkedConvert('trust', (v) => v as String),
      );
      return val;
    });

RegistrationResponseDto _$RegistrationResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RegistrationResponseDto', json, ($checkedConvert) {
  final val = RegistrationResponseDto(
    installToken: $checkedConvert('installToken', (v) => v as String),
    expiresAt: $checkedConvert(
      'expiresAt',
      (v) => const UtcInstantConverter().fromJson(v as String),
    ),
    trust: $checkedConvert('trust', (v) => v as String),
    purchaseBinding: $checkedConvert(
      'purchaseBinding',
      (v) => PurchaseBindingDto.fromJson(v as Map<String, dynamic>),
    ),
    balance: $checkedConvert(
      'balance',
      (v) => BalanceDto.fromJson(v as Map<String, dynamic>),
    ),
    config: $checkedConvert('config', (v) => v as Map<String, dynamic>),
  );
  return val;
});

Map<String, dynamic> _$TimezoneRequestDtoToJson(TimezoneRequestDto instance) =>
    <String, dynamic>{'timezone': instance.timezone};
