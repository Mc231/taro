// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkFailure value)?  network,TResult Function( TimeoutFailure value)?  timeout,TResult Function( ServerFailure value)?  server,TResult Function( RateLimitedFailure value)?  rateLimited,TResult Function( UpgradeRequiredFailure value)?  upgradeRequired,TResult Function( ContractFailure value)?  contract,TResult Function( SessionExpiredFailure value)?  sessionExpired,TResult Function( AttestationFailure value)?  attestation,TResult Function( InsufficientCreditsFailure value)?  insufficientCredits,TResult Function( HoldConflictFailure value)?  holdConflict,TResult Function( ReadingExpiredRefundedFailure value)?  readingExpiredRefunded,TResult Function( AiConsentRequiredFailure value)?  aiConsentRequired,TResult Function( AiUnavailableRegionFailure value)?  aiUnavailableRegion,TResult Function( ReadingsPausedFailure value)?  readingsPaused,TResult Function( AiUnavailableFailure value)?  aiUnavailable,TResult Function( RequestInProgressFailure value)?  requestInProgress,TResult Function( RewardUnavailableFailure value)?  rewardUnavailable,TResult Function( TimezoneChangeRejectedFailure value)?  timezoneChangeRejected,TResult Function( PurchaseCancelledFailure value)?  purchaseCancelled,TResult Function( PurchasePendingFailure value)?  purchasePending,TResult Function( PurchaseFailure value)?  purchase,TResult Function( PurchaseAlreadyClaimedFailure value)?  purchaseAlreadyClaimed,TResult Function( PurchasesBlockedFailure value)?  purchasesBlocked,TResult Function( ProductUnavailableFailure value)?  productUnavailable,TResult Function( StorageFailure value)?  storage,TResult Function( BackupInvalidFailure value)?  backupInvalid,TResult Function( UnexpectedFailure value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case TimeoutFailure() when timeout != null:
return timeout(_that);case ServerFailure() when server != null:
return server(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case UpgradeRequiredFailure() when upgradeRequired != null:
return upgradeRequired(_that);case ContractFailure() when contract != null:
return contract(_that);case SessionExpiredFailure() when sessionExpired != null:
return sessionExpired(_that);case AttestationFailure() when attestation != null:
return attestation(_that);case InsufficientCreditsFailure() when insufficientCredits != null:
return insufficientCredits(_that);case HoldConflictFailure() when holdConflict != null:
return holdConflict(_that);case ReadingExpiredRefundedFailure() when readingExpiredRefunded != null:
return readingExpiredRefunded(_that);case AiConsentRequiredFailure() when aiConsentRequired != null:
return aiConsentRequired(_that);case AiUnavailableRegionFailure() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case ReadingsPausedFailure() when readingsPaused != null:
return readingsPaused(_that);case AiUnavailableFailure() when aiUnavailable != null:
return aiUnavailable(_that);case RequestInProgressFailure() when requestInProgress != null:
return requestInProgress(_that);case RewardUnavailableFailure() when rewardUnavailable != null:
return rewardUnavailable(_that);case TimezoneChangeRejectedFailure() when timezoneChangeRejected != null:
return timezoneChangeRejected(_that);case PurchaseCancelledFailure() when purchaseCancelled != null:
return purchaseCancelled(_that);case PurchasePendingFailure() when purchasePending != null:
return purchasePending(_that);case PurchaseFailure() when purchase != null:
return purchase(_that);case PurchaseAlreadyClaimedFailure() when purchaseAlreadyClaimed != null:
return purchaseAlreadyClaimed(_that);case PurchasesBlockedFailure() when purchasesBlocked != null:
return purchasesBlocked(_that);case ProductUnavailableFailure() when productUnavailable != null:
return productUnavailable(_that);case StorageFailure() when storage != null:
return storage(_that);case BackupInvalidFailure() when backupInvalid != null:
return backupInvalid(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkFailure value)  network,required TResult Function( TimeoutFailure value)  timeout,required TResult Function( ServerFailure value)  server,required TResult Function( RateLimitedFailure value)  rateLimited,required TResult Function( UpgradeRequiredFailure value)  upgradeRequired,required TResult Function( ContractFailure value)  contract,required TResult Function( SessionExpiredFailure value)  sessionExpired,required TResult Function( AttestationFailure value)  attestation,required TResult Function( InsufficientCreditsFailure value)  insufficientCredits,required TResult Function( HoldConflictFailure value)  holdConflict,required TResult Function( ReadingExpiredRefundedFailure value)  readingExpiredRefunded,required TResult Function( AiConsentRequiredFailure value)  aiConsentRequired,required TResult Function( AiUnavailableRegionFailure value)  aiUnavailableRegion,required TResult Function( ReadingsPausedFailure value)  readingsPaused,required TResult Function( AiUnavailableFailure value)  aiUnavailable,required TResult Function( RequestInProgressFailure value)  requestInProgress,required TResult Function( RewardUnavailableFailure value)  rewardUnavailable,required TResult Function( TimezoneChangeRejectedFailure value)  timezoneChangeRejected,required TResult Function( PurchaseCancelledFailure value)  purchaseCancelled,required TResult Function( PurchasePendingFailure value)  purchasePending,required TResult Function( PurchaseFailure value)  purchase,required TResult Function( PurchaseAlreadyClaimedFailure value)  purchaseAlreadyClaimed,required TResult Function( PurchasesBlockedFailure value)  purchasesBlocked,required TResult Function( ProductUnavailableFailure value)  productUnavailable,required TResult Function( StorageFailure value)  storage,required TResult Function( BackupInvalidFailure value)  backupInvalid,required TResult Function( UnexpectedFailure value)  unexpected,}){
final _that = this;
switch (_that) {
case NetworkFailure():
return network(_that);case TimeoutFailure():
return timeout(_that);case ServerFailure():
return server(_that);case RateLimitedFailure():
return rateLimited(_that);case UpgradeRequiredFailure():
return upgradeRequired(_that);case ContractFailure():
return contract(_that);case SessionExpiredFailure():
return sessionExpired(_that);case AttestationFailure():
return attestation(_that);case InsufficientCreditsFailure():
return insufficientCredits(_that);case HoldConflictFailure():
return holdConflict(_that);case ReadingExpiredRefundedFailure():
return readingExpiredRefunded(_that);case AiConsentRequiredFailure():
return aiConsentRequired(_that);case AiUnavailableRegionFailure():
return aiUnavailableRegion(_that);case ReadingsPausedFailure():
return readingsPaused(_that);case AiUnavailableFailure():
return aiUnavailable(_that);case RequestInProgressFailure():
return requestInProgress(_that);case RewardUnavailableFailure():
return rewardUnavailable(_that);case TimezoneChangeRejectedFailure():
return timezoneChangeRejected(_that);case PurchaseCancelledFailure():
return purchaseCancelled(_that);case PurchasePendingFailure():
return purchasePending(_that);case PurchaseFailure():
return purchase(_that);case PurchaseAlreadyClaimedFailure():
return purchaseAlreadyClaimed(_that);case PurchasesBlockedFailure():
return purchasesBlocked(_that);case ProductUnavailableFailure():
return productUnavailable(_that);case StorageFailure():
return storage(_that);case BackupInvalidFailure():
return backupInvalid(_that);case UnexpectedFailure():
return unexpected(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkFailure value)?  network,TResult? Function( TimeoutFailure value)?  timeout,TResult? Function( ServerFailure value)?  server,TResult? Function( RateLimitedFailure value)?  rateLimited,TResult? Function( UpgradeRequiredFailure value)?  upgradeRequired,TResult? Function( ContractFailure value)?  contract,TResult? Function( SessionExpiredFailure value)?  sessionExpired,TResult? Function( AttestationFailure value)?  attestation,TResult? Function( InsufficientCreditsFailure value)?  insufficientCredits,TResult? Function( HoldConflictFailure value)?  holdConflict,TResult? Function( ReadingExpiredRefundedFailure value)?  readingExpiredRefunded,TResult? Function( AiConsentRequiredFailure value)?  aiConsentRequired,TResult? Function( AiUnavailableRegionFailure value)?  aiUnavailableRegion,TResult? Function( ReadingsPausedFailure value)?  readingsPaused,TResult? Function( AiUnavailableFailure value)?  aiUnavailable,TResult? Function( RequestInProgressFailure value)?  requestInProgress,TResult? Function( RewardUnavailableFailure value)?  rewardUnavailable,TResult? Function( TimezoneChangeRejectedFailure value)?  timezoneChangeRejected,TResult? Function( PurchaseCancelledFailure value)?  purchaseCancelled,TResult? Function( PurchasePendingFailure value)?  purchasePending,TResult? Function( PurchaseFailure value)?  purchase,TResult? Function( PurchaseAlreadyClaimedFailure value)?  purchaseAlreadyClaimed,TResult? Function( PurchasesBlockedFailure value)?  purchasesBlocked,TResult? Function( ProductUnavailableFailure value)?  productUnavailable,TResult? Function( StorageFailure value)?  storage,TResult? Function( BackupInvalidFailure value)?  backupInvalid,TResult? Function( UnexpectedFailure value)?  unexpected,}){
final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network(_that);case TimeoutFailure() when timeout != null:
return timeout(_that);case ServerFailure() when server != null:
return server(_that);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that);case UpgradeRequiredFailure() when upgradeRequired != null:
return upgradeRequired(_that);case ContractFailure() when contract != null:
return contract(_that);case SessionExpiredFailure() when sessionExpired != null:
return sessionExpired(_that);case AttestationFailure() when attestation != null:
return attestation(_that);case InsufficientCreditsFailure() when insufficientCredits != null:
return insufficientCredits(_that);case HoldConflictFailure() when holdConflict != null:
return holdConflict(_that);case ReadingExpiredRefundedFailure() when readingExpiredRefunded != null:
return readingExpiredRefunded(_that);case AiConsentRequiredFailure() when aiConsentRequired != null:
return aiConsentRequired(_that);case AiUnavailableRegionFailure() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case ReadingsPausedFailure() when readingsPaused != null:
return readingsPaused(_that);case AiUnavailableFailure() when aiUnavailable != null:
return aiUnavailable(_that);case RequestInProgressFailure() when requestInProgress != null:
return requestInProgress(_that);case RewardUnavailableFailure() when rewardUnavailable != null:
return rewardUnavailable(_that);case TimezoneChangeRejectedFailure() when timezoneChangeRejected != null:
return timezoneChangeRejected(_that);case PurchaseCancelledFailure() when purchaseCancelled != null:
return purchaseCancelled(_that);case PurchasePendingFailure() when purchasePending != null:
return purchasePending(_that);case PurchaseFailure() when purchase != null:
return purchase(_that);case PurchaseAlreadyClaimedFailure() when purchaseAlreadyClaimed != null:
return purchaseAlreadyClaimed(_that);case PurchasesBlockedFailure() when purchasesBlocked != null:
return purchasesBlocked(_that);case ProductUnavailableFailure() when productUnavailable != null:
return productUnavailable(_that);case StorageFailure() when storage != null:
return storage(_that);case BackupInvalidFailure() when backupInvalid != null:
return backupInvalid(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  network,TResult Function()?  timeout,TResult Function( int status,  String? wireCode,  String? requestId)?  server,TResult Function( RateLimitReason reason,  Duration? retryAfter)?  rateLimited,TResult Function( String? storeUrl)?  upgradeRequired,TResult Function( String wireCode)?  contract,TResult Function()?  sessionExpired,TResult Function( AttestationFailureKind kind)?  attestation,TResult Function( InsufficientReason reason,  CreditBalance? balance,  DateTime? freeResetsAt)?  insufficientCredits,TResult Function()?  holdConflict,TResult Function( CreditBalance? balance)?  readingExpiredRefunded,TResult Function( int? requiredVersion)?  aiConsentRequired,TResult Function()?  aiUnavailableRegion,TResult Function( PausedReason reason,  Duration? retryAfter)?  readingsPaused,TResult Function()?  aiUnavailable,TResult Function()?  requestInProgress,TResult Function( RewardUnavailableReason reason,  DateTime? availableAt)?  rewardUnavailable,TResult Function( DateTime allowedAfter)?  timezoneChangeRejected,TResult Function()?  purchaseCancelled,TResult Function()?  purchasePending,TResult Function( String wireCode,  String? reason)?  purchase,TResult Function( bool transferEligible,  String? transferToken)?  purchaseAlreadyClaimed,TResult Function( PurchasesBlockedReason reason)?  purchasesBlocked,TResult Function()?  productUnavailable,TResult Function()?  storage,TResult Function( BackupInvalidReason reason)?  backupInvalid,TResult Function( Object error,  StackTrace stack)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case TimeoutFailure() when timeout != null:
return timeout();case ServerFailure() when server != null:
return server(_that.status,_that.wireCode,_that.requestId);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.reason,_that.retryAfter);case UpgradeRequiredFailure() when upgradeRequired != null:
return upgradeRequired(_that.storeUrl);case ContractFailure() when contract != null:
return contract(_that.wireCode);case SessionExpiredFailure() when sessionExpired != null:
return sessionExpired();case AttestationFailure() when attestation != null:
return attestation(_that.kind);case InsufficientCreditsFailure() when insufficientCredits != null:
return insufficientCredits(_that.reason,_that.balance,_that.freeResetsAt);case HoldConflictFailure() when holdConflict != null:
return holdConflict();case ReadingExpiredRefundedFailure() when readingExpiredRefunded != null:
return readingExpiredRefunded(_that.balance);case AiConsentRequiredFailure() when aiConsentRequired != null:
return aiConsentRequired(_that.requiredVersion);case AiUnavailableRegionFailure() when aiUnavailableRegion != null:
return aiUnavailableRegion();case ReadingsPausedFailure() when readingsPaused != null:
return readingsPaused(_that.reason,_that.retryAfter);case AiUnavailableFailure() when aiUnavailable != null:
return aiUnavailable();case RequestInProgressFailure() when requestInProgress != null:
return requestInProgress();case RewardUnavailableFailure() when rewardUnavailable != null:
return rewardUnavailable(_that.reason,_that.availableAt);case TimezoneChangeRejectedFailure() when timezoneChangeRejected != null:
return timezoneChangeRejected(_that.allowedAfter);case PurchaseCancelledFailure() when purchaseCancelled != null:
return purchaseCancelled();case PurchasePendingFailure() when purchasePending != null:
return purchasePending();case PurchaseFailure() when purchase != null:
return purchase(_that.wireCode,_that.reason);case PurchaseAlreadyClaimedFailure() when purchaseAlreadyClaimed != null:
return purchaseAlreadyClaimed(_that.transferEligible,_that.transferToken);case PurchasesBlockedFailure() when purchasesBlocked != null:
return purchasesBlocked(_that.reason);case ProductUnavailableFailure() when productUnavailable != null:
return productUnavailable();case StorageFailure() when storage != null:
return storage();case BackupInvalidFailure() when backupInvalid != null:
return backupInvalid(_that.reason);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.error,_that.stack);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  network,required TResult Function()  timeout,required TResult Function( int status,  String? wireCode,  String? requestId)  server,required TResult Function( RateLimitReason reason,  Duration? retryAfter)  rateLimited,required TResult Function( String? storeUrl)  upgradeRequired,required TResult Function( String wireCode)  contract,required TResult Function()  sessionExpired,required TResult Function( AttestationFailureKind kind)  attestation,required TResult Function( InsufficientReason reason,  CreditBalance? balance,  DateTime? freeResetsAt)  insufficientCredits,required TResult Function()  holdConflict,required TResult Function( CreditBalance? balance)  readingExpiredRefunded,required TResult Function( int? requiredVersion)  aiConsentRequired,required TResult Function()  aiUnavailableRegion,required TResult Function( PausedReason reason,  Duration? retryAfter)  readingsPaused,required TResult Function()  aiUnavailable,required TResult Function()  requestInProgress,required TResult Function( RewardUnavailableReason reason,  DateTime? availableAt)  rewardUnavailable,required TResult Function( DateTime allowedAfter)  timezoneChangeRejected,required TResult Function()  purchaseCancelled,required TResult Function()  purchasePending,required TResult Function( String wireCode,  String? reason)  purchase,required TResult Function( bool transferEligible,  String? transferToken)  purchaseAlreadyClaimed,required TResult Function( PurchasesBlockedReason reason)  purchasesBlocked,required TResult Function()  productUnavailable,required TResult Function()  storage,required TResult Function( BackupInvalidReason reason)  backupInvalid,required TResult Function( Object error,  StackTrace stack)  unexpected,}) {final _that = this;
switch (_that) {
case NetworkFailure():
return network();case TimeoutFailure():
return timeout();case ServerFailure():
return server(_that.status,_that.wireCode,_that.requestId);case RateLimitedFailure():
return rateLimited(_that.reason,_that.retryAfter);case UpgradeRequiredFailure():
return upgradeRequired(_that.storeUrl);case ContractFailure():
return contract(_that.wireCode);case SessionExpiredFailure():
return sessionExpired();case AttestationFailure():
return attestation(_that.kind);case InsufficientCreditsFailure():
return insufficientCredits(_that.reason,_that.balance,_that.freeResetsAt);case HoldConflictFailure():
return holdConflict();case ReadingExpiredRefundedFailure():
return readingExpiredRefunded(_that.balance);case AiConsentRequiredFailure():
return aiConsentRequired(_that.requiredVersion);case AiUnavailableRegionFailure():
return aiUnavailableRegion();case ReadingsPausedFailure():
return readingsPaused(_that.reason,_that.retryAfter);case AiUnavailableFailure():
return aiUnavailable();case RequestInProgressFailure():
return requestInProgress();case RewardUnavailableFailure():
return rewardUnavailable(_that.reason,_that.availableAt);case TimezoneChangeRejectedFailure():
return timezoneChangeRejected(_that.allowedAfter);case PurchaseCancelledFailure():
return purchaseCancelled();case PurchasePendingFailure():
return purchasePending();case PurchaseFailure():
return purchase(_that.wireCode,_that.reason);case PurchaseAlreadyClaimedFailure():
return purchaseAlreadyClaimed(_that.transferEligible,_that.transferToken);case PurchasesBlockedFailure():
return purchasesBlocked(_that.reason);case ProductUnavailableFailure():
return productUnavailable();case StorageFailure():
return storage();case BackupInvalidFailure():
return backupInvalid(_that.reason);case UnexpectedFailure():
return unexpected(_that.error,_that.stack);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  network,TResult? Function()?  timeout,TResult? Function( int status,  String? wireCode,  String? requestId)?  server,TResult? Function( RateLimitReason reason,  Duration? retryAfter)?  rateLimited,TResult? Function( String? storeUrl)?  upgradeRequired,TResult? Function( String wireCode)?  contract,TResult? Function()?  sessionExpired,TResult? Function( AttestationFailureKind kind)?  attestation,TResult? Function( InsufficientReason reason,  CreditBalance? balance,  DateTime? freeResetsAt)?  insufficientCredits,TResult? Function()?  holdConflict,TResult? Function( CreditBalance? balance)?  readingExpiredRefunded,TResult? Function( int? requiredVersion)?  aiConsentRequired,TResult? Function()?  aiUnavailableRegion,TResult? Function( PausedReason reason,  Duration? retryAfter)?  readingsPaused,TResult? Function()?  aiUnavailable,TResult? Function()?  requestInProgress,TResult? Function( RewardUnavailableReason reason,  DateTime? availableAt)?  rewardUnavailable,TResult? Function( DateTime allowedAfter)?  timezoneChangeRejected,TResult? Function()?  purchaseCancelled,TResult? Function()?  purchasePending,TResult? Function( String wireCode,  String? reason)?  purchase,TResult? Function( bool transferEligible,  String? transferToken)?  purchaseAlreadyClaimed,TResult? Function( PurchasesBlockedReason reason)?  purchasesBlocked,TResult? Function()?  productUnavailable,TResult? Function()?  storage,TResult? Function( BackupInvalidReason reason)?  backupInvalid,TResult? Function( Object error,  StackTrace stack)?  unexpected,}) {final _that = this;
switch (_that) {
case NetworkFailure() when network != null:
return network();case TimeoutFailure() when timeout != null:
return timeout();case ServerFailure() when server != null:
return server(_that.status,_that.wireCode,_that.requestId);case RateLimitedFailure() when rateLimited != null:
return rateLimited(_that.reason,_that.retryAfter);case UpgradeRequiredFailure() when upgradeRequired != null:
return upgradeRequired(_that.storeUrl);case ContractFailure() when contract != null:
return contract(_that.wireCode);case SessionExpiredFailure() when sessionExpired != null:
return sessionExpired();case AttestationFailure() when attestation != null:
return attestation(_that.kind);case InsufficientCreditsFailure() when insufficientCredits != null:
return insufficientCredits(_that.reason,_that.balance,_that.freeResetsAt);case HoldConflictFailure() when holdConflict != null:
return holdConflict();case ReadingExpiredRefundedFailure() when readingExpiredRefunded != null:
return readingExpiredRefunded(_that.balance);case AiConsentRequiredFailure() when aiConsentRequired != null:
return aiConsentRequired(_that.requiredVersion);case AiUnavailableRegionFailure() when aiUnavailableRegion != null:
return aiUnavailableRegion();case ReadingsPausedFailure() when readingsPaused != null:
return readingsPaused(_that.reason,_that.retryAfter);case AiUnavailableFailure() when aiUnavailable != null:
return aiUnavailable();case RequestInProgressFailure() when requestInProgress != null:
return requestInProgress();case RewardUnavailableFailure() when rewardUnavailable != null:
return rewardUnavailable(_that.reason,_that.availableAt);case TimezoneChangeRejectedFailure() when timezoneChangeRejected != null:
return timezoneChangeRejected(_that.allowedAfter);case PurchaseCancelledFailure() when purchaseCancelled != null:
return purchaseCancelled();case PurchasePendingFailure() when purchasePending != null:
return purchasePending();case PurchaseFailure() when purchase != null:
return purchase(_that.wireCode,_that.reason);case PurchaseAlreadyClaimedFailure() when purchaseAlreadyClaimed != null:
return purchaseAlreadyClaimed(_that.transferEligible,_that.transferToken);case PurchasesBlockedFailure() when purchasesBlocked != null:
return purchasesBlocked(_that.reason);case ProductUnavailableFailure() when productUnavailable != null:
return productUnavailable();case StorageFailure() when storage != null:
return storage();case BackupInvalidFailure() when backupInvalid != null:
return backupInvalid(_that.reason);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class NetworkFailure extends Failure {
  const NetworkFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.network()';
}


}




/// @nodoc


class TimeoutFailure extends Failure {
  const TimeoutFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeoutFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.timeout()';
}


}




