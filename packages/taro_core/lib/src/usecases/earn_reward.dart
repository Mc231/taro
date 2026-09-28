import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/ports/ads_service.dart';
import 'package:taro_core/src/ports/balance_repository.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/consent_store.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/remote_config_repository.dart';
import 'package:taro_core/src/ports/reward_gateway.dart';
import 'package:taro_core/src/ports/rewarded_show_result.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'earn_reward.freezed.dart';

/// Waits for [duration]; injected so polling is testable without real time.
typedef Delay = Future<void> Function(Duration duration);

/// How a rewarded view ended for the user (02 §9.6).
@freezed
sealed class RewardOutcome with _$RewardOutcome {
  /// The Worker granted [amount] bonus readings.
  const factory RewardOutcome.granted({required int amount}) = RewardGranted;

  /// Still `issued` at `rewarded.grantPollTimeoutSec`: `grantDelayed`
  /// ("Your reading will appear shortly"); the next balance sync settles it.
  const factory RewardOutcome.delayed() = RewardDelayed;

  /// Closed before the reward: no grant, no penalty.
  const factory RewardOutcome.dismissed() = RewardDismissed;

  /// The intent ended without a grant (`cancelled`, `expired`, `rejected`).
  const factory RewardOutcome.notGranted(RewardIntentState state) =
      RewardNotGranted;
}

/// A user-initiated rewarded ad (02 §9.6, RC33, RC34, RC56, RC57).
///
/// Never auto-shown and never mid-reading: only an explicit button on S10
/// or S11 calls it.
final class EarnReward {
  /// Creates the use case. [delay] defaults to `Future.delayed`.
  EarnReward({
    required RewardGateway gateway,
    required AdsService ads,
    required BalanceRepository balance,
    required RemoteConfigRepository config,
    required ConsentStore consent,
    required Clock clock,
    required Logger logger,
    Delay? delay,
  }) : _gateway = gateway,
       _ads = ads,
       _balance = balance,
       _config = config,
       _consent = consent,
       _clock = clock,
       _logger = logger,
       _delay = delay ?? Future<void>.delayed;

  /// How often the intent is polled after `onUserEarnedReward` (02 §9.6).
  static const Duration pollInterval = Duration(milliseconds: 1500);

  final RewardGateway _gateway;
  final AdsService _ads;
  final BalanceRepository _balance;
  final RemoteConfigRepository _config;
  final ConsentStore _consent;
  final Clock _clock;
  final Logger _logger;
  final Delay _delay;

  /// Why a rewarded ad cannot be offered now, or `null` when it can
  /// (02 §9.6 step 1; `free.remaining == 0`, RC34). The Worker is still the
  /// authority on cap and cooldown.
  RewardUnavailableReason? unavailableReason() {
    final config = _config.current;
    if (!config.adsEnabled || !config.rewardedEnabled) {
      return RewardUnavailableReason.disabled;
    }
    if (!_consent.current.ads.canRequestAds) {
      return RewardUnavailableReason.consent;
    }
    final balance = _balance.cached;
    if (balance == null) return null;
    final rewarded = balance.rewarded;
    if (!rewarded.enabled || balance.free.remaining > 0) {
      return RewardUnavailableReason.disabled;
    }
    if (rewarded.available) return null;
    final cooldownEndsAt = rewarded.cooldownEndsAt;
    return cooldownEndsAt != null && cooldownEndsAt.isAfter(_clock.now())
        ? RewardUnavailableReason.cooldown
        : RewardUnavailableReason.cap;
  }

  /// Creates an intent, shows the ad and polls for the SSV grant.
  Future<Result<RewardOutcome>> call({required String adUnitId}) async {
    final reason = unavailableReason();
    if (reason != null) {
      return Result.err(Failure.rewardUnavailable(reason: reason));
    }
    final created = await _gateway.createIntent(adUnitId);
    if (created case Err(:final failure)) return Result.err(failure);
    final intent = created.valueOrNull!;
    final shown = await _ads.showRewarded(intent);
    switch (shown) {
      case Ok(value: RewardedShowResult.earned):
        return Result.ok(await _awaitGrant(intent.intentId));
      case Ok(value: RewardedShowResult.dismissedEarly):
        await _gateway.cancel(intent.intentId);
        return const Result.ok(RewardOutcome.dismissed());
      case Ok(value: RewardedShowResult.failedToShow) ||
          Ok(value: RewardedShowResult.noFill):
        await _gateway.cancel(intent.intentId);
        return const Result.err(
          Failure.rewardUnavailable(reason: RewardUnavailableReason.noFill),
        );
      case Err(:final failure):
        await _gateway.cancel(intent.intentId);
        return Result.err(failure);
    }
  }

  Future<RewardOutcome> _awaitGrant(IntentId intentId) async {
    final deadline = _clock.now().add(_config.current.rewardedGrantPollTimeout);
    while (true) {
      final status = await _gateway.status(intentId);
      switch (status) {
        case Ok(value: RewardStatus(state: RewardIntentState.granted)):
          final value = status.valueOrNull!;
          final balance = value.balance;
          if (balance != null) await _balance.apply(balance);
          return RewardOutcome.granted(amount: value.amount);
        case Ok(value: RewardStatus(state: RewardIntentState.issued)):
          break;
        case Ok(:final value):
          return RewardOutcome.notGranted(value.state);
        case Err(:final failure):
          _logger.info('reward poll failed: ${failure.code}');
      }
      if (!_clock.now().isBefore(deadline)) {
        return const RewardOutcome.delayed();
      }
      await _delay(pollInterval);
    }
  }
}
