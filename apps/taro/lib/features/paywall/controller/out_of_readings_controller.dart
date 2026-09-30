import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro_core/taro_core.dart';

part 'out_of_readings_controller.freezed.dart';

/// S10 out-of-readings sheet (MO13, 04 §11, 01 §8.3).
@freezed
sealed class OutOfReadingsState with _$OutOfReadingsState {
  /// The sheet: always the free path ("Next free reading in …" from server
  /// time), the rewarded row when eligible, and the packs.
  const factory OutOfReadingsState.content({
    /// The rewarded row (RC34, RC35).
    required RewardedOption rewarded,

    /// The pack area.
    required PaywallPacks packs,

    /// The `lowTrustLimited` copy variant (RC74): "Free readings aren't
    /// available on this device right now".
    required bool lowTrustLimited,

    /// Time until the next free reading, from server time (`free.resetsAt`,
    /// 01 §7.1); `null` before the first balance.
    Duration? nextFreeIn,

    /// The reset instant on the device clock ("at 00:00").
    DateTime? nextFreeAt,
  }) = OutOfReadingsContent;

  /// A grant or purchase made a reading available: the sheet closes and S07
  /// shows Begin enabled; nothing auto-starts (RC58, 01 F3).
  const factory OutOfReadingsState.resolved() = OutOfReadingsResolved;
}

/// Drives S10 for one opening [source] (`out_of_readings_viewed.source`).
///
/// The balance, config and no-fill pause are listened to, so the sheet
/// follows syncs, grants and purchases; it never computes a balance (AR8).
final class OutOfReadingsController extends Notifier<OutOfReadingsState> {
  /// A controller for a sheet opened from [source].
  OutOfReadingsController(this.source);

  /// Where the sheet was opened from.
  final OutOfReadingsSource source;

  late ProviderSubscription<CreditBalance?> _balance;
  late ProviderSubscription<RemoteConfig> _config;
  late ProviderSubscription<DateTime?> _noFill;
  PaywallPacks _listing = const PaywallPacks.loading();
  DateTime? _openedAt;
  bool _wasBlocked = false;
  PaywallAction _action = PaywallAction.none;
  bool _dismissed = false;
  Timer? _wake;
  DateTime? _resyncedFor;

  Clock get _clock => ref.read(clockProvider);

  @override
  OutOfReadingsState build() {
    _balance = ref.listen(balanceProvider, (_, _) => _update());
    _config = ref.listen(remoteConfigProvider, (_, _) => _update());
    _noFill = ref.listen(rewardedNoFillProvider, (_, _) => _update());
    ref.onDispose(() => _wake?.cancel());
    _openedAt = _clock.now();
    _wasBlocked = !(_balance.read()?.canRead ?? false);
    final (:state, :evaluation) = _compute();
    unawaited(_opened(evaluation));
    return state;
  }

  /// Re-evaluates the sheet (the view's countdown ticker may call it).
  void refresh() => _update();

  /// Retries the store listing after `unavailable`.
  Future<void> retryPacks() async {
    _listing = const PaywallPacks.loading();
    _update();
    await _loadPacks();
  }

  /// The rewarded row was tapped; returns whether S12 may open.
  Future<bool> tapRewarded() async {
    if (state case OutOfReadingsContent(
      :final rewarded,
    ) when rewarded.isAvailable) {
      _action = PaywallAction.reward;
      await ref
          .read(analyticsServiceProvider)
          .log(
            const RewardedOfferTappedEvent(
              source: RewardedSource.outOfReadings,
            ),
          );
      return true;
    }
    return false;
  }

  /// "Get more readings" (→ S11); returns whether packs can be bought.
  bool tapGetMore() {
    if (state case OutOfReadingsContent(packs: PaywallPacksBlocked())) {
      return false;
    }
    _action = PaywallAction.purchase;
    return true;
  }

