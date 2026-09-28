// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReminderSettings {

/// Whether the reminder is scheduled.
 bool get enabled;/// Local time `HH:mm`.
 String get time;
/// Create a copy of ReminderSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderSettingsCopyWith<ReminderSettings> get copyWith => _$ReminderSettingsCopyWithImpl<ReminderSettings>(this as ReminderSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,time);

@override
String toString() {
  return 'ReminderSettings(enabled: $enabled, time: $time)';
}


}

/// @nodoc
abstract mixin class $ReminderSettingsCopyWith<$Res>  {
  factory $ReminderSettingsCopyWith(ReminderSettings value, $Res Function(ReminderSettings) _then) = _$ReminderSettingsCopyWithImpl;
@useResult
$Res call({
 bool enabled, String time
});




}
/// @nodoc
class _$ReminderSettingsCopyWithImpl<$Res>
    implements $ReminderSettingsCopyWith<$Res> {
  _$ReminderSettingsCopyWithImpl(this._self, this._then);

  final ReminderSettings _self;
  final $Res Function(ReminderSettings) _then;

/// Create a copy of ReminderSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? time = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReminderSettings].
extension ReminderSettingsPatterns on ReminderSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReminderSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReminderSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReminderSettings value)  $default,){
final _that = this;
switch (_that) {
case _ReminderSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReminderSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ReminderSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReminderSettings() when $default != null:
return $default(_that.enabled,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String time)  $default,) {final _that = this;
switch (_that) {
case _ReminderSettings():
return $default(_that.enabled,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String time)?  $default,) {final _that = this;
switch (_that) {
case _ReminderSettings() when $default != null:
return $default(_that.enabled,_that.time);case _:
  return null;

}
}

}

/// @nodoc


class _ReminderSettings extends ReminderSettings {
  const _ReminderSettings({this.enabled = false, this.time = '09:00'}): super._();
  

/// Whether the reminder is scheduled.
@override@JsonKey() final  bool enabled;
/// Local time `HH:mm`.
@override@JsonKey() final  String time;

/// Create a copy of ReminderSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderSettingsCopyWith<_ReminderSettings> get copyWith => __$ReminderSettingsCopyWithImpl<_ReminderSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReminderSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,enabled,time);

@override
String toString() {
  return 'ReminderSettings(enabled: $enabled, time: $time)';
}


}

/// @nodoc
abstract mixin class _$ReminderSettingsCopyWith<$Res> implements $ReminderSettingsCopyWith<$Res> {
  factory _$ReminderSettingsCopyWith(_ReminderSettings value, $Res Function(_ReminderSettings) _then) = __$ReminderSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String time
});




}
/// @nodoc
class __$ReminderSettingsCopyWithImpl<$Res>
    implements _$ReminderSettingsCopyWith<$Res> {
  __$ReminderSettingsCopyWithImpl(this._self, this._then);

  final _ReminderSettings _self;
  final $Res Function(_ReminderSettings) _then;

/// Create a copy of ReminderSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? time = null,}) {
  return _then(_ReminderSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$UserSettings {

/// App theme.
 ThemeMode get themeMode;/// One of [kSupportedLocales]; `null` follows the device.
 String? get localeOverride;/// Whether cards may be drawn reversed.
 bool get reversalsEnabled;/// Haptic feedback.
 bool get hapticsEnabled;/// Daily reminder.
 ReminderSettings get reminder;/// Reduce motion; `null` follows the OS. Device-local, not exported.
 bool? get reduceMotion;
/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<UserSettings> get copyWith => _$UserSettingsCopyWithImpl<UserSettings>(this as UserSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localeOverride, localeOverride) || other.localeOverride == localeOverride)&&(identical(other.reversalsEnabled, reversalsEnabled) || other.reversalsEnabled == reversalsEnabled)&&(identical(other.hapticsEnabled, hapticsEnabled) || other.hapticsEnabled == hapticsEnabled)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,localeOverride,reversalsEnabled,hapticsEnabled,reminder,reduceMotion);

@override
String toString() {
  return 'UserSettings(themeMode: $themeMode, localeOverride: $localeOverride, reversalsEnabled: $reversalsEnabled, hapticsEnabled: $hapticsEnabled, reminder: $reminder, reduceMotion: $reduceMotion)';
}


}

/// @nodoc
abstract mixin class $UserSettingsCopyWith<$Res>  {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) _then) = _$UserSettingsCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode, String? localeOverride, bool reversalsEnabled, bool hapticsEnabled, ReminderSettings reminder, bool? reduceMotion
});


