// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'install_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseBinding {

/// StoreKit `appAccountToken` (UUIDv5, iOS).
 String? get appleAccountToken;/// Play `obfuscatedAccountId` (HMAC, Android).
 String? get playAccountId;
/// Create a copy of PurchaseBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseBindingCopyWith<PurchaseBinding> get copyWith => _$PurchaseBindingCopyWithImpl<PurchaseBinding>(this as PurchaseBinding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseBinding&&(identical(other.appleAccountToken, appleAccountToken) || other.appleAccountToken == appleAccountToken)&&(identical(other.playAccountId, playAccountId) || other.playAccountId == playAccountId));
}


@override
int get hashCode => Object.hash(runtimeType,appleAccountToken,playAccountId);

@override
String toString() {
  return 'PurchaseBinding(appleAccountToken: $appleAccountToken, playAccountId: $playAccountId)';
}


}

/// @nodoc
abstract mixin class $PurchaseBindingCopyWith<$Res>  {
  factory $PurchaseBindingCopyWith(PurchaseBinding value, $Res Function(PurchaseBinding) _then) = _$PurchaseBindingCopyWithImpl;
@useResult
$Res call({
 String? appleAccountToken, String? playAccountId
});




}
/// @nodoc
class _$PurchaseBindingCopyWithImpl<$Res>
    implements $PurchaseBindingCopyWith<$Res> {
  _$PurchaseBindingCopyWithImpl(this._self, this._then);

  final PurchaseBinding _self;
  final $Res Function(PurchaseBinding) _then;

/// Create a copy of PurchaseBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appleAccountToken = freezed,Object? playAccountId = freezed,}) {
  return _then(_self.copyWith(
appleAccountToken: freezed == appleAccountToken ? _self.appleAccountToken : appleAccountToken // ignore: cast_nullable_to_non_nullable
as String?,playAccountId: freezed == playAccountId ? _self.playAccountId : playAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseBinding].
extension PurchaseBindingPatterns on PurchaseBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseBinding value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseBinding value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? appleAccountToken,  String? playAccountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseBinding() when $default != null:
return $default(_that.appleAccountToken,_that.playAccountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? appleAccountToken,  String? playAccountId)  $default,) {final _that = this;
switch (_that) {
case _PurchaseBinding():
return $default(_that.appleAccountToken,_that.playAccountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? appleAccountToken,  String? playAccountId)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseBinding() when $default != null:
return $default(_that.appleAccountToken,_that.playAccountId);case _:
  return null;

}
}

}

/// @nodoc


class _PurchaseBinding implements PurchaseBinding {
  const _PurchaseBinding({this.appleAccountToken, this.playAccountId});
  

/// StoreKit `appAccountToken` (UUIDv5, iOS).
@override final  String? appleAccountToken;
/// Play `obfuscatedAccountId` (HMAC, Android).
@override final  String? playAccountId;

/// Create a copy of PurchaseBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseBindingCopyWith<_PurchaseBinding> get copyWith => __$PurchaseBindingCopyWithImpl<_PurchaseBinding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseBinding&&(identical(other.appleAccountToken, appleAccountToken) || other.appleAccountToken == appleAccountToken)&&(identical(other.playAccountId, playAccountId) || other.playAccountId == playAccountId));
}


@override
int get hashCode => Object.hash(runtimeType,appleAccountToken,playAccountId);

@override
String toString() {
  return 'PurchaseBinding(appleAccountToken: $appleAccountToken, playAccountId: $playAccountId)';
}


}

