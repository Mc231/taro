// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_consent_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiConsentState {

 AiConsentOrigin get origin;
/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentStateCopyWith<AiConsentState> get copyWith => _$AiConsentStateCopyWithImpl<AiConsentState>(this as AiConsentState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsentState&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,origin);

@override
String toString() {
  return 'AiConsentState(origin: $origin)';
}


}

/// @nodoc
abstract mixin class $AiConsentStateCopyWith<$Res>  {
  factory $AiConsentStateCopyWith(AiConsentState value, $Res Function(AiConsentState) _then) = _$AiConsentStateCopyWithImpl;
@useResult
$Res call({
 AiConsentOrigin origin
});




}
/// @nodoc
class _$AiConsentStateCopyWithImpl<$Res>
    implements $AiConsentStateCopyWith<$Res> {
  _$AiConsentStateCopyWithImpl(this._self, this._then);

  final AiConsentState _self;
  final $Res Function(AiConsentState) _then;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? origin = null,}) {
  return _then(_self.copyWith(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as AiConsentOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [AiConsentState].
extension AiConsentStatePatterns on AiConsentState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AiConsentUndecided value)?  undecided,TResult Function( AiConsentGranted value)?  granted,TResult Function( AiConsentDeclined value)?  declined,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AiConsentUndecided() when undecided != null:
return undecided(_that);case AiConsentGranted() when granted != null:
return granted(_that);case AiConsentDeclined() when declined != null:
return declined(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AiConsentUndecided value)  undecided,required TResult Function( AiConsentGranted value)  granted,required TResult Function( AiConsentDeclined value)  declined,}){
final _that = this;
switch (_that) {
case AiConsentUndecided():
return undecided(_that);case AiConsentGranted():
return granted(_that);case AiConsentDeclined():
return declined(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AiConsentUndecided value)?  undecided,TResult? Function( AiConsentGranted value)?  granted,TResult? Function( AiConsentDeclined value)?  declined,}){
final _that = this;
switch (_that) {
case AiConsentUndecided() when undecided != null:
return undecided(_that);case AiConsentGranted() when granted != null:
return granted(_that);case AiConsentDeclined() when declined != null:
return declined(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AiConsentOrigin origin,  int version,  bool previouslyDeclined)?  undecided,TResult Function( AiConsentOrigin origin)?  granted,TResult Function( AiConsentOrigin origin)?  declined,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AiConsentUndecided() when undecided != null:
return undecided(_that.origin,_that.version,_that.previouslyDeclined);case AiConsentGranted() when granted != null:
return granted(_that.origin);case AiConsentDeclined() when declined != null:
return declined(_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AiConsentOrigin origin,  int version,  bool previouslyDeclined)  undecided,required TResult Function( AiConsentOrigin origin)  granted,required TResult Function( AiConsentOrigin origin)  declined,}) {final _that = this;
switch (_that) {
case AiConsentUndecided():
return undecided(_that.origin,_that.version,_that.previouslyDeclined);case AiConsentGranted():
return granted(_that.origin);case AiConsentDeclined():
return declined(_that.origin);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AiConsentOrigin origin,  int version,  bool previouslyDeclined)?  undecided,TResult? Function( AiConsentOrigin origin)?  granted,TResult? Function( AiConsentOrigin origin)?  declined,}) {final _that = this;
switch (_that) {
case AiConsentUndecided() when undecided != null:
return undecided(_that.origin,_that.version,_that.previouslyDeclined);case AiConsentGranted() when granted != null:
return granted(_that.origin);case AiConsentDeclined() when declined != null:
return declined(_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class AiConsentUndecided implements AiConsentState {
  const AiConsentUndecided({required this.origin, required this.version, this.previouslyDeclined = false});
  

@override final  AiConsentOrigin origin;
 final  int version;
@JsonKey() final  bool previouslyDeclined;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentUndecidedCopyWith<AiConsentUndecided> get copyWith => _$AiConsentUndecidedCopyWithImpl<AiConsentUndecided>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsentUndecided&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.version, version) || other.version == version)&&(identical(other.previouslyDeclined, previouslyDeclined) || other.previouslyDeclined == previouslyDeclined));
}


