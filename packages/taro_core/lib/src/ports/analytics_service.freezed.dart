// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AnalyticsConsent {

/// `analytics_storage`.
 bool get analyticsStorage;/// `ad_storage`.
 bool get adStorage;/// `ad_user_data`.
 bool get adUserData;/// `ad_personalization`.
 bool get adPersonalization;
/// Create a copy of AnalyticsConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsConsentCopyWith<AnalyticsConsent> get copyWith => _$AnalyticsConsentCopyWithImpl<AnalyticsConsent>(this as AnalyticsConsent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsConsent&&(identical(other.analyticsStorage, analyticsStorage) || other.analyticsStorage == analyticsStorage)&&(identical(other.adStorage, adStorage) || other.adStorage == adStorage)&&(identical(other.adUserData, adUserData) || other.adUserData == adUserData)&&(identical(other.adPersonalization, adPersonalization) || other.adPersonalization == adPersonalization));
}


@override
int get hashCode => Object.hash(runtimeType,analyticsStorage,adStorage,adUserData,adPersonalization);

@override
String toString() {
  return 'AnalyticsConsent(analyticsStorage: $analyticsStorage, adStorage: $adStorage, adUserData: $adUserData, adPersonalization: $adPersonalization)';
}


}

/// @nodoc
abstract mixin class $AnalyticsConsentCopyWith<$Res>  {
  factory $AnalyticsConsentCopyWith(AnalyticsConsent value, $Res Function(AnalyticsConsent) _then) = _$AnalyticsConsentCopyWithImpl;
@useResult
$Res call({
 bool analyticsStorage, bool adStorage, bool adUserData, bool adPersonalization
});




}
/// @nodoc
class _$AnalyticsConsentCopyWithImpl<$Res>
    implements $AnalyticsConsentCopyWith<$Res> {
  _$AnalyticsConsentCopyWithImpl(this._self, this._then);

  final AnalyticsConsent _self;
  final $Res Function(AnalyticsConsent) _then;

/// Create a copy of AnalyticsConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? analyticsStorage = null,Object? adStorage = null,Object? adUserData = null,Object? adPersonalization = null,}) {
  return _then(_self.copyWith(
analyticsStorage: null == analyticsStorage ? _self.analyticsStorage : analyticsStorage // ignore: cast_nullable_to_non_nullable
as bool,adStorage: null == adStorage ? _self.adStorage : adStorage // ignore: cast_nullable_to_non_nullable
as bool,adUserData: null == adUserData ? _self.adUserData : adUserData // ignore: cast_nullable_to_non_nullable
as bool,adPersonalization: null == adPersonalization ? _self.adPersonalization : adPersonalization // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsConsent].
extension AnalyticsConsentPatterns on AnalyticsConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsConsent value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsConsent value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool analyticsStorage,  bool adStorage,  bool adUserData,  bool adPersonalization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsConsent() when $default != null:
return $default(_that.analyticsStorage,_that.adStorage,_that.adUserData,_that.adPersonalization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool analyticsStorage,  bool adStorage,  bool adUserData,  bool adPersonalization)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsConsent():
return $default(_that.analyticsStorage,_that.adStorage,_that.adUserData,_that.adPersonalization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool analyticsStorage,  bool adStorage,  bool adUserData,  bool adPersonalization)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsConsent() when $default != null:
return $default(_that.analyticsStorage,_that.adStorage,_that.adUserData,_that.adPersonalization);case _:
  return null;

}
}

}

/// @nodoc


class _AnalyticsConsent implements AnalyticsConsent {
  const _AnalyticsConsent({required this.analyticsStorage, required this.adStorage, required this.adUserData, required this.adPersonalization});
  

/// `analytics_storage`.
@override final  bool analyticsStorage;
/// `ad_storage`.
@override final  bool adStorage;
/// `ad_user_data`.
@override final  bool adUserData;
/// `ad_personalization`.
@override final  bool adPersonalization;

/// Create a copy of AnalyticsConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsConsentCopyWith<_AnalyticsConsent> get copyWith => __$AnalyticsConsentCopyWithImpl<_AnalyticsConsent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsConsent&&(identical(other.analyticsStorage, analyticsStorage) || other.analyticsStorage == analyticsStorage)&&(identical(other.adStorage, adStorage) || other.adStorage == adStorage)&&(identical(other.adUserData, adUserData) || other.adUserData == adUserData)&&(identical(other.adPersonalization, adPersonalization) || other.adPersonalization == adPersonalization));
}


@override
int get hashCode => Object.hash(runtimeType,analyticsStorage,adStorage,adUserData,adPersonalization);

@override
String toString() {
  return 'AnalyticsConsent(analyticsStorage: $analyticsStorage, adStorage: $adStorage, adUserData: $adUserData, adPersonalization: $adPersonalization)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsConsentCopyWith<$Res> implements $AnalyticsConsentCopyWith<$Res> {
  factory _$AnalyticsConsentCopyWith(_AnalyticsConsent value, $Res Function(_AnalyticsConsent) _then) = __$AnalyticsConsentCopyWithImpl;
@override @useResult
$Res call({
 bool analyticsStorage, bool adStorage, bool adUserData, bool adPersonalization
});




}
/// @nodoc
class __$AnalyticsConsentCopyWithImpl<$Res>
    implements _$AnalyticsConsentCopyWith<$Res> {
  __$AnalyticsConsentCopyWithImpl(this._self, this._then);

  final _AnalyticsConsent _self;
  final $Res Function(_AnalyticsConsent) _then;

/// Create a copy of AnalyticsConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? analyticsStorage = null,Object? adStorage = null,Object? adUserData = null,Object? adPersonalization = null,}) {
  return _then(_AnalyticsConsent(
analyticsStorage: null == analyticsStorage ? _self.analyticsStorage : analyticsStorage // ignore: cast_nullable_to_non_nullable
as bool,adStorage: null == adStorage ? _self.adStorage : adStorage // ignore: cast_nullable_to_non_nullable
as bool,adUserData: null == adUserData ? _self.adUserData : adUserData // ignore: cast_nullable_to_non_nullable
as bool,adPersonalization: null == adPersonalization ? _self.adPersonalization : adPersonalization // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
