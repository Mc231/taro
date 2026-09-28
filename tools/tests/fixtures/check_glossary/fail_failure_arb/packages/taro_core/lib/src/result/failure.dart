sealed class Failure {
  const Failure();
}

final class ContractFailure extends Failure {
  const ContractFailure();
}

final class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure();
}

final class AttestationFailure extends Failure {
  const AttestationFailure();
}

final class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure();
}

final class RewardUnavailableFailure extends Failure {
  const RewardUnavailableFailure();
}

final class AiUnavailableRegionFailure extends Failure {
  const AiUnavailableRegionFailure();
}

final class RequestInProgressFailure extends Failure {
  const RequestInProgressFailure();
}

final class HoldConflictFailure extends Failure {
  const HoldConflictFailure();
}

final class PurchaseAlreadyClaimedFailure extends Failure {
  const PurchaseAlreadyClaimedFailure();
}

final class TimezoneChangeRejectedFailure extends Failure {
  const TimezoneChangeRejectedFailure();
}

final class ReadingExpiredRefundedFailure extends Failure {
  const ReadingExpiredRefundedFailure();
}

final class AiConsentRequiredFailure extends Failure {
  const AiConsentRequiredFailure();
}

final class PurchaseFailure extends Failure {
  const PurchaseFailure();
}

final class UpgradeRequiredFailure extends Failure {
  const UpgradeRequiredFailure();
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure();
}

final class PurchasePendingFailure extends Failure {
  const PurchasePendingFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure();
}

final class ReadingsPausedFailure extends Failure {
  const ReadingsPausedFailure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

final class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure();
}

final class PurchasesBlockedFailure extends Failure {
  const PurchasesBlockedFailure();
}

final class ProductUnavailableFailure extends Failure {
  const ProductUnavailableFailure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class BackupInvalidFailure extends Failure {
  const BackupInvalidFailure();
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}

abstract class BaseFailure extends Failure {}
final class OopsFailure extends Failure {}
