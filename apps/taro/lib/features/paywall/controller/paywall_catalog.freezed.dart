// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paywall_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaywallCatalog {

/// The reading packs in `store.packs` order, with store prices.
 List<ProductOffer> get packs;/// Remove Banner Ads, when listed and `store.removeAdsEnabled`.
 ProductOffer? get removeAds;/// The pack with the lowest per-reading price, when
/// `store.showBestValueBadge` and it is strictly the lowest (04 §11).
 ProductId? get bestValue;
/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallCatalogCopyWith<PaywallCatalog> get copyWith => _$PaywallCatalogCopyWithImpl<PaywallCatalog>(this as PaywallCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallCatalog&&const DeepCollectionEquality().equals(other.packs, packs)&&(identical(other.removeAds, removeAds) || other.removeAds == removeAds)&&(identical(other.bestValue, bestValue) || other.bestValue == bestValue));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(packs),removeAds,bestValue);

@override
String toString() {
  return 'PaywallCatalog(packs: $packs, removeAds: $removeAds, bestValue: $bestValue)';
}


}

/// @nodoc
abstract mixin class $PaywallCatalogCopyWith<$Res>  {
  factory $PaywallCatalogCopyWith(PaywallCatalog value, $Res Function(PaywallCatalog) _then) = _$PaywallCatalogCopyWithImpl;
@useResult
$Res call({
 List<ProductOffer> packs, ProductOffer? removeAds, ProductId? bestValue
});


$ProductOfferCopyWith<$Res>? get removeAds;

}
/// @nodoc
class _$PaywallCatalogCopyWithImpl<$Res>
    implements $PaywallCatalogCopyWith<$Res> {
  _$PaywallCatalogCopyWithImpl(this._self, this._then);

  final PaywallCatalog _self;
  final $Res Function(PaywallCatalog) _then;

/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packs = null,Object? removeAds = freezed,Object? bestValue = freezed,}) {
  return _then(_self.copyWith(
packs: null == packs ? _self.packs : packs // ignore: cast_nullable_to_non_nullable
as List<ProductOffer>,removeAds: freezed == removeAds ? _self.removeAds : removeAds // ignore: cast_nullable_to_non_nullable
as ProductOffer?,bestValue: freezed == bestValue ? _self.bestValue : bestValue // ignore: cast_nullable_to_non_nullable
as ProductId?,
  ));
}
/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductOfferCopyWith<$Res>? get removeAds {
    if (_self.removeAds == null) {
    return null;
  }

  return $ProductOfferCopyWith<$Res>(_self.removeAds!, (value) {
    return _then(_self.copyWith(removeAds: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaywallCatalog].
extension PaywallCatalogPatterns on PaywallCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaywallCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaywallCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaywallCatalog value)  $default,){
final _that = this;
switch (_that) {
case _PaywallCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaywallCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _PaywallCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProductOffer> packs,  ProductOffer? removeAds,  ProductId? bestValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaywallCatalog() when $default != null:
return $default(_that.packs,_that.removeAds,_that.bestValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProductOffer> packs,  ProductOffer? removeAds,  ProductId? bestValue)  $default,) {final _that = this;
switch (_that) {
case _PaywallCatalog():
return $default(_that.packs,_that.removeAds,_that.bestValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProductOffer> packs,  ProductOffer? removeAds,  ProductId? bestValue)?  $default,) {final _that = this;
switch (_that) {
case _PaywallCatalog() when $default != null:
return $default(_that.packs,_that.removeAds,_that.bestValue);case _:
  return null;

}
}

}

/// @nodoc


class _PaywallCatalog implements PaywallCatalog {
  const _PaywallCatalog({required final  List<ProductOffer> packs, this.removeAds, this.bestValue}): _packs = packs;
  

/// The reading packs in `store.packs` order, with store prices.
 final  List<ProductOffer> _packs;
/// The reading packs in `store.packs` order, with store prices.
@override List<ProductOffer> get packs {
  if (_packs is EqualUnmodifiableListView) return _packs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_packs);
}

/// Remove Banner Ads, when listed and `store.removeAdsEnabled`.
@override final  ProductOffer? removeAds;
/// The pack with the lowest per-reading price, when
/// `store.showBestValueBadge` and it is strictly the lowest (04 §11).
@override final  ProductId? bestValue;

/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaywallCatalogCopyWith<_PaywallCatalog> get copyWith => __$PaywallCatalogCopyWithImpl<_PaywallCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaywallCatalog&&const DeepCollectionEquality().equals(other._packs, _packs)&&(identical(other.removeAds, removeAds) || other.removeAds == removeAds)&&(identical(other.bestValue, bestValue) || other.bestValue == bestValue));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_packs),removeAds,bestValue);