/// @nodoc
abstract mixin class _$PurchaseBindingCopyWith<$Res> implements $PurchaseBindingCopyWith<$Res> {
  factory _$PurchaseBindingCopyWith(_PurchaseBinding value, $Res Function(_PurchaseBinding) _then) = __$PurchaseBindingCopyWithImpl;
@override @useResult
$Res call({
 String? appleAccountToken, String? playAccountId
});




}
/// @nodoc
class __$PurchaseBindingCopyWithImpl<$Res>
    implements _$PurchaseBindingCopyWith<$Res> {
  __$PurchaseBindingCopyWithImpl(this._self, this._then);

  final _PurchaseBinding _self;
  final $Res Function(_PurchaseBinding) _then;

/// Create a copy of PurchaseBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appleAccountToken = freezed,Object? playAccountId = freezed,}) {
  return _then(_PurchaseBinding(
appleAccountToken: freezed == appleAccountToken ? _self.appleAccountToken : appleAccountToken // ignore: cast_nullable_to_non_nullable
as String?,playAccountId: freezed == playAccountId ? _self.playAccountId : playAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$InstallIdentity {

/// The install ID (never logged).
 InstallId get installId;/// When registration with the Worker succeeded.
 DateTime? get registeredAt;/// The IANA timezone sent at registration.
 String? get registeredTimezone;/// Trust level from registration.
 Trust? get trust;/// Purchase binding from registration.
 PurchaseBinding? get purchaseBinding;/// App Attest key ID (iOS).
 String? get attestationKeyId;
/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallIdentityCopyWith<InstallIdentity> get copyWith => _$InstallIdentityCopyWithImpl<InstallIdentity>(this as InstallIdentity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallIdentity&&(identical(other.installId, installId) || other.installId == installId)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.registeredTimezone, registeredTimezone) || other.registeredTimezone == registeredTimezone)&&(identical(other.trust, trust) || other.trust == trust)&&(identical(other.purchaseBinding, purchaseBinding) || other.purchaseBinding == purchaseBinding)&&(identical(other.attestationKeyId, attestationKeyId) || other.attestationKeyId == attestationKeyId));
}


@override
int get hashCode => Object.hash(runtimeType,installId,registeredAt,registeredTimezone,trust,purchaseBinding,attestationKeyId);

@override
String toString() {
  return 'InstallIdentity(installId: $installId, registeredAt: $registeredAt, registeredTimezone: $registeredTimezone, trust: $trust, purchaseBinding: $purchaseBinding, attestationKeyId: $attestationKeyId)';
}


}

