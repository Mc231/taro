// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_settings_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReminderSettingsState {

 ReminderSettings get reminder;
/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderSettingsStateCopyWith<ReminderSettingsState> get copyWith => _$ReminderSettingsStateCopyWithImpl<ReminderSettingsState>(this as ReminderSettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderSettingsState&&(identical(other.reminder, reminder) || other.reminder == reminder));
}


@override
int get hashCode => Object.hash(runtimeType,reminder);

@override
String toString() {
  return 'ReminderSettingsState(reminder: $reminder)';
}


}

/// @nodoc
abstract mixin class $ReminderSettingsStateCopyWith<$Res>  {
  factory $ReminderSettingsStateCopyWith(ReminderSettingsState value, $Res Function(ReminderSettingsState) _then) = _$ReminderSettingsStateCopyWithImpl;
@useResult
$Res call({
 ReminderSettings reminder
});


$ReminderSettingsCopyWith<$Res> get reminder;

}
/// @nodoc
class _$ReminderSettingsStateCopyWithImpl<$Res>
    implements $ReminderSettingsStateCopyWith<$Res> {
  _$ReminderSettingsStateCopyWithImpl(this._self, this._then);

  final ReminderSettingsState _self;
  final $Res Function(ReminderSettingsState) _then;

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reminder = null,}) {
  return _then(_self.copyWith(
reminder: null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as ReminderSettings,
  ));
}
/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderSettingsCopyWith<$Res> get reminder {
  
  return $ReminderSettingsCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReminderSettingsState].
extension ReminderSettingsStatePatterns on ReminderSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReminderSettingsContent value)?  content,TResult Function( ReminderSettingsPermissionDenied value)?  permissionDenied,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReminderSettingsContent() when content != null:
return content(_that);case ReminderSettingsPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReminderSettingsContent value)  content,required TResult Function( ReminderSettingsPermissionDenied value)  permissionDenied,}){
final _that = this;
switch (_that) {
case ReminderSettingsContent():
return content(_that);case ReminderSettingsPermissionDenied():
return permissionDenied(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReminderSettingsContent value)?  content,TResult? Function( ReminderSettingsPermissionDenied value)?  permissionDenied,}){
final _that = this;
switch (_that) {
case ReminderSettingsContent() when content != null:
return content(_that);case ReminderSettingsPermissionDenied() when permissionDenied != null:
return permissionDenied(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ReminderSettings reminder)?  content,TResult Function( ReminderSettings reminder)?  permissionDenied,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReminderSettingsContent() when content != null:
return content(_that.reminder);case ReminderSettingsPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.reminder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ReminderSettings reminder)  content,required TResult Function( ReminderSettings reminder)  permissionDenied,}) {final _that = this;
switch (_that) {
case ReminderSettingsContent():
return content(_that.reminder);case ReminderSettingsPermissionDenied():
return permissionDenied(_that.reminder);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ReminderSettings reminder)?  content,TResult? Function( ReminderSettings reminder)?  permissionDenied,}) {final _that = this;
switch (_that) {
case ReminderSettingsContent() when content != null:
return content(_that.reminder);case ReminderSettingsPermissionDenied() when permissionDenied != null:
return permissionDenied(_that.reminder);case _:
  return null;

}
}

}

/// @nodoc


class ReminderSettingsContent implements ReminderSettingsState {
  const ReminderSettingsContent(this.reminder);
  

@override final  ReminderSettings reminder;

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderSettingsContentCopyWith<ReminderSettingsContent> get copyWith => _$ReminderSettingsContentCopyWithImpl<ReminderSettingsContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderSettingsContent&&(identical(other.reminder, reminder) || other.reminder == reminder));
}


@override
int get hashCode => Object.hash(runtimeType,reminder);

@override
String toString() {
  return 'ReminderSettingsState.content(reminder: $reminder)';
}


}

/// @nodoc
abstract mixin class $ReminderSettingsContentCopyWith<$Res> implements $ReminderSettingsStateCopyWith<$Res> {
  factory $ReminderSettingsContentCopyWith(ReminderSettingsContent value, $Res Function(ReminderSettingsContent) _then) = _$ReminderSettingsContentCopyWithImpl;
@override @useResult
$Res call({
 ReminderSettings reminder
});


@override $ReminderSettingsCopyWith<$Res> get reminder;

}
/// @nodoc
class _$ReminderSettingsContentCopyWithImpl<$Res>
    implements $ReminderSettingsContentCopyWith<$Res> {
  _$ReminderSettingsContentCopyWithImpl(this._self, this._then);

  final ReminderSettingsContent _self;
  final $Res Function(ReminderSettingsContent) _then;

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reminder = null,}) {
  return _then(ReminderSettingsContent(
null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as ReminderSettings,
  ));
}

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderSettingsCopyWith<$Res> get reminder {
  
  return $ReminderSettingsCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}

/// @nodoc


class ReminderSettingsPermissionDenied implements ReminderSettingsState {
  const ReminderSettingsPermissionDenied(this.reminder);
  

@override final  ReminderSettings reminder;

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderSettingsPermissionDeniedCopyWith<ReminderSettingsPermissionDenied> get copyWith => _$ReminderSettingsPermissionDeniedCopyWithImpl<ReminderSettingsPermissionDenied>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderSettingsPermissionDenied&&(identical(other.reminder, reminder) || other.reminder == reminder));
}


@override
int get hashCode => Object.hash(runtimeType,reminder);

@override
String toString() {
  return 'ReminderSettingsState.permissionDenied(reminder: $reminder)';
}


}

/// @nodoc
abstract mixin class $ReminderSettingsPermissionDeniedCopyWith<$Res> implements $ReminderSettingsStateCopyWith<$Res> {
  factory $ReminderSettingsPermissionDeniedCopyWith(ReminderSettingsPermissionDenied value, $Res Function(ReminderSettingsPermissionDenied) _then) = _$ReminderSettingsPermissionDeniedCopyWithImpl;
@override @useResult
$Res call({
 ReminderSettings reminder
});


@override $ReminderSettingsCopyWith<$Res> get reminder;

}
/// @nodoc
class _$ReminderSettingsPermissionDeniedCopyWithImpl<$Res>
    implements $ReminderSettingsPermissionDeniedCopyWith<$Res> {
  _$ReminderSettingsPermissionDeniedCopyWithImpl(this._self, this._then);

  final ReminderSettingsPermissionDenied _self;
  final $Res Function(ReminderSettingsPermissionDenied) _then;

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reminder = null,}) {
  return _then(ReminderSettingsPermissionDenied(
null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as ReminderSettings,
  ));
}

/// Create a copy of ReminderSettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderSettingsCopyWith<$Res> get reminder {
  
  return $ReminderSettingsCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}

// dart format on