@override
String toString() {
  return 'PaywallCatalog(packs: $packs, removeAds: $removeAds, bestValue: $bestValue)';
}


}

/// @nodoc
abstract mixin class _$PaywallCatalogCopyWith<$Res> implements $PaywallCatalogCopyWith<$Res> {
  factory _$PaywallCatalogCopyWith(_PaywallCatalog value, $Res Function(_PaywallCatalog) _then) = __$PaywallCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<ProductOffer> packs, ProductOffer? removeAds, ProductId? bestValue
});


@override $ProductOfferCopyWith<$Res>? get removeAds;

}
/// @nodoc
class __$PaywallCatalogCopyWithImpl<$Res>
    implements _$PaywallCatalogCopyWith<$Res> {
  __$PaywallCatalogCopyWithImpl(this._self, this._then);

  final _PaywallCatalog _self;
  final $Res Function(_PaywallCatalog) _then;

/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packs = null,Object? removeAds = freezed,Object? bestValue = freezed,}) {
  return _then(_PaywallCatalog(
packs: null == packs ? _self._packs : packs // ignore: cast_nullable_to_non_nullable
as List<ProductOffer>,removeAds: freezed == removeAds ? _self.removeAds : removeAds // ignore: cast_nullable_to_non_nullable
as ProductOffer?,bestValue: freezed == bestValue ? _self.bestValue : bestValue // ignore: cast_nullable_to_non_nullable
as ProductId?,
  ));
}

/// Create a copy of PaywallCatalog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductOfferCopyWith<$Res>? get removeAds {
    if (_self.removeAds == null) {
    return null;
  }

  return $ProductOfferCopyWith<$Res>(_self.removeAds!, (value) {
    return _then(_self.copyWith(removeAds: value));
  });
}
}

/// @nodoc
mixin _$PaywallPacks {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallPacks);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaywallPacks()';
}


}

/// @nodoc
class $PaywallPacksCopyWith<$Res>  {
$PaywallPacksCopyWith(PaywallPacks _, $Res Function(PaywallPacks) __);
}


