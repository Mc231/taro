// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoreState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreState()';
}


}

/// @nodoc
class $StoreStateCopyWith<$Res>  {
$StoreStateCopyWith(StoreState _, $Res Function(StoreState) __);
}


/// Adds pattern-matching-related methods to [StoreState].
extension StoreStatePatterns on StoreState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoreLoading value)?  loading,TResult Function( StoreReady value)?  ready,TResult Function( StoreUnavailable value)?  storeUnavailable,TResult Function( StoreProductsFailed value)?  productsFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoreLoading() when loading != null:
return loading(_that);case StoreReady() when ready != null:
return ready(_that);case StoreUnavailable() when storeUnavailable != null:
return storeUnavailable(_that);case StoreProductsFailed() when productsFailed != null:
return productsFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoreLoading value)  loading,required TResult Function( StoreReady value)  ready,required TResult Function( StoreUnavailable value)  storeUnavailable,required TResult Function( StoreProductsFailed value)  productsFailed,}){
final _that = this;
switch (_that) {
case StoreLoading():
return loading(_that);case StoreReady():
return ready(_that);case StoreUnavailable():
return storeUnavailable(_that);case StoreProductsFailed():
return productsFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoreLoading value)?  loading,TResult? Function( StoreReady value)?  ready,TResult? Function( StoreUnavailable value)?  storeUnavailable,TResult? Function( StoreProductsFailed value)?  productsFailed,}){
final _that = this;
switch (_that) {
case StoreLoading() when loading != null:
return loading(_that);case StoreReady() when ready != null:
return ready(_that);case StoreUnavailable() when storeUnavailable != null:
return storeUnavailable(_that);case StoreProductsFailed() when productsFailed != null:
return productsFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( StoreView view,  StorePurchasePhase phase)?  ready,TResult Function()?  storeUnavailable,TResult Function( ErrorKind kind)?  productsFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoreLoading() when loading != null:
return loading();case StoreReady() when ready != null:
return ready(_that.view,_that.phase);case StoreUnavailable() when storeUnavailable != null:
return storeUnavailable();case StoreProductsFailed() when productsFailed != null:
return productsFailed(_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( StoreView view,  StorePurchasePhase phase)  ready,required TResult Function()  storeUnavailable,required TResult Function( ErrorKind kind)  productsFailed,}) {final _that = this;
switch (_that) {
case StoreLoading():
return loading();case StoreReady():
return ready(_that.view,_that.phase);case StoreUnavailable():
return storeUnavailable();case StoreProductsFailed():
return productsFailed(_that.kind);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( StoreView view,  StorePurchasePhase phase)?  ready,TResult? Function()?  storeUnavailable,TResult? Function( ErrorKind kind)?  productsFailed,}) {final _that = this;
switch (_that) {
case StoreLoading() when loading != null:
return loading();case StoreReady() when ready != null:
return ready(_that.view,_that.phase);case StoreUnavailable() when storeUnavailable != null:
return storeUnavailable();case StoreProductsFailed() when productsFailed != null:
return productsFailed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class StoreLoading implements StoreState {
  const StoreLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreState.loading()';
}


}




/// @nodoc


class StoreReady implements StoreState {
  const StoreReady({required this.view, required this.phase});
  

 final  StoreView view;
 final  StorePurchasePhase phase;

/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreReadyCopyWith<StoreReady> get copyWith => _$StoreReadyCopyWithImpl<StoreReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreReady&&(identical(other.view, view) || other.view == view)&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,view,phase);

@override
String toString() {
  return 'StoreState.ready(view: $view, phase: $phase)';
}


}

/// @nodoc
abstract mixin class $StoreReadyCopyWith<$Res> implements $StoreStateCopyWith<$Res> {
  factory $StoreReadyCopyWith(StoreReady value, $Res Function(StoreReady) _then) = _$StoreReadyCopyWithImpl;
@useResult
$Res call({
 StoreView view, StorePurchasePhase phase
});


$StoreViewCopyWith<$Res> get view;$StorePurchasePhaseCopyWith<$Res> get phase;

}
/// @nodoc
class _$StoreReadyCopyWithImpl<$Res>
    implements $StoreReadyCopyWith<$Res> {
  _$StoreReadyCopyWithImpl(this._self, this._then);

  final StoreReady _self;
  final $Res Function(StoreReady) _then;

/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? phase = null,}) {
  return _then(StoreReady(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as StoreView,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as StorePurchasePhase,
  ));
}