/// @nodoc


class ServerFailure extends Failure {
  const ServerFailure({required this.status, this.wireCode, this.requestId}): super._();
  

 final  int status;
 final  String? wireCode;
 final  String? requestId;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerFailureCopyWith<ServerFailure> get copyWith => _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerFailure&&(identical(other.status, status) || other.status == status)&&(identical(other.wireCode, wireCode) || other.wireCode == wireCode)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,status,wireCode,requestId);

@override
String toString() {
  return 'Failure.server(status: $status, wireCode: $wireCode, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(ServerFailure value, $Res Function(ServerFailure) _then) = _$ServerFailureCopyWithImpl;
@useResult
$Res call({
 int status, String? wireCode, String? requestId
});




}
/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? wireCode = freezed,Object? requestId = freezed,}) {
  return _then(ServerFailure(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int,wireCode: freezed == wireCode ? _self.wireCode : wireCode // ignore: cast_nullable_to_non_nullable
as String?,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RateLimitedFailure extends Failure {
  const RateLimitedFailure({required this.reason, this.retryAfter}): super._();
  

 final  RateLimitReason reason;
 final  Duration? retryAfter;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateLimitedFailureCopyWith<RateLimitedFailure> get copyWith => _$RateLimitedFailureCopyWithImpl<RateLimitedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateLimitedFailure&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode => Object.hash(runtimeType,reason,retryAfter);

@override
String toString() {
  return 'Failure.rateLimited(reason: $reason, retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $RateLimitedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $RateLimitedFailureCopyWith(RateLimitedFailure value, $Res Function(RateLimitedFailure) _then) = _$RateLimitedFailureCopyWithImpl;
@useResult
$Res call({
 RateLimitReason reason, Duration? retryAfter
});




}
/// @nodoc
class _$RateLimitedFailureCopyWithImpl<$Res>
    implements $RateLimitedFailureCopyWith<$Res> {
  _$RateLimitedFailureCopyWithImpl(this._self, this._then);

  final RateLimitedFailure _self;
  final $Res Function(RateLimitedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? retryAfter = freezed,}) {
  return _then(RateLimitedFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as RateLimitReason,retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class UpgradeRequiredFailure extends Failure {
  const UpgradeRequiredFailure({this.storeUrl}): super._();
  

 final  String? storeUrl;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpgradeRequiredFailureCopyWith<UpgradeRequiredFailure> get copyWith => _$UpgradeRequiredFailureCopyWithImpl<UpgradeRequiredFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpgradeRequiredFailure&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl));
}


@override
int get hashCode => Object.hash(runtimeType,storeUrl);

@override
String toString() {
  return 'Failure.upgradeRequired(storeUrl: $storeUrl)';
}


}

/// @nodoc
abstract mixin class $UpgradeRequiredFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UpgradeRequiredFailureCopyWith(UpgradeRequiredFailure value, $Res Function(UpgradeRequiredFailure) _then) = _$UpgradeRequiredFailureCopyWithImpl;
@useResult
$Res call({
 String? storeUrl
});




}
/// @nodoc
class _$UpgradeRequiredFailureCopyWithImpl<$Res>
    implements $UpgradeRequiredFailureCopyWith<$Res> {
  _$UpgradeRequiredFailureCopyWithImpl(this._self, this._then);

  final UpgradeRequiredFailure _self;
  final $Res Function(UpgradeRequiredFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? storeUrl = freezed,}) {
  return _then(UpgradeRequiredFailure(
storeUrl: freezed == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ContractFailure extends Failure {
  const ContractFailure({required this.wireCode}): super._();
  

 final  String wireCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractFailureCopyWith<ContractFailure> get copyWith => _$ContractFailureCopyWithImpl<ContractFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractFailure&&(identical(other.wireCode, wireCode) || other.wireCode == wireCode));
}


@override
int get hashCode => Object.hash(runtimeType,wireCode);

@override
String toString() {
  return 'Failure.contract(wireCode: $wireCode)';
}


}

/// @nodoc
abstract mixin class $ContractFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ContractFailureCopyWith(ContractFailure value, $Res Function(ContractFailure) _then) = _$ContractFailureCopyWithImpl;
@useResult
$Res call({
 String wireCode
});




}
/// @nodoc
class _$ContractFailureCopyWithImpl<$Res>
    implements $ContractFailureCopyWith<$Res> {
  _$ContractFailureCopyWithImpl(this._self, this._then);

  final ContractFailure _self;
  final $Res Function(ContractFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? wireCode = null,}) {
  return _then(ContractFailure(
wireCode: null == wireCode ? _self.wireCode : wireCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionExpiredFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.sessionExpired()';
}


}




/// @nodoc


class AttestationFailure extends Failure {
  const AttestationFailure({required this.kind}): super._();
  

 final  AttestationFailureKind kind;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttestationFailureCopyWith<AttestationFailure> get copyWith => _$AttestationFailureCopyWithImpl<AttestationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttestationFailure&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'Failure.attestation(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $AttestationFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $AttestationFailureCopyWith(AttestationFailure value, $Res Function(AttestationFailure) _then) = _$AttestationFailureCopyWithImpl;
@useResult
$Res call({
 AttestationFailureKind kind
});




}
/// @nodoc
class _$AttestationFailureCopyWithImpl<$Res>
    implements $AttestationFailureCopyWith<$Res> {
  _$AttestationFailureCopyWithImpl(this._self, this._then);

  final AttestationFailure _self;
  final $Res Function(AttestationFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(AttestationFailure(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttestationFailureKind,
  ));
}


}

/// @nodoc


class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure({required this.reason, this.balance, this.freeResetsAt}): super._();
  

 final  InsufficientReason reason;
 final  CreditBalance? balance;
 final  DateTime? freeResetsAt;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsufficientCreditsFailureCopyWith<InsufficientCreditsFailure> get copyWith => _$InsufficientCreditsFailureCopyWithImpl<InsufficientCreditsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsufficientCreditsFailure&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.freeResetsAt, freeResetsAt) || other.freeResetsAt == freeResetsAt));
}