/// Adds pattern-matching-related methods to [PaywallPacks].
extension PaywallPacksPatterns on PaywallPacks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PaywallPacksLoading value)?  loading,TResult Function( PaywallPacksLoaded value)?  loaded,TResult Function( PaywallPacksUnavailable value)?  unavailable,TResult Function( PaywallPacksBlocked value)?  purchasesBlocked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PaywallPacksLoading() when loading != null:
return loading(_that);case PaywallPacksLoaded() when loaded != null:
return loaded(_that);case PaywallPacksUnavailable() when unavailable != null:
return unavailable(_that);case PaywallPacksBlocked() when purchasesBlocked != null:
return purchasesBlocked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PaywallPacksLoading value)  loading,required TResult Function( PaywallPacksLoaded value)  loaded,required TResult Function( PaywallPacksUnavailable value)  unavailable,required TResult Function( PaywallPacksBlocked value)  purchasesBlocked,}){
final _that = this;
switch (_that) {
case PaywallPacksLoading():
return loading(_that);case PaywallPacksLoaded():
return loaded(_that);case PaywallPacksUnavailable():
return unavailable(_that);case PaywallPacksBlocked():
return purchasesBlocked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PaywallPacksLoading value)?  loading,TResult? Function( PaywallPacksLoaded value)?  loaded,TResult? Function( PaywallPacksUnavailable value)?  unavailable,TResult? Function( PaywallPacksBlocked value)?  purchasesBlocked,}){
final _that = this;
switch (_that) {
case PaywallPacksLoading() when loading != null:
return loading(_that);case PaywallPacksLoaded() when loaded != null:
return loaded(_that);case PaywallPacksUnavailable() when unavailable != null:
return unavailable(_that);case PaywallPacksBlocked() when purchasesBlocked != null:
return purchasesBlocked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( PaywallCatalog catalog)?  loaded,TResult Function()?  unavailable,TResult Function( PurchasesBlockedReason reason)?  purchasesBlocked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PaywallPacksLoading() when loading != null:
return loading();case PaywallPacksLoaded() when loaded != null:
return loaded(_that.catalog);case PaywallPacksUnavailable() when unavailable != null:
return unavailable();case PaywallPacksBlocked() when purchasesBlocked != null:
return purchasesBlocked(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( PaywallCatalog catalog)  loaded,required TResult Function()  unavailable,required TResult Function( PurchasesBlockedReason reason)  purchasesBlocked,}) {final _that = this;
switch (_that) {
case PaywallPacksLoading():
return loading();case PaywallPacksLoaded():
return loaded(_that.catalog);case PaywallPacksUnavailable():
return unavailable();case PaywallPacksBlocked():
return purchasesBlocked(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( PaywallCatalog catalog)?  loaded,TResult? Function()?  unavailable,TResult? Function( PurchasesBlockedReason reason)?  purchasesBlocked,}) {final _that = this;
switch (_that) {
case PaywallPacksLoading() when loading != null:
return loading();case PaywallPacksLoaded() when loaded != null:
return loaded(_that.catalog);case PaywallPacksUnavailable() when unavailable != null:
return unavailable();case PaywallPacksBlocked() when purchasesBlocked != null:
return purchasesBlocked(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class PaywallPacksLoading implements PaywallPacks {
  const PaywallPacksLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallPacksLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaywallPacks.loading()';
}


}




/// @nodoc


class PaywallPacksLoaded implements PaywallPacks {
  const PaywallPacksLoaded(this.catalog);
  

 final  PaywallCatalog catalog;

/// Create a copy of PaywallPacks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallPacksLoadedCopyWith<PaywallPacksLoaded> get copyWith => _$PaywallPacksLoadedCopyWithImpl<PaywallPacksLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallPacksLoaded&&(identical(other.catalog, catalog) || other.catalog == catalog));
}


@override
int get hashCode => Object.hash(runtimeType,catalog);

@override
String toString() {
  return 'PaywallPacks.loaded(catalog: $catalog)';
}


}

/// @nodoc
abstract mixin class $PaywallPacksLoadedCopyWith<$Res> implements $PaywallPacksCopyWith<$Res> {
  factory $PaywallPacksLoadedCopyWith(PaywallPacksLoaded value, $Res Function(PaywallPacksLoaded) _then) = _$PaywallPacksLoadedCopyWithImpl;
@useResult
$Res call({
 PaywallCatalog catalog
});


$PaywallCatalogCopyWith<$Res> get catalog;

}
/// @nodoc
class _$PaywallPacksLoadedCopyWithImpl<$Res>
    implements $PaywallPacksLoadedCopyWith<$Res> {
  _$PaywallPacksLoadedCopyWithImpl(this._self, this._then);

  final PaywallPacksLoaded _self;
  final $Res Function(PaywallPacksLoaded) _then;

/// Create a copy of PaywallPacks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? catalog = null,}) {
  return _then(PaywallPacksLoaded(
null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as PaywallCatalog,
  ));
}

/// Create a copy of PaywallPacks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallCatalogCopyWith<$Res> get catalog {
  
  return $PaywallCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}
}

/// @nodoc


class PaywallPacksUnavailable implements PaywallPacks {
  const PaywallPacksUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallPacksUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PaywallPacks.unavailable()';
}


}




/// @nodoc


class PaywallPacksBlocked implements PaywallPacks {
  const PaywallPacksBlocked(this.reason);
  

 final  PurchasesBlockedReason reason;

/// Create a copy of PaywallPacks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallPacksBlockedCopyWith<PaywallPacksBlocked> get copyWith => _$PaywallPacksBlockedCopyWithImpl<PaywallPacksBlocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallPacksBlocked&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'PaywallPacks.purchasesBlocked(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PaywallPacksBlockedCopyWith<$Res> implements $PaywallPacksCopyWith<$Res> {
  factory $PaywallPacksBlockedCopyWith(PaywallPacksBlocked value, $Res Function(PaywallPacksBlocked) _then) = _$PaywallPacksBlockedCopyWithImpl;
@useResult
$Res call({
 PurchasesBlockedReason reason
});




}
/// @nodoc
class _$PaywallPacksBlockedCopyWithImpl<$Res>
    implements $PaywallPacksBlockedCopyWith<$Res> {
  _$PaywallPacksBlockedCopyWithImpl(this._self, this._then);

  final PaywallPacksBlocked _self;
  final $Res Function(PaywallPacksBlocked) _then;

/// Create a copy of PaywallPacks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(PaywallPacksBlocked(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason,
  ));
}


}