/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoreViewCopyWith<$Res> get view {
  
  return $StoreViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorePurchasePhaseCopyWith<$Res> get phase {
  
  return $StorePurchasePhaseCopyWith<$Res>(_self.phase, (value) {
    return _then(_self.copyWith(phase: value));
  });
}
}

/// @nodoc


class StoreUnavailable implements StoreState {
  const StoreUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreState.storeUnavailable()';
}


}




/// @nodoc


class StoreProductsFailed implements StoreState {
  const StoreProductsFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreProductsFailedCopyWith<StoreProductsFailed> get copyWith => _$StoreProductsFailedCopyWithImpl<StoreProductsFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreProductsFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'StoreState.productsFailed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $StoreProductsFailedCopyWith<$Res> implements $StoreStateCopyWith<$Res> {
  factory $StoreProductsFailedCopyWith(StoreProductsFailed value, $Res Function(StoreProductsFailed) _then) = _$StoreProductsFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$StoreProductsFailedCopyWithImpl<$Res>
    implements $StoreProductsFailedCopyWith<$Res> {
  _$StoreProductsFailedCopyWithImpl(this._self, this._then);

  final StoreProductsFailed _self;
  final $Res Function(StoreProductsFailed) _then;

/// Create a copy of StoreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(StoreProductsFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

/// @nodoc
mixin _$StoreView {

/// Packs and Remove Banner Ads with store prices.
 PaywallCatalog get catalog;/// The rewarded row (S11 is the second entry point, RC34).
 RewardedOption get rewarded;/// Remove Banner Ads is owned ("Banner ads removed ✓", no button).
 bool get removeAdsOwned;/// Offline: the store needs the network; a warning is shown.
 bool get offline;/// Paid readings are blocked (03 §5.1 `paidBlocked` notice).
 bool get paidBlocked;/// Pack buttons hidden: `blocked`, `refundDebt` or the `store.enabled`
/// kill switch (`storeDisabled`); free, rewarded and restore stay
/// (RC66).
 PurchasesBlockedReason? get purchasesBlocked;
/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreViewCopyWith<StoreView> get copyWith => _$StoreViewCopyWithImpl<StoreView>(this as StoreView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreView&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.rewarded, rewarded) || other.rewarded == rewarded)&&(identical(other.removeAdsOwned, removeAdsOwned) || other.removeAdsOwned == removeAdsOwned)&&(identical(other.offline, offline) || other.offline == offline)&&(identical(other.paidBlocked, paidBlocked) || other.paidBlocked == paidBlocked)&&(identical(other.purchasesBlocked, purchasesBlocked) || other.purchasesBlocked == purchasesBlocked));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,rewarded,removeAdsOwned,offline,paidBlocked,purchasesBlocked);

@override
String toString() {
  return 'StoreView(catalog: $catalog, rewarded: $rewarded, removeAdsOwned: $removeAdsOwned, offline: $offline, paidBlocked: $paidBlocked, purchasesBlocked: $purchasesBlocked)';
}


}

/// @nodoc
abstract mixin class $StoreViewCopyWith<$Res>  {
  factory $StoreViewCopyWith(StoreView value, $Res Function(StoreView) _then) = _$StoreViewCopyWithImpl;
@useResult
$Res call({
 PaywallCatalog catalog, RewardedOption rewarded, bool removeAdsOwned, bool offline, bool paidBlocked, PurchasesBlockedReason? purchasesBlocked
});


$PaywallCatalogCopyWith<$Res> get catalog;$RewardedOptionCopyWith<$Res> get rewarded;

}
/// @nodoc
class _$StoreViewCopyWithImpl<$Res>
    implements $StoreViewCopyWith<$Res> {
  _$StoreViewCopyWithImpl(this._self, this._then);

  final StoreView _self;
  final $Res Function(StoreView) _then;

/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalog = null,Object? rewarded = null,Object? removeAdsOwned = null,Object? offline = null,Object? paidBlocked = null,Object? purchasesBlocked = freezed,}) {
  return _then(_self.copyWith(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as PaywallCatalog,rewarded: null == rewarded ? _self.rewarded : rewarded // ignore: cast_nullable_to_non_nullable
as RewardedOption,removeAdsOwned: null == removeAdsOwned ? _self.removeAdsOwned : removeAdsOwned // ignore: cast_nullable_to_non_nullable
as bool,offline: null == offline ? _self.offline : offline // ignore: cast_nullable_to_non_nullable
as bool,paidBlocked: null == paidBlocked ? _self.paidBlocked : paidBlocked // ignore: cast_nullable_to_non_nullable
as bool,purchasesBlocked: freezed == purchasesBlocked ? _self.purchasesBlocked : purchasesBlocked // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason?,
  ));
}
/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallCatalogCopyWith<$Res> get catalog {
  
  return $PaywallCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardedOptionCopyWith<$Res> get rewarded {
  
  return $RewardedOptionCopyWith<$Res>(_self.rewarded, (value) {
    return _then(_self.copyWith(rewarded: value));
  });
}
}


