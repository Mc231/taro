// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iap_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreditGrant {

/// `creditsGranted` (the amount lives only in the Worker, RC3).
 int get credits;/// Whether this was the install's first purchase.
 bool get isFirstPurchase;/// The balance after the grant.
 CreditBalance? get balance;
/// Create a copy of CreditGrant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditGrantCopyWith<CreditGrant> get copyWith => _$CreditGrantCopyWithImpl<CreditGrant>(this as CreditGrant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditGrant&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.isFirstPurchase, isFirstPurchase) || other.isFirstPurchase == isFirstPurchase)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,credits,isFirstPurchase,balance);

@override
String toString() {
  return 'CreditGrant(credits: $credits, isFirstPurchase: $isFirstPurchase, balance: $balance)';
}


}

/// @nodoc
abstract mixin class $CreditGrantCopyWith<$Res>  {
  factory $CreditGrantCopyWith(CreditGrant value, $Res Function(CreditGrant) _then) = _$CreditGrantCopyWithImpl;
@useResult
$Res call({
 int credits, bool isFirstPurchase, CreditBalance? balance
});


$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$CreditGrantCopyWithImpl<$Res>
    implements $CreditGrantCopyWith<$Res> {
  _$CreditGrantCopyWithImpl(this._self, this._then);

  final CreditGrant _self;
  final $Res Function(CreditGrant) _then;

/// Create a copy of CreditGrant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? credits = null,Object? isFirstPurchase = null,Object? balance = freezed,}) {
  return _then(_self.copyWith(
credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,isFirstPurchase: null == isFirstPurchase ? _self.isFirstPurchase : isFirstPurchase // ignore: cast_nullable_to_non_nullable
as bool,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}
/// Create a copy of CreditGrant
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


/// Adds pattern-matching-related methods to [CreditGrant].
extension CreditGrantPatterns on CreditGrant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditGrant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditGrant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditGrant value)  $default,){
final _that = this;
switch (_that) {
case _CreditGrant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditGrant value)?  $default,){
final _that = this;
switch (_that) {
case _CreditGrant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int credits,  bool isFirstPurchase,  CreditBalance? balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditGrant() when $default != null:
return $default(_that.credits,_that.isFirstPurchase,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int credits,  bool isFirstPurchase,  CreditBalance? balance)  $default,) {final _that = this;
switch (_that) {
case _CreditGrant():
return $default(_that.credits,_that.isFirstPurchase,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int credits,  bool isFirstPurchase,  CreditBalance? balance)?  $default,) {final _that = this;
switch (_that) {
case _CreditGrant() when $default != null:
return $default(_that.credits,_that.isFirstPurchase,_that.balance);case _:
  return null;

}
}

}

/// @nodoc


class _CreditGrant implements CreditGrant {
  const _CreditGrant({required this.credits, required this.isFirstPurchase, this.balance});
  

/// `creditsGranted` (the amount lives only in the Worker, RC3).
@override final  int credits;
/// Whether this was the install's first purchase.
@override final  bool isFirstPurchase;
/// The balance after the grant.
@override final  CreditBalance? balance;

/// Create a copy of CreditGrant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditGrantCopyWith<_CreditGrant> get copyWith => __$CreditGrantCopyWithImpl<_CreditGrant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditGrant&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.isFirstPurchase, isFirstPurchase) || other.isFirstPurchase == isFirstPurchase)&&(identical(other.balance, balance) || other.balance == balance));
}


@override
int get hashCode => Object.hash(runtimeType,credits,isFirstPurchase,balance);

@override
String toString() {
  return 'CreditGrant(credits: $credits, isFirstPurchase: $isFirstPurchase, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$CreditGrantCopyWith<$Res> implements $CreditGrantCopyWith<$Res> {
  factory _$CreditGrantCopyWith(_CreditGrant value, $Res Function(_CreditGrant) _then) = __$CreditGrantCopyWithImpl;
@override @useResult
$Res call({
 int credits, bool isFirstPurchase, CreditBalance? balance
});


@override $CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class __$CreditGrantCopyWithImpl<$Res>
    implements _$CreditGrantCopyWith<$Res> {
  __$CreditGrantCopyWithImpl(this._self, this._then);

  final _CreditGrant _self;
  final $Res Function(_CreditGrant) _then;

/// Create a copy of CreditGrant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? credits = null,Object? isFirstPurchase = null,Object? balance = freezed,}) {
  return _then(_CreditGrant(
credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,isFirstPurchase: null == isFirstPurchase ? _self.isFirstPurchase : isFirstPurchase // ignore: cast_nullable_to_non_nullable
as bool,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,
  ));
}

/// Create a copy of CreditGrant
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

/// @nodoc
mixin _$IapEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IapEvent()';
}


}

/// @nodoc
class $IapEventCopyWith<$Res>  {
$IapEventCopyWith(IapEvent _, $Res Function(IapEvent) __);
}


/// Adds pattern-matching-related methods to [IapEvent].
extension IapEventPatterns on IapEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IapPurchased value)?  purchased,TResult Function( IapPending value)?  pending,TResult Function( IapCancelled value)?  cancelled,TResult Function( IapFailed value)?  failed,TResult Function( IapRestored value)?  restored,TResult Function( IapEntitlementChanged value)?  entitlementChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IapPurchased() when purchased != null:
return purchased(_that);case IapPending() when pending != null:
return pending(_that);case IapCancelled() when cancelled != null:
return cancelled(_that);case IapFailed() when failed != null:
return failed(_that);case IapRestored() when restored != null:
return restored(_that);case IapEntitlementChanged() when entitlementChanged != null:
return entitlementChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IapPurchased value)  purchased,required TResult Function( IapPending value)  pending,required TResult Function( IapCancelled value)  cancelled,required TResult Function( IapFailed value)  failed,required TResult Function( IapRestored value)  restored,required TResult Function( IapEntitlementChanged value)  entitlementChanged,}){
final _that = this;
switch (_that) {
case IapPurchased():
return purchased(_that);case IapPending():
return pending(_that);case IapCancelled():
return cancelled(_that);case IapFailed():
return failed(_that);case IapRestored():
return restored(_that);case IapEntitlementChanged():
return entitlementChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IapPurchased value)?  purchased,TResult? Function( IapPending value)?  pending,TResult? Function( IapCancelled value)?  cancelled,TResult? Function( IapFailed value)?  failed,TResult? Function( IapRestored value)?  restored,TResult? Function( IapEntitlementChanged value)?  entitlementChanged,}){
final _that = this;
switch (_that) {
case IapPurchased() when purchased != null:
return purchased(_that);case IapPending() when pending != null:
return pending(_that);case IapCancelled() when cancelled != null:
return cancelled(_that);case IapFailed() when failed != null:
return failed(_that);case IapRestored() when restored != null:
return restored(_that);case IapEntitlementChanged() when entitlementChanged != null:
return entitlementChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProductId productId,  CreditGrant? grant)?  purchased,TResult Function( ProductId productId)?  pending,TResult Function()?  cancelled,TResult Function( Failure failure)?  failed,TResult Function( Set<ProductId> productIds)?  restored,TResult Function( Entitlement entitlement)?  entitlementChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IapPurchased() when purchased != null:
return purchased(_that.productId,_that.grant);case IapPending() when pending != null:
return pending(_that.productId);case IapCancelled() when cancelled != null:
return cancelled();case IapFailed() when failed != null:
return failed(_that.failure);case IapRestored() when restored != null:
return restored(_that.productIds);case IapEntitlementChanged() when entitlementChanged != null:
return entitlementChanged(_that.entitlement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProductId productId,  CreditGrant? grant)  purchased,required TResult Function( ProductId productId)  pending,required TResult Function()  cancelled,required TResult Function( Failure failure)  failed,required TResult Function( Set<ProductId> productIds)  restored,required TResult Function( Entitlement entitlement)  entitlementChanged,}) {final _that = this;
switch (_that) {
case IapPurchased():
return purchased(_that.productId,_that.grant);case IapPending():
return pending(_that.productId);case IapCancelled():
return cancelled();case IapFailed():
return failed(_that.failure);case IapRestored():
return restored(_that.productIds);case IapEntitlementChanged():
return entitlementChanged(_that.entitlement);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProductId productId,  CreditGrant? grant)?  purchased,TResult? Function( ProductId productId)?  pending,TResult? Function()?  cancelled,TResult? Function( Failure failure)?  failed,TResult? Function( Set<ProductId> productIds)?  restored,TResult? Function( Entitlement entitlement)?  entitlementChanged,}) {final _that = this;
switch (_that) {
case IapPurchased() when purchased != null:
return purchased(_that.productId,_that.grant);case IapPending() when pending != null:
return pending(_that.productId);case IapCancelled() when cancelled != null:
return cancelled();case IapFailed() when failed != null:
return failed(_that.failure);case IapRestored() when restored != null:
return restored(_that.productIds);case IapEntitlementChanged() when entitlementChanged != null:
return entitlementChanged(_that.entitlement);case _:
  return null;

}
}

}

