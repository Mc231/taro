// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attestation_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AttestationBlob {

/// The attestation kind.
 AttestationType get type;/// The challenge it answers.
 String get challenge;/// The platform attestation object or integrity token (base64url).
 String? get payload;/// The App Attest key ID (iOS).
 String? get keyId;
/// Create a copy of AttestationBlob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttestationBlobCopyWith<AttestationBlob> get copyWith => _$AttestationBlobCopyWithImpl<AttestationBlob>(this as AttestationBlob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttestationBlob&&(identical(other.type, type) || other.type == type)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.keyId, keyId) || other.keyId == keyId));
}


@override
int get hashCode => Object.hash(runtimeType,type,challenge,payload,keyId);

@override
String toString() {
  return 'AttestationBlob(type: $type, challenge: $challenge, payload: $payload, keyId: $keyId)';
}


}

/// @nodoc
abstract mixin class $AttestationBlobCopyWith<$Res>  {
  factory $AttestationBlobCopyWith(AttestationBlob value, $Res Function(AttestationBlob) _then) = _$AttestationBlobCopyWithImpl;
@useResult
$Res call({
 AttestationType type, String challenge, String? payload, String? keyId
});




}
/// @nodoc
class _$AttestationBlobCopyWithImpl<$Res>
    implements $AttestationBlobCopyWith<$Res> {
  _$AttestationBlobCopyWithImpl(this._self, this._then);

  final AttestationBlob _self;
  final $Res Function(AttestationBlob) _then;

/// Create a copy of AttestationBlob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? challenge = null,Object? payload = freezed,Object? keyId = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AttestationType,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttestationBlob].
extension AttestationBlobPatterns on AttestationBlob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttestationBlob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttestationBlob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttestationBlob value)  $default,){
final _that = this;
switch (_that) {
case _AttestationBlob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttestationBlob value)?  $default,){
final _that = this;
switch (_that) {
case _AttestationBlob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AttestationType type,  String challenge,  String? payload,  String? keyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttestationBlob() when $default != null:
return $default(_that.type,_that.challenge,_that.payload,_that.keyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AttestationType type,  String challenge,  String? payload,  String? keyId)  $default,) {final _that = this;
switch (_that) {
case _AttestationBlob():
return $default(_that.type,_that.challenge,_that.payload,_that.keyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AttestationType type,  String challenge,  String? payload,  String? keyId)?  $default,) {final _that = this;
switch (_that) {
case _AttestationBlob() when $default != null:
return $default(_that.type,_that.challenge,_that.payload,_that.keyId);case _:
  return null;

}
}

}

/// @nodoc


class _AttestationBlob implements AttestationBlob {
  const _AttestationBlob({required this.type, required this.challenge, this.payload, this.keyId});
  

/// The attestation kind.
@override final  AttestationType type;
/// The challenge it answers.
@override final  String challenge;
/// The platform attestation object or integrity token (base64url).
@override final  String? payload;
/// The App Attest key ID (iOS).
@override final  String? keyId;

/// Create a copy of AttestationBlob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttestationBlobCopyWith<_AttestationBlob> get copyWith => __$AttestationBlobCopyWithImpl<_AttestationBlob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttestationBlob&&(identical(other.type, type) || other.type == type)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.keyId, keyId) || other.keyId == keyId));
}


@override
int get hashCode => Object.hash(runtimeType,type,challenge,payload,keyId);

@override
String toString() {
  return 'AttestationBlob(type: $type, challenge: $challenge, payload: $payload, keyId: $keyId)';
}


}