/// Adds pattern-matching-related methods to [StoreView].
extension StoreViewPatterns on StoreView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreView value)  $default,){
final _that = this;
switch (_that) {
case _StoreView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreView value)?  $default,){
final _that = this;
switch (_that) {
case _StoreView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaywallCatalog catalog,  RewardedOption rewarded,  bool removeAdsOwned,  bool offline,  bool paidBlocked,  PurchasesBlockedReason? purchasesBlocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreView() when $default != null:
return $default(_that.catalog,_that.rewarded,_that.removeAdsOwned,_that.offline,_that.paidBlocked,_that.purchasesBlocked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaywallCatalog catalog,  RewardedOption rewarded,  bool removeAdsOwned,  bool offline,  bool paidBlocked,  PurchasesBlockedReason? purchasesBlocked)  $default,) {final _that = this;
switch (_that) {
case _StoreView():
return $default(_that.catalog,_that.rewarded,_that.removeAdsOwned,_that.offline,_that.paidBlocked,_that.purchasesBlocked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaywallCatalog catalog,  RewardedOption rewarded,  bool removeAdsOwned,  bool offline,  bool paidBlocked,  PurchasesBlockedReason? purchasesBlocked)?  $default,) {final _that = this;
switch (_that) {
case _StoreView() when $default != null:
return $default(_that.catalog,_that.rewarded,_that.removeAdsOwned,_that.offline,_that.paidBlocked,_that.purchasesBlocked);case _:
  return null;

}
}

}

/// @nodoc


class _StoreView implements StoreView {
  const _StoreView({required this.catalog, required this.rewarded, required this.removeAdsOwned, required this.offline, required this.paidBlocked, this.purchasesBlocked});
  

/// Packs and Remove Banner Ads with store prices.
@override final  PaywallCatalog catalog;
/// The rewarded row (S11 is the second entry point, RC34).
@override final  RewardedOption rewarded;
/// Remove Banner Ads is owned ("Banner ads removed ✓", no button).
@override final  bool removeAdsOwned;
/// Offline: the store needs the network; a warning is shown.
@override final  bool offline;
/// Paid readings are blocked (03 §5.1 `paidBlocked` notice).
@override final  bool paidBlocked;
/// Pack buttons hidden: `blocked`, `refundDebt` or the `store.enabled`
/// kill switch (`storeDisabled`); free, rewarded and restore stay
/// (RC66).
@override final  PurchasesBlockedReason? purchasesBlocked;

/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreViewCopyWith<_StoreView> get copyWith => __$StoreViewCopyWithImpl<_StoreView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreView&&(identical(other.catalog, catalog) || other.catalog == catalog)&&(identical(other.rewarded, rewarded) || other.rewarded == rewarded)&&(identical(other.removeAdsOwned, removeAdsOwned) || other.removeAdsOwned == removeAdsOwned)&&(identical(other.offline, offline) || other.offline == offline)&&(identical(other.paidBlocked, paidBlocked) || other.paidBlocked == paidBlocked)&&(identical(other.purchasesBlocked, purchasesBlocked) || other.purchasesBlocked == purchasesBlocked));
}


@override
int get hashCode => Object.hash(runtimeType,catalog,rewarded,removeAdsOwned,offline,paidBlocked,purchasesBlocked);

