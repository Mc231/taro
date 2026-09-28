// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingHold {

/// The `clientReadingId` (= `Idempotency-Key`, RC42).
 ReadingId get readingId;/// Which allowance the Worker reserved.
 ChargeSource get chargeSource;/// When the hold lapses (server time, UTC).
 DateTime get expiresAt;/// The balance returned with the hold.
 CreditBalance get balance;
/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingHoldCopyWith<ReadingHold> get copyWith => _$ReadingHoldCopyWithImpl<ReadingHold>(this as ReadingHold, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHold&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.chargeSource, chargeSource) || other.chargeSource == chargeSource)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,readingId,chargeSource,expiresAt,balance);

@override
String toString() {
  return 'ReadingHold(readingId: $readingId, chargeSource: $chargeSource, expiresAt: $expiresAt, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $ReadingHoldCopyWith<$Res>  {
  factory $ReadingHoldCopyWith(ReadingHold value, $Res Function(ReadingHold) _then) = _$ReadingHoldCopyWithImpl;
@useResult
$Res call({
 ReadingId readingId, ChargeSource chargeSource, DateTime expiresAt, CreditBalance balance
});


$CreditBalanceCopyWith<$Res> get balance;

}
/// @nodoc
class _$ReadingHoldCopyWithImpl<$Res>
    implements $ReadingHoldCopyWith<$Res> {
  _$ReadingHoldCopyWithImpl(this._self, this._then);

  final ReadingHold _self;
  final $Res Function(ReadingHold) _then;

/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readingId = null,Object? chargeSource = null,Object? expiresAt = null,Object? balance = null,}) {
  return _then(_self.copyWith(
readingId: null == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId,chargeSource: null == chargeSource ? _self.chargeSource : chargeSource // ignore: cast_nullable_to_non_nullable
as ChargeSource,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance,
  ));
}
/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res> get balance {
  
  return $CreditBalanceCopyWith<$Res>(_self.balance, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingHold].
extension ReadingHoldPatterns on ReadingHold {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingHold value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingHold() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingHold value)  $default,){
final _that = this;
switch (_that) {
case _ReadingHold():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingHold value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingHold() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReadingId readingId,  ChargeSource chargeSource,  DateTime expiresAt,  CreditBalance balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingHold() when $default != null:
return $default(_that.readingId,_that.chargeSource,_that.expiresAt,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReadingId readingId,  ChargeSource chargeSource,  DateTime expiresAt,  CreditBalance balance)  $default,) {final _that = this;
switch (_that) {
case _ReadingHold():
return $default(_that.readingId,_that.chargeSource,_that.expiresAt,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReadingId readingId,  ChargeSource chargeSource,  DateTime expiresAt,  CreditBalance balance)?  $default,) {final _that = this;
switch (_that) {
case _ReadingHold() when $default != null:
return $default(_that.readingId,_that.chargeSource,_that.expiresAt,_that.balance);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingHold extends ReadingHold {
  const _ReadingHold({required this.readingId, required this.chargeSource, required this.expiresAt, required this.balance}): super._();
  

/// The `clientReadingId` (= `Idempotency-Key`, RC42).
@override final  ReadingId readingId;
/// Which allowance the Worker reserved.
@override final  ChargeSource chargeSource;
/// When the hold lapses (server time, UTC).
@override final  DateTime expiresAt;
/// The balance returned with the hold.
@override final  CreditBalance balance;

/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingHoldCopyWith<_ReadingHold> get copyWith => __$ReadingHoldCopyWithImpl<_ReadingHold>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingHold&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.chargeSource, chargeSource) || other.chargeSource == chargeSource)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,readingId,chargeSource,expiresAt,balance);

@override
String toString() {
  return 'ReadingHold(readingId: $readingId, chargeSource: $chargeSource, expiresAt: $expiresAt, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$ReadingHoldCopyWith<$Res> implements $ReadingHoldCopyWith<$Res> {
  factory _$ReadingHoldCopyWith(_ReadingHold value, $Res Function(_ReadingHold) _then) = __$ReadingHoldCopyWithImpl;
@override @useResult
$Res call({
 ReadingId readingId, ChargeSource chargeSource, DateTime expiresAt, CreditBalance balance
});


@override $CreditBalanceCopyWith<$Res> get balance;

}
/// @nodoc
class __$ReadingHoldCopyWithImpl<$Res>
    implements _$ReadingHoldCopyWith<$Res> {
  __$ReadingHoldCopyWithImpl(this._self, this._then);

  final _ReadingHold _self;
  final $Res Function(_ReadingHold) _then;

/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readingId = null,Object? chargeSource = null,Object? expiresAt = null,Object? balance = null,}) {
  return _then(_ReadingHold(
readingId: null == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId,chargeSource: null == chargeSource ? _self.chargeSource : chargeSource // ignore: cast_nullable_to_non_nullable
as ChargeSource,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance,
  ));
}

/// Create a copy of ReadingHold
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res> get balance {
  
  return $CreditBalanceCopyWith<$Res>(_self.balance, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}

// dart format on
