// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$VerifyPurchaseRequestDtoToJson(
  VerifyPurchaseRequestDto instance,
) => <String, dynamic>{
  'platform': instance.platform,
  'productId': instance.productId,
  'transactionId': ?instance.transactionId,
  'signedTransaction': ?instance.signedTransaction,
  'purchaseToken': ?instance.purchaseToken,
  'orderId': ?instance.orderId,
  'transferToken': ?instance.transferToken,
};

VerifyPurchaseResponseDto _$VerifyPurchaseResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VerifyPurchaseResponseDto', json, ($checkedConvert) {
  final val = VerifyPurchaseResponseDto(
    status: $checkedConvert('status', (v) => v as String),
    purchaseId: $checkedConvert('purchaseId', (v) => v as String?),
    productId: $checkedConvert('productId', (v) => v as String?),
    creditsGranted: $checkedConvert(
      'creditsGranted',
      (v) => (v as num?)?.toInt() ?? 0,
    ),
    isFirstPurchase: $checkedConvert(
      'isFirstPurchase',
      (v) => v as bool? ?? false,
    ),
    balance: $checkedConvert(
      'balance',
      (v) => v == null ? null : BalanceDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$RewardIntentRequestDtoToJson(
  RewardIntentRequestDto instance,
) => <String, dynamic>{'adUnitId': instance.adUnitId};

RewardIntentDto _$RewardIntentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RewardIntentDto', json, ($checkedConvert) {
      final val = RewardIntentDto(
        intentId: $checkedConvert('intentId', (v) => v as String),
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        customData: $checkedConvert('customData', (v) => v as String?),
        userId: $checkedConvert('userId', (v) => v as String?),
      );
      return val;
    });

RewardIntentStatusDto _$RewardIntentStatusDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RewardIntentStatusDto', json, ($checkedConvert) {
  final val = RewardIntentStatusDto(
    status: $checkedConvert('status', (v) => v as String),
    amount: $checkedConvert('amount', (v) => (v as num).toInt()),
    balance: $checkedConvert(
      'balance',
      (v) => v == null ? null : BalanceDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});