@override
String toString() {
  return 'StoreView(catalog: $catalog, rewarded: $rewarded, removeAdsOwned: $removeAdsOwned, offline: $offline, paidBlocked: $paidBlocked, purchasesBlocked: $purchasesBlocked)';
}


}

/// @nodoc
abstract mixin class _$StoreViewCopyWith<$Res> implements $StoreViewCopyWith<$Res> {
  factory _$StoreViewCopyWith(_StoreView value, $Res Function(_StoreView) _then) = __$StoreViewCopyWithImpl;
@override @useResult
$Res call({
 PaywallCatalog catalog, RewardedOption rewarded, bool removeAdsOwned, bool offline, bool paidBlocked, PurchasesBlockedReason? purchasesBlocked
});


@override $PaywallCatalogCopyWith<$Res> get catalog;@override $RewardedOptionCopyWith<$Res> get rewarded;

}
/// @nodoc
class __$StoreViewCopyWithImpl<$Res>
    implements _$StoreViewCopyWith<$Res> {
  __$StoreViewCopyWithImpl(this._self, this._then);

  final _StoreView _self;
  final $Res Function(_StoreView) _then;

/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalog = null,Object? rewarded = null,Object? removeAdsOwned = null,Object? offline = null,Object? paidBlocked = null,Object? purchasesBlocked = freezed,}) {
  return _then(_StoreView(
catalog: null == catalog ? _self.catalog : catalog // ignore: cast_nullable_to_non_nullable
as PaywallCatalog,rewarded: null == rewarded ? _self.rewarded : rewarded // ignore: cast_nullable_to_non_nullable
as RewardedOption,removeAdsOwned: null == removeAdsOwned ? _self.removeAdsOwned : removeAdsOwned // ignore: cast_nullable_to_non_nullable
as bool,offline: null == offline ? _self.offline : offline // ignore: cast_nullable_to_non_nullable
as bool,paidBlocked: null == paidBlocked ? _self.paidBlocked : paidBlocked // ignore: cast_nullable_to_non_nullable
as bool,purchasesBlocked: freezed == purchasesBlocked ? _self.purchasesBlocked : purchasesBlocked // ignore: cast_nullable_to_non_nullable
as PurchasesBlockedReason?,
  ));
}

/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallCatalogCopyWith<$Res> get catalog {
  
  return $PaywallCatalogCopyWith<$Res>(_self.catalog, (value) {
    return _then(_self.copyWith(catalog: value));
  });
}/// Create a copy of StoreView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardedOptionCopyWith<$Res> get rewarded {
  
  return $RewardedOptionCopyWith<$Res>(_self.rewarded, (value) {
    return _then(_self.copyWith(rewarded: value));
  });
}
}

/// @nodoc
mixin _$StorePurchasePhase {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePurchasePhase);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorePurchasePhase()';
}


}

/// @nodoc
class $StorePurchasePhaseCopyWith<$Res>  {
$StorePurchasePhaseCopyWith(StorePurchasePhase _, $Res Function(StorePurchasePhase) __);
}