/// @nodoc


class IapPurchased implements IapEvent {
  const IapPurchased(this.productId, {this.grant});
  

 final  ProductId productId;
 final  CreditGrant? grant;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IapPurchasedCopyWith<IapPurchased> get copyWith => _$IapPurchasedCopyWithImpl<IapPurchased>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapPurchased&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.grant, grant) || other.grant == grant));
}


@override
int get hashCode => Object.hash(runtimeType,productId,grant);

@override
String toString() {
  return 'IapEvent.purchased(productId: $productId, grant: $grant)';
}


}

/// @nodoc
abstract mixin class $IapPurchasedCopyWith<$Res> implements $IapEventCopyWith<$Res> {
  factory $IapPurchasedCopyWith(IapPurchased value, $Res Function(IapPurchased) _then) = _$IapPurchasedCopyWithImpl;
@useResult
$Res call({
 ProductId productId, CreditGrant? grant
});


$CreditGrantCopyWith<$Res>? get grant;

}
/// @nodoc
class _$IapPurchasedCopyWithImpl<$Res>
    implements $IapPurchasedCopyWith<$Res> {
  _$IapPurchasedCopyWithImpl(this._self, this._then);

  final IapPurchased _self;
  final $Res Function(IapPurchased) _then;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? grant = freezed,}) {
  return _then(IapPurchased(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,grant: freezed == grant ? _self.grant : grant // ignore: cast_nullable_to_non_nullable
as CreditGrant?,
  ));
}

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditGrantCopyWith<$Res>? get grant {
    if (_self.grant == null) {
    return null;
  }

  return $CreditGrantCopyWith<$Res>(_self.grant!, (value) {
    return _then(_self.copyWith(grant: value));
  });
}
}

