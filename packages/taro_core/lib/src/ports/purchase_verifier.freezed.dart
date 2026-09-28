// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_verifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrantResult {

/// The response status.
 GrantStatus get status;/// `creditsGranted` (0 when pending).
 int get creditsGranted;/// `isFirstPurchase`.
 bool get isFirstPurchase;/// The Worker purchase ID.
 String? get purchaseId;/// The product the store says was bought.
 ProductId? get productId;/// The balance after the grant (absent when pending).
 CreditBalance? get balance;
/// Create a copy of GrantResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrantResultCopyWith<GrantResult> get copyWith => _$GrantResultCopyWithImpl<GrantResult>(this as GrantResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrantResult&&(identical(other.status, status) || other.status == status)&&(identical(other.creditsGranted, creditsGranted) || other.creditsGranted == creditsGranted)&&(identical(other.isFirstPurchase, isFirstPurchase) || other.isFirstPurchase == isFirstPurchase)&&(identical(other.purchaseId, purchaseId) || other.purchaseId == purchaseId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,status,creditsGranted,isFirstPurchase,purchaseId,productId,balance);

@override
String toString() {
  return 'GrantResult(status: $status, creditsGranted: $creditsGranted, isFirstPurchase: $isFirstPurchase, purchaseId: $purchaseId, productId: $productId, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $GrantResultCopyWith<$Res>  {
  factory $GrantResultCopyWith(GrantResult value, $Res Function(GrantResult) _then) = _$GrantResultCopyWithImpl;
@useResult
$Res call({
 GrantStatus status, int creditsGranted, bool isFirstPurchase, String? purchaseId, ProductId? productId, CreditBalance? balance
});


$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$GrantResultCopyWithImpl<$Res>
    implements $GrantResultCopyWith<$Res> {
  _$GrantResultCopyWithImpl(this._self, this._then);

  final GrantResult _self;
  final $Res Function(GrantResult) _then;

/// Create a copy of GrantResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? creditsGranted = null,Object? isFirstPurchase = null,Object? purchaseId = freezed,Object? productId = freezed,Object? balance = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrantStatus,creditsGranted: null == creditsGranted ? _self.creditsGranted : creditsGranted // ignore: cast_nullable_to_non_nullable
as int,isFirstPurchase: null == isFirstPurchase ? _self.isFirstPurchase : isFirstPurchase // ignore: cast_nullable_to_non_nullable
as bool,purchaseId: freezed == purchaseId ? _self.purchaseId : purchaseId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}
/// Create a copy of GrantResult
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


/// Adds pattern-matching-related methods to [GrantResult].
extension GrantResultPatterns on GrantResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrantResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrantResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrantResult value)  $default,){
final _that = this;
switch (_that) {
case _GrantResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrantResult value)?  $default,){
final _that = this;
switch (_that) {
case _GrantResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrantStatus status,  int creditsGranted,  bool isFirstPurchase,  String? purchaseId,  ProductId? productId,  CreditBalance? balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrantResult() when $default != null:
return $default(_that.status,_that.creditsGranted,_that.isFirstPurchase,_that.purchaseId,_that.productId,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrantStatus status,  int creditsGranted,  bool isFirstPurchase,  String? purchaseId,  ProductId? productId,  CreditBalance? balance)  $default,) {final _that = this;
switch (_that) {
case _GrantResult():
return $default(_that.status,_that.creditsGranted,_that.isFirstPurchase,_that.purchaseId,_that.productId,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrantStatus status,  int creditsGranted,  bool isFirstPurchase,  String? purchaseId,  ProductId? productId,  CreditBalance? balance)?  $default,) {final _that = this;
switch (_that) {
case _GrantResult() when $default != null:
return $default(_that.status,_that.creditsGranted,_that.isFirstPurchase,_that.purchaseId,_that.productId,_that.balance);case _:
  return null;

}
}

}

/// @nodoc


class _GrantResult implements GrantResult {
  const _GrantResult({required this.status, this.creditsGranted = 0, this.isFirstPurchase = false, this.purchaseId, this.productId, this.balance});
  

/// The response status.
@override final  GrantStatus status;
/// `creditsGranted` (0 when pending).
@override@JsonKey() final  int creditsGranted;
/// `isFirstPurchase`.
@override@JsonKey() final  bool isFirstPurchase;
/// The Worker purchase ID.
@override final  String? purchaseId;
/// The product the store says was bought.
@override final  ProductId? productId;
/// The balance after the grant (absent when pending).
@override final  CreditBalance? balance;

/// Create a copy of GrantResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrantResultCopyWith<_GrantResult> get copyWith => __$GrantResultCopyWithImpl<_GrantResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrantResult&&(identical(other.status, status) || other.status == status)&&(identical(other.creditsGranted, creditsGranted) || other.creditsGranted == creditsGranted)&&(identical(other.isFirstPurchase, isFirstPurchase) || other.isFirstPurchase == isFirstPurchase)&&(identical(other.purchaseId, purchaseId) || other.purchaseId == purchaseId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,status,creditsGranted,isFirstPurchase,purchaseId,productId,balance);

@override
String toString() {
  return 'GrantResult(status: $status, creditsGranted: $creditsGranted, isFirstPurchase: $isFirstPurchase, purchaseId: $purchaseId, productId: $productId, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$GrantResultCopyWith<$Res> implements $GrantResultCopyWith<$Res> {
  factory _$GrantResultCopyWith(_GrantResult value, $Res Function(_GrantResult) _then) = __$GrantResultCopyWithImpl;
@override @useResult
$Res call({
 GrantStatus status, int creditsGranted, bool isFirstPurchase, String? purchaseId, ProductId? productId, CreditBalance? balance
});


@override $CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class __$GrantResultCopyWithImpl<$Res>
    implements _$GrantResultCopyWith<$Res> {
  __$GrantResultCopyWithImpl(this._self, this._then);

  final _GrantResult _self;
  final $Res Function(_GrantResult) _then;

/// Create a copy of GrantResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? creditsGranted = null,Object? isFirstPurchase = null,Object? purchaseId = freezed,Object? productId = freezed,Object? balance = freezed,}) {
  return _then(_GrantResult(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrantStatus,creditsGranted: null == creditsGranted ? _self.creditsGranted : creditsGranted // ignore: cast_nullable_to_non_nullable
as int,isFirstPurchase: null == isFirstPurchase ? _self.isFirstPurchase : isFirstPurchase // ignore: cast_nullable_to_non_nullable
as bool,purchaseId: freezed == purchaseId ? _self.purchaseId : purchaseId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}

/// Create a copy of GrantResult
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
