// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entitlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Entitlement {

/// Remove Banner Ads ownership.
 EntitlementState get removeAds;/// Where [removeAds] came from.
 EntitlementSource get source;/// When the store last confirmed it.
 DateTime? get verifiedAt;
/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntitlementCopyWith<Entitlement> get copyWith => _$EntitlementCopyWithImpl<Entitlement>(this as Entitlement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Entitlement&&(identical(other.removeAds, removeAds) || other.removeAds == removeAds)&&(identical(other.source, source) || other.source == source)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,removeAds,source,verifiedAt);

@override
String toString() {
  return 'Entitlement(removeAds: $removeAds, source: $source, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class $EntitlementCopyWith<$Res>  {
  factory $EntitlementCopyWith(Entitlement value, $Res Function(Entitlement) _then) = _$EntitlementCopyWithImpl;
@useResult
$Res call({
 EntitlementState removeAds, EntitlementSource source, DateTime? verifiedAt
});




}
/// @nodoc
class _$EntitlementCopyWithImpl<$Res>
    implements $EntitlementCopyWith<$Res> {
  _$EntitlementCopyWithImpl(this._self, this._then);

  final Entitlement _self;
  final $Res Function(Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? removeAds = null,Object? source = null,Object? verifiedAt = freezed,}) {
  return _then(_self.copyWith(
removeAds: null == removeAds ? _self.removeAds : removeAds // ignore: cast_nullable_to_non_nullable
as EntitlementState,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EntitlementSource,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Entitlement].
extension EntitlementPatterns on Entitlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Entitlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Entitlement value)  $default,){
final _that = this;
switch (_that) {
case _Entitlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Entitlement value)?  $default,){
final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntitlementState removeAds,  EntitlementSource source,  DateTime? verifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.removeAds,_that.source,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntitlementState removeAds,  EntitlementSource source,  DateTime? verifiedAt)  $default,) {final _that = this;
switch (_that) {
case _Entitlement():
return $default(_that.removeAds,_that.source,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntitlementState removeAds,  EntitlementSource source,  DateTime? verifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _Entitlement() when $default != null:
return $default(_that.removeAds,_that.source,_that.verifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Entitlement extends Entitlement {
  const _Entitlement({required this.removeAds, required this.source, this.verifiedAt}): super._();
  

/// Remove Banner Ads ownership.
@override final  EntitlementState removeAds;
/// Where [removeAds] came from.
@override final  EntitlementSource source;
/// When the store last confirmed it.
@override final  DateTime? verifiedAt;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntitlementCopyWith<_Entitlement> get copyWith => __$EntitlementCopyWithImpl<_Entitlement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Entitlement&&(identical(other.removeAds, removeAds) || other.removeAds == removeAds)&&(identical(other.source, source) || other.source == source)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,removeAds,source,verifiedAt);

@override
String toString() {
  return 'Entitlement(removeAds: $removeAds, source: $source, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class _$EntitlementCopyWith<$Res> implements $EntitlementCopyWith<$Res> {
  factory _$EntitlementCopyWith(_Entitlement value, $Res Function(_Entitlement) _then) = __$EntitlementCopyWithImpl;
@override @useResult
$Res call({
 EntitlementState removeAds, EntitlementSource source, DateTime? verifiedAt
});




}
/// @nodoc
class __$EntitlementCopyWithImpl<$Res>
    implements _$EntitlementCopyWith<$Res> {
  __$EntitlementCopyWithImpl(this._self, this._then);

  final _Entitlement _self;
  final $Res Function(_Entitlement) _then;

/// Create a copy of Entitlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? removeAds = null,Object? source = null,Object? verifiedAt = freezed,}) {
  return _then(_Entitlement(
removeAds: null == removeAds ? _self.removeAds : removeAds // ignore: cast_nullable_to_non_nullable
as EntitlementState,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EntitlementSource,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
