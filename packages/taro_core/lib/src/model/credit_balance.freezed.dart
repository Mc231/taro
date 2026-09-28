// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FreeAllowance {

/// Free readings per day today.
 int get limit;/// Used today.
 int get used;/// Left today.
 int get remaining;/// The install's local date `YYYY-MM-DD` on the Worker.
 String get localDate;/// Next reset (UTC).
 DateTime get resetsAt;/// IANA timezone the day boundary uses.
 String get timezone;/// Whether the budget free-stop tier pauses free readings (RC64).
 bool get paused;
/// Create a copy of FreeAllowance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeAllowanceCopyWith<FreeAllowance> get copyWith => _$FreeAllowanceCopyWithImpl<FreeAllowance>(this as FreeAllowance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeAllowance&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.used, used) || other.used == used)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.resetsAt, resetsAt) || other.resetsAt == resetsAt)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.paused, paused) || other.paused == paused));
}


@override
int get hashCode => Object.hash(runtimeType,limit,used,remaining,localDate,resetsAt,timezone,paused);

@override
String toString() {
  return 'FreeAllowance(limit: $limit, used: $used, remaining: $remaining, localDate: $localDate, resetsAt: $resetsAt, timezone: $timezone, paused: $paused)';
}


}

/// @nodoc
abstract mixin class $FreeAllowanceCopyWith<$Res>  {
  factory $FreeAllowanceCopyWith(FreeAllowance value, $Res Function(FreeAllowance) _then) = _$FreeAllowanceCopyWithImpl;
@useResult
$Res call({
 int limit, int used, int remaining, String localDate, DateTime resetsAt, String timezone, bool paused
});




}
/// @nodoc
class _$FreeAllowanceCopyWithImpl<$Res>
    implements $FreeAllowanceCopyWith<$Res> {
  _$FreeAllowanceCopyWithImpl(this._self, this._then);

  final FreeAllowance _self;
  final $Res Function(FreeAllowance) _then;

/// Create a copy of FreeAllowance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? used = null,Object? remaining = null,Object? localDate = null,Object? resetsAt = null,Object? timezone = null,Object? paused = null,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,resetsAt: null == resetsAt ? _self.resetsAt : resetsAt // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FreeAllowance].
extension FreeAllowancePatterns on FreeAllowance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreeAllowance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreeAllowance() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreeAllowance value)  $default,){
final _that = this;
switch (_that) {
case _FreeAllowance():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreeAllowance value)?  $default,){
final _that = this;
switch (_that) {
case _FreeAllowance() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int limit,  int used,  int remaining,  String localDate,  DateTime resetsAt,  String timezone,  bool paused)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeAllowance() when $default != null:
return $default(_that.limit,_that.used,_that.remaining,_that.localDate,_that.resetsAt,_that.timezone,_that.paused);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int limit,  int used,  int remaining,  String localDate,  DateTime resetsAt,  String timezone,  bool paused)  $default,) {final _that = this;
switch (_that) {
case _FreeAllowance():
return $default(_that.limit,_that.used,_that.remaining,_that.localDate,_that.resetsAt,_that.timezone,_that.paused);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int limit,  int used,  int remaining,  String localDate,  DateTime resetsAt,  String timezone,  bool paused)?  $default,) {final _that = this;
switch (_that) {
case _FreeAllowance() when $default != null:
return $default(_that.limit,_that.used,_that.remaining,_that.localDate,_that.resetsAt,_that.timezone,_that.paused);case _:
  return null;

}
}

}

/// @nodoc


class _FreeAllowance implements FreeAllowance {
  const _FreeAllowance({required this.limit, required this.used, required this.remaining, required this.localDate, required this.resetsAt, required this.timezone, this.paused = false});
  

/// Free readings per day today.
@override final  int limit;
/// Used today.
@override final  int used;
/// Left today.
@override final  int remaining;
/// The install's local date `YYYY-MM-DD` on the Worker.
@override final  String localDate;
/// Next reset (UTC).
@override final  DateTime resetsAt;
/// IANA timezone the day boundary uses.
@override final  String timezone;
/// Whether the budget free-stop tier pauses free readings (RC64).
@override@JsonKey() final  bool paused;

/// Create a copy of FreeAllowance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeAllowanceCopyWith<_FreeAllowance> get copyWith => __$FreeAllowanceCopyWithImpl<_FreeAllowance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeAllowance&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.used, used) || other.used == used)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.resetsAt, resetsAt) || other.resetsAt == resetsAt)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.paused, paused) || other.paused == paused));
}