  /// The sheet closed ("Not now", swipe, back): logs `paywall_dismissed`
  /// once.
  Future<void> dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    final opened = _openedAt ?? _clock.now();
    await ref
        .read(analyticsServiceProvider)
        .log(
          PaywallDismissedEvent(
            surface: PaywallSurface.outOfReadings,
            secondsVisible: _clock.now().difference(opened).inSeconds,
            actionTaken: _action,
          ),
        );
  }

  Future<void> _opened(RewardedEvaluation evaluation) async {
    final analytics = ref.read(analyticsServiceProvider);
    final ads = ref.read(adsServiceProvider);
    final balance = _balance.read();
    final nextFreeIn = balance == null
        ? null
        : ResetSchedule.untilNextFree(balance, _clock.now());
    await analytics.log(
      OutOfReadingsViewedEvent(
        source: source,
        rewardedAvailable: evaluation.option.isAvailable,
        freeResetInMin: nextFreeIn?.inMinutes ?? 0,
      ),
    );
    await analytics.log(
      RewardedOfferShownEvent(
        eligible: evaluation.option.isAvailable,
        ineligibleReason: evaluation.reason,
      ),
    );
    // Rewarded ads load lazily when S10 opens (Phase 12, 04 §9.2).
    if (evaluation.option.isAvailable) {
      await ads.preloadRewarded();
    }
    await _loadPacks();
  }

  Future<void> _loadPacks() async {
    if (!ref.mounted) return;
    final loaded = await loadPaywallCatalog(ref);
    if (!ref.mounted) return;
    _listing = switch (loaded) {
      Ok(:final value) when value.packs.isNotEmpty => PaywallPacks.loaded(
        value,
      ),
      _ => const PaywallPacks.unavailable(),
    };
    _update();
  }

  void _update() {
    if (!ref.mounted) return;
    state = _compute().state;
  }

  ({OutOfReadingsState state, RewardedEvaluation evaluation}) _compute() {
    final balance = _balance.read();
    final config = _config.read();
    final now = _clock.now();
    final evaluation = evaluateRewarded(
      earnReward: ref.read(earnRewardProvider),
      balance: balance,
      noFillUntil: _noFill.read(),
      now: now,
    );
    _schedule(evaluation.option, balance);
    if (_wasBlocked && (balance?.canRead ?? false)) {
      return (
        state: const OutOfReadingsState.resolved(),
        evaluation: evaluation,
      );
    }
    final blocked = packsBlockedReason(config, balance);
    return (
      state: OutOfReadingsState.content(
        rewarded: evaluation.option,
        packs: blocked == null
            ? _listing
            : PaywallPacks.purchasesBlocked(blocked),
        lowTrustLimited:
            source == OutOfReadingsSource.lowTrust ||
            balance?.canReadReason == CanReadReason.lowTrustCap,
        nextFreeIn: balance == null
            ? null
            : ResetSchedule.untilNextFree(balance, now),
        nextFreeAt: balance == null
            ? null
            : ResetSchedule.nextSyncAt(balance, now),
      ),
      evaluation: evaluation,
    );
  }

  /// Wakes up when a cooldown or no-fill pause ends. A cooldown that has
  /// ended while the cached balance still says "not available" needs a
  /// balance sync (the Worker decides availability, AR8); it is requested
  /// once per cooldown.
  void _schedule(RewardedOption option, CreditBalance? balance) {
    _wake?.cancel();
    _wake = null;
    final cooldown = balance?.rewarded.cooldownEndsAt;
    if (option is RewardedOptionCapped &&
        cooldown != null &&
        !cooldown.isAfter(_clock.now()) &&
        _resyncedFor != cooldown) {
      _resyncedFor = cooldown;
      scheduleMicrotask(() {
        if (ref.mounted) {
          unawaited(ref.read(balanceProvider.notifier).refresh());
        }
      });
    }
    final until = option.waitsUntil;
    if (until == null) return;
    // `until` is in the future: the option waits only while it is.
    _wake = Timer(until.difference(_clock.now()), () {
      if (ref.mounted) _update();
    });
  }
}

/// S10 controllers by opening source (auto-disposed with the sheet).
final NotifierProviderFamily<
  OutOfReadingsController,
  OutOfReadingsState,
  OutOfReadingsSource
>
outOfReadingsControllerProvider = NotifierProvider.autoDispose.family(
  OutOfReadingsController.new,
);