@override
int get hashCode => Object.hash(runtimeType,reason,balance,freeResetsAt);

@override
String toString() {
  return 'Failure.insufficientCredits(reason: $reason, balance: $balance, freeResetsAt: $freeResetsAt)';
}


}

/// @nodoc
abstract mixin class $InsufficientCreditsFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $InsufficientCreditsFailureCopyWith(InsufficientCreditsFailure value, $Res Function(InsufficientCreditsFailure) _then) = _$InsufficientCreditsFailureCopyWithImpl;
@useResult
$Res call({
 InsufficientReason reason, CreditBalance? balance, DateTime? freeResetsAt
});


$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$InsufficientCreditsFailureCopyWithImpl<$Res>
    implements $InsufficientCreditsFailureCopyWith<$Res> {
  _$InsufficientCreditsFailureCopyWithImpl(this._self, this._then);

  final InsufficientCreditsFailure _self;
  final $Res Function(InsufficientCreditsFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? balance = freezed,Object? freeResetsAt = freezed,}) {
  return _then(InsufficientCreditsFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as InsufficientReason,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,freeResetsAt: freezed == freeResetsAt ? _self.freeResetsAt : freeResetsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $CreditBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}

/// @nodoc


class HoldConflictFailure extends Failure {
  const HoldConflictFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HoldConflictFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.holdConflict()';
}


}




