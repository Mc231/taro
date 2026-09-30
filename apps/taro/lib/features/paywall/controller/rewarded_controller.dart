import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro_core/taro_core.dart';

part 'rewarded_controller.freezed.dart';

/// S12 rewarded flow overlay (04 §9.2, 01 §8.3, RC33, RC57).
@freezed
sealed class RewardedState with _$RewardedState {
  /// Creating the intent and loading the ad (≤ `rewarded.loadTimeoutSec`).
  const factory RewardedState.loadingAd() = RewardedLoadingAd;

  /// The SDK shows the ad (not customised).
  const factory RewardedState.showing() = RewardedShowing;

  /// Polling the intent every 1.5 s up to `rewarded.grantPollTimeoutSec`
  /// for the SSV grant (RC33).
  const factory RewardedState.granting() = RewardedGranting;

  /// The Worker granted [amount] reading(s); "Continue" returns to S07.
  const factory RewardedState.granted({required int amount}) = RewardedGranted;

  /// The poll timed out: "Your reading will appear shortly" (re-synced on
  /// resume).
  const factory RewardedState.grantDelayed() = RewardedGrantDelayed;

  /// The ad closed early: no reward, neutral copy; the intent was cancelled
  /// so the cap slot is free (RC57).
  const factory RewardedState.dismissedEarly() = RewardedDismissedEarly;

  /// No ad to show (or it failed to show): the intent was cancelled and the
  /// S10 row greys out for 60 s.
  const factory RewardedState.noFill() = RewardedNoFill;

  /// Not eligible any more (cap, cooldown, consent, disabled).
  const factory RewardedState.unavailable(RewardUnavailableReason reason) =
      RewardedUnavailable;

  /// Offline or a Worker error; the intent (if any) was cancelled.
  const factory RewardedState.failed(ErrorKind kind) = RewardedFailed;
}

/// Waits between grant polls; tests advance a fake clock instead.
final rewardedPollDelayProvider = Provider<Delay>(
  (ref) => Future<void>.delayed,
);

/// Drives S12 over [EarnReward]: intent → show → poll (04 §9.2). The client
/// never grants: a grant is applied only from the Worker's status (AR8).
final class RewardedController extends Notifier<RewardedState> {
  bool _started = false;
  DateTime? _earnedAt;

  @override
  RewardedState build() => const RewardedState.loadingAd();

  /// Runs the flow once (the overlay calls it when it opens).
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final clock = ref.read(clockProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final noFill = ref.read(rewardedNoFillProvider.notifier);
    final earn = EarnReward(
      gateway: _ObservedGateway(
        ref.read(rewardGatewayProvider),
        onPoll: () => _enter(const RewardedState.granting()),
      ),
      ads: _ObservedAds(
        ref.read(adsServiceProvider),
        onShow: () => _enter(const RewardedState.showing()),
        onShown: () => _earnedAt = clock.now(),
      ),
      balance: ref.read(balanceRepositoryProvider),
      config: ref.read(remoteConfigRepositoryProvider),
      consent: ref.read(consentStoreProvider),
      connectivity: ref.read(connectivityMonitorProvider),
      clock: clock,
      logger: ref.read(loggerProvider).child('rewarded'),
      delay: ref.read(rewardedPollDelayProvider),
    );
    final result = await earn(adUnitId: _adUnitId());
    final waitMs = _earnedAt == null
        ? 0
        : clock.now().difference(_earnedAt!).inMilliseconds;
    switch (result) {
      case Ok(value: RewardGranted(:final amount)):
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.completed),
        );
        await analytics.log(
          RewardedGrantResultEvent(
            result: RewardedGrantResult.granted,
            waitMs: waitMs,
          ),
        );
        _enter(RewardedState.granted(amount: amount));
      case Ok(value: RewardDelayed()):
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.completed),
        );
        await analytics.log(
          RewardedGrantResultEvent(
            result: RewardedGrantResult.delayed,
            waitMs: waitMs,
          ),
        );
        _enter(const RewardedState.grantDelayed());
      case Ok(value: RewardNotGranted()):
        // Rejected / expired / cancelled by the Worker: nothing was added.
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.completed),
        );
        _enter(const RewardedState.failed(ErrorKind.server));
      case Ok(value: RewardDismissed()):
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.dismissed),
        );
        _enter(const RewardedState.dismissedEarly());
      case Err(
        failure: RewardUnavailableFailure(
          reason: RewardUnavailableReason.noFill,
        ),
      ):
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.noFill),
        );
        noFill.recordNoFill(clock.now());
        _enter(const RewardedState.noFill());
      case Err(failure: RewardUnavailableFailure(:final reason)):
        final grant = switch (reason) {
          RewardUnavailableReason.cap => RewardedGrantResult.capped,
          RewardUnavailableReason.cooldown => RewardedGrantResult.cooldown,
          _ => null,
        };
        if (grant != null) {
          await analytics.log(
            RewardedGrantResultEvent(result: grant, waitMs: 0),
          );
        }
        _enter(RewardedState.unavailable(reason));
      case Err(:final failure):
        await analytics.log(
          const RewardedAdResultEvent(result: RewardedAdResult.error),
        );
        _enter(RewardedState.failed(ErrorKind.fromFailure(failure)));
    }
  }

  String _adUnitId() {
    final flavor = ref.read(flavorConfigProvider);
    return switch (ref.read(appInfoProvider).platform) {
      AppPlatform.ios => flavor.admobIos.rewarded,
      AppPlatform.android => flavor.admobAndroid.rewarded,
    };
  }

  void _enter(RewardedState next) {
    if (ref.mounted) state = next;
  }
}

/// S12 controller (auto-disposed with the overlay).
final NotifierProvider<RewardedController, RewardedState>
rewardedControllerProvider = NotifierProvider.autoDispose(
  RewardedController.new,
);

/// Reports the first status poll (the `granting` phase).
final class _ObservedGateway implements RewardGateway {
  _ObservedGateway(this._inner, {required this.onPoll});

  final RewardGateway _inner;
  final void Function() onPoll;
  bool _polled = false;

  @override
  Future<Result<RewardIntent>> createIntent(String adUnitId) =>
      _inner.createIntent(adUnitId);

  @override
  Future<Result<RewardStatus>> status(IntentId intentId) {
    if (!_polled) {
      _polled = true;
      onPoll();
    }
    return _inner.status(intentId);
  }

  @override
  Future<void> cancel(IntentId intentId) => _inner.cancel(intentId);
}

/// Reports the ad show (the `showing` phase) and its end.
final class _ObservedAds implements AdsService {
  _ObservedAds(this._inner, {required this.onShow, required this.onShown});

  final AdsService _inner;
  final void Function() onShow;
  final void Function() onShown;

  @override
  Future<void> initialize(AdRequestPolicy policy) => _inner.initialize(policy);

  @override
  bool get isInitialized => _inner.isInitialized;

  @override
  Future<void> preloadRewarded() => _inner.preloadRewarded();

  @override
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent) async {
    onShow();
    final shown = await _inner.showRewarded(intent);
    onShown();
    return shown;
  }
}