$ReminderSettingsCopyWith<$Res> get reminder;

}
/// @nodoc
class _$UserSettingsCopyWithImpl<$Res>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._self, this._then);

  final UserSettings _self;
  final $Res Function(UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? localeOverride = freezed,Object? reversalsEnabled = null,Object? hapticsEnabled = null,Object? reminder = null,Object? reduceMotion = freezed,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,localeOverride: freezed == localeOverride ? _self.localeOverride : localeOverride // ignore: cast_nullable_to_non_nullable
as String?,reversalsEnabled: null == reversalsEnabled ? _self.reversalsEnabled : reversalsEnabled // ignore: cast_nullable_to_non_nullable
as bool,hapticsEnabled: null == hapticsEnabled ? _self.hapticsEnabled : hapticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminder: null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as ReminderSettings,reduceMotion: freezed == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderSettingsCopyWith<$Res> get reminder {
  
  return $ReminderSettingsCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserSettings].
extension UserSettingsPatterns on UserSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettings value)  $default,){
final _that = this;
switch (_that) {
case _UserSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettings value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode themeMode,  String? localeOverride,  bool reversalsEnabled,  bool hapticsEnabled,  ReminderSettings reminder,  bool? reduceMotion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.themeMode,_that.localeOverride,_that.reversalsEnabled,_that.hapticsEnabled,_that.reminder,_that.reduceMotion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode themeMode,  String? localeOverride,  bool reversalsEnabled,  bool hapticsEnabled,  ReminderSettings reminder,  bool? reduceMotion)  $default,) {final _that = this;
switch (_that) {
case _UserSettings():
return $default(_that.themeMode,_that.localeOverride,_that.reversalsEnabled,_that.hapticsEnabled,_that.reminder,_that.reduceMotion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode themeMode,  String? localeOverride,  bool reversalsEnabled,  bool hapticsEnabled,  ReminderSettings reminder,  bool? reduceMotion)?  $default,) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.themeMode,_that.localeOverride,_that.reversalsEnabled,_that.hapticsEnabled,_that.reminder,_that.reduceMotion);case _:
  return null;

}
}

}

/// @nodoc


class _UserSettings extends UserSettings {
  const _UserSettings({this.themeMode = ThemeMode.system, this.localeOverride, this.reversalsEnabled = true, this.hapticsEnabled = true, this.reminder = const ReminderSettings(), this.reduceMotion}): super._();
  

/// App theme.
@override@JsonKey() final  ThemeMode themeMode;
/// One of [kSupportedLocales]; `null` follows the device.
@override final  String? localeOverride;
/// Whether cards may be drawn reversed.
@override@JsonKey() final  bool reversalsEnabled;
/// Haptic feedback.
@override@JsonKey() final  bool hapticsEnabled;
/// Daily reminder.
@override@JsonKey() final  ReminderSettings reminder;
/// Reduce motion; `null` follows the OS. Device-local, not exported.
@override final  bool? reduceMotion;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsCopyWith<_UserSettings> get copyWith => __$UserSettingsCopyWithImpl<_UserSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.localeOverride, localeOverride) || other.localeOverride == localeOverride)&&(identical(other.reversalsEnabled, reversalsEnabled) || other.reversalsEnabled == reversalsEnabled)&&(identical(other.hapticsEnabled, hapticsEnabled) || other.hapticsEnabled == hapticsEnabled)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,localeOverride,reversalsEnabled,hapticsEnabled,reminder,reduceMotion);

@override
String toString() {
  return 'UserSettings(themeMode: $themeMode, localeOverride: $localeOverride, reversalsEnabled: $reversalsEnabled, hapticsEnabled: $hapticsEnabled, reminder: $reminder, reduceMotion: $reduceMotion)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsCopyWith<$Res> implements $UserSettingsCopyWith<$Res> {
  factory _$UserSettingsCopyWith(_UserSettings value, $Res Function(_UserSettings) _then) = __$UserSettingsCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode themeMode, String? localeOverride, bool reversalsEnabled, bool hapticsEnabled, ReminderSettings reminder, bool? reduceMotion
});


@override $ReminderSettingsCopyWith<$Res> get reminder;

}
/// @nodoc
class __$UserSettingsCopyWithImpl<$Res>
    implements _$UserSettingsCopyWith<$Res> {
  __$UserSettingsCopyWithImpl(this._self, this._then);

  final _UserSettings _self;
  final $Res Function(_UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? localeOverride = freezed,Object? reversalsEnabled = null,Object? hapticsEnabled = null,Object? reminder = null,Object? reduceMotion = freezed,}) {
  return _then(_UserSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,localeOverride: freezed == localeOverride ? _self.localeOverride : localeOverride // ignore: cast_nullable_to_non_nullable
as String?,reversalsEnabled: null == reversalsEnabled ? _self.reversalsEnabled : reversalsEnabled // ignore: cast_nullable_to_non_nullable
as bool,hapticsEnabled: null == hapticsEnabled ? _self.hapticsEnabled : hapticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,reminder: null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as ReminderSettings,reduceMotion: freezed == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of UserSettings
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
