import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/result/failure.dart';

part 'credit_balance.freezed.dart';

/// The bucket a reading is paid from (03 §5.1 `nextSource`, `chargeSource`).
enum ChargeSource {
  /// Today's free allowance.
  free,

  /// Earned readings (rewarded ads, grants).
  bonus,

  /// Purchased readings.
  paid,
}

/// Why `canRead` is false (03 §5.1, RC74).
enum CanReadReason {
  /// Nothing left: the paywall (S10).
  noCredits,

  /// `readings.maxPerInstallPerDay` reached: S07 `dailyLimitReached`, no
  /// paywall.
  dailyLimit,

  /// Low-trust cap: paywall with `lowTrustLimited` copy.
  lowTrustCap,

  /// Kill switch or budget stop: S31 `readingsPaused`, never a paywall.
  readingsPaused,
}

/// Today's free allowance (03 §5.1 `free`).
@freezed
abstract class FreeAllowance with _$FreeAllowance {
  /// Creates the allowance.
  const factory FreeAllowance({
    /// Free readings per day today.
    required int limit,

    /// Used today.
    required int used,

    /// Left today.
    required int remaining,

    /// The install's local date `YYYY-MM-DD` on the Worker.
    required String localDate,

    /// Next reset (UTC).
    required DateTime resetsAt,

    /// IANA timezone the day boundary uses.
    required String timezone,

    /// Whether the budget free-stop tier pauses free readings (RC64).
    @Default(false) bool paused,
  }) = _FreeAllowance;
}

/// Rewarded-ad status (03 §5.1 `rewarded`, RC57).
@freezed
abstract class RewardedStatus with _$RewardedStatus {
  /// Creates the status.
  const factory RewardedStatus({
    /// `rewarded.enabled`.
    required bool enabled,

    /// Readings per completed ad.
    required int amount,

    /// Grants per local day.
    required int dailyCap,

    /// Grants so far today.
    required int grantedToday,

    /// Whether an ad may be offered now.
    required bool available,

    /// End of the cooldown after the last grant (UTC).
    DateTime? cooldownEndsAt,
  }) = _RewardedStatus;
}

/// The install's credits, mapped from the wire `BalanceDto` (RC6, 03 §5.1).
///
/// The Worker is the only source of truth: the client never increments or
/// decrements it, it only replaces it with a newer Worker response
/// ([shouldReplace], RC67).
@freezed
abstract class CreditBalance with _$CreditBalance {
  /// Creates a balance.
  const factory CreditBalance({
    /// Today's free allowance.
    required FreeAllowance free,

    /// Earned readings ("earned readings" in the UI).
    required int bonus,

    /// Purchased readings; negative after a refund clawback (MO16).
    required int paid,

    /// Whether a reading may start.
    required bool canRead,

    /// Why [canRead] is false.
    required CanReadReason? canReadReason,

    /// Which bucket the next reading uses; `null` when none can.
    required ChargeSource? nextSource,

    /// Rewarded-ad status.
    required RewardedStatus rewarded,

    /// `paid < 0`.
    required bool paidBlocked,

    /// Whether pack purchases are offered (RC66).
    required bool purchasesAllowed,

    /// Why purchases are blocked.
    required PurchasesBlockedReason? purchasesBlockedReason,

    /// `installs.state_version` (RC67).
    required int ledgerVersion,

    /// Worker time of the response (UTC).
    required DateTime serverTime,

    /// Device time when the response was received.
    required DateTime syncedAt,
  }) = _CreditBalance;

  const CreditBalance._();