/// @nodoc
mixin _$RewardedOption {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOption);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedOption()';
}


}

/// @nodoc
class $RewardedOptionCopyWith<$Res>  {
$RewardedOptionCopyWith(RewardedOption _, $Res Function(RewardedOption) __);
}


/// Adds pattern-matching-related methods to [RewardedOption].
extension RewardedOptionPatterns on RewardedOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RewardedOptionAvailable value)?  available,TResult Function( RewardedOptionCoolingDown value)?  coolingDown,TResult Function( RewardedOptionCapped value)?  capped,TResult Function( RewardedOptionNoFill value)?  noFill,TResult Function( RewardedOptionHidden value)?  hidden,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RewardedOptionAvailable() when available != null:
return available(_that);case RewardedOptionCoolingDown() when coolingDown != null:
return coolingDown(_that);case RewardedOptionCapped() when capped != null:
return capped(_that);case RewardedOptionNoFill() when noFill != null:
return noFill(_that);case RewardedOptionHidden() when hidden != null:
return hidden(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RewardedOptionAvailable value)  available,required TResult Function( RewardedOptionCoolingDown value)  coolingDown,required TResult Function( RewardedOptionCapped value)  capped,required TResult Function( RewardedOptionNoFill value)  noFill,required TResult Function( RewardedOptionHidden value)  hidden,}){
final _that = this;
switch (_that) {
case RewardedOptionAvailable():
return available(_that);case RewardedOptionCoolingDown():
return coolingDown(_that);case RewardedOptionCapped():
return capped(_that);case RewardedOptionNoFill():
return noFill(_that);case RewardedOptionHidden():
return hidden(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RewardedOptionAvailable value)?  available,TResult? Function( RewardedOptionCoolingDown value)?  coolingDown,TResult? Function( RewardedOptionCapped value)?  capped,TResult? Function( RewardedOptionNoFill value)?  noFill,TResult? Function( RewardedOptionHidden value)?  hidden,}){
final _that = this;
switch (_that) {
case RewardedOptionAvailable() when available != null:
return available(_that);case RewardedOptionCoolingDown() when coolingDown != null:
return coolingDown(_that);case RewardedOptionCapped() when capped != null:
return capped(_that);case RewardedOptionNoFill() when noFill != null:
return noFill(_that);case RewardedOptionHidden() when hidden != null:
return hidden(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int amount,  int leftToday)?  available,TResult Function( DateTime until)?  coolingDown,TResult Function()?  capped,TResult Function( DateTime until)?  noFill,TResult Function()?  hidden,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RewardedOptionAvailable() when available != null:
return available(_that.amount,_that.leftToday);case RewardedOptionCoolingDown() when coolingDown != null:
return coolingDown(_that.until);case RewardedOptionCapped() when capped != null:
return capped();case RewardedOptionNoFill() when noFill != null:
return noFill(_that.until);case RewardedOptionHidden() when hidden != null:
return hidden();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int amount,  int leftToday)  available,required TResult Function( DateTime until)  coolingDown,required TResult Function()  capped,required TResult Function( DateTime until)  noFill,required TResult Function()  hidden,}) {final _that = this;
switch (_that) {
case RewardedOptionAvailable():
return available(_that.amount,_that.leftToday);case RewardedOptionCoolingDown():
return coolingDown(_that.until);case RewardedOptionCapped():
return capped();case RewardedOptionNoFill():
return noFill(_that.until);case RewardedOptionHidden():
return hidden();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int amount,  int leftToday)?  available,TResult? Function( DateTime until)?  coolingDown,TResult? Function()?  capped,TResult? Function( DateTime until)?  noFill,TResult? Function()?  hidden,}) {final _that = this;
switch (_that) {
case RewardedOptionAvailable() when available != null:
return available(_that.amount,_that.leftToday);case RewardedOptionCoolingDown() when coolingDown != null:
return coolingDown(_that.until);case RewardedOptionCapped() when capped != null:
return capped();case RewardedOptionNoFill() when noFill != null:
return noFill(_that.until);case RewardedOptionHidden() when hidden != null:
return hidden();case _:
  return null;

}
}

}

/// @nodoc


class RewardedOptionAvailable extends RewardedOption {
  const RewardedOptionAvailable({required this.amount, required this.leftToday}): super._();
  