/// @nodoc


class ReadingExpiredRefundedFailure extends Failure {
  const ReadingExpiredRefundedFailure({this.balance}): super._();
  

 final  CreditBalance? balance;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingExpiredRefundedFailureCopyWith<ReadingExpiredRefundedFailure> get copyWith => _$ReadingExpiredRefundedFailureCopyWithImpl<ReadingExpiredRefundedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingExpiredRefundedFailure&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,balance);

@override
String toString() {
  return 'Failure.readingExpiredRefunded(balance: $balance)';
}


}

/// @nodoc
abstract mixin class $ReadingExpiredRefundedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ReadingExpiredRefundedFailureCopyWith(ReadingExpiredRefundedFailure value, $Res Function(ReadingExpiredRefundedFailure) _then) = _$ReadingExpiredRefundedFailureCopyWithImpl;
@useResult
$Res call({
 CreditBalance? balance
});


$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$ReadingExpiredRefundedFailureCopyWithImpl<$Res>
    implements $ReadingExpiredRefundedFailureCopyWith<$Res> {
  _$ReadingExpiredRefundedFailureCopyWithImpl(this._self, this._then);

  final ReadingExpiredRefundedFailure _self;
  final $Res Function(ReadingExpiredRefundedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? balance = freezed,}) {
  return _then(ReadingExpiredRefundedFailure(
balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $CreditBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}

/// @nodoc


class AiConsentRequiredFailure extends Failure {
  const AiConsentRequiredFailure({this.requiredVersion}): super._();
  

 final  int? requiredVersion;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentRequiredFailureCopyWith<AiConsentRequiredFailure> get copyWith => _$AiConsentRequiredFailureCopyWithImpl<AiConsentRequiredFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsentRequiredFailure&&(identical(other.requiredVersion, requiredVersion) || other.requiredVersion == requiredVersion));
}


@override
int get hashCode => Object.hash(runtimeType,requiredVersion);

@override
String toString() {
  return 'Failure.aiConsentRequired(requiredVersion: $requiredVersion)';
}


}

