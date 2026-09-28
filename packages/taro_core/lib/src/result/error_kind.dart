import 'package:taro_core/src/result/failure.dart';

/// The shared UI error kinds shown by `TaroErrorView` (01 §8.2).
///
/// Screens handle the failures they know by name and fall back to
/// [ErrorKind.fromFailure] for the rest.
enum ErrorKind {
  /// Offline or timed out.
  network,

  /// The server failed or the request could not be completed.
  server,

  /// Too many requests.
  rateLimited,

  /// Device attestation failed.
  deviceUnverified,

  /// Local storage failed.
  storage,

  /// An imported file is invalid.
  invalidFile,

  /// Anything else.
  unknown;

  /// The generic error kind for [failure].
  static ErrorKind fromFailure(Failure failure) => switch (failure) {
    NetworkFailure() || TimeoutFailure() => network,
    ServerFailure() ||
    ContractFailure() ||
    UpgradeRequiredFailure() ||
    SessionExpiredFailure() ||
    HoldConflictFailure() ||
    ReadingExpiredRefundedFailure() ||
    AiUnavailableFailure() ||
    RequestInProgressFailure() ||
    ReadingsPausedFailure() ||
    AiUnavailableRegionFailure() ||
    TimezoneChangeRejectedFailure() => server,
    RateLimitedFailure() => rateLimited,
    AttestationFailure() => deviceUnverified,
    StorageFailure() => storage,
    BackupInvalidFailure() => invalidFile,
    InsufficientCreditsFailure() ||
    AiConsentRequiredFailure() ||
    RewardUnavailableFailure() ||
    PurchaseCancelledFailure() ||
    PurchasePendingFailure() ||
    PurchaseFailure() ||
    PurchaseAlreadyClaimedFailure() ||
    PurchasesBlockedFailure() ||
    ProductUnavailableFailure() ||
    UnexpectedFailure() => unknown,
  };
}