/// Adds pattern-matching-related methods to [StorePurchasePhase].
extension StorePurchasePhasePatterns on StorePurchasePhase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StorePhaseIdle value)?  idle,TResult Function( StorePhasePurchasing value)?  purchasing,TResult Function( StorePhasePending value)?  pending,TResult Function( StorePhaseVerifying value)?  verifying,TResult Function( StorePhaseVerificationDeferred value)?  verificationDeferred,TResult Function( StorePhaseGranted value)?  granted,TResult Function( StorePhaseFailed value)?  failed,TResult Function( StorePhaseCancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StorePhaseIdle() when idle != null:
return idle(_that);case StorePhasePurchasing() when purchasing != null:
return purchasing(_that);case StorePhasePending() when pending != null:
return pending(_that);case StorePhaseVerifying() when verifying != null:
return verifying(_that);case StorePhaseVerificationDeferred() when verificationDeferred != null:
return verificationDeferred(_that);case StorePhaseGranted() when granted != null:
return granted(_that);case StorePhaseFailed() when failed != null:
return failed(_that);case StorePhaseCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StorePhaseIdle value)  idle,required TResult Function( StorePhasePurchasing value)  purchasing,required TResult Function( StorePhasePending value)  pending,required TResult Function( StorePhaseVerifying value)  verifying,required TResult Function( StorePhaseVerificationDeferred value)  verificationDeferred,required TResult Function( StorePhaseGranted value)  granted,required TResult Function( StorePhaseFailed value)  failed,required TResult Function( StorePhaseCancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case StorePhaseIdle():
return idle(_that);case StorePhasePurchasing():
return purchasing(_that);case StorePhasePending():
return pending(_that);case StorePhaseVerifying():
return verifying(_that);case StorePhaseVerificationDeferred():
return verificationDeferred(_that);case StorePhaseGranted():
return granted(_that);case StorePhaseFailed():
return failed(_that);case StorePhaseCancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StorePhaseIdle value)?  idle,TResult? Function( StorePhasePurchasing value)?  purchasing,TResult? Function( StorePhasePending value)?  pending,TResult? Function( StorePhaseVerifying value)?  verifying,TResult? Function( StorePhaseVerificationDeferred value)?  verificationDeferred,TResult? Function( StorePhaseGranted value)?  granted,TResult? Function( StorePhaseFailed value)?  failed,TResult? Function( StorePhaseCancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case StorePhaseIdle() when idle != null:
return idle(_that);case StorePhasePurchasing() when purchasing != null:
return purchasing(_that);case StorePhasePending() when pending != null:
return pending(_that);case StorePhaseVerifying() when verifying != null:
return verifying(_that);case StorePhaseVerificationDeferred() when verificationDeferred != null:
return verificationDeferred(_that);case StorePhaseGranted() when granted != null:
return granted(_that);case StorePhaseFailed() when failed != null:
return failed(_that);case StorePhaseCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( ProductId productId)?  purchasing,TResult Function( ProductId productId)?  pending,TResult Function( ProductId productId)?  verifying,TResult Function( ProductId productId)?  verificationDeferred,TResult Function( ProductId productId,  int credits)?  granted,TResult Function( ProductId productId,  PurchaseErrorKind reason,  bool transferEligible)?  failed,TResult Function( ProductId productId)?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StorePhaseIdle() when idle != null:
return idle();case StorePhasePurchasing() when purchasing != null:
return purchasing(_that.productId);case StorePhasePending() when pending != null:
return pending(_that.productId);case StorePhaseVerifying() when verifying != null:
return verifying(_that.productId);case StorePhaseVerificationDeferred() when verificationDeferred != null:
return verificationDeferred(_that.productId);case StorePhaseGranted() when granted != null:
return granted(_that.productId,_that.credits);case StorePhaseFailed() when failed != null:
return failed(_that.productId,_that.reason,_that.transferEligible);case StorePhaseCancelled() when cancelled != null:
return cancelled(_that.productId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( ProductId productId)  purchasing,required TResult Function( ProductId productId)  pending,required TResult Function( ProductId productId)  verifying,required TResult Function( ProductId productId)  verificationDeferred,required TResult Function( ProductId productId,  int credits)  granted,required TResult Function( ProductId productId,  PurchaseErrorKind reason,  bool transferEligible)  failed,required TResult Function( ProductId productId)  cancelled,}) {final _that = this;
switch (_that) {
case StorePhaseIdle():
return idle();case StorePhasePurchasing():
return purchasing(_that.productId);case StorePhasePending():
return pending(_that.productId);case StorePhaseVerifying():
return verifying(_that.productId);case StorePhaseVerificationDeferred():
return verificationDeferred(_that.productId);case StorePhaseGranted():
return granted(_that.productId,_that.credits);case StorePhaseFailed():
return failed(_that.productId,_that.reason,_that.transferEligible);case StorePhaseCancelled():
return cancelled(_that.productId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( ProductId productId)?  purchasing,TResult? Function( ProductId productId)?  pending,TResult? Function( ProductId productId)?  verifying,TResult? Function( ProductId productId)?  verificationDeferred,TResult? Function( ProductId productId,  int credits)?  granted,TResult? Function( ProductId productId,  PurchaseErrorKind reason,  bool transferEligible)?  failed,TResult? Function( ProductId productId)?  cancelled,}) {final _that = this;
switch (_that) {
case StorePhaseIdle() when idle != null:
return idle();case StorePhasePurchasing() when purchasing != null:
return purchasing(_that.productId);case StorePhasePending() when pending != null:
return pending(_that.productId);case StorePhaseVerifying() when verifying != null:
return verifying(_that.productId);case StorePhaseVerificationDeferred() when verificationDeferred != null:
return verificationDeferred(_that.productId);case StorePhaseGranted() when granted != null:
return granted(_that.productId,_that.credits);case StorePhaseFailed() when failed != null:
return failed(_that.productId,_that.reason,_that.transferEligible);case StorePhaseCancelled() when cancelled != null:
return cancelled(_that.productId);case _:
  return null;

}
}

}