/// @nodoc
abstract mixin class $AiConsentRequiredFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $AiConsentRequiredFailureCopyWith(AiConsentRequiredFailure value, $Res Function(AiConsentRequiredFailure) _then) = _$AiConsentRequiredFailureCopyWithImpl;
@useResult
$Res call({
 int? requiredVersion
});




}
/// @nodoc
class _$AiConsentRequiredFailureCopyWithImpl<$Res>
    implements $AiConsentRequiredFailureCopyWith<$Res> {
  _$AiConsentRequiredFailureCopyWithImpl(this._self, this._then);

  final AiConsentRequiredFailure _self;
  final $Res Function(AiConsentRequiredFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requiredVersion = freezed,}) {
  return _then(AiConsentRequiredFailure(
requiredVersion: freezed == requiredVersion ? _self.requiredVersion : requiredVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class AiUnavailableRegionFailure extends Failure {
  const AiUnavailableRegionFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiUnavailableRegionFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.aiUnavailableRegion()';
}


}




/// @nodoc


class ReadingsPausedFailure extends Failure {
  const ReadingsPausedFailure({required this.reason, this.retryAfter}): super._();
  

 final  PausedReason reason;
 final  Duration? retryAfter;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingsPausedFailureCopyWith<ReadingsPausedFailure> get copyWith => _$ReadingsPausedFailureCopyWithImpl<ReadingsPausedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingsPausedFailure&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode => Object.hash(runtimeType,reason,retryAfter);

@override
String toString() {
  return 'Failure.readingsPaused(reason: $reason, retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $ReadingsPausedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ReadingsPausedFailureCopyWith(ReadingsPausedFailure value, $Res Function(ReadingsPausedFailure) _then) = _$ReadingsPausedFailureCopyWithImpl;
@useResult
$Res call({
 PausedReason reason, Duration? retryAfter
});




}
/// @nodoc
class _$ReadingsPausedFailureCopyWithImpl<$Res>
    implements $ReadingsPausedFailureCopyWith<$Res> {
  _$ReadingsPausedFailureCopyWithImpl(this._self, this._then);

  final ReadingsPausedFailure _self;
  final $Res Function(ReadingsPausedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? retryAfter = freezed,}) {
  return _then(ReadingsPausedFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PausedReason,retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

/// @nodoc


class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiUnavailableFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.aiUnavailable()';
}


}




/// @nodoc


class RequestInProgressFailure extends Failure {
  const RequestInProgressFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestInProgressFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.requestInProgress()';
}


}




/// @nodoc


class RewardUnavailableFailure extends Failure {
  const RewardUnavailableFailure({required this.reason, this.availableAt}): super._();
  

 final  RewardUnavailableReason reason;
 final  DateTime? availableAt;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardUnavailableFailureCopyWith<RewardUnavailableFailure> get copyWith => _$RewardUnavailableFailureCopyWithImpl<RewardUnavailableFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardUnavailableFailure&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt));
}


