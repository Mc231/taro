import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';

part 'failure.freezed.dart';

/// Why the Worker answered `429 RATE_LIMITED` (`details.reason`, 03 §2.2).
enum RateLimitReason {
  /// Too many requests in a short window.
  burst,

  /// `readings.maxPerInstallPerDay` reached: S07 `dailyLimitReached`, never
  /// a paywall (RC74).
  dailyLimit,

  /// `safety.maxDeclinedPerDay` reached.
  declinedLimit,

  /// The low-trust daily cap was reached (RC74).
  lowTrustCap,

  /// Too many reading reports (S33 `rateLimited`, RC72).
  reportLimit,
}

/// Why the Worker answered `402 INSUFFICIENT_CREDITS` (`details.reason`).
enum InsufficientReason {
  /// No free, bonus or paid readings left: S10 paywall.
  noCredits,

  /// A low-trust install hit its cap: `lowTrustLimited` copy (RC74).
  lowTrustCap,

  /// Free readings are paused by the budget free stop: S31 `freePaused`
  /// variant (RC64).
  freePaused,
}

/// Why readings are paused (`503 READINGS_DISABLED | AI_BUDGET_EXHAUSTED`).
///
/// Always S31 `readingsPaused` with the Classic offer, never S10 (RC47).
enum PausedReason {
  /// The `readings.enabled` kill switch is off (`READINGS_DISABLED`).
  disabled,

  /// The hard AI budget tier is exhausted (`AI_BUDGET_EXHAUSTED`,
  /// `tier: hard`).
  budgetHard,

  /// The free-stop budget tier is active (`AI_BUDGET_EXHAUSTED`,
  /// `tier: freeStop`, RC64).
  freeStop,
}

/// Why a rewarded ad cannot be offered or granted (RC57).
enum RewardUnavailableReason {
  /// `403 REWARDED_DISABLED`.
  disabled,

  /// `409 REWARDED_DAILY_CAP` with `reason: cap`.
  cap,

  /// `409 REWARDED_DAILY_CAP` with `reason: cooldown`.
  cooldown,

  /// The ad network had no fill (client side).
  noFill,

  /// Ads cannot be requested without consent (client side).
  consent,
}

/// What went wrong with device attestation (02 §6.4).
enum AttestationFailureKind {
  /// The device or OS does not support attestation.
  unsupported,

  /// The attestation key was invalidated and must be regenerated.
  keyInvalidated,

  /// The Worker rejected the attestation.
  rejected,

  /// The platform attestation quota is exhausted.
  quota,

  /// A transient error; retry later.
  transient,
}

/// Why purchases are blocked (`BalanceDto.purchasesBlockedReason`, RC66).
enum PurchasesBlockedReason {
  /// The install is blocked.
  blocked,

  /// The install owes readings after a refund.
  refundDebt,

  /// The store kill switch is off.
  storeDisabled,
}

/// Why a backup file cannot be imported (01 §7.11).
enum BackupInvalidReason {
  /// The file is not JSON.
  notJson,

  /// The JSON is not a Taro backup.
  wrongFormat,

  /// `schemaVersion` is newer than this app supports.
  unsupportedVersion,

  /// The checksum does not match the content.
  checksum,

  /// The content violates `backup_schema_v1.json`.
  schema,

  /// The file exceeds the size or entry limits.
  tooLarge,
}

