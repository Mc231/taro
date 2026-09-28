// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_outbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxEntry {

/// The store transaction.
 StorePurchase get purchase;/// The `Idempotency-Key`, reused on every retry.
 String get idempotencyKey;/// The row status.
 OutboxStatus get status;/// When the row was written (UTC).
 DateTime get createdAt;/// When it last changed (UTC).
 DateTime get updatedAt;/// Verification attempts so far.
 int get attempts;/// The last failure code, if any.
 String? get lastError;
/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxEntryCopyWith<OutboxEntry> get copyWith => _$OutboxEntryCopyWithImpl<OutboxEntry>(this as OutboxEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxEntry&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,purchase,idempotencyKey,status,createdAt,updatedAt,attempts,lastError);

@override
String toString() {
  return 'OutboxEntry(purchase: $purchase, idempotencyKey: $idempotencyKey, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, attempts: $attempts, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $OutboxEntryCopyWith<$Res>  {
  factory $OutboxEntryCopyWith(OutboxEntry value, $Res Function(OutboxEntry) _then) = _$OutboxEntryCopyWithImpl;
@useResult
$Res call({
 StorePurchase purchase, String idempotencyKey, OutboxStatus status, DateTime createdAt, DateTime updatedAt, int attempts, String? lastError
});


$StorePurchaseCopyWith<$Res> get purchase;

}
/// @nodoc
class _$OutboxEntryCopyWithImpl<$Res>
    implements $OutboxEntryCopyWith<$Res> {
  _$OutboxEntryCopyWithImpl(this._self, this._then);

  final OutboxEntry _self;
  final $Res Function(OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? purchase = null,Object? idempotencyKey = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? attempts = null,Object? lastError = freezed,}) {
  return _then(_self.copyWith(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as StorePurchase,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorePurchaseCopyWith<$Res> get purchase {
  
  return $StorePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}
}


/// Adds pattern-matching-related methods to [OutboxEntry].
extension OutboxEntryPatterns on OutboxEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxEntry value)  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StorePurchase purchase,  String idempotencyKey,  OutboxStatus status,  DateTime createdAt,  DateTime updatedAt,  int attempts,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.purchase,_that.idempotencyKey,_that.status,_that.createdAt,_that.updatedAt,_that.attempts,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StorePurchase purchase,  String idempotencyKey,  OutboxStatus status,  DateTime createdAt,  DateTime updatedAt,  int attempts,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry():
return $default(_that.purchase,_that.idempotencyKey,_that.status,_that.createdAt,_that.updatedAt,_that.attempts,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StorePurchase purchase,  String idempotencyKey,  OutboxStatus status,  DateTime createdAt,  DateTime updatedAt,  int attempts,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.purchase,_that.idempotencyKey,_that.status,_that.createdAt,_that.updatedAt,_that.attempts,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxEntry extends OutboxEntry {
  const _OutboxEntry({required this.purchase, required this.idempotencyKey, required this.status, required this.createdAt, required this.updatedAt, this.attempts = 0, this.lastError}): super._();
  

/// The store transaction.
@override final  StorePurchase purchase;
/// The `Idempotency-Key`, reused on every retry.
@override final  String idempotencyKey;
/// The row status.
@override final  OutboxStatus status;
/// When the row was written (UTC).
@override final  DateTime createdAt;
/// When it last changed (UTC).
@override final  DateTime updatedAt;
/// Verification attempts so far.
@override@JsonKey() final  int attempts;
/// The last failure code, if any.
@override final  String? lastError;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxEntryCopyWith<_OutboxEntry> get copyWith => __$OutboxEntryCopyWithImpl<_OutboxEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxEntry&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,purchase,idempotencyKey,status,createdAt,updatedAt,attempts,lastError);

@override
String toString() {
  return 'OutboxEntry(purchase: $purchase, idempotencyKey: $idempotencyKey, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, attempts: $attempts, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$OutboxEntryCopyWith<$Res> implements $OutboxEntryCopyWith<$Res> {
  factory _$OutboxEntryCopyWith(_OutboxEntry value, $Res Function(_OutboxEntry) _then) = __$OutboxEntryCopyWithImpl;
@override @useResult
$Res call({
 StorePurchase purchase, String idempotencyKey, OutboxStatus status, DateTime createdAt, DateTime updatedAt, int attempts, String? lastError
});


@override $StorePurchaseCopyWith<$Res> get purchase;

}
/// @nodoc
class __$OutboxEntryCopyWithImpl<$Res>
    implements _$OutboxEntryCopyWith<$Res> {
  __$OutboxEntryCopyWithImpl(this._self, this._then);

  final _OutboxEntry _self;
  final $Res Function(_OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? purchase = null,Object? idempotencyKey = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? attempts = null,Object? lastError = freezed,}) {
  return _then(_OutboxEntry(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as StorePurchase,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboxStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorePurchaseCopyWith<$Res> get purchase {
  
  return $StorePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}
}

// dart format on
