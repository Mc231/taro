import 'package:flutter/widgets.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Localised text for a [Failure], a refusal and an [ErrorKind] (RC5,
/// RC94, GLOSSARY §5, §16.1). Widgets never show a raw code or message.
abstract final class FailureMessage {
  /// The one-sentence message of [failure] (its `failure*` ARB key).
  static String of(BuildContext context, Failure failure) =>
      ofL10n(TaroLocalizations.of(context), failure);

  /// [of] with explicit localizations (tests, share text).
  static String ofL10n(TaroLocalizations l10n, Failure failure) =>
      switch (failure) {
        NetworkFailure() => l10n.failureNetwork,
        TimeoutFailure() => l10n.failureTimeout,
        ServerFailure() => l10n.failureServer,
        RateLimitedFailure() => l10n.failureRateLimited,
        UpgradeRequiredFailure() => l10n.failureUpgradeRequired,
        ContractFailure() => l10n.failureContract,
        SessionExpiredFailure() => l10n.failureSessionExpired,
        AttestationFailure() => l10n.failureAttestation,
        InsufficientCreditsFailure() => l10n.failureInsufficientCredits,
        HoldConflictFailure() => l10n.failureHoldConflict,
        ReadingExpiredRefundedFailure() => l10n.failureReadingExpiredRefunded,
        AiConsentRequiredFailure() => l10n.failureAiConsentRequired,
        AiUnavailableRegionFailure() => l10n.failureAiUnavailableRegion,
        ReadingsPausedFailure() => l10n.failureReadingsPaused,
        AiUnavailableFailure() => l10n.failureAiUnavailable,
        RequestInProgressFailure() => l10n.failureRequestInProgress,
        RewardUnavailableFailure() => l10n.failureRewardUnavailable,
        TimezoneChangeRejectedFailure() => l10n.failureTimezoneChangeRejected,
        PurchaseCancelledFailure() => l10n.failurePurchaseCancelled,
        PurchasePendingFailure() => l10n.failurePurchasePending,
        PurchaseFailure() => l10n.failurePurchase,
        PurchaseAlreadyClaimedFailure() => l10n.failurePurchaseAlreadyClaimed,
        PurchasesBlockedFailure() => l10n.failurePurchasesBlocked,
        ProductUnavailableFailure() => l10n.failureProductUnavailable,
        StorageFailure() => l10n.failureStorage,
        BackupInvalidFailure() => l10n.failureBackupInvalid,
        UnexpectedFailure() => l10n.failureUnexpected,
      };

  /// The refusal card text of [category] (its `messageKey`; GLOSSARY §5.2,
  /// with `refusalGeneric` for `other`).
  static String refusal(TaroLocalizations l10n, RefusalCategory category) =>
      switch (category) {
        RefusalCategory.health => l10n.safetyDeclinedHealth,
        RefusalCategory.pregnancy => l10n.safetyDeclinedPregnancy,
        RefusalCategory.death => l10n.safetyDeclinedDeath,
        RefusalCategory.legal => l10n.safetyDeclinedLegal,
        RefusalCategory.financial => l10n.safetyDeclinedFinancial,
        RefusalCategory.gambling => l10n.safetyDeclinedGambling,
        RefusalCategory.selfHarm => l10n.safetyDeclinedSelfHarm,
        RefusalCategory.harmToOthers => l10n.safetyDeclinedHarmToOthers,
        RefusalCategory.sexualMinors => l10n.safetyDeclinedSexualMinors,
        RefusalCategory.hateOrHarassment => l10n.safetyDeclinedHateOrHarassment,
        RefusalCategory.other => l10n.refusalGeneric,
      };

  /// The text of a Worker or `Failure` message key (`failure*`,
  /// `safetyDeclined*`, `refusalGeneric`); an unknown key falls back to
  /// `refusalGeneric` for `safetyDeclined*` keys and to `failureUnexpected`
  /// otherwise, so a new server key never shows raw.
  static String forKey(TaroLocalizations l10n, String key) {
    for (final category in RefusalCategory.values) {
      if (category.messageKey == key) return refusal(l10n, category);
    }
    final failure = _byKey[key];
    if (failure != null) return ofL10n(l10n, failure);
    return key.startsWith('safetyDeclined')
        ? l10n.refusalGeneric
        : l10n.failureUnexpected;
  }