@override
int get hashCode => Object.hash(runtimeType,reason,availableAt);

@override
String toString() {
  return 'Failure.rewardUnavailable(reason: $reason, availableAt: $availableAt)';
}


}

/// @nodoc
abstract mixin class $RewardUnavailableFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $RewardUnavailableFailureCopyWith(RewardUnavailableFailure value, $Res Function(RewardUnavailableFailure) _then) = _$RewardUnavailableFailureCopyWithImpl;
@useResult
$Res call({
 RewardUnavailableReason reason, DateTime? availableAt
});




}
/// @nodoc
class _$RewardUnavailableFailureCopyWithImpl<$Res>
    implements $RewardUnavailableFailureCopyWith<$Res> {
  _$RewardUnavailableFailureCopyWithImpl(this._self, this._then);

  final RewardUnavailableFailure _self;
  final $Res Function(RewardUnavailableFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? availableAt = freezed,}) {
  return _then(RewardUnavailableFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as RewardUnavailableReason,availableAt: freezed == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class TimezoneChangeRejectedFailure extends Failure {
  const TimezoneChangeRejectedFailure({required this.allowedAfter}): super._();
  

 final  DateTime allowedAfter;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimezoneChangeRejectedFailureCopyWith<TimezoneChangeRejectedFailure> get copyWith => _$TimezoneChangeRejectedFailureCopyWithImpl<TimezoneChangeRejectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimezoneChangeRejectedFailure&&(identical(other.allowedAfter, allowedAfter) || other.allowedAfter == allowedAfter));
}


@override
int get hashCode => Object.hash(runtimeType,allowedAfter);

@override
String toString() {
  return 'Failure.timezoneChangeRejected(allowedAfter: $allowedAfter)';
}


}

