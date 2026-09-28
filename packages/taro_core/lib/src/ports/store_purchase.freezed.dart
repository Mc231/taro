// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StorePurchase {

/// The outbox primary key: `transactionId ?? sha256(purchaseToken)`.
 String get txnKey;/// The fully qualified product ID.
 ProductId get productId;/// Which store delivered it.
 StorePlatform get platform;/// StoreKit transaction ID (iOS).
 String? get transactionId;/// StoreKit JWS `signedTransaction` (iOS, optional on the wire).
 String? get signedTransaction;/// Play purchase token (Android). Never logged.
 String? get purchaseToken;/// Play order ID (Android).
 String? get orderId;/// Whether the store redelivered it from a restore.
 bool get isRestored;
/// Create a copy of StorePurchase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePurchaseCopyWith<StorePurchase> get copyWith => _$StorePurchaseCopyWithImpl<StorePurchase>(this as StorePurchase, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePurchase&&(identical(other.txnKey, txnKey) || other.txnKey == txnKey)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.signedTransaction, signedTransaction) || other.signedTransaction == signedTransaction)&&(identical(other.purchaseToken, purchaseToken) || other.purchaseToken == purchaseToken)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.isRestored, isRestored) || other.isRestored == isRestored));
}


@override
int get hashCode => Object.hash(runtimeType,txnKey,productId,platform,transactionId,signedTransaction,purchaseToken,orderId,isRestored);

@override
String toString() {
  return 'StorePurchase(txnKey: $txnKey, productId: $productId, platform: $platform, transactionId: $transactionId, signedTransaction: $signedTransaction, purchaseToken: $purchaseToken, orderId: $orderId, isRestored: $isRestored)';
}


}

/// @nodoc
abstract mixin class $StorePurchaseCopyWith<$Res>  {
  factory $StorePurchaseCopyWith(StorePurchase value, $Res Function(StorePurchase) _then) = _$StorePurchaseCopyWithImpl;
@useResult
$Res call({
 String txnKey, ProductId productId, StorePlatform platform, String? transactionId, String? signedTransaction, String? purchaseToken, String? orderId, bool isRestored
});




}
/// @nodoc
class _$StorePurchaseCopyWithImpl<$Res>
    implements $StorePurchaseCopyWith<$Res> {
  _$StorePurchaseCopyWithImpl(this._self, this._then);

  final StorePurchase _self;
  final $Res Function(StorePurchase) _then;

/// Create a copy of StorePurchase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? txnKey = null,Object? productId = null,Object? platform = null,Object? transactionId = freezed,Object? signedTransaction = freezed,Object? purchaseToken = freezed,Object? orderId = freezed,Object? isRestored = null,}) {
  return _then(_self.copyWith(
txnKey: null == txnKey ? _self.txnKey : txnKey // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as StorePlatform,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,signedTransaction: freezed == signedTransaction ? _self.signedTransaction : signedTransaction // ignore: cast_nullable_to_non_nullable
as String?,purchaseToken: freezed == purchaseToken ? _self.purchaseToken : purchaseToken // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,isRestored: null == isRestored ? _self.isRestored : isRestored // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StorePurchase].
extension StorePurchasePatterns on StorePurchase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorePurchase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorePurchase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorePurchase value)  $default,){
final _that = this;
switch (_that) {
case _StorePurchase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorePurchase value)?  $default,){
final _that = this;
switch (_that) {
case _StorePurchase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String txnKey,  ProductId productId,  StorePlatform platform,  String? transactionId,  String? signedTransaction,  String? purchaseToken,  String? orderId,  bool isRestored)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorePurchase() when $default != null:
return $default(_that.txnKey,_that.productId,_that.platform,_that.transactionId,_that.signedTransaction,_that.purchaseToken,_that.orderId,_that.isRestored);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String txnKey,  ProductId productId,  StorePlatform platform,  String? transactionId,  String? signedTransaction,  String? purchaseToken,  String? orderId,  bool isRestored)  $default,) {final _that = this;
switch (_that) {
case _StorePurchase():
return $default(_that.txnKey,_that.productId,_that.platform,_that.transactionId,_that.signedTransaction,_that.purchaseToken,_that.orderId,_that.isRestored);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String txnKey,  ProductId productId,  StorePlatform platform,  String? transactionId,  String? signedTransaction,  String? purchaseToken,  String? orderId,  bool isRestored)?  $default,) {final _that = this;
switch (_that) {
case _StorePurchase() when $default != null:
return $default(_that.txnKey,_that.productId,_that.platform,_that.transactionId,_that.signedTransaction,_that.purchaseToken,_that.orderId,_that.isRestored);case _:
  return null;

}
}

}

