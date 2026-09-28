// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_gateway.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingReport {

/// The reported reading.
 ReadingId get readingId;/// The reason (`reason` wire value = `ReportReason.wire`).
 ReportReason get reason;/// The reading's content locale.
 String get locale;/// A fresh UUID per submission, reused on retry.
 String get idempotencyKey;/// The user's note (≤ 500 characters).
 String? get note;/// The question as asked.
 String? get question;/// The stored reading, sent back as the §9.1 wire object; absent for a
/// declined reading.
 ReadingContent? get reading;
/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingReportCopyWith<ReadingReport> get copyWith => _$ReadingReportCopyWithImpl<ReadingReport>(this as ReadingReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingReport&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.note, note) || other.note == note)&&(identical(other.question, question) || other.question == question)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,readingId,reason,locale,idempotencyKey,note,question,reading);

@override
String toString() {
  return 'ReadingReport(readingId: $readingId, reason: $reason, locale: $locale, idempotencyKey: $idempotencyKey, note: $note, question: $question, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $ReadingReportCopyWith<$Res>  {
  factory $ReadingReportCopyWith(ReadingReport value, $Res Function(ReadingReport) _then) = _$ReadingReportCopyWithImpl;
@useResult
$Res call({
 ReadingId readingId, ReportReason reason, String locale, String idempotencyKey, String? note, String? question, ReadingContent? reading
});


$ReadingContentCopyWith<$Res>? get reading;

}
/// @nodoc
class _$ReadingReportCopyWithImpl<$Res>
    implements $ReadingReportCopyWith<$Res> {
  _$ReadingReportCopyWithImpl(this._self, this._then);

  final ReadingReport _self;
  final $Res Function(ReadingReport) _then;

/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readingId = null,Object? reason = null,Object? locale = null,Object? idempotencyKey = null,Object? note = freezed,Object? question = freezed,Object? reading = freezed,}) {
  return _then(_self.copyWith(
readingId: null == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as ReadingContent?,
  ));
}
/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingContentCopyWith<$Res>? get reading {
    if (_self.reading == null) {
    return null;
  }

  return $ReadingContentCopyWith<$Res>(_self.reading!, (value) {
    return _then(_self.copyWith(reading: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingReport].
extension ReadingReportPatterns on ReadingReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingReport value)  $default,){
final _that = this;
switch (_that) {
case _ReadingReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingReport value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReadingId readingId,  ReportReason reason,  String locale,  String idempotencyKey,  String? note,  String? question,  ReadingContent? reading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingReport() when $default != null:
return $default(_that.readingId,_that.reason,_that.locale,_that.idempotencyKey,_that.note,_that.question,_that.reading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReadingId readingId,  ReportReason reason,  String locale,  String idempotencyKey,  String? note,  String? question,  ReadingContent? reading)  $default,) {final _that = this;
switch (_that) {
case _ReadingReport():
return $default(_that.readingId,_that.reason,_that.locale,_that.idempotencyKey,_that.note,_that.question,_that.reading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReadingId readingId,  ReportReason reason,  String locale,  String idempotencyKey,  String? note,  String? question,  ReadingContent? reading)?  $default,) {final _that = this;
switch (_that) {
case _ReadingReport() when $default != null:
return $default(_that.readingId,_that.reason,_that.locale,_that.idempotencyKey,_that.note,_that.question,_that.reading);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingReport implements ReadingReport {
  const _ReadingReport({required this.readingId, required this.reason, required this.locale, required this.idempotencyKey, this.note, this.question, this.reading});
  

/// The reported reading.
@override final  ReadingId readingId;
/// The reason (`reason` wire value = `ReportReason.wire`).
@override final  ReportReason reason;
/// The reading's content locale.
@override final  String locale;
/// A fresh UUID per submission, reused on retry.
@override final  String idempotencyKey;
/// The user's note (≤ 500 characters).
@override final  String? note;
/// The question as asked.
@override final  String? question;
/// The stored reading, sent back as the §9.1 wire object; absent for a
/// declined reading.
@override final  ReadingContent? reading;

/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingReportCopyWith<_ReadingReport> get copyWith => __$ReadingReportCopyWithImpl<_ReadingReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingReport&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.note, note) || other.note == note)&&(identical(other.question, question) || other.question == question)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,readingId,reason,locale,idempotencyKey,note,question,reading);

@override
String toString() {
  return 'ReadingReport(readingId: $readingId, reason: $reason, locale: $locale, idempotencyKey: $idempotencyKey, note: $note, question: $question, reading: $reading)';
}


}

/// @nodoc
abstract mixin class _$ReadingReportCopyWith<$Res> implements $ReadingReportCopyWith<$Res> {
  factory _$ReadingReportCopyWith(_ReadingReport value, $Res Function(_ReadingReport) _then) = __$ReadingReportCopyWithImpl;
@override @useResult
$Res call({
 ReadingId readingId, ReportReason reason, String locale, String idempotencyKey, String? note, String? question, ReadingContent? reading
});


@override $ReadingContentCopyWith<$Res>? get reading;

}
/// @nodoc
class __$ReadingReportCopyWithImpl<$Res>
    implements _$ReadingReportCopyWith<$Res> {
  __$ReadingReportCopyWithImpl(this._self, this._then);

  final _ReadingReport _self;
  final $Res Function(_ReadingReport) _then;

/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readingId = null,Object? reason = null,Object? locale = null,Object? idempotencyKey = null,Object? note = freezed,Object? question = freezed,Object? reading = freezed,}) {
  return _then(_ReadingReport(
readingId: null == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,idempotencyKey: null == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as ReadingContent?,
  ));
}

/// Create a copy of ReadingReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingContentCopyWith<$Res>? get reading {
    if (_self.reading == null) {
    return null;
  }

  return $ReadingContentCopyWith<$Res>(_self.reading!, (value) {
    return _then(_self.copyWith(reading: value));
  });
}
}

// dart format on
