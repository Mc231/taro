import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/consent_state.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/install_identity.dart';
import 'package:taro_core/src/model/remote_config.dart';
import 'package:taro_core/src/model/spread.dart';

part 'reading_gate.freezed.dart';

/// Why the paywall (S10) opens (02 §4.1, RC74).
enum PaywallReason {
  /// Nothing left to spend.
  noCredits,

  /// The low-trust cap: S10 with the `lowTrustLimited` copy.
  lowTrustCap,
}

/// What the out-of-readings sheet (S10) offers (02 §4.1, 04 §5.5).
///
/// Store availability is not decided here: the sheet reads
/// `CreditBalance.purchasesAllowed` / `purchasesBlockedReason` (RC66).
@freezed
abstract class PaywallOptions with _$PaywallOptions {
  /// Creates the options.
  const factory PaywallOptions({
    /// Why the paywall opens.
    required PaywallReason reason,

    /// Enabled `store.packs` in `sortOrder`; empty when `store.enabled` is
    /// off.
    required List<StorePack> packs,

    /// Whether a rewarded ad may be offered (RC34: only when
    /// `free.remaining == 0`).
    required bool rewardedAvailable,

    /// When the next free reading arrives (`free.resetsAt`, server time);
    /// `null` when no free reading is coming (low-trust cap, zero limit).
    required DateTime? nextFreeAt,
  }) = _PaywallOptions;
}

/// The [GateDecision] variant without its payload (`GateDecision.kind`);
/// also `reading_gate_evaluated.decision`, whose wire value is the
/// snake_case name (02 §4.1).
enum GateDecisionKind {
  /// `deviceUnverified()`.
  deviceUnverified,

  /// `needsAiConsent()`.
  needsAiConsent,

  /// `offline()`.
  offline,

  /// `readingsPaused()`.
  readingsPaused,

  /// `aiUnavailableRegion()`.
  aiUnavailableRegion,

  /// `spreadDisabled()`.
  spreadDisabled,

  /// `needsCredits()`: the paywall.
  needsCredits,

  /// `dailyLimitReached()`.
  dailyLimitReached,

  /// `needsSync()`.
  needsSync,

  /// `allowed()`.
  allowed,
}

/// The outcome of the pre-draw gate (02 §4.1, RC44, RC74, GLOSSARY §9).
@freezed
sealed class GateDecision with _$GateDecision {
  const GateDecision._();

  /// The install is not registered with the Worker.
  const factory GateDecision.deviceUnverified() = GateDeviceUnverified;

  /// AI consent is missing or older than `ai.consentVersion` (RC21) → S04.
  const factory GateDecision.needsAiConsent() = GateNeedsAiConsent;

  /// No connection: Begin disabled with an inline notice.
  const factory GateDecision.offline() = GateOffline;

  /// S31 with the Classic-reading offer; never a paywall (RC47).
  /// [freePaused] selects the "Free readings are resting until tomorrow"
  /// copy (RC64).
  const factory GateDecision.readingsPaused({
    @Default(false) bool freePaused,
  }) = GateReadingsPaused;

  /// AI readings are not offered in this region (RC29) → Classic offer.
  const factory GateDecision.aiUnavailableRegion() = GateAiUnavailableRegion;

  /// The spread is not in `spreads.enabled`.
  const factory GateDecision.spreadDisabled() = GateSpreadDisabled;

  /// The paywall (S10) before anything is drawn.
  const factory GateDecision.needsCredits(PaywallOptions options) =
      GateNeedsCredits;

  /// `readings.maxPerInstallPerDay` reached: S07 `dailyLimitReached`, no
  /// paywall (RC74).
  const factory GateDecision.dailyLimitReached() = GateDailyLimitReached;

  /// The balance is missing or stale: `GET /v1/balance` first.
  const factory GateDecision.needsSync() = GateNeedsSync;

  /// The reading may start; [expected] is the bucket the Worker should
  /// charge. The pre-draw hold (RC50) is still the authority.
  const factory GateDecision.allowed(ChargeSource expected) = GateAllowed;

  /// The variant, for analytics (`reading_gate_evaluated.decision`).
  GateDecisionKind get kind => switch (this) {
    GateDeviceUnverified() => GateDecisionKind.deviceUnverified,
    GateNeedsAiConsent() => GateDecisionKind.needsAiConsent,
    GateOffline() => GateDecisionKind.offline,
    GateReadingsPaused() => GateDecisionKind.readingsPaused,
    GateAiUnavailableRegion() => GateDecisionKind.aiUnavailableRegion,
    GateSpreadDisabled() => GateDecisionKind.spreadDisabled,
    GateNeedsCredits() => GateDecisionKind.needsCredits,
    GateDailyLimitReached() => GateDecisionKind.dailyLimitReached,
    GateNeedsSync() => GateDecisionKind.needsSync,
    GateAllowed() => GateDecisionKind.allowed,
  };
}