/// Every way an operation can fail (02 §3, GLOSSARY §5).
///
/// Sealed: `switch` on it exhaustively. Every case has a factory on
/// `Failure` (sealed-factory rule). [code] is a stable UPPER_SNAKE key for
/// analytics and logs; it equals the Worker error code (03 §2.2) wherever the
/// failure maps to exactly one wire code for the given fields.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  // Transport ---------------------------------------------------------------

  /// Offline, DNS or socket error.
  const factory Failure.network() = NetworkFailure;

  /// The client-side request timeout elapsed.
  const factory Failure.timeout() = TimeoutFailure;

  /// `500 INTERNAL`, an unknown error code, or an unparseable response.
  ///
  /// [wireCode] is the raw `error.code` when the Worker sent one.
  const factory Failure.server({
    required int status,
    String? wireCode,
    String? requestId,
  }) = ServerFailure;

  /// `429 RATE_LIMITED`.
  const factory Failure.rateLimited({
    required RateLimitReason reason,
    Duration? retryAfter,
  }) = RateLimitedFailure;

  /// `426 UPGRADE_REQUIRED`: route to S30 `/update`.
  const factory Failure.upgradeRequired({String? storeUrl}) =
      UpgradeRequiredFailure;

  /// A client bug: `VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REQUIRED`,
  /// `NOT_FOUND`, `IDEMPOTENCY_KEY_REUSED` or `SPREAD_INVALID`.
  ///
  /// Always reported to crash. [wireCode] is the Worker error code.
  const factory Failure.contract({required String wireCode}) = ContractFailure;

  // Identity / trust --------------------------------------------------------

  /// `401 UNAUTHENTICATED`, or `TOKEN_EXPIRED` after a failed refresh:
  /// re-register silently.
  const factory Failure.sessionExpired() = SessionExpiredFailure;

  /// `401 ATTESTATION_REQUIRED` or `403 ATTESTATION_FAILED`.
  const factory Failure.attestation({required AttestationFailureKind kind}) =
      AttestationFailure;

  // Readings ----------------------------------------------------------------

  /// `402 INSUFFICIENT_CREDITS`.
  ///
  /// [balance] is the Worker's `BalanceDto` from `details`, when sent.
  const factory Failure.insufficientCredits({
    required InsufficientReason reason,
    CreditBalance? balance,
    DateTime? freeResetsAt,
  }) = InsufficientCreditsFailure;

  /// `409 HOLD_CONFLICT`: the pre-draw hold was lost; S08 `holdLost` → S10
  /// with the cards kept face-down (RC48, RC50).
  const factory Failure.holdConflict() = HoldConflictFailure;

  /// `410 READING_EXPIRED_REFUNDED`: S08 `deliveryExpired` (RC51).
  ///
  /// [balance] is the refunded balance, when sent.
  const factory Failure.readingExpiredRefunded({CreditBalance? balance}) =
      ReadingExpiredRefundedFailure;

  /// `412 AI_CONSENT_REQUIRED`: re-prompt on S04 (RC28).
  const factory Failure.aiConsentRequired({int? requiredVersion}) =
      AiConsentRequiredFailure;

  /// `403 AI_UNAVAILABLE_REGION`: offer a Classic reading (RC29).
  const factory Failure.aiUnavailableRegion() = AiUnavailableRegionFailure;

  /// `503 READINGS_DISABLED` or `AI_BUDGET_EXHAUSTED`: S31 `readingsPaused`
  /// with the Classic offer, never S10 (RC47).
  const factory Failure.readingsPaused({
    required PausedReason reason,
    Duration? retryAfter,
  }) = ReadingsPausedFailure;

  /// `503 AI_UNAVAILABLE`: the upstream model failed and the hold was
  /// refunded; S08 `generationFailed`.
  const factory Failure.aiUnavailable() = AiUnavailableFailure;

  /// `409 REQUEST_IN_PROGRESS`: retried with `Retry-After`, surfaced only if
  /// it persists.
  const factory Failure.requestInProgress() = RequestInProgressFailure;

  // Rewarded ----------------------------------------------------------------

  /// `403 REWARDED_DISABLED`, `409 REWARDED_DAILY_CAP`, no fill or no ad
  /// consent (RC57).
  const factory Failure.rewardUnavailable({
    required RewardUnavailableReason reason,
    DateTime? availableAt,
  }) = RewardUnavailableFailure;

  // Account -----------------------------------------------------------------

  /// `409 TIMEZONE_CHANGE_TOO_SOON`.
  const factory Failure.timezoneChangeRejected({
    required DateTime allowedAfter,
  }) = TimezoneChangeRejectedFailure;

  // Store -------------------------------------------------------------------

  /// The user cancelled the store sheet (silent return).
  const factory Failure.purchaseCancelled() = PurchaseCancelledFailure;

  /// Ask to Buy / deferred payment, or `202 PURCHASE_PENDING`.
  const factory Failure.purchasePending() = PurchasePendingFailure;

  /// A store error, `422 PURCHASE_INVALID` (incl. `reason: sandbox_cap`) or
  /// `422 PRODUCT_UNKNOWN`. [wireCode] is the Worker or store error code.
  const factory Failure.purchase({required String wireCode, String? reason}) =
      PurchaseFailure;

  /// `409 PURCHASE_ALREADY_CLAIMED` (RC84, RC85).
  const factory Failure.purchaseAlreadyClaimed({
    required bool transferEligible,
    String? transferToken,
  }) = PurchaseAlreadyClaimedFailure;

  /// Client side: `BalanceDto.purchasesAllowed == false` (RC66).
  const factory Failure.purchasesBlocked({
    required PurchasesBlockedReason reason,
  }) = PurchasesBlockedFailure;

  /// The store does not offer the product.
  const factory Failure.productUnavailable() = ProductUnavailableFailure;

  // Local -------------------------------------------------------------------

  /// drift or secure-storage error.
  const factory Failure.storage() = StorageFailure;

  /// A backup file cannot be imported.
  const factory Failure.backupInvalid({required BackupInvalidReason reason}) =
      BackupInvalidFailure;

  /// Anything unmapped. Always reported to crash.
  const factory Failure.unexpected({
    required Object error,
    required StackTrace stack,
  }) = UnexpectedFailure;

  /// Stable UPPER_SNAKE key for analytics and logs.
  String get code => switch (this) {
    NetworkFailure() => 'NETWORK',
    TimeoutFailure() => 'TIMEOUT',
    ServerFailure() => 'INTERNAL',
    RateLimitedFailure() => 'RATE_LIMITED',
    UpgradeRequiredFailure() => 'UPGRADE_REQUIRED',
    ContractFailure(:final wireCode) => wireCode,
    SessionExpiredFailure() => 'UNAUTHENTICATED',
    AttestationFailure() => 'ATTESTATION_FAILED',
    InsufficientCreditsFailure() => 'INSUFFICIENT_CREDITS',
    HoldConflictFailure() => 'HOLD_CONFLICT',
    ReadingExpiredRefundedFailure() => 'READING_EXPIRED_REFUNDED',
    AiConsentRequiredFailure() => 'AI_CONSENT_REQUIRED',
    AiUnavailableRegionFailure() => 'AI_UNAVAILABLE_REGION',
    ReadingsPausedFailure(reason: PausedReason.disabled) => 'READINGS_DISABLED',
    ReadingsPausedFailure() => 'AI_BUDGET_EXHAUSTED',
    AiUnavailableFailure() => 'AI_UNAVAILABLE',
    RequestInProgressFailure() => 'REQUEST_IN_PROGRESS',
    RewardUnavailableFailure(reason: RewardUnavailableReason.disabled) =>
      'REWARDED_DISABLED',
    RewardUnavailableFailure(
      reason: RewardUnavailableReason.cap || RewardUnavailableReason.cooldown,
    ) =>
      'REWARDED_DAILY_CAP',
    RewardUnavailableFailure() => 'REWARD_UNAVAILABLE',
    TimezoneChangeRejectedFailure() => 'TIMEZONE_CHANGE_TOO_SOON',
    PurchaseCancelledFailure() => 'PURCHASE_CANCELLED',
    PurchasePendingFailure() => 'PURCHASE_PENDING',
    PurchaseFailure(:final wireCode) => wireCode,
    PurchaseAlreadyClaimedFailure() => 'PURCHASE_ALREADY_CLAIMED',
    PurchasesBlockedFailure() => 'PURCHASES_BLOCKED',
    ProductUnavailableFailure() => 'PRODUCT_UNAVAILABLE',
    StorageFailure() => 'STORAGE',
    BackupInvalidFailure() => 'BACKUP_INVALID',
    UnexpectedFailure() => 'UNEXPECTED',
  };

  /// The ARB message key: `failure` + the class name without the suffix
  /// (GLOSSARY §5, RC94).
  String get messageKey => switch (this) {
    NetworkFailure() => 'failureNetwork',
    TimeoutFailure() => 'failureTimeout',
    ServerFailure() => 'failureServer',
    RateLimitedFailure() => 'failureRateLimited',
    UpgradeRequiredFailure() => 'failureUpgradeRequired',
    ContractFailure() => 'failureContract',
    SessionExpiredFailure() => 'failureSessionExpired',
    AttestationFailure() => 'failureAttestation',
    InsufficientCreditsFailure() => 'failureInsufficientCredits',
    HoldConflictFailure() => 'failureHoldConflict',
    ReadingExpiredRefundedFailure() => 'failureReadingExpiredRefunded',
    AiConsentRequiredFailure() => 'failureAiConsentRequired',
    AiUnavailableRegionFailure() => 'failureAiUnavailableRegion',
    ReadingsPausedFailure() => 'failureReadingsPaused',
    AiUnavailableFailure() => 'failureAiUnavailable',
    RequestInProgressFailure() => 'failureRequestInProgress',
    RewardUnavailableFailure() => 'failureRewardUnavailable',
    TimezoneChangeRejectedFailure() => 'failureTimezoneChangeRejected',
    PurchaseCancelledFailure() => 'failurePurchaseCancelled',
    PurchasePendingFailure() => 'failurePurchasePending',
    PurchaseFailure() => 'failurePurchase',
    PurchaseAlreadyClaimedFailure() => 'failurePurchaseAlreadyClaimed',
    PurchasesBlockedFailure() => 'failurePurchasesBlocked',
    ProductUnavailableFailure() => 'failureProductUnavailable',
    StorageFailure() => 'failureStorage',
    BackupInvalidFailure() => 'failureBackupInvalid',
    UnexpectedFailure() => 'failureUnexpected',
  };

  /// Whether this failure is always sent to the crash reporter (02 §3):
  /// contract violations and unexpected errors.
  bool get alwaysReportToCrash =>
      this is ContractFailure || this is UnexpectedFailure;
}
