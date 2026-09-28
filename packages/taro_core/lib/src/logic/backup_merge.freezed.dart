// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_merge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MergeReport {

/// Entries that were not in the journal.
 int get added;/// Existing entries changed by the file.
 int get updated;/// File entries that changed nothing (older or identical).
 int get skipped;/// Journal entries dropped by [MergeMode.replace].
 int get removed;
/// Create a copy of MergeReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeReportCopyWith<MergeReport> get copyWith => _$MergeReportCopyWithImpl<MergeReport>(this as MergeReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeReport&&(identical(other.added, added) || other.added == added)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.removed, removed) || other.removed == removed));
}


@override
int get hashCode => Object.hash(runtimeType,added,updated,skipped,removed);

@override
String toString() {
  return 'MergeReport(added: $added, updated: $updated, skipped: $skipped, removed: $removed)';
}


}

/// @nodoc
abstract mixin class $MergeReportCopyWith<$Res>  {
  factory $MergeReportCopyWith(MergeReport value, $Res Function(MergeReport) _then) = _$MergeReportCopyWithImpl;
@useResult
$Res call({
 int added, int updated, int skipped, int removed
});




}
/// @nodoc
class _$MergeReportCopyWithImpl<$Res>
    implements $MergeReportCopyWith<$Res> {
  _$MergeReportCopyWithImpl(this._self, this._then);

  final MergeReport _self;
  final $Res Function(MergeReport) _then;

/// Create a copy of MergeReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? added = null,Object? updated = null,Object? skipped = null,Object? removed = null,}) {
  return _then(_self.copyWith(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MergeReport].
extension MergeReportPatterns on MergeReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MergeReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MergeReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MergeReport value)  $default,){
final _that = this;
switch (_that) {
case _MergeReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MergeReport value)?  $default,){
final _that = this;
switch (_that) {
case _MergeReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int added,  int updated,  int skipped,  int removed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MergeReport() when $default != null:
return $default(_that.added,_that.updated,_that.skipped,_that.removed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int added,  int updated,  int skipped,  int removed)  $default,) {final _that = this;
switch (_that) {
case _MergeReport():
return $default(_that.added,_that.updated,_that.skipped,_that.removed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int added,  int updated,  int skipped,  int removed)?  $default,) {final _that = this;
switch (_that) {
case _MergeReport() when $default != null:
return $default(_that.added,_that.updated,_that.skipped,_that.removed);case _:
  return null;

}
}

}

/// @nodoc


class _MergeReport extends MergeReport {
  const _MergeReport({this.added = 0, this.updated = 0, this.skipped = 0, this.removed = 0}): super._();
  

/// Entries that were not in the journal.
@override@JsonKey() final  int added;
/// Existing entries changed by the file.
@override@JsonKey() final  int updated;
/// File entries that changed nothing (older or identical).
@override@JsonKey() final  int skipped;
/// Journal entries dropped by [MergeMode.replace].
@override@JsonKey() final  int removed;

/// Create a copy of MergeReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MergeReportCopyWith<_MergeReport> get copyWith => __$MergeReportCopyWithImpl<_MergeReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MergeReport&&(identical(other.added, added) || other.added == added)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.removed, removed) || other.removed == removed));
}


@override
int get hashCode => Object.hash(runtimeType,added,updated,skipped,removed);

@override
String toString() {
  return 'MergeReport(added: $added, updated: $updated, skipped: $skipped, removed: $removed)';
}


}

/// @nodoc
abstract mixin class _$MergeReportCopyWith<$Res> implements $MergeReportCopyWith<$Res> {
  factory _$MergeReportCopyWith(_MergeReport value, $Res Function(_MergeReport) _then) = __$MergeReportCopyWithImpl;
@override @useResult
$Res call({
 int added, int updated, int skipped, int removed
});




}
/// @nodoc
class __$MergeReportCopyWithImpl<$Res>
    implements _$MergeReportCopyWith<$Res> {
  __$MergeReportCopyWithImpl(this._self, this._then);

  final _MergeReport _self;
  final $Res Function(_MergeReport) _then;

/// Create a copy of MergeReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? added = null,Object? updated = null,Object? skipped = null,Object? removed = null,}) {
  return _then(_MergeReport(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$MergeResult {

/// Settings to store.
 UserSettings get settings;/// Every reading, in journal order then new ones in file order.
 List<Reading> get readings;/// Every daily card, in journal order then new ones in file order.
 List<DailyCard> get dailyCards;/// The counts.
 MergeReport get report;
/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeResultCopyWith<MergeResult> get copyWith => _$MergeResultCopyWithImpl<MergeResult>(this as MergeResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeResult&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.readings, readings)&&const DeepCollectionEquality().equals(other.dailyCards, dailyCards)&&(identical(other.report, report) || other.report == report));
}


@override
int get hashCode => Object.hash(runtimeType,settings,const DeepCollectionEquality().hash(readings),const DeepCollectionEquality().hash(dailyCards),report);

@override
String toString() {
  return 'MergeResult(settings: $settings, readings: $readings, dailyCards: $dailyCards, report: $report)';
}


}

/// @nodoc
abstract mixin class $MergeResultCopyWith<$Res>  {
  factory $MergeResultCopyWith(MergeResult value, $Res Function(MergeResult) _then) = _$MergeResultCopyWithImpl;
@useResult
$Res call({
 UserSettings settings, List<Reading> readings, List<DailyCard> dailyCards, MergeReport report
});


$UserSettingsCopyWith<$Res> get settings;$MergeReportCopyWith<$Res> get report;

}
/// @nodoc
class _$MergeResultCopyWithImpl<$Res>
    implements $MergeResultCopyWith<$Res> {
  _$MergeResultCopyWithImpl(this._self, this._then);

  final MergeResult _self;
  final $Res Function(MergeResult) _then;

/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? readings = null,Object? dailyCards = null,Object? report = null,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self.dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as MergeReport,
  ));
}
/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MergeReportCopyWith<$Res> get report {
  
  return $MergeReportCopyWith<$Res>(_self.report, (value) {
    return _then(_self.copyWith(report: value));
  });
}
}


