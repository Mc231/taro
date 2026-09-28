// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackupData {

/// Exported settings.
 UserSettings get settings;/// `complete`, `refused` and `classic` readings.
 List<Reading> get readings;/// Daily cards.
 List<DailyCard> get dailyCards;
/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupDataCopyWith<BackupData> get copyWith => _$BackupDataCopyWithImpl<BackupData>(this as BackupData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupData&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.readings, readings)&&const DeepCollectionEquality().equals(other.dailyCards, dailyCards));
}


@override
int get hashCode => Object.hash(runtimeType,settings,const DeepCollectionEquality().hash(readings),const DeepCollectionEquality().hash(dailyCards));

@override
String toString() {
  return 'BackupData(settings: $settings, readings: $readings, dailyCards: $dailyCards)';
}


}

/// @nodoc
abstract mixin class $BackupDataCopyWith<$Res>  {
  factory $BackupDataCopyWith(BackupData value, $Res Function(BackupData) _then) = _$BackupDataCopyWithImpl;
@useResult
$Res call({
 UserSettings settings, List<Reading> readings, List<DailyCard> dailyCards
});


$UserSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$BackupDataCopyWithImpl<$Res>
    implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._self, this._then);

  final BackupData _self;
  final $Res Function(BackupData) _then;

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? readings = null,Object? dailyCards = null,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self.dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,
  ));
}
/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [BackupData].
extension BackupDataPatterns on BackupData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackupData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackupData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackupData value)  $default,){
final _that = this;
switch (_that) {
case _BackupData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackupData value)?  $default,){
final _that = this;
switch (_that) {
case _BackupData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackupData() when $default != null:
return $default(_that.settings,_that.readings,_that.dailyCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards)  $default,) {final _that = this;
switch (_that) {
case _BackupData():
return $default(_that.settings,_that.readings,_that.dailyCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards)?  $default,) {final _that = this;
switch (_that) {
case _BackupData() when $default != null:
return $default(_that.settings,_that.readings,_that.dailyCards);case _:
  return null;

}
}

}

/// @nodoc


class _BackupData extends BackupData {
  const _BackupData({required this.settings, required final  List<Reading> readings, required final  List<DailyCard> dailyCards}): _readings = readings,_dailyCards = dailyCards,super._();
  

/// Exported settings.
@override final  UserSettings settings;
/// `complete`, `refused` and `classic` readings.
 final  List<Reading> _readings;
/// `complete`, `refused` and `classic` readings.
@override List<Reading> get readings {
  if (_readings is EqualUnmodifiableListView) return _readings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readings);
}

/// Daily cards.
 final  List<DailyCard> _dailyCards;
/// Daily cards.
@override List<DailyCard> get dailyCards {
  if (_dailyCards is EqualUnmodifiableListView) return _dailyCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyCards);
}


/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackupDataCopyWith<_BackupData> get copyWith => __$BackupDataCopyWithImpl<_BackupData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackupData&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other._readings, _readings)&&const DeepCollectionEquality().equals(other._dailyCards, _dailyCards));
}


@override
int get hashCode => Object.hash(runtimeType,settings,const DeepCollectionEquality().hash(_readings),const DeepCollectionEquality().hash(_dailyCards));

@override
String toString() {
  return 'BackupData(settings: $settings, readings: $readings, dailyCards: $dailyCards)';
}


}

/// @nodoc
abstract mixin class _$BackupDataCopyWith<$Res> implements $BackupDataCopyWith<$Res> {
  factory _$BackupDataCopyWith(_BackupData value, $Res Function(_BackupData) _then) = __$BackupDataCopyWithImpl;
@override @useResult
$Res call({
 UserSettings settings, List<Reading> readings, List<DailyCard> dailyCards
});


@override $UserSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$BackupDataCopyWithImpl<$Res>
    implements _$BackupDataCopyWith<$Res> {
  __$BackupDataCopyWithImpl(this._self, this._then);

  final _BackupData _self;
  final $Res Function(_BackupData) _then;

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? readings = null,Object? dailyCards = null,}) {
  return _then(_BackupData(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,readings: null == readings ? _self._readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self._dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,
  ));
}