/// @nodoc
abstract mixin class _$AttestationBlobCopyWith<$Res> implements $AttestationBlobCopyWith<$Res> {
  factory _$AttestationBlobCopyWith(_AttestationBlob value, $Res Function(_AttestationBlob) _then) = __$AttestationBlobCopyWithImpl;
@override @useResult
$Res call({
 AttestationType type, String challenge, String? payload, String? keyId
});




}
/// @nodoc
class __$AttestationBlobCopyWithImpl<$Res>
    implements _$AttestationBlobCopyWith<$Res> {
  __$AttestationBlobCopyWithImpl(this._self, this._then);

  final _AttestationBlob _self;
  final $Res Function(_AttestationBlob) _then;

/// Create a copy of AttestationBlob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? challenge = null,Object? payload = freezed,Object? keyId = freezed,}) {
  return _then(_AttestationBlob(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AttestationType,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as String,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AssertionBlob {

/// The full header value: `aa1.<assertion>`, `pi1.<token>` or `none`.
 String get header;
/// Create a copy of AssertionBlob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssertionBlobCopyWith<AssertionBlob> get copyWith => _$AssertionBlobCopyWithImpl<AssertionBlob>(this as AssertionBlob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssertionBlob&&(identical(other.header, header) || other.header == header));
}


@override
int get hashCode => Object.hash(runtimeType,header);

@override
String toString() {
  return 'AssertionBlob(header: $header)';
}


}

/// @nodoc
abstract mixin class $AssertionBlobCopyWith<$Res>  {
  factory $AssertionBlobCopyWith(AssertionBlob value, $Res Function(AssertionBlob) _then) = _$AssertionBlobCopyWithImpl;
@useResult
$Res call({
 String header
});




}
/// @nodoc
class _$AssertionBlobCopyWithImpl<$Res>
    implements $AssertionBlobCopyWith<$Res> {
  _$AssertionBlobCopyWithImpl(this._self, this._then);

  final AssertionBlob _self;
  final $Res Function(AssertionBlob) _then;

/// Create a copy of AssertionBlob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? header = null,}) {
  return _then(_self.copyWith(
header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AssertionBlob].
extension AssertionBlobPatterns on AssertionBlob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssertionBlob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssertionBlob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssertionBlob value)  $default,){
final _that = this;
switch (_that) {
case _AssertionBlob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssertionBlob value)?  $default,){
final _that = this;
switch (_that) {
case _AssertionBlob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String header)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssertionBlob() when $default != null:
return $default(_that.header);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String header)  $default,) {final _that = this;
switch (_that) {
case _AssertionBlob():
return $default(_that.header);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String header)?  $default,) {final _that = this;
switch (_that) {
case _AssertionBlob() when $default != null:
return $default(_that.header);case _:
  return null;

}
}

}

/// @nodoc


class _AssertionBlob implements AssertionBlob {
  const _AssertionBlob({required this.header});
  

/// The full header value: `aa1.<assertion>`, `pi1.<token>` or `none`.
@override final  String header;

/// Create a copy of AssertionBlob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssertionBlobCopyWith<_AssertionBlob> get copyWith => __$AssertionBlobCopyWithImpl<_AssertionBlob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssertionBlob&&(identical(other.header, header) || other.header == header));
}


@override
int get hashCode => Object.hash(runtimeType,header);

@override
String toString() {
  return 'AssertionBlob(header: $header)';
}


}