/// The single "paywall before the draw" check (02 §4.1, 04 §5.5, RC44).
///
/// Checks run in this order and the first failing one wins:
/// registration/trust → AI consent → online → `readings.enabled` / region →
/// spread enabled → balance. It is followed by the Worker pre-draw hold
/// (RC50), which is the authority.
abstract final class ReadingGate {
  /// Evaluates the gate.
  ///
  /// [aiRegionBlocked] is the caller's memory of a previous
  /// `403 AI_UNAVAILABLE_REGION` (02 §4.1 has no region input; the client
  /// never knows its region otherwise).
  static GateDecision evaluate({
    required InstallIdentity install,
    required CreditBalance? balance,
    required RemoteConfig config,
    required ConsentState consent,
    required bool online,
    required SpreadDefinition spread,
    required DateTime now,
    bool aiRegionBlocked = false,
  }) {
    if (!install.isRegistered) return const GateDecision.deviceUnverified();
    if (!consent.ai.isValidFor(config.aiConsentVersion)) {
      return const GateDecision.needsAiConsent();
    }
    if (!online) return const GateDecision.offline();
    if (!config.readingsEnabled) return const GateDecision.readingsPaused();
    if (aiRegionBlocked) return const GateDecision.aiUnavailableRegion();
    if (!spread.enabled || !config.isSpreadEnabled(spread.id)) {
      return const GateDecision.spreadDisabled();
    }
    if (balance == null || balance.isStaleAt(now, config.balanceStaleAfter)) {
      return const GateDecision.needsSync();
    }
    return _balanceStep(balance, config, consent, online: online, now: now);
  }

  static GateDecision _balanceStep(
    CreditBalance balance,
    RemoteConfig config,
    ConsentState consent, {
    required bool online,
    required DateTime now,
  }) {
    if (balance.canRead) {
      final source = balance.nextSource ?? _inferSource(balance);
      return source == null
          ? const GateDecision.needsSync()
          : GateDecision.allowed(source);
    }
    final nothingElse = balance.bonus <= 0 && balance.displayPaid <= 0;
    switch (balance.canReadReason) {
      case CanReadReason.dailyLimit:
        return const GateDecision.dailyLimitReached();
      case CanReadReason.readingsPaused:
        return GateDecision.readingsPaused(
          freePaused: balance.free.paused && nothingElse,
        );
      case CanReadReason.lowTrustCap:
        return GateDecision.needsCredits(
          paywall(
            balance,
            config,
            consent,
            reason: PaywallReason.lowTrustCap,
            online: online,
            now: now,
          ),
        );
      case CanReadReason.noCredits:
      case null:
        if (balance.free.paused && nothingElse) {
          return const GateDecision.readingsPaused(freePaused: true);
        }
        return GateDecision.needsCredits(
          paywall(
            balance,
            config,
            consent,
            reason: PaywallReason.noCredits,
            online: online,
            now: now,
          ),
        );
    }
  }

  /// The bucket the Worker charges first (free → bonus → paid), for a
  /// balance whose `nextSource` is missing.
  static ChargeSource? _inferSource(CreditBalance b) {
    if (b.free.remaining > 0 && !b.free.paused) return ChargeSource.free;
    if (b.bonus > 0) return ChargeSource.bonus;
    if (b.paid > 0) return ChargeSource.paid;
    return null;
  }

  /// Builds the S10 options for [reason] (also used when a hold returns
  /// `402`, 04 §5.5).
  ///
  /// `rewardedAvailable = rewarded.available && free.remaining == 0 &&
  /// canRequestAds && online` (04 §5.5, RC34), additionally requiring
  /// `ads.enabled`, `rewarded.enabled` and a passed cooldown (RC57).
  static PaywallOptions paywall(
    CreditBalance balance,
    RemoteConfig config,
    ConsentState consent, {
    required PaywallReason reason,
    required bool online,
    required DateTime now,
  }) {
    final cooldown = balance.rewarded.cooldownEndsAt;
    final rewardedAvailable =
        balance.rewarded.available &&
        balance.free.remaining == 0 &&
        consent.ads.canRequestAds &&
        online &&
        config.adsEnabled &&
        config.rewardedEnabled &&
        (cooldown == null || !now.isBefore(cooldown));
    final freeComing =
        reason == PaywallReason.noCredits && balance.free.limit > 0;
    return PaywallOptions(
      reason: reason,
      packs: config.storeEnabled ? config.enabledPacks : const [],
      rewardedAvailable: rewardedAvailable,
      nextFreeAt: freeComing ? balance.free.resetsAt : null,
    );
  }
}