/// @nodoc
abstract mixin class $TimezoneChangeRejectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $TimezoneChangeRejectedFailureCopyWith(TimezoneChangeRejectedFailure value, $Res Function(TimezoneChangeRejectedFailure) _then) = _$TimezoneChangeRejectedFailureCopyWithImpl;
@useResult
$Res call({
 DateTime allowedAfter
});




}
/// @nodoc
class _$TimezoneChangeRejectedFailureCopyWithImpl<$Res>
    implements $TimezoneChangeRejectedFailureCopyWith<$Res> {
  _$TimezoneChangeRejectedFailureCopyWithImpl(this._self, this._then);

  final TimezoneChangeRejectedFailure _self;
  final $Res Function(TimezoneChangeRejectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? allowedAfter = null,}) {
  return _then(TimezoneChangeRejectedFailure(
allowedAfter: null == allowedAfter ? _self.allowedAfter : allowedAfter // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseCancelledFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.purchaseCancelled()';
}


}




/// @nodoc


class PurchasePendingFailure extends Failure {
  const PurchasePendingFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchasePendingFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.purchasePending()';
}


}




/// @nodoc


class PurchaseFailure extends Failure {
  const PurchaseFailure({required this.wireCode, this.reason}): super._();
  

 final  String wireCode;
 final  String? reason;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseFailureCopyWith<PurchaseFailure> get copyWith => _$PurchaseFailureCopyWithImpl<PurchaseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseFailure&&(identical(other.wireCode, wireCode) || other.wireCode == wireCode)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,wireCode,reason);