/// @nodoc


class StorePhaseIdle extends StorePurchasePhase {
  const StorePhaseIdle(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorePurchasePhase.idle()';
}


}




/// @nodoc


class StorePhasePurchasing extends StorePurchasePhase {
  const StorePhasePurchasing(this.productId): super._();
  

 final  ProductId productId;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhasePurchasingCopyWith<StorePhasePurchasing> get copyWith => _$StorePhasePurchasingCopyWithImpl<StorePhasePurchasing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhasePurchasing&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'StorePurchasePhase.purchasing(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $StorePhasePurchasingCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhasePurchasingCopyWith(StorePhasePurchasing value, $Res Function(StorePhasePurchasing) _then) = _$StorePhasePurchasingCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$StorePhasePurchasingCopyWithImpl<$Res>
    implements $StorePhasePurchasingCopyWith<$Res> {
  _$StorePhasePurchasingCopyWithImpl(this._self, this._then);

  final StorePhasePurchasing _self;
  final $Res Function(StorePhasePurchasing) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(StorePhasePurchasing(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

/// @nodoc


class StorePhasePending extends StorePurchasePhase {
  const StorePhasePending(this.productId): super._();
  

 final  ProductId productId;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhasePendingCopyWith<StorePhasePending> get copyWith => _$StorePhasePendingCopyWithImpl<StorePhasePending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhasePending&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'StorePurchasePhase.pending(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $StorePhasePendingCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhasePendingCopyWith(StorePhasePending value, $Res Function(StorePhasePending) _then) = _$StorePhasePendingCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$StorePhasePendingCopyWithImpl<$Res>
    implements $StorePhasePendingCopyWith<$Res> {
  _$StorePhasePendingCopyWithImpl(this._self, this._then);

  final StorePhasePending _self;
  final $Res Function(StorePhasePending) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(StorePhasePending(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

/// @nodoc


class StorePhaseVerifying extends StorePurchasePhase {
  const StorePhaseVerifying(this.productId): super._();
  

 final  ProductId productId;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhaseVerifyingCopyWith<StorePhaseVerifying> get copyWith => _$StorePhaseVerifyingCopyWithImpl<StorePhaseVerifying>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseVerifying&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'StorePurchasePhase.verifying(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $StorePhaseVerifyingCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhaseVerifyingCopyWith(StorePhaseVerifying value, $Res Function(StorePhaseVerifying) _then) = _$StorePhaseVerifyingCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$StorePhaseVerifyingCopyWithImpl<$Res>
    implements $StorePhaseVerifyingCopyWith<$Res> {
  _$StorePhaseVerifyingCopyWithImpl(this._self, this._then);

  final StorePhaseVerifying _self;
  final $Res Function(StorePhaseVerifying) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(StorePhaseVerifying(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

/// @nodoc


class StorePhaseVerificationDeferred extends StorePurchasePhase {
  const StorePhaseVerificationDeferred(this.productId): super._();
  

 final  ProductId productId;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhaseVerificationDeferredCopyWith<StorePhaseVerificationDeferred> get copyWith => _$StorePhaseVerificationDeferredCopyWithImpl<StorePhaseVerificationDeferred>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseVerificationDeferred&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'StorePurchasePhase.verificationDeferred(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $StorePhaseVerificationDeferredCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhaseVerificationDeferredCopyWith(StorePhaseVerificationDeferred value, $Res Function(StorePhaseVerificationDeferred) _then) = _$StorePhaseVerificationDeferredCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$StorePhaseVerificationDeferredCopyWithImpl<$Res>
    implements $StorePhaseVerificationDeferredCopyWith<$Res> {
  _$StorePhaseVerificationDeferredCopyWithImpl(this._self, this._then);

  final StorePhaseVerificationDeferred _self;
  final $Res Function(StorePhaseVerificationDeferred) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(StorePhaseVerificationDeferred(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

/// @nodoc


class StorePhaseGranted extends StorePurchasePhase {
  const StorePhaseGranted(this.productId, {required this.credits}): super._();
  

 final  ProductId productId;
 final  int credits;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhaseGrantedCopyWith<StorePhaseGranted> get copyWith => _$StorePhaseGrantedCopyWithImpl<StorePhaseGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseGranted&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.credits, credits) || other.credits == credits));
}


@override
int get hashCode => Object.hash(runtimeType,productId,credits);

@override
String toString() {
  return 'StorePurchasePhase.granted(productId: $productId, credits: $credits)';
}


}

/// @nodoc
abstract mixin class $StorePhaseGrantedCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhaseGrantedCopyWith(StorePhaseGranted value, $Res Function(StorePhaseGranted) _then) = _$StorePhaseGrantedCopyWithImpl;
@useResult
$Res call({
 ProductId productId, int credits
});




}
/// @nodoc
class _$StorePhaseGrantedCopyWithImpl<$Res>
    implements $StorePhaseGrantedCopyWith<$Res> {
  _$StorePhaseGrantedCopyWithImpl(this._self, this._then);

  final StorePhaseGranted _self;
  final $Res Function(StorePhaseGranted) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? credits = null,}) {
  return _then(StorePhaseGranted(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class StorePhaseFailed extends StorePurchasePhase {
  const StorePhaseFailed(this.productId, {required this.reason, this.transferEligible = false}): super._();
  

 final  ProductId productId;
 final  PurchaseErrorKind reason;
@JsonKey() final  bool transferEligible;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhaseFailedCopyWith<StorePhaseFailed> get copyWith => _$StorePhaseFailedCopyWithImpl<StorePhaseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseFailed&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.transferEligible, transferEligible) || other.transferEligible == transferEligible));
}


@override
int get hashCode => Object.hash(runtimeType,productId,reason,transferEligible);

@override
String toString() {
  return 'StorePurchasePhase.failed(productId: $productId, reason: $reason, transferEligible: $transferEligible)';
}


}

/// @nodoc
abstract mixin class $StorePhaseFailedCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhaseFailedCopyWith(StorePhaseFailed value, $Res Function(StorePhaseFailed) _then) = _$StorePhaseFailedCopyWithImpl;
@useResult
$Res call({
 ProductId productId, PurchaseErrorKind reason, bool transferEligible
});




}
/// @nodoc
class _$StorePhaseFailedCopyWithImpl<$Res>
    implements $StorePhaseFailedCopyWith<$Res> {
  _$StorePhaseFailedCopyWithImpl(this._self, this._then);

  final StorePhaseFailed _self;
  final $Res Function(StorePhaseFailed) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? reason = null,Object? transferEligible = null,}) {
  return _then(StorePhaseFailed(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PurchaseErrorKind,transferEligible: null == transferEligible ? _self.transferEligible : transferEligible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class StorePhaseCancelled extends StorePurchasePhase {
  const StorePhaseCancelled(this.productId): super._();
  

 final  ProductId productId;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePhaseCancelledCopyWith<StorePhaseCancelled> get copyWith => _$StorePhaseCancelledCopyWithImpl<StorePhaseCancelled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePhaseCancelled&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'StorePurchasePhase.cancelled(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $StorePhaseCancelledCopyWith<$Res> implements $StorePurchasePhaseCopyWith<$Res> {
  factory $StorePhaseCancelledCopyWith(StorePhaseCancelled value, $Res Function(StorePhaseCancelled) _then) = _$StorePhaseCancelledCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$StorePhaseCancelledCopyWithImpl<$Res>
    implements $StorePhaseCancelledCopyWith<$Res> {
  _$StorePhaseCancelledCopyWithImpl(this._self, this._then);

  final StorePhaseCancelled _self;
  final $Res Function(StorePhaseCancelled) _then;

/// Create a copy of StorePurchasePhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(StorePhaseCancelled(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

// dart format on