/// Create a copy of BackupData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc
mixin _$BackupV1 {

/// Export time (UTC).
 DateTime get exportedAt;/// `major.minor.patch+build` of the exporting app.
 String get appVersion;/// The journal content.
 BackupData get data;/// 64 lowercase hex characters.
 String get checksum;
/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupV1CopyWith<BackupV1> get copyWith => _$BackupV1CopyWithImpl<BackupV1>(this as BackupV1, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupV1&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.data, data) || other.data == data)&&(identical(other.checksum, checksum) || other.checksum == checksum));
}


@override
int get hashCode => Object.hash(runtimeType,exportedAt,appVersion,data,checksum);

@override
String toString() {
  return 'BackupV1(exportedAt: $exportedAt, appVersion: $appVersion, data: $data, checksum: $checksum)';
}


}

/// @nodoc
abstract mixin class $BackupV1CopyWith<$Res>  {
  factory $BackupV1CopyWith(BackupV1 value, $Res Function(BackupV1) _then) = _$BackupV1CopyWithImpl;
@useResult
$Res call({
 DateTime exportedAt, String appVersion, BackupData data, String checksum
});


$BackupDataCopyWith<$Res> get data;

}
/// @nodoc
class _$BackupV1CopyWithImpl<$Res>
    implements $BackupV1CopyWith<$Res> {
  _$BackupV1CopyWithImpl(this._self, this._then);

  final BackupV1 _self;
  final $Res Function(BackupV1) _then;

/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exportedAt = null,Object? appVersion = null,Object? data = null,Object? checksum = null,}) {
  return _then(_self.copyWith(
exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BackupData,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackupDataCopyWith<$Res> get data {
  
  return $BackupDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [BackupV1].
extension BackupV1Patterns on BackupV1 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackupV1 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackupV1() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackupV1 value)  $default,){
final _that = this;
switch (_that) {
case _BackupV1():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackupV1 value)?  $default,){
final _that = this;
switch (_that) {
case _BackupV1() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime exportedAt,  String appVersion,  BackupData data,  String checksum)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackupV1() when $default != null:
return $default(_that.exportedAt,_that.appVersion,_that.data,_that.checksum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime exportedAt,  String appVersion,  BackupData data,  String checksum)  $default,) {final _that = this;
switch (_that) {
case _BackupV1():
return $default(_that.exportedAt,_that.appVersion,_that.data,_that.checksum);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime exportedAt,  String appVersion,  BackupData data,  String checksum)?  $default,) {final _that = this;
switch (_that) {
case _BackupV1() when $default != null:
return $default(_that.exportedAt,_that.appVersion,_that.data,_that.checksum);case _:
  return null;

}
}

}

/// @nodoc


class _BackupV1 extends BackupV1 {
  const _BackupV1({required this.exportedAt, required this.appVersion, required this.data, required this.checksum}): super._();
  

/// Export time (UTC).
@override final  DateTime exportedAt;
/// `major.minor.patch+build` of the exporting app.
@override final  String appVersion;
/// The journal content.
@override final  BackupData data;
/// 64 lowercase hex characters.
@override final  String checksum;

/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackupV1CopyWith<_BackupV1> get copyWith => __$BackupV1CopyWithImpl<_BackupV1>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackupV1&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.data, data) || other.data == data)&&(identical(other.checksum, checksum) || other.checksum == checksum));
}


@override
int get hashCode => Object.hash(runtimeType,exportedAt,appVersion,data,checksum);

@override
String toString() {
  return 'BackupV1(exportedAt: $exportedAt, appVersion: $appVersion, data: $data, checksum: $checksum)';
}


}

/// @nodoc
abstract mixin class _$BackupV1CopyWith<$Res> implements $BackupV1CopyWith<$Res> {
  factory _$BackupV1CopyWith(_BackupV1 value, $Res Function(_BackupV1) _then) = __$BackupV1CopyWithImpl;
@override @useResult
$Res call({
 DateTime exportedAt, String appVersion, BackupData data, String checksum
});


@override $BackupDataCopyWith<$Res> get data;

}
/// @nodoc
class __$BackupV1CopyWithImpl<$Res>
    implements _$BackupV1CopyWith<$Res> {
  __$BackupV1CopyWithImpl(this._self, this._then);

  final _BackupV1 _self;
  final $Res Function(_BackupV1) _then;

/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exportedAt = null,Object? appVersion = null,Object? data = null,Object? checksum = null,}) {
  return _then(_BackupV1(
exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BackupData,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of BackupV1
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackupDataCopyWith<$Res> get data {
  
  return $BackupDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
