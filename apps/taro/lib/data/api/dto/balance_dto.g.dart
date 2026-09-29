// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreeAllowanceDto _$FreeAllowanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FreeAllowanceDto', json, ($checkedConvert) {
      final val = FreeAllowanceDto(
        limit: $checkedConvert('limit', (v) => (v as num).toInt()),
        used: $checkedConvert('used', (v) => (v as num).toInt()),
        remaining: $checkedConvert('remaining', (v) => (v as num).toInt()),
        localDate: $checkedConvert('localDate', (v) => v as String),
        resetsAt: $checkedConvert(
          'resetsAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        paused: $checkedConvert('paused', (v) => v as bool? ?? false),
      );
      return val;
    });

RewardedStatusDto _$RewardedStatusDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RewardedStatusDto', json, ($checkedConvert) {
      final val = RewardedStatusDto(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        dailyCap: $checkedConvert('dailyCap', (v) => (v as num).toInt()),
        grantedToday: $checkedConvert(
          'grantedToday',
          (v) => (v as num).toInt(),
        ),
        available: $checkedConvert('available', (v) => v as bool),
        cooldownEndsAt: $checkedConvert(
          'cooldownEndsAt',
          (v) => const NullableUtcInstantConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

BalanceDto _$BalanceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BalanceDto', json, ($checkedConvert) {
      final val = BalanceDto(
        free: $checkedConvert(
          'free',
          (v) => FreeAllowanceDto.fromJson(v as Map<String, dynamic>),
        ),
        bonus: $checkedConvert('bonus', (v) => (v as num).toInt()),
        paid: $checkedConvert('paid', (v) => (v as num).toInt()),
        canRead: $checkedConvert('canRead', (v) => v as bool),
        rewarded: $checkedConvert(
          'rewarded',
          (v) => RewardedStatusDto.fromJson(v as Map<String, dynamic>),
        ),
        paidBlocked: $checkedConvert('paidBlocked', (v) => v as bool),
        purchasesAllowed: $checkedConvert('purchasesAllowed', (v) => v as bool),
        ledgerVersion: $checkedConvert(
          'ledgerVersion',
          (v) => (v as num).toInt(),
        ),
        serverTime: $checkedConvert(
          'serverTime',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        canReadReason: $checkedConvert('canReadReason', (v) => v as String?),
        nextSource: $checkedConvert('nextSource', (v) => v as String?),
        purchasesBlockedReason: $checkedConvert(
          'purchasesBlockedReason',
          (v) => v as String?,
        ),
      );
      return val;
    });
