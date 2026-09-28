import 'package:taro_core/taro_core.dart';

/// One sample per `Failure` subtype (and per `code`-relevant variant) with
/// its expected stable `code` and `ErrorKind`.
typedef FailureSample = ({Failure failure, String code, ErrorKind kind});

final _stack = StackTrace.fromString('sample');

/// Every `Failure` subtype, table-driven.
final List<FailureSample> failureSamples = [
  (
    failure: const Failure.network(),
    code: 'NETWORK',
    kind: ErrorKind.network,
  ),
  (
    failure: const Failure.timeout(),
    code: 'TIMEOUT',
    kind: ErrorKind.network,
  ),
  (
    failure: const Failure.server(
      status: 500,
      wireCode: 'SOMETHING_NEW',
      requestId: 'req-1',
    ),
    code: 'INTERNAL',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.rateLimited(
      reason: RateLimitReason.dailyLimit,
      retryAfter: Duration(seconds: 30),
    ),
    code: 'RATE_LIMITED',
    kind: ErrorKind.rateLimited,
  ),
  (
    failure: const Failure.upgradeRequired(storeUrl: 'https://example.com'),
    code: 'UPGRADE_REQUIRED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.contract(wireCode: 'SPREAD_INVALID'),
    code: 'SPREAD_INVALID',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.sessionExpired(),
    code: 'UNAUTHENTICATED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.attestation(kind: AttestationFailureKind.rejected),
    code: 'ATTESTATION_FAILED',
    kind: ErrorKind.deviceUnverified,
  ),
  (
    failure: Failure.insufficientCredits(
      reason: InsufficientReason.noCredits,
      freeResetsAt: DateTime.utc(2026, 9, 29),
    ),
    code: 'INSUFFICIENT_CREDITS',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.holdConflict(),
    code: 'HOLD_CONFLICT',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.readingExpiredRefunded(),
    code: 'READING_EXPIRED_REFUNDED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.aiConsentRequired(requiredVersion: 2),
    code: 'AI_CONSENT_REQUIRED',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.aiUnavailableRegion(),
    code: 'AI_UNAVAILABLE_REGION',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.readingsPaused(reason: PausedReason.disabled),
    code: 'READINGS_DISABLED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.readingsPaused(
      reason: PausedReason.budgetHard,
      retryAfter: Duration(minutes: 5),
    ),
    code: 'AI_BUDGET_EXHAUSTED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.readingsPaused(reason: PausedReason.freeStop),
    code: 'AI_BUDGET_EXHAUSTED',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.aiUnavailable(),
    code: 'AI_UNAVAILABLE',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.requestInProgress(),
    code: 'REQUEST_IN_PROGRESS',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.rewardUnavailable(
      reason: RewardUnavailableReason.disabled,
    ),
    code: 'REWARDED_DISABLED',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.rewardUnavailable(
      reason: RewardUnavailableReason.cap,
    ),
    code: 'REWARDED_DAILY_CAP',
    kind: ErrorKind.unknown,
  ),
  (
    failure: Failure.rewardUnavailable(
      reason: RewardUnavailableReason.cooldown,
      availableAt: DateTime.utc(2026, 9, 28, 12),
    ),
    code: 'REWARDED_DAILY_CAP',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.rewardUnavailable(
      reason: RewardUnavailableReason.noFill,
    ),
    code: 'REWARD_UNAVAILABLE',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.rewardUnavailable(
      reason: RewardUnavailableReason.consent,
    ),
    code: 'REWARD_UNAVAILABLE',
    kind: ErrorKind.unknown,
  ),
  (
    failure: Failure.timezoneChangeRejected(
      allowedAfter: DateTime.utc(2026, 10),
    ),
    code: 'TIMEZONE_CHANGE_TOO_SOON',
    kind: ErrorKind.server,
  ),
  (
    failure: const Failure.purchaseCancelled(),
    code: 'PURCHASE_CANCELLED',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.purchasePending(),
    code: 'PURCHASE_PENDING',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.purchase(
      wireCode: 'PURCHASE_INVALID',
      reason: 'sandbox_cap',
    ),
    code: 'PURCHASE_INVALID',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.purchaseAlreadyClaimed(
      transferEligible: true,
      transferToken: 'tt-1',
    ),
    code: 'PURCHASE_ALREADY_CLAIMED',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.purchasesBlocked(
      reason: PurchasesBlockedReason.refundDebt,
    ),
    code: 'PURCHASES_BLOCKED',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.productUnavailable(),
    code: 'PRODUCT_UNAVAILABLE',
    kind: ErrorKind.unknown,
  ),
  (
    failure: const Failure.storage(),
    code: 'STORAGE',
    kind: ErrorKind.storage,
  ),
  (
    failure: const Failure.backupInvalid(reason: BackupInvalidReason.checksum),
    code: 'BACKUP_INVALID',
    kind: ErrorKind.invalidFile,
  ),
  (
    failure: Failure.unexpected(error: StateError('boom'), stack: _stack),
    code: 'UNEXPECTED',
    kind: ErrorKind.unknown,
  ),
];