@override
String toString() {
  return 'Failure.purchase(wireCode: $wireCode, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PurchaseFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PurchaseFailureCopyWith(PurchaseFailure value, $Res Function(PurchaseFailure) _then) = _$PurchaseFailureCopyWithImpl;
@useResult
$Res call({
 String wireCode, String? reason
});




}
/// @nodoc
class _$PurchaseFailureCopyWithImpl<$Res>
    implements $PurchaseFailureCopyWith<$Res> {
  _$PurchaseFailureCopyWithImpl(this._self, this._then);

  final PurchaseFailure _self;
  final $Res Function(PurchaseFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? wireCode = null,Object? reason = freezed,}) {
  return _then(PurchaseFailure(
wireCode: null == wireCode ? _self.wireCode : wireCode // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PurchaseAlreadyClaimedFailure extends Failure {
  const PurchaseAlreadyClaimedFailure({required this.transferEligible, this.transferToken}): super._();
  

 final  bool transferEligible;
 final  String? transferToken;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseAlreadyClaimedFailureCopyWith<PurchaseAlreadyClaimedFailure> get copyWith => _$PurchaseAlreadyClaimedFailureCopyWithImpl<PurchaseAlreadyClaimedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseAlreadyClaimedFailure&&(identical(other.transferEligible, transferEligible) || other.transferEligible == transferEligible)&&(identical(other.transferToken, transferToken) || other.transferToken == transferToken));
}


@override
int get hashCode => Object.hash(runtimeType,transferEligible,transferToken);

@override
String toString() {
  return 'Failure.purchaseAlreadyClaimed(transferEligible: $transferEligible, transferToken: $transferToken)';
}


}

/// @nodoc
abstract mixin class $PurchaseAlreadyClaimedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PurchaseAlreadyClaimedFailureCopyWith(PurchaseAlreadyClaimedFailure value, $Res Function(PurchaseAlreadyClaimedFailure) _then) = _$PurchaseAlreadyClaimedFailureCopyWithImpl;
@useResult
$Res call({
 bool transferEligible, String? transferToken
});




}
/// @nodoc
class _$PurchaseAlreadyClaimedFailureCopyWithImpl<$Res>
    implements $PurchaseAlreadyClaimedFailureCopyWith<$Res> {
  _$PurchaseAlreadyClaimedFailureCopyWithImpl(this._self, this._then);

  final PurchaseAlreadyClaimedFailure _self;
  final $Res Function(PurchaseAlreadyClaimedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transferEligible = null,Object? transferToken = freezed,}) {
  return _then(PurchaseAlreadyClaimedFailure(
transferEligible: null == transferEligible ? _self.transferEligible : transferEligible // ignore: cast_nullable_to_non_nullable
as bool,transferToken: freezed == transferToken ? _self.transferToken : transferToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PurchasesBlockedFailure extends Failure {
  const PurchasesBlockedFailure({required this.reason}): super._();
  

 final  PurchasesBlockedReason reason;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchasesBlockedFailureCopyWith<PurchasesBlockedFailure> get copyWith => _$PurchasesBlockedFailureCopyWithImpl<PurchasesBlockedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchasesBlockedFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'Failure.purchasesBlocked(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PurchasesBlockedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $PurchasesBlockedFailureCopyWith(PurchasesBlockedFailure value, $Res Function(PurchasesBlockedFailure) _then) = _$PurchasesBlockedFailureCopyWithImpl;
@useResult
$Res call({
 PurchasesBlockedReason reason
});




}
/// @nodoc
class _$PurchasesBlockedFailureCopyWithImpl<$Res>
    implements $PurchasesBlockedFailureCopyWith<$Res> {
  _$PurchasesBlockedFailureCopyWithImpl(this._self, this._then);

  final PurchasesBlockedFailure _self;
  final $Res Function(PurchasesBlockedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PurchasesBlockedFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason,
  ));
}


}

/// @nodoc


class ProductUnavailableFailure extends Failure {
  const ProductUnavailableFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductUnavailableFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.productUnavailable()';
}


}




/// @nodoc


class StorageFailure extends Failure {
  const StorageFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.storage()';
}


}




/// @nodoc


class BackupInvalidFailure extends Failure {
  const BackupInvalidFailure({required this.reason}): super._();
  

 final  BackupInvalidReason reason;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupInvalidFailureCopyWith<BackupInvalidFailure> get copyWith => _$BackupInvalidFailureCopyWithImpl<BackupInvalidFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupInvalidFailure&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'Failure.backupInvalid(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BackupInvalidFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $BackupInvalidFailureCopyWith(BackupInvalidFailure value, $Res Function(BackupInvalidFailure) _then) = _$BackupInvalidFailureCopyWithImpl;
@useResult
$Res call({
 BackupInvalidReason reason
});




}
/// @nodoc
class _$BackupInvalidFailureCopyWithImpl<$Res>
    implements $BackupInvalidFailureCopyWith<$Res> {
  _$BackupInvalidFailureCopyWithImpl(this._self, this._then);

  final BackupInvalidFailure _self;
  final $Res Function(BackupInvalidFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(BackupInvalidFailure(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BackupInvalidReason,
  ));
}


}

/// @nodoc


class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required this.error, required this.stack}): super._();
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexpectedFailureCopyWith<UnexpectedFailure> get copyWith => _$UnexpectedFailureCopyWithImpl<UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexpectedFailure&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'Failure.unexpected(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $UnexpectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexpectedFailureCopyWith(UnexpectedFailure value, $Res Function(UnexpectedFailure) _then) = _$UnexpectedFailureCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$UnexpectedFailureCopyWithImpl<$Res>
    implements $UnexpectedFailureCopyWith<$Res> {
  _$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final UnexpectedFailure _self;
  final $Res Function(UnexpectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(UnexpectedFailure(
error: null == error ? _self.error : error ,stack: null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