  /// The title of an error state of [kind] (01 §8.2).
  static String title(TaroLocalizations l10n, ErrorKind kind) => switch (kind) {
    ErrorKind.network => l10n.errorNetworkTitle,
    ErrorKind.server => l10n.errorServerTitle,
    ErrorKind.rateLimited => l10n.errorRateLimitedTitle,
    ErrorKind.deviceUnverified => l10n.errorDeviceUnverifiedTitle,
    ErrorKind.storage => l10n.errorStorageTitle,
    ErrorKind.invalidFile => l10n.errorInvalidFileTitle,
    ErrorKind.unknown => l10n.errorUnknownTitle,
  };

  /// The body of an error state of [kind] (01 §8.2).
  static String body(TaroLocalizations l10n, ErrorKind kind) => switch (kind) {
    ErrorKind.network => l10n.errorNetworkBody,
    ErrorKind.server => l10n.errorServerBody,
    ErrorKind.rateLimited => l10n.errorRateLimitedBody,
    ErrorKind.deviceUnverified => l10n.errorDeviceUnverifiedBody,
    ErrorKind.storage => l10n.errorStorageBody,
    ErrorKind.invalidFile => l10n.errorInvalidFileBody,
    ErrorKind.unknown => l10n.errorUnknownBody,
  };

  /// The `taro_ui` visual kind of [kind] (`taro_ui` cannot import
  /// `taro_core`, RC95).
  static TaroErrorKind visual(ErrorKind kind) => switch (kind) {
    ErrorKind.network => TaroErrorKind.network,
    ErrorKind.server => TaroErrorKind.server,
    ErrorKind.rateLimited => TaroErrorKind.rateLimited,
    ErrorKind.deviceUnverified => TaroErrorKind.deviceUnverified,
    ErrorKind.storage => TaroErrorKind.storage,
    ErrorKind.invalidFile => TaroErrorKind.invalidFile,
    ErrorKind.unknown => TaroErrorKind.unknown,
  };

  // One representative failure per message key (fields do not change it).
  static final Map<String, Failure> _byKey = {
    for (final f in <Failure>[
      const Failure.network(),
      const Failure.timeout(),
      const Failure.server(status: 500),
      const Failure.rateLimited(reason: RateLimitReason.burst),
      const Failure.upgradeRequired(),
      const Failure.contract(wireCode: 'VALIDATION_FAILED'),
      const Failure.sessionExpired(),
      const Failure.attestation(kind: AttestationFailureKind.rejected),
      const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      const Failure.holdConflict(),
      const Failure.readingExpiredRefunded(),
      const Failure.aiConsentRequired(),
      const Failure.aiUnavailableRegion(),
      const Failure.readingsPaused(reason: PausedReason.disabled),
      const Failure.aiUnavailable(),
      const Failure.requestInProgress(),
      const Failure.rewardUnavailable(reason: RewardUnavailableReason.noFill),
      Failure.timezoneChangeRejected(
        allowedAfter: DateTime.utc(1970),
      ),
      const Failure.purchaseCancelled(),
      const Failure.purchasePending(),
      const Failure.purchase(wireCode: 'PURCHASE_INVALID'),
      const Failure.purchaseAlreadyClaimed(transferEligible: false),
      const Failure.purchasesBlocked(reason: PurchasesBlockedReason.blocked),
      const Failure.productUnavailable(),
      const Failure.storage(),
      const Failure.backupInvalid(reason: BackupInvalidReason.notJson),
      const Failure.unexpected(error: 'unknown', stack: StackTrace.empty),
    ])
      f.messageKey: f,
  };
}

/// A full-screen error for a failure (01 §8.2): [TaroErrorView] with the
/// localised title and body of its [ErrorKind] and, when [onRetry] is set,
/// a Try again button. [secondaryAction] adds another action (e.g.
/// "Contact support").
class FailureView extends StatelessWidget {
  /// Creates the view.
  const FailureView({
    required this.kind,
    this.onRetry,
    this.secondaryAction,
    super.key,
  });

  /// The view of [failure].
  factory FailureView.of(
    Failure failure, {
    VoidCallback? onRetry,
    Widget? secondaryAction,
    Key? key,
  }) => FailureView(
    kind: ErrorKind.fromFailure(failure),
    onRetry: onRetry,
    secondaryAction: secondaryAction,
    key: key,
  );

  /// What went wrong.
  final ErrorKind kind;

  /// Retries.
  final VoidCallback? onRetry;

  /// Another action.
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroErrorView(
      kind: FailureMessage.visual(kind),
      title: FailureMessage.title(l10n, kind),
      body: FailureMessage.body(l10n, kind),
      onRetry: onRetry,
      retryLabel: onRetry == null ? null : l10n.commonRetry,
      secondaryAction: secondaryAction,
    );
  }
}
