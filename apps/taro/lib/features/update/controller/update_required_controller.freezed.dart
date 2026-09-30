// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_required_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateRequiredState {

 AppPlatform get platform; String get installedVersion; String get minVersion;
/// Create a copy of UpdateRequiredState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateRequiredStateCopyWith<UpdateRequiredState> get copyWith => _$UpdateRequiredStateCopyWithImpl<UpdateRequiredState>(this as UpdateRequiredState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequiredState&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion));
}


@override
int get hashCode => Object.hash(runtimeType,platform,installedVersion,minVersion);

@override
String toString() {
  return 'UpdateRequiredState(platform: $platform, installedVersion: $installedVersion, minVersion: $minVersion)';
}


}

/// @nodoc
abstract mixin class $UpdateRequiredStateCopyWith<$Res>  {
  factory $UpdateRequiredStateCopyWith(UpdateRequiredState value, $Res Function(UpdateRequiredState) _then) = _$UpdateRequiredStateCopyWithImpl;
@useResult
$Res call({
 AppPlatform platform, String installedVersion, String minVersion
});




}
/// @nodoc
class _$UpdateRequiredStateCopyWithImpl<$Res>
    implements $UpdateRequiredStateCopyWith<$Res> {
  _$UpdateRequiredStateCopyWithImpl(this._self, this._then);

  final UpdateRequiredState _self;
  final $Res Function(UpdateRequiredState) _then;

/// Create a copy of UpdateRequiredState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? installedVersion = null,Object? minVersion = null,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as AppPlatform,installedVersion: null == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String,minVersion: null == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateRequiredState].
extension UpdateRequiredStatePatterns on UpdateRequiredState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateRequiredContent value)?  content,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateRequiredContent() when content != null:
return content(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateRequiredContent value)  content,}){
final _that = this;
switch (_that) {
case UpdateRequiredContent():
return content(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateRequiredContent value)?  content,}){
final _that = this;
switch (_that) {
case UpdateRequiredContent() when content != null:
return content(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AppPlatform platform,  String installedVersion,  String minVersion)?  content,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateRequiredContent() when content != null:
return content(_that.platform,_that.installedVersion,_that.minVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AppPlatform platform,  String installedVersion,  String minVersion)  content,}) {final _that = this;
switch (_that) {
case UpdateRequiredContent():
return content(_that.platform,_that.installedVersion,_that.minVersion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AppPlatform platform,  String installedVersion,  String minVersion)?  content,}) {final _that = this;
switch (_that) {
case UpdateRequiredContent() when content != null:
return content(_that.platform,_that.installedVersion,_that.minVersion);case _:
  return null;

}
}

}

/// @nodoc


class UpdateRequiredContent implements UpdateRequiredState {
  const UpdateRequiredContent({required this.platform, required this.installedVersion, required this.minVersion});
  

@override final  AppPlatform platform;
@override final  String installedVersion;
@override final  String minVersion;

/// Create a copy of UpdateRequiredState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateRequiredContentCopyWith<UpdateRequiredContent> get copyWith => _$UpdateRequiredContentCopyWithImpl<UpdateRequiredContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequiredContent&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion));
}


@override
int get hashCode => Object.hash(runtimeType,platform,installedVersion,minVersion);

@override
String toString() {
  return 'UpdateRequiredState.content(platform: $platform, installedVersion: $installedVersion, minVersion: $minVersion)';
}


}

/// @nodoc
abstract mixin class $UpdateRequiredContentCopyWith<$Res> implements $UpdateRequiredStateCopyWith<$Res> {
  factory $UpdateRequiredContentCopyWith(UpdateRequiredContent value, $Res Function(UpdateRequiredContent) _then) = _$UpdateRequiredContentCopyWithImpl;
@override @useResult
$Res call({
 AppPlatform platform, String installedVersion, String minVersion
});




}
/// @nodoc
class _$UpdateRequiredContentCopyWithImpl<$Res>
    implements $UpdateRequiredContentCopyWith<$Res> {
  _$UpdateRequiredContentCopyWithImpl(this._self, this._then);

  final UpdateRequiredContent _self;
  final $Res Function(UpdateRequiredContent) _then;

/// Create a copy of UpdateRequiredState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? installedVersion = null,Object? minVersion = null,}) {
  return _then(UpdateRequiredContent(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as AppPlatform,installedVersion: null == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String,minVersion: null == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