@override
int get hashCode => Object.hash(runtimeType,limit,used,remaining,localDate,resetsAt,timezone,paused);

@override
String toString() {
  return 'FreeAllowance(limit: $limit, used: $used, remaining: $remaining, localDate: $localDate, resetsAt: $resetsAt, timezone: $timezone, paused: $paused)';
}


}

/// @nodoc
abstract mixin class _$FreeAllowanceCopyWith<$Res> implements $FreeAllowanceCopyWith<$Res> {
  factory _$FreeAllowanceCopyWith(_FreeAllowance value, $Res Function(_FreeAllowance) _then) = __$FreeAllowanceCopyWithImpl;
@override @useResult
$Res call({
 int limit, int used, int remaining, String localDate, DateTime resetsAt, String timezone, bool paused
});




}
/// @nodoc
class __$FreeAllowanceCopyWithImpl<$Res>
    implements _$FreeAllowanceCopyWith<$Res> {
  __$FreeAllowanceCopyWithImpl(this._self, this._then);

  final _FreeAllowance _self;
  final $Res Function(_FreeAllowance) _then;

/// Create a copy of FreeAllowance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? used = null,Object? remaining = null,Object? localDate = null,Object? resetsAt = null,Object? timezone = null,Object? paused = null,}) {
  return _then(_FreeAllowance(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,resetsAt: null == resetsAt ? _self.resetsAt : resetsAt // ignore: cast_nullable_to_non_nullable
as DateTime,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RewardedStatus {

/// `rewarded.enabled`.
 bool get enabled;/// Readings per completed ad.
 int get amount;/// Grants per local day.
 int get dailyCap;/// Grants so far today.
 int get grantedToday;/// Whether an ad may be offered now.
 bool get available;/// End of the cooldown after the last grant (UTC).
 DateTime? get cooldownEndsAt;
/// Create a copy of RewardedStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedStatusCopyWith<RewardedStatus> get copyWith => _$RewardedStatusCopyWithImpl<RewardedStatus>(this as RewardedStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedStatus&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dailyCap, dailyCap) || other.dailyCap == dailyCap)&&(identical(other.grantedToday, grantedToday) || other.grantedToday == grantedToday)&&(identical(other.available, available) || other.available == available)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,amount,dailyCap,grantedToday,available,cooldownEndsAt);

@override
String toString() {
  return 'RewardedStatus(enabled: $enabled, amount: $amount, dailyCap: $dailyCap, grantedToday: $grantedToday, available: $available, cooldownEndsAt: $cooldownEndsAt)';
}


}

/// @nodoc
abstract mixin class $RewardedStatusCopyWith<$Res>  {
  factory $RewardedStatusCopyWith(RewardedStatus value, $Res Function(RewardedStatus) _then) = _$RewardedStatusCopyWithImpl;
@useResult
$Res call({
 bool enabled, int amount, int dailyCap, int grantedToday, bool available, DateTime? cooldownEndsAt
});




}
/// @nodoc
class _$RewardedStatusCopyWithImpl<$Res>
    implements $RewardedStatusCopyWith<$Res> {
  _$RewardedStatusCopyWithImpl(this._self, this._then);

  final RewardedStatus _self;
  final $Res Function(RewardedStatus) _then;

/// Create a copy of RewardedStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? amount = null,Object? dailyCap = null,Object? grantedToday = null,Object? available = null,Object? cooldownEndsAt = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,dailyCap: null == dailyCap ? _self.dailyCap : dailyCap // ignore: cast_nullable_to_non_nullable
as int,grantedToday: null == grantedToday ? _self.grantedToday : grantedToday // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardedStatus].
extension RewardedStatusPatterns on RewardedStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardedStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardedStatus() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardedStatus value)  $default,){
final _that = this;
switch (_that) {
case _RewardedStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardedStatus value)?  $default,){
final _that = this;
switch (_that) {
case _RewardedStatus() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  int amount,  int dailyCap,  int grantedToday,  bool available,  DateTime? cooldownEndsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardedStatus() when $default != null:
return $default(_that.enabled,_that.amount,_that.dailyCap,_that.grantedToday,_that.available,_that.cooldownEndsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  int amount,  int dailyCap,  int grantedToday,  bool available,  DateTime? cooldownEndsAt)  $default,) {final _that = this;
switch (_that) {
case _RewardedStatus():
return $default(_that.enabled,_that.amount,_that.dailyCap,_that.grantedToday,_that.available,_that.cooldownEndsAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  int amount,  int dailyCap,  int grantedToday,  bool available,  DateTime? cooldownEndsAt)?  $default,) {final _that = this;
switch (_that) {
case _RewardedStatus() when $default != null:
return $default(_that.enabled,_that.amount,_that.dailyCap,_that.grantedToday,_that.available,_that.cooldownEndsAt);case _:
  return null;

}
}

}

/// @nodoc


class _RewardedStatus implements RewardedStatus {
  const _RewardedStatus({required this.enabled, required this.amount, required this.dailyCap, required this.grantedToday, required this.available, this.cooldownEndsAt});
  

/// `rewarded.enabled`.
@override final  bool enabled;
/// Readings per completed ad.
@override final  int amount;
/// Grants per local day.
@override final  int dailyCap;
/// Grants so far today.
@override final  int grantedToday;
/// Whether an ad may be offered now.
@override final  bool available;
/// End of the cooldown after the last grant (UTC).
@override final  DateTime? cooldownEndsAt;

/// Create a copy of RewardedStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardedStatusCopyWith<_RewardedStatus> get copyWith => __$RewardedStatusCopyWithImpl<_RewardedStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardedStatus&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dailyCap, dailyCap) || other.dailyCap == dailyCap)&&(identical(other.grantedToday, grantedToday) || other.grantedToday == grantedToday)&&(identical(other.available, available) || other.available == available)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,amount,dailyCap,grantedToday,available,cooldownEndsAt);

@override
String toString() {
  return 'RewardedStatus(enabled: $enabled, amount: $amount, dailyCap: $dailyCap, grantedToday: $grantedToday, available: $available, cooldownEndsAt: $cooldownEndsAt)';
}


}

/// @nodoc
abstract mixin class _$RewardedStatusCopyWith<$Res> implements $RewardedStatusCopyWith<$Res> {
  factory _$RewardedStatusCopyWith(_RewardedStatus value, $Res Function(_RewardedStatus) _then) = __$RewardedStatusCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, int amount, int dailyCap, int grantedToday, bool available, DateTime? cooldownEndsAt
});




}
/// @nodoc
class __$RewardedStatusCopyWithImpl<$Res>
    implements _$RewardedStatusCopyWith<$Res> {
  __$RewardedStatusCopyWithImpl(this._self, this._then);

  final _RewardedStatus _self;
  final $Res Function(_RewardedStatus) _then;

/// Create a copy of RewardedStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? amount = null,Object? dailyCap = null,Object? grantedToday = null,Object? available = null,Object? cooldownEndsAt = freezed,}) {
  return _then(_RewardedStatus(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,dailyCap: null == dailyCap ? _self.dailyCap : dailyCap // ignore: cast_nullable_to_non_nullable
as int,grantedToday: null == grantedToday ? _self.grantedToday : grantedToday // ignore: cast_nullable_to_non_nullable
as int,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$CreditBalance {

/// Today's free allowance.
 FreeAllowance get free;/// Earned readings ("earned readings" in the UI).
 int get bonus;/// Purchased readings; negative after a refund clawback (MO16).
 int get paid;/// Whether a reading may start.
 bool get canRead;/// Why [canRead] is false.
 CanReadReason? get canReadReason;/// Which bucket the next reading uses; `null` when none can.
 ChargeSource? get nextSource;/// Rewarded-ad status.
 RewardedStatus get rewarded;/// `paid < 0`.
 bool get paidBlocked;/// Whether pack purchases are offered (RC66).
 bool get purchasesAllowed;/// Why purchases are blocked.
 PurchasesBlockedReason? get purchasesBlockedReason;/// `installs.state_version` (RC67).
 int get ledgerVersion;/// Worker time of the response (UTC).
 DateTime get serverTime;/// Device time when the response was received.
 DateTime get syncedAt;
/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<CreditBalance> get copyWith => _$CreditBalanceCopyWithImpl<CreditBalance>(this as CreditBalance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditBalance&&(identical(other.free, free) || other.free == free)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.canRead, canRead) || other.canRead == canRead)&&(identical(other.canReadReason, canReadReason) || other.canReadReason == canReadReason)&&(identical(other.nextSource, nextSource) || other.nextSource == nextSource)&&(identical(other.rewarded, rewarded) || other.rewarded == rewarded)&&(identical(other.paidBlocked, paidBlocked) || other.paidBlocked == paidBlocked)&&(identical(other.purchasesAllowed, purchasesAllowed) || other.purchasesAllowed == purchasesAllowed)&&(identical(other.purchasesBlockedReason, purchasesBlockedReason) || other.purchasesBlockedReason == purchasesBlockedReason)&&(identical(other.ledgerVersion, ledgerVersion) || other.ledgerVersion == ledgerVersion)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,free,bonus,paid,canRead,canReadReason,nextSource,rewarded,paidBlocked,purchasesAllowed,purchasesBlockedReason,ledgerVersion,serverTime,syncedAt);

@override
String toString() {
  return 'CreditBalance(free: $free, bonus: $bonus, paid: $paid, canRead: $canRead, canReadReason: $canReadReason, nextSource: $nextSource, rewarded: $rewarded, paidBlocked: $paidBlocked, purchasesAllowed: $purchasesAllowed, purchasesBlockedReason: $purchasesBlockedReason, ledgerVersion: $ledgerVersion, serverTime: $serverTime, syncedAt: $syncedAt)';
}


}

/// @nodoc
abstract mixin class $CreditBalanceCopyWith<$Res>  {
  factory $CreditBalanceCopyWith(CreditBalance value, $Res Function(CreditBalance) _then) = _$CreditBalanceCopyWithImpl;
@useResult
$Res call({
 FreeAllowance free, int bonus, int paid, bool canRead, CanReadReason? canReadReason, ChargeSource? nextSource, RewardedStatus rewarded, bool paidBlocked, bool purchasesAllowed, PurchasesBlockedReason? purchasesBlockedReason, int ledgerVersion, DateTime serverTime, DateTime syncedAt
});


$FreeAllowanceCopyWith<$Res> get free;$RewardedStatusCopyWith<$Res> get rewarded;

}
/// @nodoc
class _$CreditBalanceCopyWithImpl<$Res>
    implements $CreditBalanceCopyWith<$Res> {
  _$CreditBalanceCopyWithImpl(this._self, this._then);

  final CreditBalance _self;
  final $Res Function(CreditBalance) _then;

/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? free = null,Object? bonus = null,Object? paid = null,Object? canRead = null,Object? canReadReason = freezed,Object? nextSource = freezed,Object? rewarded = null,Object? paidBlocked = null,Object? purchasesAllowed = null,Object? purchasesBlockedReason = freezed,Object? ledgerVersion = null,Object? serverTime = null,Object? syncedAt = null,}) {
  return _then(_self.copyWith(
free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as FreeAllowance,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as int,canRead: null == canRead ? _self.canRead : canRead // ignore: cast_nullable_to_non_nullable
as bool,canReadReason: freezed == canReadReason ? _self.canReadReason : canReadReason // ignore: cast_nullable_to_non_nullable
as CanReadReason?,nextSource: freezed == nextSource ? _self.nextSource : nextSource // ignore: cast_nullable_to_non_nullable
as ChargeSource?,rewarded: null == rewarded ? _self.rewarded : rewarded // ignore: cast_nullable_to_non_nullable
as RewardedStatus,paidBlocked: null == paidBlocked ? _self.paidBlocked : paidBlocked // ignore: cast_nullable_to_non_nullable
as bool,purchasesAllowed: null == purchasesAllowed ? _self.purchasesAllowed : purchasesAllowed // ignore: cast_nullable_to_non_nullable
as bool,purchasesBlockedReason: freezed == purchasesBlockedReason ? _self.purchasesBlockedReason : purchasesBlockedReason // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason?,ledgerVersion: null == ledgerVersion ? _self.ledgerVersion : ledgerVersion // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,syncedAt: null == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeAllowanceCopyWith<$Res> get free {
  
  return $FreeAllowanceCopyWith<$Res>(_self.free, (value) {
    return _then(_self.copyWith(free: value));
  });
}/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardedStatusCopyWith<$Res> get rewarded {
  
  return $RewardedStatusCopyWith<$Res>(_self.rewarded, (value) {
    return _then(_self.copyWith(rewarded: value));
  });
}
}


/// Adds pattern-matching-related methods to [CreditBalance].
extension CreditBalancePatterns on CreditBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditBalance() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditBalance value)  $default,){
final _that = this;
switch (_that) {
case _CreditBalance():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditBalance value)?  $default,){
final _that = this;
switch (_that) {
case _CreditBalance() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FreeAllowance free,  int bonus,  int paid,  bool canRead,  CanReadReason? canReadReason,  ChargeSource? nextSource,  RewardedStatus rewarded,  bool paidBlocked,  bool purchasesAllowed,  PurchasesBlockedReason? purchasesBlockedReason,  int ledgerVersion,  DateTime serverTime,  DateTime syncedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditBalance() when $default != null:
return $default(_that.free,_that.bonus,_that.paid,_that.canRead,_that.canReadReason,_that.nextSource,_that.rewarded,_that.paidBlocked,_that.purchasesAllowed,_that.purchasesBlockedReason,_that.ledgerVersion,_that.serverTime,_that.syncedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FreeAllowance free,  int bonus,  int paid,  bool canRead,  CanReadReason? canReadReason,  ChargeSource? nextSource,  RewardedStatus rewarded,  bool paidBlocked,  bool purchasesAllowed,  PurchasesBlockedReason? purchasesBlockedReason,  int ledgerVersion,  DateTime serverTime,  DateTime syncedAt)  $default,) {final _that = this;
switch (_that) {
case _CreditBalance():
return $default(_that.free,_that.bonus,_that.paid,_that.canRead,_that.canReadReason,_that.nextSource,_that.rewarded,_that.paidBlocked,_that.purchasesAllowed,_that.purchasesBlockedReason,_that.ledgerVersion,_that.serverTime,_that.syncedAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FreeAllowance free,  int bonus,  int paid,  bool canRead,  CanReadReason? canReadReason,  ChargeSource? nextSource,  RewardedStatus rewarded,  bool paidBlocked,  bool purchasesAllowed,  PurchasesBlockedReason? purchasesBlockedReason,  int ledgerVersion,  DateTime serverTime,  DateTime syncedAt)?  $default,) {final _that = this;
switch (_that) {
case _CreditBalance() when $default != null:
return $default(_that.free,_that.bonus,_that.paid,_that.canRead,_that.canReadReason,_that.nextSource,_that.rewarded,_that.paidBlocked,_that.purchasesAllowed,_that.purchasesBlockedReason,_that.ledgerVersion,_that.serverTime,_that.syncedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CreditBalance extends CreditBalance {
  const _CreditBalance({required this.free, required this.bonus, required this.paid, required this.canRead, required this.canReadReason, required this.nextSource, required this.rewarded, required this.paidBlocked, required this.purchasesAllowed, required this.purchasesBlockedReason, required this.ledgerVersion, required this.serverTime, required this.syncedAt}): super._();
  

/// Today's free allowance.
@override final  FreeAllowance free;
/// Earned readings ("earned readings" in the UI).
@override final  int bonus;
/// Purchased readings; negative after a refund clawback (MO16).
@override final  int paid;
/// Whether a reading may start.
@override final  bool canRead;
/// Why [canRead] is false.
@override final  CanReadReason? canReadReason;
/// Which bucket the next reading uses; `null` when none can.
@override final  ChargeSource? nextSource;
/// Rewarded-ad status.
@override final  RewardedStatus rewarded;
/// `paid < 0`.
@override final  bool paidBlocked;
/// Whether pack purchases are offered (RC66).
@override final  bool purchasesAllowed;
/// Why purchases are blocked.
@override final  PurchasesBlockedReason? purchasesBlockedReason;
/// `installs.state_version` (RC67).
@override final  int ledgerVersion;
/// Worker time of the response (UTC).
@override final  DateTime serverTime;
/// Device time when the response was received.
@override final  DateTime syncedAt;

/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditBalanceCopyWith<_CreditBalance> get copyWith => __$CreditBalanceCopyWithImpl<_CreditBalance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditBalance&&(identical(other.free, free) || other.free == free)&&(identical(other.bonus, bonus) || other.bonus == bonus)&&(identical(other.paid, paid) || other.paid == paid)&&(identical(other.canRead, canRead) || other.canRead == canRead)&&(identical(other.canReadReason, canReadReason) || other.canReadReason == canReadReason)&&(identical(other.nextSource, nextSource) || other.nextSource == nextSource)&&(identical(other.rewarded, rewarded) || other.rewarded == rewarded)&&(identical(other.paidBlocked, paidBlocked) || other.paidBlocked == paidBlocked)&&(identical(other.purchasesAllowed, purchasesAllowed) || other.purchasesAllowed == purchasesAllowed)&&(identical(other.purchasesBlockedReason, purchasesBlockedReason) || other.purchasesBlockedReason == purchasesBlockedReason)&&(identical(other.ledgerVersion, ledgerVersion) || other.ledgerVersion == ledgerVersion)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.syncedAt, syncedAt) || other.syncedAt == syncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,free,bonus,paid,canRead,canReadReason,nextSource,rewarded,paidBlocked,purchasesAllowed,purchasesBlockedReason,ledgerVersion,serverTime,syncedAt);

@override
String toString() {
  return 'CreditBalance(free: $free, bonus: $bonus, paid: $paid, canRead: $canRead, canReadReason: $canReadReason, nextSource: $nextSource, rewarded: $rewarded, paidBlocked: $paidBlocked, purchasesAllowed: $purchasesAllowed, purchasesBlockedReason: $purchasesBlockedReason, ledgerVersion: $ledgerVersion, serverTime: $serverTime, syncedAt: $syncedAt)';
}


}

/// @nodoc
abstract mixin class _$CreditBalanceCopyWith<$Res> implements $CreditBalanceCopyWith<$Res> {
  factory _$CreditBalanceCopyWith(_CreditBalance value, $Res Function(_CreditBalance) _then) = __$CreditBalanceCopyWithImpl;
@override @useResult
$Res call({
 FreeAllowance free, int bonus, int paid, bool canRead, CanReadReason? canReadReason, ChargeSource? nextSource, RewardedStatus rewarded, bool paidBlocked, bool purchasesAllowed, PurchasesBlockedReason? purchasesBlockedReason, int ledgerVersion, DateTime serverTime, DateTime syncedAt
});


@override $FreeAllowanceCopyWith<$Res> get free;@override $RewardedStatusCopyWith<$Res> get rewarded;

}
/// @nodoc
class __$CreditBalanceCopyWithImpl<$Res>
    implements _$CreditBalanceCopyWith<$Res> {
  __$CreditBalanceCopyWithImpl(this._self, this._then);

  final _CreditBalance _self;
  final $Res Function(_CreditBalance) _then;

/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? free = null,Object? bonus = null,Object? paid = null,Object? canRead = null,Object? canReadReason = freezed,Object? nextSource = freezed,Object? rewarded = null,Object? paidBlocked = null,Object? purchasesAllowed = null,Object? purchasesBlockedReason = freezed,Object? ledgerVersion = null,Object? serverTime = null,Object? syncedAt = null,}) {
  return _then(_CreditBalance(
free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as FreeAllowance,bonus: null == bonus ? _self.bonus : bonus // ignore: cast_nullable_to_non_nullable
as int,paid: null == paid ? _self.paid : paid // ignore: cast_nullable_to_non_nullable
as int,canRead: null == canRead ? _self.canRead : canRead // ignore: cast_nullable_to_non_nullable
as bool,canReadReason: freezed == canReadReason ? _self.canReadReason : canReadReason // ignore: cast_nullable_to_non_nullable
as CanReadReason?,nextSource: freezed == nextSource ? _self.nextSource : nextSource // ignore: cast_nullable_to_non_nullable
as ChargeSource?,rewarded: null == rewarded ? _self.rewarded : rewarded // ignore: cast_nullable_to_non_nullable
as RewardedStatus,paidBlocked: null == paidBlocked ? _self.paidBlocked : paidBlocked // ignore: cast_nullable_to_non_nullable
as bool,purchasesAllowed: null == purchasesAllowed ? _self.purchasesAllowed : purchasesAllowed // ignore: cast_nullable_to_non_nullable
as bool,purchasesBlockedReason: freezed == purchasesBlockedReason ? _self.purchasesBlockedReason : purchasesBlockedReason // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason?,ledgerVersion: null == ledgerVersion ? _self.ledgerVersion : ledgerVersion // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,syncedAt: null == syncedAt ? _self.syncedAt : syncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeAllowanceCopyWith<$Res> get free {
  
  return $FreeAllowanceCopyWith<$Res>(_self.free, (value) {
    return _then(_self.copyWith(free: value));
  });
}/// Create a copy of CreditBalance
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardedStatusCopyWith<$Res> get rewarded {
  
  return $RewardedStatusCopyWith<$Res>(_self.rewarded, (value) {
    return _then(_self.copyWith(rewarded: value));
  });
}
}

// dart format on