/// @nodoc


class IapPending implements IapEvent {
  const IapPending(this.productId);
  

 final  ProductId productId;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IapPendingCopyWith<IapPending> get copyWith => _$IapPendingCopyWithImpl<IapPending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapPending&&(identical(other.productId, productId) || other.productId == productId));
}


@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'IapEvent.pending(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $IapPendingCopyWith<$Res> implements $IapEventCopyWith<$Res> {
  factory $IapPendingCopyWith(IapPending value, $Res Function(IapPending) _then) = _$IapPendingCopyWithImpl;
@useResult
$Res call({
 ProductId productId
});




}
/// @nodoc
class _$IapPendingCopyWithImpl<$Res>
    implements $IapPendingCopyWith<$Res> {
  _$IapPendingCopyWithImpl(this._self, this._then);

  final IapPending _self;
  final $Res Function(IapPending) _then;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(IapPending(
null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,
  ));
}


}

/// @nodoc


class IapCancelled implements IapEvent {
  const IapCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'IapEvent.cancelled()';
}


}




/// @nodoc


class IapFailed implements IapEvent {
  const IapFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IapFailedCopyWith<IapFailed> get copyWith => _$IapFailedCopyWithImpl<IapFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'IapEvent.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $IapFailedCopyWith<$Res> implements $IapEventCopyWith<$Res> {
  factory $IapFailedCopyWith(IapFailed value, $Res Function(IapFailed) _then) = _$IapFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$IapFailedCopyWithImpl<$Res>
    implements $IapFailedCopyWith<$Res> {
  _$IapFailedCopyWithImpl(this._self, this._then);

  final IapFailed _self;
  final $Res Function(IapFailed) _then;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(IapFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class IapRestored implements IapEvent {
  const IapRestored(final  Set<ProductId> productIds): _productIds = productIds;
  

 final  Set<ProductId> _productIds;
 Set<ProductId> get productIds {
  if (_productIds is EqualUnmodifiableSetView) return _productIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_productIds);
}


/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IapRestoredCopyWith<IapRestored> get copyWith => _$IapRestoredCopyWithImpl<IapRestored>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapRestored&&const DeepCollectionEquality().equals(other._productIds, _productIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_productIds));

@override
String toString() {
  return 'IapEvent.restored(productIds: $productIds)';
}


}

/// @nodoc
abstract mixin class $IapRestoredCopyWith<$Res> implements $IapEventCopyWith<$Res> {
  factory $IapRestoredCopyWith(IapRestored value, $Res Function(IapRestored) _then) = _$IapRestoredCopyWithImpl;
@useResult
$Res call({
 Set<ProductId> productIds
});




}
/// @nodoc
class _$IapRestoredCopyWithImpl<$Res>
    implements $IapRestoredCopyWith<$Res> {
  _$IapRestoredCopyWithImpl(this._self, this._then);

  final IapRestored _self;
  final $Res Function(IapRestored) _then;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productIds = null,}) {
  return _then(IapRestored(
null == productIds ? _self._productIds : productIds // ignore: cast_nullable_to_non_nullable
as Set<ProductId>,
  ));
}


}