/// @nodoc
abstract mixin class $InstallIdentityCopyWith<$Res>  {
  factory $InstallIdentityCopyWith(InstallIdentity value, $Res Function(InstallIdentity) _then) = _$InstallIdentityCopyWithImpl;
@useResult
$Res call({
 InstallId installId, DateTime? registeredAt, String? registeredTimezone, Trust? trust, PurchaseBinding? purchaseBinding, String? attestationKeyId
});


$PurchaseBindingCopyWith<$Res>? get purchaseBinding;

}
/// @nodoc
class _$InstallIdentityCopyWithImpl<$Res>
    implements $InstallIdentityCopyWith<$Res> {
  _$InstallIdentityCopyWithImpl(this._self, this._then);

  final InstallIdentity _self;
  final $Res Function(InstallIdentity) _then;

/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installId = null,Object? registeredAt = freezed,Object? registeredTimezone = freezed,Object? trust = freezed,Object? purchaseBinding = freezed,Object? attestationKeyId = freezed,}) {
  return _then(_self.copyWith(
installId: null == installId ? _self.installId : installId // ignore: cast_nullable_to_non_nullable
as InstallId,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,registeredTimezone: freezed == registeredTimezone ? _self.registeredTimezone : registeredTimezone // ignore: cast_nullable_to_non_nullable
as String?,trust: freezed == trust ? _self.trust : trust // ignore: cast_nullable_to_non_nullable
as Trust?,purchaseBinding: freezed == purchaseBinding ? _self.purchaseBinding : purchaseBinding // ignore: cast_nullable_to_non_nullable
as PurchaseBinding?,attestationKeyId: freezed == attestationKeyId ? _self.attestationKeyId : attestationKeyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseBindingCopyWith<$Res>? get purchaseBinding {
    if (_self.purchaseBinding == null) {
    return null;
  }

  return $PurchaseBindingCopyWith<$Res>(_self.purchaseBinding!, (value) {
    return _then(_self.copyWith(purchaseBinding: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstallIdentity].
extension InstallIdentityPatterns on InstallIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallIdentity value)  $default,){
final _that = this;
switch (_that) {
case _InstallIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _InstallIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InstallId installId,  DateTime? registeredAt,  String? registeredTimezone,  Trust? trust,  PurchaseBinding? purchaseBinding,  String? attestationKeyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallIdentity() when $default != null:
return $default(_that.installId,_that.registeredAt,_that.registeredTimezone,_that.trust,_that.purchaseBinding,_that.attestationKeyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InstallId installId,  DateTime? registeredAt,  String? registeredTimezone,  Trust? trust,  PurchaseBinding? purchaseBinding,  String? attestationKeyId)  $default,) {final _that = this;
switch (_that) {
case _InstallIdentity():
return $default(_that.installId,_that.registeredAt,_that.registeredTimezone,_that.trust,_that.purchaseBinding,_that.attestationKeyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InstallId installId,  DateTime? registeredAt,  String? registeredTimezone,  Trust? trust,  PurchaseBinding? purchaseBinding,  String? attestationKeyId)?  $default,) {final _that = this;
switch (_that) {
case _InstallIdentity() when $default != null:
return $default(_that.installId,_that.registeredAt,_that.registeredTimezone,_that.trust,_that.purchaseBinding,_that.attestationKeyId);case _:
  return null;

}
}

}

/// @nodoc


class _InstallIdentity extends InstallIdentity {
  const _InstallIdentity({required this.installId, this.registeredAt, this.registeredTimezone, this.trust, this.purchaseBinding, this.attestationKeyId}): super._();
  

/// The install ID (never logged).
@override final  InstallId installId;
/// When registration with the Worker succeeded.
@override final  DateTime? registeredAt;
/// The IANA timezone sent at registration.
@override final  String? registeredTimezone;
/// Trust level from registration.
@override final  Trust? trust;
/// Purchase binding from registration.
@override final  PurchaseBinding? purchaseBinding;
/// App Attest key ID (iOS).
@override final  String? attestationKeyId;

/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallIdentityCopyWith<_InstallIdentity> get copyWith => __$InstallIdentityCopyWithImpl<_InstallIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallIdentity&&(identical(other.installId, installId) || other.installId == installId)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.registeredTimezone, registeredTimezone) || other.registeredTimezone == registeredTimezone)&&(identical(other.trust, trust) || other.trust == trust)&&(identical(other.purchaseBinding, purchaseBinding) || other.purchaseBinding == purchaseBinding)&&(identical(other.attestationKeyId, attestationKeyId) || other.attestationKeyId == attestationKeyId));
}


@override
int get hashCode => Object.hash(runtimeType,installId,registeredAt,registeredTimezone,trust,purchaseBinding,attestationKeyId);

@override
String toString() {
  return 'InstallIdentity(installId: $installId, registeredAt: $registeredAt, registeredTimezone: $registeredTimezone, trust: $trust, purchaseBinding: $purchaseBinding, attestationKeyId: $attestationKeyId)';
}


}

/// @nodoc
abstract mixin class _$InstallIdentityCopyWith<$Res> implements $InstallIdentityCopyWith<$Res> {
  factory _$InstallIdentityCopyWith(_InstallIdentity value, $Res Function(_InstallIdentity) _then) = __$InstallIdentityCopyWithImpl;
@override @useResult
$Res call({
 InstallId installId, DateTime? registeredAt, String? registeredTimezone, Trust? trust, PurchaseBinding? purchaseBinding, String? attestationKeyId
});


@override $PurchaseBindingCopyWith<$Res>? get purchaseBinding;

}
/// @nodoc
class __$InstallIdentityCopyWithImpl<$Res>
    implements _$InstallIdentityCopyWith<$Res> {
  __$InstallIdentityCopyWithImpl(this._self, this._then);

  final _InstallIdentity _self;
  final $Res Function(_InstallIdentity) _then;

/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installId = null,Object? registeredAt = freezed,Object? registeredTimezone = freezed,Object? trust = freezed,Object? purchaseBinding = freezed,Object? attestationKeyId = freezed,}) {
  return _then(_InstallIdentity(
installId: null == installId ? _self.installId : installId // ignore: cast_nullable_to_non_nullable
as InstallId,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,registeredTimezone: freezed == registeredTimezone ? _self.registeredTimezone : registeredTimezone // ignore: cast_nullable_to_non_nullable
as String?,trust: freezed == trust ? _self.trust : trust // ignore: cast_nullable_to_non_nullable
as Trust?,purchaseBinding: freezed == purchaseBinding ? _self.purchaseBinding : purchaseBinding // ignore: cast_nullable_to_non_nullable
as PurchaseBinding?,attestationKeyId: freezed == attestationKeyId ? _self.attestationKeyId : attestationKeyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of InstallIdentity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseBindingCopyWith<$Res>? get purchaseBinding {
    if (_self.purchaseBinding == null) {
    return null;
  }

  return $PurchaseBindingCopyWith<$Res>(_self.purchaseBinding!, (value) {
    return _then(_self.copyWith(purchaseBinding: value));
  });
}
}

// dart format on