@override
int get hashCode => Object.hash(runtimeType,origin,version,previouslyDeclined);

@override
String toString() {
  return 'AiConsentState.undecided(origin: $origin, version: $version, previouslyDeclined: $previouslyDeclined)';
}


}

/// @nodoc
abstract mixin class $AiConsentUndecidedCopyWith<$Res> implements $AiConsentStateCopyWith<$Res> {
  factory $AiConsentUndecidedCopyWith(AiConsentUndecided value, $Res Function(AiConsentUndecided) _then) = _$AiConsentUndecidedCopyWithImpl;
@override @useResult
$Res call({
 AiConsentOrigin origin, int version, bool previouslyDeclined
});




}
/// @nodoc
class _$AiConsentUndecidedCopyWithImpl<$Res>
    implements $AiConsentUndecidedCopyWith<$Res> {
  _$AiConsentUndecidedCopyWithImpl(this._self, this._then);

  final AiConsentUndecided _self;
  final $Res Function(AiConsentUndecided) _then;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? origin = null,Object? version = null,Object? previouslyDeclined = null,}) {
  return _then(AiConsentUndecided(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as AiConsentOrigin,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,previouslyDeclined: null == previouslyDeclined ? _self.previouslyDeclined : previouslyDeclined // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AiConsentGranted implements AiConsentState {
  const AiConsentGranted({required this.origin});
  

@override final  AiConsentOrigin origin;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentGrantedCopyWith<AiConsentGranted> get copyWith => _$AiConsentGrantedCopyWithImpl<AiConsentGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsentGranted&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,origin);

@override
String toString() {
  return 'AiConsentState.granted(origin: $origin)';
}


}

/// @nodoc
abstract mixin class $AiConsentGrantedCopyWith<$Res> implements $AiConsentStateCopyWith<$Res> {
  factory $AiConsentGrantedCopyWith(AiConsentGranted value, $Res Function(AiConsentGranted) _then) = _$AiConsentGrantedCopyWithImpl;
@override @useResult
$Res call({
 AiConsentOrigin origin
});




}
/// @nodoc
class _$AiConsentGrantedCopyWithImpl<$Res>
    implements $AiConsentGrantedCopyWith<$Res> {
  _$AiConsentGrantedCopyWithImpl(this._self, this._then);

  final AiConsentGranted _self;
  final $Res Function(AiConsentGranted) _then;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? origin = null,}) {
  return _then(AiConsentGranted(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as AiConsentOrigin,
  ));
}


}

/// @nodoc


class AiConsentDeclined implements AiConsentState {
  const AiConsentDeclined({required this.origin});
  

@override final  AiConsentOrigin origin;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentDeclinedCopyWith<AiConsentDeclined> get copyWith => _$AiConsentDeclinedCopyWithImpl<AiConsentDeclined>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsentDeclined&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,origin);

@override
String toString() {
  return 'AiConsentState.declined(origin: $origin)';
}


}

/// @nodoc
abstract mixin class $AiConsentDeclinedCopyWith<$Res> implements $AiConsentStateCopyWith<$Res> {
  factory $AiConsentDeclinedCopyWith(AiConsentDeclined value, $Res Function(AiConsentDeclined) _then) = _$AiConsentDeclinedCopyWithImpl;
@override @useResult
$Res call({
 AiConsentOrigin origin
});




}
/// @nodoc
class _$AiConsentDeclinedCopyWithImpl<$Res>
    implements $AiConsentDeclinedCopyWith<$Res> {
  _$AiConsentDeclinedCopyWithImpl(this._self, this._then);

  final AiConsentDeclined _self;
  final $Res Function(AiConsentDeclined) _then;

/// Create a copy of AiConsentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? origin = null,}) {
  return _then(AiConsentDeclined(
origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as AiConsentOrigin,
  ));
}


}

// dart format on
