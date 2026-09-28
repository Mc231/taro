// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ads_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdRequestPolicy {

/// Banners may be requested (`ads.enabled`, `ads.bannerEnabled`, Remove
/// Banner Ads not owned).
 bool get bannersEnabled;/// Rewarded ads may be requested (`ads.enabled`, `rewarded.enabled`).
 bool get rewardedEnabled;
/// Create a copy of AdRequestPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdRequestPolicyCopyWith<AdRequestPolicy> get copyWith => _$AdRequestPolicyCopyWithImpl<AdRequestPolicy>(this as AdRequestPolicy, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdRequestPolicy&&(identical(other.bannersEnabled, bannersEnabled) || other.bannersEnabled == bannersEnabled)&&(identical(other.rewardedEnabled, rewardedEnabled) || other.rewardedEnabled == rewardedEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,bannersEnabled,rewardedEnabled);

@override
String toString() {
  return 'AdRequestPolicy(bannersEnabled: $bannersEnabled, rewardedEnabled: $rewardedEnabled)';
}


}

/// @nodoc
abstract mixin class $AdRequestPolicyCopyWith<$Res>  {
  factory $AdRequestPolicyCopyWith(AdRequestPolicy value, $Res Function(AdRequestPolicy) _then) = _$AdRequestPolicyCopyWithImpl;
@useResult
$Res call({
 bool bannersEnabled, bool rewardedEnabled
});




}
/// @nodoc
class _$AdRequestPolicyCopyWithImpl<$Res>
    implements $AdRequestPolicyCopyWith<$Res> {
  _$AdRequestPolicyCopyWithImpl(this._self, this._then);

  final AdRequestPolicy _self;
  final $Res Function(AdRequestPolicy) _then;

/// Create a copy of AdRequestPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bannersEnabled = null,Object? rewardedEnabled = null,}) {
  return _then(_self.copyWith(
bannersEnabled: null == bannersEnabled ? _self.bannersEnabled : bannersEnabled // ignore: cast_nullable_to_non_nullable
as bool,rewardedEnabled: null == rewardedEnabled ? _self.rewardedEnabled : rewardedEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdRequestPolicy].
extension AdRequestPolicyPatterns on AdRequestPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdRequestPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdRequestPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdRequestPolicy value)  $default,){
final _that = this;
switch (_that) {
case _AdRequestPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdRequestPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _AdRequestPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool bannersEnabled,  bool rewardedEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdRequestPolicy() when $default != null:
return $default(_that.bannersEnabled,_that.rewardedEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool bannersEnabled,  bool rewardedEnabled)  $default,) {final _that = this;
switch (_that) {
case _AdRequestPolicy():
return $default(_that.bannersEnabled,_that.rewardedEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool bannersEnabled,  bool rewardedEnabled)?  $default,) {final _that = this;
switch (_that) {
case _AdRequestPolicy() when $default != null:
return $default(_that.bannersEnabled,_that.rewardedEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _AdRequestPolicy extends AdRequestPolicy {
  const _AdRequestPolicy({required this.bannersEnabled, required this.rewardedEnabled}): super._();
  

/// Banners may be requested (`ads.enabled`, `ads.bannerEnabled`, Remove
/// Banner Ads not owned).
@override final  bool bannersEnabled;
/// Rewarded ads may be requested (`ads.enabled`, `rewarded.enabled`).
@override final  bool rewardedEnabled;

/// Create a copy of AdRequestPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdRequestPolicyCopyWith<_AdRequestPolicy> get copyWith => __$AdRequestPolicyCopyWithImpl<_AdRequestPolicy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdRequestPolicy&&(identical(other.bannersEnabled, bannersEnabled) || other.bannersEnabled == bannersEnabled)&&(identical(other.rewardedEnabled, rewardedEnabled) || other.rewardedEnabled == rewardedEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,bannersEnabled,rewardedEnabled);

@override
String toString() {
  return 'AdRequestPolicy(bannersEnabled: $bannersEnabled, rewardedEnabled: $rewardedEnabled)';
}


}

/// @nodoc
abstract mixin class _$AdRequestPolicyCopyWith<$Res> implements $AdRequestPolicyCopyWith<$Res> {
  factory _$AdRequestPolicyCopyWith(_AdRequestPolicy value, $Res Function(_AdRequestPolicy) _then) = __$AdRequestPolicyCopyWithImpl;
@override @useResult
$Res call({
 bool bannersEnabled, bool rewardedEnabled
});




}
/// @nodoc
class __$AdRequestPolicyCopyWithImpl<$Res>
    implements _$AdRequestPolicyCopyWith<$Res> {
  __$AdRequestPolicyCopyWithImpl(this._self, this._then);

  final _AdRequestPolicy _self;
  final $Res Function(_AdRequestPolicy) _then;

/// Create a copy of AdRequestPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bannersEnabled = null,Object? rewardedEnabled = null,}) {
  return _then(_AdRequestPolicy(
bannersEnabled: null == bannersEnabled ? _self.bannersEnabled : bannersEnabled // ignore: cast_nullable_to_non_nullable
as bool,rewardedEnabled: null == rewardedEnabled ? _self.rewardedEnabled : rewardedEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