/// @nodoc
abstract mixin class _$AssertionBlobCopyWith<$Res> implements $AssertionBlobCopyWith<$Res> {
  factory _$AssertionBlobCopyWith(_AssertionBlob value, $Res Function(_AssertionBlob) _then) = __$AssertionBlobCopyWithImpl;
@override @useResult
$Res call({
 String header
});




}
/// @nodoc
class __$AssertionBlobCopyWithImpl<$Res>
    implements _$AssertionBlobCopyWith<$Res> {
  __$AssertionBlobCopyWithImpl(this._self, this._then);

  final _AssertionBlob _self;
  final $Res Function(_AssertionBlob) _then;

/// Create a copy of AssertionBlob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? header = null,}) {
  return _then(_AssertionBlob(
header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DeviceSignal {

/// Android `deviceKey`.
 String? get deviceKey;/// iOS DeviceCheck token.
 String? get deviceCheckToken;
/// Create a copy of DeviceSignal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceSignalCopyWith<DeviceSignal> get copyWith => _$DeviceSignalCopyWithImpl<DeviceSignal>(this as DeviceSignal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceSignal&&(identical(other.deviceKey, deviceKey) || other.deviceKey == deviceKey)&&(identical(other.deviceCheckToken, deviceCheckToken) || other.deviceCheckToken == deviceCheckToken));
}


@override
int get hashCode => Object.hash(runtimeType,deviceKey,deviceCheckToken);

@override
String toString() {
  return 'DeviceSignal(deviceKey: $deviceKey, deviceCheckToken: $deviceCheckToken)';
}


}

/// @nodoc
abstract mixin class $DeviceSignalCopyWith<$Res>  {
  factory $DeviceSignalCopyWith(DeviceSignal value, $Res Function(DeviceSignal) _then) = _$DeviceSignalCopyWithImpl;
@useResult
$Res call({
 String? deviceKey, String? deviceCheckToken
});




}
/// @nodoc
class _$DeviceSignalCopyWithImpl<$Res>
    implements $DeviceSignalCopyWith<$Res> {
  _$DeviceSignalCopyWithImpl(this._self, this._then);

  final DeviceSignal _self;
  final $Res Function(DeviceSignal) _then;

/// Create a copy of DeviceSignal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceKey = freezed,Object? deviceCheckToken = freezed,}) {
  return _then(_self.copyWith(
deviceKey: freezed == deviceKey ? _self.deviceKey : deviceKey // ignore: cast_nullable_to_non_nullable
as String?,deviceCheckToken: freezed == deviceCheckToken ? _self.deviceCheckToken : deviceCheckToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceSignal].
extension DeviceSignalPatterns on DeviceSignal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceSignal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceSignal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceSignal value)  $default,){
final _that = this;
switch (_that) {
case _DeviceSignal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceSignal value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceSignal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? deviceKey,  String? deviceCheckToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceSignal() when $default != null:
return $default(_that.deviceKey,_that.deviceCheckToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? deviceKey,  String? deviceCheckToken)  $default,) {final _that = this;
switch (_that) {
case _DeviceSignal():
return $default(_that.deviceKey,_that.deviceCheckToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? deviceKey,  String? deviceCheckToken)?  $default,) {final _that = this;
switch (_that) {
case _DeviceSignal() when $default != null:
return $default(_that.deviceKey,_that.deviceCheckToken);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceSignal implements DeviceSignal {
  const _DeviceSignal({this.deviceKey, this.deviceCheckToken});
  

/// Android `deviceKey`.
@override final  String? deviceKey;
/// iOS DeviceCheck token.
@override final  String? deviceCheckToken;

/// Create a copy of DeviceSignal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceSignalCopyWith<_DeviceSignal> get copyWith => __$DeviceSignalCopyWithImpl<_DeviceSignal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceSignal&&(identical(other.deviceKey, deviceKey) || other.deviceKey == deviceKey)&&(identical(other.deviceCheckToken, deviceCheckToken) || other.deviceCheckToken == deviceCheckToken));
}


@override
int get hashCode => Object.hash(runtimeType,deviceKey,deviceCheckToken);

@override
String toString() {
  return 'DeviceSignal(deviceKey: $deviceKey, deviceCheckToken: $deviceCheckToken)';
}


}

/// @nodoc
abstract mixin class _$DeviceSignalCopyWith<$Res> implements $DeviceSignalCopyWith<$Res> {
  factory _$DeviceSignalCopyWith(_DeviceSignal value, $Res Function(_DeviceSignal) _then) = __$DeviceSignalCopyWithImpl;
@override @useResult
$Res call({
 String? deviceKey, String? deviceCheckToken
});




}
/// @nodoc
class __$DeviceSignalCopyWithImpl<$Res>
    implements _$DeviceSignalCopyWith<$Res> {
  __$DeviceSignalCopyWithImpl(this._self, this._then);

  final _DeviceSignal _self;
  final $Res Function(_DeviceSignal) _then;

/// Create a copy of DeviceSignal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceKey = freezed,Object? deviceCheckToken = freezed,}) {
  return _then(_DeviceSignal(
deviceKey: freezed == deviceKey ? _self.deviceKey : deviceKey // ignore: cast_nullable_to_non_nullable
as String?,deviceCheckToken: freezed == deviceCheckToken ? _self.deviceCheckToken : deviceCheckToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