  /// Maps a decoded `BalanceDto` received at [syncedAt] (device clock).
  ///
  /// Throws a [FormatException] on a missing or mistyped field; the data
  /// layer maps it to a `Failure`.
  factory CreditBalance.fromDto(
    Map<String, Object?> json, {
    required DateTime syncedAt,
  }) {
    final free = reqMap(json, 'free');
    final rewarded = reqMap(json, 'rewarded');
    final nextSource = opt<String>(json, 'nextSource');
    return CreditBalance(
      free: FreeAllowance(
        limit: reqInt(free, 'limit'),
        used: reqInt(free, 'used'),
        remaining: reqInt(free, 'remaining'),
        localDate: reqLocalDate(free, 'localDate'),
        resetsAt: reqInstant(free, 'resetsAt'),
        timezone: req<String>(free, 'timezone'),
        paused: opt<bool>(free, 'paused') ?? false,
      ),
      bonus: reqInt(json, 'bonus'),
      paid: reqInt(json, 'paid'),
      canRead: req<bool>(json, 'canRead'),
      canReadReason: optEnum(
        json,
        'canReadReason',
        CanReadReason.values.asNameMap(),
      ),
      nextSource: nextSource == 'none'
          ? null
          : optEnum(json, 'nextSource', ChargeSource.values.asNameMap()),
      rewarded: RewardedStatus(
        enabled: req<bool>(rewarded, 'enabled'),
        amount: reqInt(rewarded, 'amount'),
        dailyCap: reqInt(rewarded, 'dailyCap'),
        grantedToday: reqInt(rewarded, 'grantedToday'),
        available: req<bool>(rewarded, 'available'),
        cooldownEndsAt: optInstant(rewarded, 'cooldownEndsAt'),
      ),
      paidBlocked: req<bool>(json, 'paidBlocked'),
      purchasesAllowed: req<bool>(json, 'purchasesAllowed'),
      purchasesBlockedReason: optEnum(
        json,
        'purchasesBlockedReason',
        PurchasesBlockedReason.values.asNameMap(),
      ),
      ledgerVersion: reqInt(json, 'ledgerVersion'),
      serverTime: reqInstant(json, 'serverTime'),
      syncedAt: syncedAt,
    );
  }

  /// The `BalanceDto` JSON of this balance (for the local cache); inverse of
  /// [CreditBalance.fromDto] apart from [syncedAt].
  Map<String, Object?> toDto() => {
    'free': {
      'limit': free.limit,
      'used': free.used,
      'remaining': free.remaining,
      'localDate': free.localDate,
      'resetsAt': formatInstant(free.resetsAt),
      'timezone': free.timezone,
      'paused': free.paused,
    },
    'bonus': bonus,
    'paid': paid,
    'canRead': canRead,
    'canReadReason': canReadReason?.name,
    'nextSource': nextSource?.name,
    'rewarded': {
      'enabled': rewarded.enabled,
      'amount': rewarded.amount,
      'dailyCap': rewarded.dailyCap,
      'grantedToday': rewarded.grantedToday,
      'available': rewarded.available,
      'cooldownEndsAt': rewarded.cooldownEndsAt == null
          ? null
          : formatInstant(rewarded.cooldownEndsAt!),
    },
    'paidBlocked': paidBlocked,
    'purchasesAllowed': purchasesAllowed,
    'purchasesBlockedReason': purchasesBlockedReason?.name,
    'ledgerVersion': ledgerVersion,
    'serverTime': formatInstant(serverTime),
  };

  /// Paid readings as shown: a debt is shown as 0 (MO16).
  int get displayPaid => paid < 0 ? 0 : paid;

  /// Readings available now, as shown: free remaining + bonus +
  /// [displayPaid].
  int get total => free.remaining + bonus + displayPaid;

  /// Whether the cached balance must be refreshed: older than [staleAfter]
  /// (`balance.staleAfterSec`) or past the free reset (02 §4).
  bool isStaleAt(DateTime now, Duration staleAfter) =>
      now.difference(syncedAt) > staleAfter || !now.isBefore(free.resetsAt);

  /// Whether this response may be applied over [cached]: its
  /// `ledgerVersion` is not older (RC67).
  bool isAcceptableOver(CreditBalance cached) =>
      ledgerVersion >= cached.ledgerVersion;

  /// Whether this response replaces [cached] (RC67): a strictly greater
  /// `ledgerVersion`, or an equal one with a newer `serverTime`.
  bool shouldReplace(CreditBalance cached) =>
      ledgerVersion > cached.ledgerVersion ||
      (ledgerVersion == cached.ledgerVersion &&
          serverTime.isAfter(cached.serverTime));
}
