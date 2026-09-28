// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_token_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionToken {

/// The `installToken` JWT. Never logged.
 String get token;/// When the Worker says it expires (UTC).
 DateTime get expiresAt;
/// Create a copy of SessionToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionTokenCopyWith<SessionToken> get copyWith => _$SessionTokenCopyWithImpl<SessionToken>(this as SessionToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionToken&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,expiresAt);

@override
String toString() {
  return 'SessionToken(token: $token, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $SessionTokenCopyWith<$Res>  {
  factory $SessionTokenCopyWith(SessionToken value, $Res Function(SessionToken) _then) = _$SessionTokenCopyWithImpl;
@useResult
$Res call({
 String token, DateTime expiresAt
});




}
/// @nodoc
class _$SessionTokenCopyWithImpl<$Res>
    implements $SessionTokenCopyWith<$Res> {
  _$SessionTokenCopyWithImpl(this._self, this._then);

  final SessionToken _self;
  final $Res Function(SessionToken) _then;

/// Create a copy of SessionToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionToken].
extension SessionTokenPatterns on SessionToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionToken value)  $default,){
final _that = this;
switch (_that) {
case _SessionToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionToken value)?  $default,){
final _that = this;
switch (_that) {
case _SessionToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionToken() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _SessionToken():
return $default(_that.token,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionToken() when $default != null:
return $default(_that.token,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _SessionToken extends SessionToken {
  const _SessionToken({required this.token, required this.expiresAt}): super._();
  

/// The `installToken` JWT. Never logged.
@override final  String token;
/// When the Worker says it expires (UTC).
@override final  DateTime expiresAt;

/// Create a copy of SessionToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionTokenCopyWith<_SessionToken> get copyWith => __$SessionTokenCopyWithImpl<_SessionToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionToken&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,expiresAt);

@override
String toString() {
  return 'SessionToken(token: $token, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$SessionTokenCopyWith<$Res> implements $SessionTokenCopyWith<$Res> {
  factory _$SessionTokenCopyWith(_SessionToken value, $Res Function(_SessionToken) _then) = __$SessionTokenCopyWithImpl;
@override @useResult
$Res call({
 String token, DateTime expiresAt
});




}
/// @nodoc
class __$SessionTokenCopyWithImpl<$Res>
    implements _$SessionTokenCopyWith<$Res> {
  __$SessionTokenCopyWithImpl(this._self, this._then);

  final _SessionToken _self;
  final $Res Function(_SessionToken) _then;

/// Create a copy of SessionToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = null,}) {
  return _then(_SessionToken(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