/// @nodoc


class _StorePurchase implements StorePurchase {
  const _StorePurchase({required this.txnKey, required this.productId, required this.platform, this.transactionId, this.signedTransaction, this.purchaseToken, this.orderId, this.isRestored = false});
  

/// The outbox primary key: `transactionId ?? sha256(purchaseToken)`.
@override final  String txnKey;
/// The fully qualified product ID.
@override final  ProductId productId;
/// Which store delivered it.
@override final  StorePlatform platform;
/// StoreKit transaction ID (iOS).
@override final  String? transactionId;
/// StoreKit JWS `signedTransaction` (iOS, optional on the wire).
@override final  String? signedTransaction;
/// Play purchase token (Android). Never logged.
@override final  String? purchaseToken;
/// Play order ID (Android).
@override final  String? orderId;
/// Whether the store redelivered it from a restore.
@override@JsonKey() final  bool isRestored;

/// Create a copy of StorePurchase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorePurchaseCopyWith<_StorePurchase> get copyWith => __$StorePurchaseCopyWithImpl<_StorePurchase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorePurchase&&(identical(other.txnKey, txnKey) || other.txnKey == txnKey)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.signedTransaction, signedTransaction) || other.signedTransaction == signedTransaction)&&(identical(other.purchaseToken, purchaseToken) || other.purchaseToken == purchaseToken)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.isRestored, isRestored) || other.isRestored == isRestored));
}


@override
int get hashCode => Object.hash(runtimeType,txnKey,productId,platform,transactionId,signedTransaction,purchaseToken,orderId,isRestored);

@override
String toString() {
  return 'StorePurchase(txnKey: $txnKey, productId: $productId, platform: $platform, transactionId: $transactionId, signedTransaction: $signedTransaction, purchaseToken: $purchaseToken, orderId: $orderId, isRestored: $isRestored)';
}


}

/// @nodoc
abstract mixin class _$StorePurchaseCopyWith<$Res> implements $StorePurchaseCopyWith<$Res> {
  factory _$StorePurchaseCopyWith(_StorePurchase value, $Res Function(_StorePurchase) _then) = __$StorePurchaseCopyWithImpl;
@override @useResult
$Res call({
 String txnKey, ProductId productId, StorePlatform platform, String? transactionId, String? signedTransaction, String? purchaseToken, String? orderId, bool isRestored
});




}
/// @nodoc
class __$StorePurchaseCopyWithImpl<$Res>
    implements _$StorePurchaseCopyWith<$Res> {
  __$StorePurchaseCopyWithImpl(this._self, this._then);

  final _StorePurchase _self;
  final $Res Function(_StorePurchase) _then;

/// Create a copy of StorePurchase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? txnKey = null,Object? productId = null,Object? platform = null,Object? transactionId = freezed,Object? signedTransaction = freezed,Object? purchaseToken = freezed,Object? orderId = freezed,Object? isRestored = null,}) {
  return _then(_StorePurchase(
txnKey: null == txnKey ? _self.txnKey : txnKey // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as StorePlatform,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,signedTransaction: freezed == signedTransaction ? _self.signedTransaction : signedTransaction // ignore: cast_nullable_to_non_nullable
as String?,purchaseToken: freezed == purchaseToken ? _self.purchaseToken : purchaseToken // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,isRestored: null == isRestored ? _self.isRestored : isRestored // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
