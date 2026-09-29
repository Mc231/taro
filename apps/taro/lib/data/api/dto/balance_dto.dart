import 'package:json_annotation/json_annotation.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro_core/taro_core.dart';

part 'balance_dto.g.dart';

/// `BalanceDto.free` (03 §5.1).
@JsonSerializable(createToJson: false, checked: true)
final class FreeAllowanceDto {
  /// Creates the DTO.
  const FreeAllowanceDto({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.localDate,
    required this.resetsAt,
    required this.timezone,
    this.paused = false,
  });

  /// Decodes the wire JSON.
  factory FreeAllowanceDto.fromJson(JsonObject json) =>
      _$FreeAllowanceDtoFromJson(json);

  /// Free readings per day today.
  final int limit;

  /// Used today.
  final int used;

  /// Left today.
  final int remaining;

  /// `YYYY-MM-DD` on the Worker.
  final String localDate;

  /// Next reset (UTC).
  @UtcInstantConverter()
  final DateTime resetsAt;

  /// IANA zone of the day boundary.
  final String timezone;

  /// The free-stop budget tier is active (RC64).
  final bool paused;

  /// The domain value.
  FreeAllowance toDomain() => FreeAllowance(
    limit: limit,
    used: used,
    remaining: remaining,
    localDate: checkLocalDate(localDate),
    resetsAt: resetsAt,
    timezone: timezone,
    paused: paused,
  );
}

/// `BalanceDto.rewarded` (03 §5.1, RC57).
@JsonSerializable(createToJson: false, checked: true)
final class RewardedStatusDto {
  /// Creates the DTO.
  const RewardedStatusDto({
    required this.enabled,
    required this.amount,
    required this.dailyCap,
    required this.grantedToday,
    required this.available,
    this.cooldownEndsAt,
  });

  /// Decodes the wire JSON.
  factory RewardedStatusDto.fromJson(JsonObject json) =>
      _$RewardedStatusDtoFromJson(json);

  /// `rewarded.enabled`.
  final bool enabled;

  /// Readings per completed ad.
  final int amount;

  /// Grants per local day.
  final int dailyCap;

  /// Grants so far today.
  final int grantedToday;

  /// Whether an ad may be offered now.
  final bool available;

  /// End of the cooldown (UTC).
  @NullableUtcInstantConverter()
  final DateTime? cooldownEndsAt;

  /// The domain value.
  RewardedStatus toDomain() => RewardedStatus(
    enabled: enabled,
    amount: amount,
    dailyCap: dailyCap,
    grantedToday: grantedToday,
    available: available,
    cooldownEndsAt: cooldownEndsAt,
  );
}

/// The wire balance of every spec (03 §5.1, RC6); maps to [CreditBalance].
@JsonSerializable(createToJson: false, checked: true)
final class BalanceDto {
  /// Creates the DTO.
  const BalanceDto({
    required this.free,
    required this.bonus,
    required this.paid,
    required this.canRead,
    required this.rewarded,
    required this.paidBlocked,
    required this.purchasesAllowed,
    required this.ledgerVersion,
    required this.serverTime,
    this.canReadReason,
    this.nextSource,
    this.purchasesBlockedReason,
  });

  /// Decodes the wire JSON.
  factory BalanceDto.fromJson(JsonObject json) => _$BalanceDtoFromJson(json);

  /// Today's free allowance.
  final FreeAllowanceDto free;

  /// Earned readings.
  final int bonus;

  /// Purchased readings (negative after a clawback).
  final int paid;

  /// Whether a reading may start.
  final bool canRead;

  /// `noCredits | dailyLimit | lowTrustCap | readingsPaused` (RC74).
  final String? canReadReason;

  /// `free | bonus | paid`; `none` or `null` when no reading can start.
  final String? nextSource;

  /// Rewarded-ad status.
  final RewardedStatusDto rewarded;

  /// `paid < 0`.
  final bool paidBlocked;

  /// Whether packs are offered (RC66).
  final bool purchasesAllowed;

  /// `blocked | refundDebt | storeDisabled`.
  final String? purchasesBlockedReason;

  /// `installs.state_version` (RC67).
  final int ledgerVersion;

  /// Worker time of the response.
  @UtcInstantConverter()
  final DateTime serverTime;

  /// The domain balance, received at device time [syncedAt].
  ///
  /// It carries [ledgerVersion] and [serverTime] unchanged so the RC67 rule
  /// (`CreditBalance.isAcceptableOver` / `shouldReplace`) can order it
  /// against the cache. Throws a [FormatException] on an unknown enum.
  CreditBalance toDomain({required DateTime syncedAt}) => CreditBalance(
    free: free.toDomain(),
    bonus: bonus,
    paid: paid,
    canRead: canRead,
    canReadReason: optWireEnum(
      CanReadReason.values.asNameMap(),
      canReadReason,
      'canReadReason',
    ),
    nextSource: nextSource == 'none'
        ? null
        : optWireEnum(
            ChargeSource.values.asNameMap(),
            nextSource,
            'nextSource',
          ),
    rewarded: rewarded.toDomain(),
    paidBlocked: paidBlocked,
    purchasesAllowed: purchasesAllowed,
    purchasesBlockedReason: optWireEnum(
      PurchasesBlockedReason.values.asNameMap(),
      purchasesBlockedReason,
      'purchasesBlockedReason',
    ),
    ledgerVersion: ledgerVersion,
    serverTime: serverTime,
    syncedAt: syncedAt.toUtc(),
  );
}
