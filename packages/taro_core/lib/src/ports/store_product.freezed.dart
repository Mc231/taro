// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoreProduct {

/// The fully qualified product ID.
 ProductId get id;/// The store's localized title.
 String get title;/// The store's localized price string, for example `€3.99`.
 String get price;/// The numeric price in [currencyCode].
 double get rawPrice;/// ISO 4217 currency code.
 String get currencyCode;
/// Create a copy of StoreProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreProductCopyWith<StoreProduct> get copyWith => _$StoreProductCopyWithImpl<StoreProduct>(this as StoreProduct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.rawPrice, rawPrice) || other.rawPrice == rawPrice)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,price,rawPrice,currencyCode);

@override
String toString() {
  return 'StoreProduct(id: $id, title: $title, price: $price, rawPrice: $rawPrice, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $StoreProductCopyWith<$Res>  {
  factory $StoreProductCopyWith(StoreProduct value, $Res Function(StoreProduct) _then) = _$StoreProductCopyWithImpl;
@useResult
$Res call({
 ProductId id, String title, String price, double rawPrice, String currencyCode
});




}
/// @nodoc
class _$StoreProductCopyWithImpl<$Res>
    implements $StoreProductCopyWith<$Res> {
  _$StoreProductCopyWithImpl(this._self, this._then);

  final StoreProduct _self;
  final $Res Function(StoreProduct) _then;

/// Create a copy of StoreProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? price = null,Object? rawPrice = null,Object? currencyCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ProductId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,rawPrice: null == rawPrice ? _self.rawPrice : rawPrice // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreProduct].
extension StoreProductPatterns on StoreProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreProduct value)  $default,){
final _that = this;
switch (_that) {
case _StoreProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreProduct value)?  $default,){
final _that = this;
switch (_that) {
case _StoreProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductId id,  String title,  String price,  double rawPrice,  String currencyCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.rawPrice,_that.currencyCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductId id,  String title,  String price,  double rawPrice,  String currencyCode)  $default,) {final _that = this;
switch (_that) {
case _StoreProduct():
return $default(_that.id,_that.title,_that.price,_that.rawPrice,_that.currencyCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductId id,  String title,  String price,  double rawPrice,  String currencyCode)?  $default,) {final _that = this;
switch (_that) {
case _StoreProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.rawPrice,_that.currencyCode);case _:
  return null;

}
}

}

/// @nodoc


class _StoreProduct implements StoreProduct {
  const _StoreProduct({required this.id, required this.title, required this.price, required this.rawPrice, required this.currencyCode});
  

/// The fully qualified product ID.
@override final  ProductId id;
/// The store's localized title.
@override final  String title;
/// The store's localized price string, for example `€3.99`.
@override final  String price;
/// The numeric price in [currencyCode].
@override final  double rawPrice;
/// ISO 4217 currency code.
@override final  String currencyCode;

/// Create a copy of StoreProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreProductCopyWith<_StoreProduct> get copyWith => __$StoreProductCopyWithImpl<_StoreProduct>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.rawPrice, rawPrice) || other.rawPrice == rawPrice)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,price,rawPrice,currencyCode);

@override
String toString() {
  return 'StoreProduct(id: $id, title: $title, price: $price, rawPrice: $rawPrice, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class _$StoreProductCopyWith<$Res> implements $StoreProductCopyWith<$Res> {
  factory _$StoreProductCopyWith(_StoreProduct value, $Res Function(_StoreProduct) _then) = __$StoreProductCopyWithImpl;
@override @useResult
$Res call({
 ProductId id, String title, String price, double rawPrice, String currencyCode
});




}
/// @nodoc
class __$StoreProductCopyWithImpl<$Res>
    implements _$StoreProductCopyWith<$Res> {
  __$StoreProductCopyWithImpl(this._self, this._then);

  final _StoreProduct _self;
  final $Res Function(_StoreProduct) _then;

/// Create a copy of StoreProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? price = null,Object? rawPrice = null,Object? currencyCode = null,}) {
  return _then(_StoreProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ProductId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,rawPrice: null == rawPrice ? _self.rawPrice : rawPrice // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