/// Adds pattern-matching-related methods to [MergeResult].
extension MergeResultPatterns on MergeResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MergeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MergeResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MergeResult value)  $default,){
final _that = this;
switch (_that) {
case _MergeResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MergeResult value)?  $default,){
final _that = this;
switch (_that) {
case _MergeResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards,  MergeReport report)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MergeResult() when $default != null:
return $default(_that.settings,_that.readings,_that.dailyCards,_that.report);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards,  MergeReport report)  $default,) {final _that = this;
switch (_that) {
case _MergeResult():
return $default(_that.settings,_that.readings,_that.dailyCards,_that.report);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserSettings settings,  List<Reading> readings,  List<DailyCard> dailyCards,  MergeReport report)?  $default,) {final _that = this;
switch (_that) {
case _MergeResult() when $default != null:
return $default(_that.settings,_that.readings,_that.dailyCards,_that.report);case _:
  return null;

}
}

}

/// @nodoc


class _MergeResult implements MergeResult {
  const _MergeResult({required this.settings, required final  List<Reading> readings, required final  List<DailyCard> dailyCards, required this.report}): _readings = readings,_dailyCards = dailyCards;
  

/// Settings to store.
@override final  UserSettings settings;
/// Every reading, in journal order then new ones in file order.
 final  List<Reading> _readings;
/// Every reading, in journal order then new ones in file order.
@override List<Reading> get readings {
  if (_readings is EqualUnmodifiableListView) return _readings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readings);
}

/// Every daily card, in journal order then new ones in file order.
 final  List<DailyCard> _dailyCards;
/// Every daily card, in journal order then new ones in file order.
@override List<DailyCard> get dailyCards {
  if (_dailyCards is EqualUnmodifiableListView) return _dailyCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyCards);
}

/// The counts.
@override final  MergeReport report;

/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MergeResultCopyWith<_MergeResult> get copyWith => __$MergeResultCopyWithImpl<_MergeResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MergeResult&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other._readings, _readings)&&const DeepCollectionEquality().equals(other._dailyCards, _dailyCards)&&(identical(other.report, report) || other.report == report));
}


@override
int get hashCode => Object.hash(runtimeType,settings,const DeepCollectionEquality().hash(_readings),const DeepCollectionEquality().hash(_dailyCards),report);

@override
String toString() {
  return 'MergeResult(settings: $settings, readings: $readings, dailyCards: $dailyCards, report: $report)';
}


}

/// @nodoc
abstract mixin class _$MergeResultCopyWith<$Res> implements $MergeResultCopyWith<$Res> {
  factory _$MergeResultCopyWith(_MergeResult value, $Res Function(_MergeResult) _then) = __$MergeResultCopyWithImpl;
@override @useResult
$Res call({
 UserSettings settings, List<Reading> readings, List<DailyCard> dailyCards, MergeReport report
});


@override $UserSettingsCopyWith<$Res> get settings;@override $MergeReportCopyWith<$Res> get report;

}
/// @nodoc
class __$MergeResultCopyWithImpl<$Res>
    implements _$MergeResultCopyWith<$Res> {
  __$MergeResultCopyWithImpl(this._self, this._then);

  final _MergeResult _self;
  final $Res Function(_MergeResult) _then;

/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? readings = null,Object? dailyCards = null,Object? report = null,}) {
  return _then(_MergeResult(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,readings: null == readings ? _self._readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self._dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as MergeReport,
  ));
}

/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of MergeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MergeReportCopyWith<$Res> get report {
  
  return $MergeReportCopyWith<$Res>(_self.report, (value) {
    return _then(_self.copyWith(report: value));
  });
}
}

// dart format on
