// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductOffer {

/// The store product ID.
 ProductId get productId;/// Localized store price, e.g. "€4.99" (`ProductDetails.price`).
 String get price;/// Numeric store price in major units (`ProductDetails.rawPrice`).
 double get rawPrice;/// ISO 4217 code (`ProductDetails.currencyCode`).
 String get currencyCode;/// Readings in the pack (Worker-injected `store.packs[].credits`).
 int get credits;/// Display order (`store.packs[].sortOrder`).
 int get sortOrder;
/// Create a copy of ProductOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductOfferCopyWith<ProductOffer> get copyWith => _$ProductOfferCopyWithImpl<ProductOffer>(this as ProductOffer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductOffer&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.price, price) || other.price == price)&&(identical(other.rawPrice, rawPrice) || other.rawPrice == rawPrice)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,productId,price,rawPrice,currencyCode,credits,sortOrder);

@override
String toString() {
  return 'ProductOffer(productId: $productId, price: $price, rawPrice: $rawPrice, currencyCode: $currencyCode, credits: $credits, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProductOfferCopyWith<$Res>  {
  factory $ProductOfferCopyWith(ProductOffer value, $Res Function(ProductOffer) _then) = _$ProductOfferCopyWithImpl;
@useResult
$Res call({
 ProductId productId, String price, double rawPrice, String currencyCode, int credits, int sortOrder
});




}
/// @nodoc
class _$ProductOfferCopyWithImpl<$Res>
    implements $ProductOfferCopyWith<$Res> {
  _$ProductOfferCopyWithImpl(this._self, this._then);

  final ProductOffer _self;
  final $Res Function(ProductOffer) _then;

/// Create a copy of ProductOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? price = null,Object? rawPrice = null,Object? currencyCode = null,Object? credits = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,rawPrice: null == rawPrice ? _self.rawPrice : rawPrice // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductOffer].
extension ProductOfferPatterns on ProductOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductOffer value)  $default,){
final _that = this;
switch (_that) {
case _ProductOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductOffer value)?  $default,){
final _that = this;
switch (_that) {
case _ProductOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductId productId,  String price,  double rawPrice,  String currencyCode,  int credits,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductOffer() when $default != null:
return $default(_that.productId,_that.price,_that.rawPrice,_that.currencyCode,_that.credits,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductId productId,  String price,  double rawPrice,  String currencyCode,  int credits,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProductOffer():
return $default(_that.productId,_that.price,_that.rawPrice,_that.currencyCode,_that.credits,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductId productId,  String price,  double rawPrice,  String currencyCode,  int credits,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProductOffer() when $default != null:
return $default(_that.productId,_that.price,_that.rawPrice,_that.currencyCode,_that.credits,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _ProductOffer extends ProductOffer {
  const _ProductOffer({required this.productId, required this.price, required this.rawPrice, required this.currencyCode, required this.credits, this.sortOrder = 0}): super._();
  

/// The store product ID.
@override final  ProductId productId;
/// Localized store price, e.g. "€4.99" (`ProductDetails.price`).
@override final  String price;
/// Numeric store price in major units (`ProductDetails.rawPrice`).
@override final  double rawPrice;
/// ISO 4217 code (`ProductDetails.currencyCode`).
@override final  String currencyCode;
/// Readings in the pack (Worker-injected `store.packs[].credits`).
@override final  int credits;
/// Display order (`store.packs[].sortOrder`).
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProductOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductOfferCopyWith<_ProductOffer> get copyWith => __$ProductOfferCopyWithImpl<_ProductOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductOffer&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.price, price) || other.price == price)&&(identical(other.rawPrice, rawPrice) || other.rawPrice == rawPrice)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,productId,price,rawPrice,currencyCode,credits,sortOrder);

@override
String toString() {
  return 'ProductOffer(productId: $productId, price: $price, rawPrice: $rawPrice, currencyCode: $currencyCode, credits: $credits, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProductOfferCopyWith<$Res> implements $ProductOfferCopyWith<$Res> {
  factory _$ProductOfferCopyWith(_ProductOffer value, $Res Function(_ProductOffer) _then) = __$ProductOfferCopyWithImpl;
@override @useResult
$Res call({
 ProductId productId, String price, double rawPrice, String currencyCode, int credits, int sortOrder
});




}
/// @nodoc
class __$ProductOfferCopyWithImpl<$Res>
    implements _$ProductOfferCopyWith<$Res> {
  __$ProductOfferCopyWithImpl(this._self, this._then);

  final _ProductOffer _self;
  final $Res Function(_ProductOffer) _then;

/// Create a copy of ProductOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? price = null,Object? rawPrice = null,Object? currencyCode = null,Object? credits = null,Object? sortOrder = null,}) {
  return _then(_ProductOffer(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,rawPrice: null == rawPrice ? _self.rawPrice : rawPrice // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