 final  int amount;
 final  int leftToday;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedOptionAvailableCopyWith<RewardedOptionAvailable> get copyWith => _$RewardedOptionAvailableCopyWithImpl<RewardedOptionAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOptionAvailable&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.leftToday, leftToday) || other.leftToday == leftToday));
}


@override
int get hashCode => Object.hash(runtimeType,amount,leftToday);

@override
String toString() {
  return 'RewardedOption.available(amount: $amount, leftToday: $leftToday)';
}


}

/// @nodoc
abstract mixin class $RewardedOptionAvailableCopyWith<$Res> implements $RewardedOptionCopyWith<$Res> {
  factory $RewardedOptionAvailableCopyWith(RewardedOptionAvailable value, $Res Function(RewardedOptionAvailable) _then) = _$RewardedOptionAvailableCopyWithImpl;
@useResult
$Res call({
 int amount, int leftToday
});




}
/// @nodoc
class _$RewardedOptionAvailableCopyWithImpl<$Res>
    implements $RewardedOptionAvailableCopyWith<$Res> {
  _$RewardedOptionAvailableCopyWithImpl(this._self, this._then);

  final RewardedOptionAvailable _self;
  final $Res Function(RewardedOptionAvailable) _then;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? leftToday = null,}) {
  return _then(RewardedOptionAvailable(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,leftToday: null == leftToday ? _self.leftToday : leftToday // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RewardedOptionCoolingDown extends RewardedOption {
  const RewardedOptionCoolingDown({required this.until}): super._();
  

 final  DateTime until;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedOptionCoolingDownCopyWith<RewardedOptionCoolingDown> get copyWith => _$RewardedOptionCoolingDownCopyWithImpl<RewardedOptionCoolingDown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOptionCoolingDown&&(identical(other.until, until) || other.until == until));
}


@override
int get hashCode => Object.hash(runtimeType,until);

@override
String toString() {
  return 'RewardedOption.coolingDown(until: $until)';
}


}

/// @nodoc
abstract mixin class $RewardedOptionCoolingDownCopyWith<$Res> implements $RewardedOptionCopyWith<$Res> {
  factory $RewardedOptionCoolingDownCopyWith(RewardedOptionCoolingDown value, $Res Function(RewardedOptionCoolingDown) _then) = _$RewardedOptionCoolingDownCopyWithImpl;
@useResult
$Res call({
 DateTime until
});




}
/// @nodoc
class _$RewardedOptionCoolingDownCopyWithImpl<$Res>
    implements $RewardedOptionCoolingDownCopyWith<$Res> {
  _$RewardedOptionCoolingDownCopyWithImpl(this._self, this._then);

  final RewardedOptionCoolingDown _self;
  final $Res Function(RewardedOptionCoolingDown) _then;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? until = null,}) {
  return _then(RewardedOptionCoolingDown(
until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class RewardedOptionCapped extends RewardedOption {
  const RewardedOptionCapped(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOptionCapped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedOption.capped()';
}


}




/// @nodoc


class RewardedOptionNoFill extends RewardedOption {
  const RewardedOptionNoFill({required this.until}): super._();
  

 final  DateTime until;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedOptionNoFillCopyWith<RewardedOptionNoFill> get copyWith => _$RewardedOptionNoFillCopyWithImpl<RewardedOptionNoFill>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOptionNoFill&&(identical(other.until, until) || other.until == until));
}


@override
int get hashCode => Object.hash(runtimeType,until);

@override
String toString() {
  return 'RewardedOption.noFill(until: $until)';
}


}

/// @nodoc
abstract mixin class $RewardedOptionNoFillCopyWith<$Res> implements $RewardedOptionCopyWith<$Res> {
  factory $RewardedOptionNoFillCopyWith(RewardedOptionNoFill value, $Res Function(RewardedOptionNoFill) _then) = _$RewardedOptionNoFillCopyWithImpl;
@useResult
$Res call({
 DateTime until
});




}
/// @nodoc
class _$RewardedOptionNoFillCopyWithImpl<$Res>
    implements $RewardedOptionNoFillCopyWith<$Res> {
  _$RewardedOptionNoFillCopyWithImpl(this._self, this._then);

  final RewardedOptionNoFill _self;
  final $Res Function(RewardedOptionNoFill) _then;

/// Create a copy of RewardedOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? until = null,}) {
  return _then(RewardedOptionNoFill(
until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class RewardedOptionHidden extends RewardedOption {
  const RewardedOptionHidden(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedOptionHidden);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedOption.hidden()';
}


}




// dart format on
