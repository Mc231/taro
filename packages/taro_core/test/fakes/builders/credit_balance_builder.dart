// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this, avoid_positional_boolean_parameters

import 'package:taro_core/taro_core.dart';

import 'defaults.dart';

/// `aCreditBalance().withFreeRemaining(0).withPaid(3).build()`.
///
/// Unless overridden, `canRead`, `canReadReason` and `nextSource` follow
/// the buckets the way the Worker computes them (free → bonus → paid).
CreditBalanceBuilder aCreditBalance() => CreditBalanceBuilder();

/// Builds a [CreditBalance].
final class CreditBalanceBuilder {
  int _limit = 1;
  int _remaining = 1;
  bool _paused = false;
  String _localDate = kTestLocalDate;
  DateTime _resetsAt = kTestResetsAt;
  String _timezone = kTestTimeZone;
  int _bonus = 0;
  int _paid = 0;
  CanReadReason? _blockedBy;
  ChargeSource? _nextSource;
  bool _nextSourceSet = false;
  bool _rewardedEnabled = true;
  int _rewardedAmount = 1;
  int _dailyCap = 3;
  int _grantedToday = 0;
  bool? _rewardedAvailable;
  DateTime? _cooldownEndsAt;
  bool _purchasesAllowed = true;
  PurchasesBlockedReason? _blockedReason;
  int _ledgerVersion = 1;
  DateTime _serverTime = kTestNow;
  DateTime _syncedAt = kTestNow;

  /// `free.remaining` (and `used = limit - remaining`).
  CreditBalanceBuilder withFreeRemaining(int remaining) {
    _remaining = remaining;
    if (_limit < remaining) _limit = remaining;
    return this;
  }

  /// `free.limit`.
  CreditBalanceBuilder withFreeLimit(int limit) {
    _limit = limit;
    if (_remaining > limit) _remaining = limit;
    return this;
  }

  /// `free.paused` (budget free stop, RC64).
  CreditBalanceBuilder withFreePaused([bool paused = true]) {
    _paused = paused;
    return this;
  }

  /// `bonus`.
  CreditBalanceBuilder withBonus(int bonus) {
    _bonus = bonus;
    return this;
  }

  /// `paid` (negative for a refund debt).
  CreditBalanceBuilder withPaid(int paid) {
    _paid = paid;
    return this;
  }

  /// `free.localDate`.
  CreditBalanceBuilder withLocalDate(String localDate) {
    _localDate = localDate;
    return this;
  }

  /// `free.resetsAt`.
  CreditBalanceBuilder withResetsAt(DateTime resetsAt) {
    _resetsAt = resetsAt;
    return this;
  }

  /// `free.timezone`.
  CreditBalanceBuilder withTimezone(String timezone) {
    _timezone = timezone;
    return this;
  }

  /// `canRead: false` with `canReadReason: dailyLimit` (RC74).
  CreditBalanceBuilder withDailyLimitReached() =>
      _blocked(CanReadReason.dailyLimit);

  /// `canRead: false` with `canReadReason: lowTrustCap` (RC74).
  CreditBalanceBuilder withLowTrustCap() => _blocked(CanReadReason.lowTrustCap);

  /// `canRead: false` with `canReadReason: readingsPaused` (RC47).
  CreditBalanceBuilder withReadingsPaused() =>
      _blocked(CanReadReason.readingsPaused);

  CreditBalanceBuilder _blocked(CanReadReason reason) {
    _blockedBy = reason;
    return this;
  }

  /// An explicit `nextSource` (`null` = none).
  CreditBalanceBuilder withNextSource(ChargeSource? source) {
    _nextSource = source;
    _nextSourceSet = true;
    return this;
  }

  /// The `rewarded` object. `available` defaults to "enabled, under the
  /// cap and no cooldown".
  CreditBalanceBuilder withRewarded({
    bool? enabled,
    bool? available,
    int? amount,
    int? dailyCap,
    int? grantedToday,
    DateTime? cooldownEndsAt,
  }) {
    _rewardedEnabled = enabled ?? _rewardedEnabled;
    _rewardedAvailable = available;
    _rewardedAmount = amount ?? _rewardedAmount;
    _dailyCap = dailyCap ?? _dailyCap;
    _grantedToday = grantedToday ?? _grantedToday;
    _cooldownEndsAt = cooldownEndsAt;
    return this;
  }

  /// `purchasesAllowed: false` with [reason] (RC66).
  CreditBalanceBuilder withPurchasesBlocked([
    PurchasesBlockedReason reason = PurchasesBlockedReason.blocked,
  ]) {
    _purchasesAllowed = false;
    _blockedReason = reason;
    return this;
  }

  /// `ledgerVersion` (RC67).
  CreditBalanceBuilder withLedgerVersion(int version) {
    _ledgerVersion = version;
    return this;
  }

  /// `serverTime`.
  CreditBalanceBuilder withServerTime(DateTime serverTime) {
    _serverTime = serverTime;
    return this;
  }

  /// Received on the device at [syncedAt] (server time follows unless set
  /// separately afterwards).
  CreditBalanceBuilder syncedAt(DateTime syncedAt) {
    _syncedAt = syncedAt;
    _serverTime = syncedAt;
    return this;
  }

  /// The balance.
  CreditBalance build() {
    final freeUsable = _remaining > 0 && !_paused;
    final inferred = freeUsable
        ? ChargeSource.free
        : _bonus > 0
        ? ChargeSource.bonus
        : _paid > 0
        ? ChargeSource.paid
        : null;
    final canRead = _blockedBy == null && inferred != null;
    final reason = canRead ? null : (_blockedBy ?? CanReadReason.noCredits);
    final cooldownActive =
        _cooldownEndsAt != null && _cooldownEndsAt!.isAfter(_serverTime);
    return CreditBalance(
      free: FreeAllowance(
        limit: _limit,
        used: _limit - _remaining < 0 ? 0 : _limit - _remaining,
        remaining: _remaining,
        localDate: _localDate,
        resetsAt: _resetsAt,
        timezone: _timezone,
        paused: _paused,
      ),
      bonus: _bonus,
      paid: _paid,
      canRead: canRead,
      canReadReason: reason,
      nextSource: _nextSourceSet ? _nextSource : (canRead ? inferred : null),
      rewarded: RewardedStatus(
        enabled: _rewardedEnabled,
        amount: _rewardedAmount,
        dailyCap: _dailyCap,
        grantedToday: _grantedToday,
        available:
            _rewardedAvailable ??
            (_rewardedEnabled && _grantedToday < _dailyCap && !cooldownActive),
        cooldownEndsAt: _cooldownEndsAt,
      ),
      paidBlocked: _paid < 0,
      purchasesAllowed: _purchasesAllowed,
      purchasesBlockedReason: _blockedReason,
      ledgerVersion: _ledgerVersion,
      serverTime: _serverTime,
      syncedAt: _syncedAt,
    );
  }
}
