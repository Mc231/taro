// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RewardIntent {

/// The intent ID (also SSV `customData` and `userId`).
 IntentId get intentId;/// Bonus readings granted on a verified view.
 int get amount;/// When the intent lapses (UTC).
 DateTime get expiresAt;
/// Create a copy of RewardIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardIntentCopyWith<RewardIntent> get copyWith => _$RewardIntentCopyWithImpl<RewardIntent>(this as RewardIntent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardIntent&&(identical(other.intentId, intentId) || other.intentId == intentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,intentId,amount,expiresAt);

@override
String toString() {
  return 'RewardIntent(intentId: $intentId, amount: $amount, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $RewardIntentCopyWith<$Res>  {
  factory $RewardIntentCopyWith(RewardIntent value, $Res Function(RewardIntent) _then) = _$RewardIntentCopyWithImpl;
@useResult
$Res call({
 IntentId intentId, int amount, DateTime expiresAt
});




}
/// @nodoc
class _$RewardIntentCopyWithImpl<$Res>
    implements $RewardIntentCopyWith<$Res> {
  _$RewardIntentCopyWithImpl(this._self, this._then);

  final RewardIntent _self;
  final $Res Function(RewardIntent) _then;

/// Create a copy of RewardIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intentId = null,Object? amount = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
intentId: null == intentId ? _self.intentId : intentId // ignore: cast_nullable_to_non_nullable
as IntentId,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardIntent].
extension RewardIntentPatterns on RewardIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardIntent value)  $default,){
final _that = this;
switch (_that) {
case _RewardIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardIntent value)?  $default,){
final _that = this;
switch (_that) {
case _RewardIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IntentId intentId,  int amount,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardIntent() when $default != null:
return $default(_that.intentId,_that.amount,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IntentId intentId,  int amount,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _RewardIntent():
return $default(_that.intentId,_that.amount,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IntentId intentId,  int amount,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _RewardIntent() when $default != null:
return $default(_that.intentId,_that.amount,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _RewardIntent implements RewardIntent {
  const _RewardIntent({required this.intentId, required this.amount, required this.expiresAt});
  

/// The intent ID (also SSV `customData` and `userId`).
@override final  IntentId intentId;
/// Bonus readings granted on a verified view.
@override final  int amount;
/// When the intent lapses (UTC).
@override final  DateTime expiresAt;

/// Create a copy of RewardIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardIntentCopyWith<_RewardIntent> get copyWith => __$RewardIntentCopyWithImpl<_RewardIntent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardIntent&&(identical(other.intentId, intentId) || other.intentId == intentId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,intentId,amount,expiresAt);

@override
String toString() {
  return 'RewardIntent(intentId: $intentId, amount: $amount, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$RewardIntentCopyWith<$Res> implements $RewardIntentCopyWith<$Res> {
  factory _$RewardIntentCopyWith(_RewardIntent value, $Res Function(_RewardIntent) _then) = __$RewardIntentCopyWithImpl;
@override @useResult
$Res call({
 IntentId intentId, int amount, DateTime expiresAt
});




}
/// @nodoc
class __$RewardIntentCopyWithImpl<$Res>
    implements _$RewardIntentCopyWith<$Res> {
  __$RewardIntentCopyWithImpl(this._self, this._then);

  final _RewardIntent _self;
  final $Res Function(_RewardIntent) _then;

/// Create a copy of RewardIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intentId = null,Object? amount = null,Object? expiresAt = null,}) {
  return _then(_RewardIntent(
intentId: null == intentId ? _self.intentId : intentId // ignore: cast_nullable_to_non_nullable
as IntentId,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$RewardStatus {

/// The intent state.
 RewardIntentState get state;/// The intent amount.
 int get amount;/// The balance after a grant.
 CreditBalance? get balance;
/// Create a copy of RewardStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardStatusCopyWith<RewardStatus> get copyWith => _$RewardStatusCopyWithImpl<RewardStatus>(this as RewardStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardStatus&&(identical(other.state, state) || other.state == state)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,state,amount,balance);

@override
String toString() {
  return 'RewardStatus(state: $state, amount: $amount, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $RewardStatusCopyWith<$Res>  {
  factory $RewardStatusCopyWith(RewardStatus value, $Res Function(RewardStatus) _then) = _$RewardStatusCopyWithImpl;
@useResult
$Res call({
 RewardIntentState state, int amount, CreditBalance? balance
});


$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$RewardStatusCopyWithImpl<$Res>
    implements $RewardStatusCopyWith<$Res> {
  _$RewardStatusCopyWithImpl(this._self, this._then);

  final RewardStatus _self;
  final $Res Function(RewardStatus) _then;

/// Create a copy of RewardStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? amount = null,Object? balance = freezed,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RewardIntentState,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}
/// Create a copy of RewardStatus
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


/// Adds pattern-matching-related methods to [RewardStatus].
extension RewardStatusPatterns on RewardStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardStatus value)  $default,){
final _that = this;
switch (_that) {
case _RewardStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardStatus value)?  $default,){
final _that = this;
switch (_that) {
case _RewardStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RewardIntentState state,  int amount,  CreditBalance? balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardStatus() when $default != null:
return $default(_that.state,_that.amount,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RewardIntentState state,  int amount,  CreditBalance? balance)  $default,) {final _that = this;
switch (_that) {
case _RewardStatus():
return $default(_that.state,_that.amount,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RewardIntentState state,  int amount,  CreditBalance? balance)?  $default,) {final _that = this;
switch (_that) {
case _RewardStatus() when $default != null:
return $default(_that.state,_that.amount,_that.balance);case _:
  return null;

}
}

}

/// @nodoc


class _RewardStatus implements RewardStatus {
  const _RewardStatus({required this.state, required this.amount, this.balance});
  

/// The intent state.
@override final  RewardIntentState state;
/// The intent amount.
@override final  int amount;
/// The balance after a grant.
@override final  CreditBalance? balance;

/// Create a copy of RewardStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardStatusCopyWith<_RewardStatus> get copyWith => __$RewardStatusCopyWithImpl<_RewardStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardStatus&&(identical(other.state, state) || other.state == state)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,state,amount,balance);

@override
String toString() {
  return 'RewardStatus(state: $state, amount: $amount, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$RewardStatusCopyWith<$Res> implements $RewardStatusCopyWith<$Res> {
  factory _$RewardStatusCopyWith(_RewardStatus value, $Res Function(_RewardStatus) _then) = __$RewardStatusCopyWithImpl;
@override @useResult
$Res call({
 RewardIntentState state, int amount, CreditBalance? balance
});


@override $CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class __$RewardStatusCopyWithImpl<$Res>
    implements _$RewardStatusCopyWith<$Res> {
  __$RewardStatusCopyWithImpl(this._self, this._then);

  final _RewardStatus _self;
  final $Res Function(_RewardStatus) _then;

/// Create a copy of RewardStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? amount = null,Object? balance = freezed,}) {
  return _then(_RewardStatus(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RewardIntentState,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}

/// Create a copy of RewardStatus
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

// dart format on