/// @nodoc


class IapEntitlementChanged implements IapEvent {
  const IapEntitlementChanged(this.entitlement);
  

 final  Entitlement entitlement;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IapEntitlementChangedCopyWith<IapEntitlementChanged> get copyWith => _$IapEntitlementChangedCopyWithImpl<IapEntitlementChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IapEntitlementChanged&&(identical(other.entitlement, entitlement) || other.entitlement == entitlement));
}


@override
int get hashCode => Object.hash(runtimeType,entitlement);

@override
String toString() {
  return 'IapEvent.entitlementChanged(entitlement: $entitlement)';
}


}

/// @nodoc
abstract mixin class $IapEntitlementChangedCopyWith<$Res> implements $IapEventCopyWith<$Res> {
  factory $IapEntitlementChangedCopyWith(IapEntitlementChanged value, $Res Function(IapEntitlementChanged) _then) = _$IapEntitlementChangedCopyWithImpl;
@useResult
$Res call({
 Entitlement entitlement
});


$EntitlementCopyWith<$Res> get entitlement;

}
/// @nodoc
class _$IapEntitlementChangedCopyWithImpl<$Res>
    implements $IapEntitlementChangedCopyWith<$Res> {
  _$IapEntitlementChangedCopyWithImpl(this._self, this._then);

  final IapEntitlementChanged _self;
  final $Res Function(IapEntitlementChanged) _then;

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entitlement = null,}) {
  return _then(IapEntitlementChanged(
null == entitlement ? _self.entitlement : entitlement // ignore: cast_nullable_to_non_nullable
as Entitlement,
  ));
}

/// Create a copy of IapEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntitlementCopyWith<$Res> get entitlement {
  
  return $EntitlementCopyWith<$Res>(_self.entitlement, (value) {
    return _then(_self.copyWith(entitlement: value));
  });
}
}

// dart format on
