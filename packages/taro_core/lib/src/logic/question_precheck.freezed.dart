// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_precheck.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuestionCheck {

/// The trimmed question; `null` when empty (the question is optional).
 String? get question;/// Grapheme clusters in [question].
 int get length;/// Why it cannot be sent; `null` when it can.
 QuestionProblem? get problem;/// Whether it looks like it contains an email address or phone number:
/// warn "Avoid sharing personal details", never block.
 bool get personalDetailsWarning;
/// Create a copy of QuestionCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCheckCopyWith<QuestionCheck> get copyWith => _$QuestionCheckCopyWithImpl<QuestionCheck>(this as QuestionCheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionCheck&&(identical(other.question, question) || other.question == question)&&(identical(other.length, length) || other.length == length)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.personalDetailsWarning, personalDetailsWarning) || other.personalDetailsWarning == personalDetailsWarning));
}


@override
int get hashCode => Object.hash(runtimeType,question,length,problem,personalDetailsWarning);

@override
String toString() {
  return 'QuestionCheck(question: $question, length: $length, problem: $problem, personalDetailsWarning: $personalDetailsWarning)';
}


}

/// @nodoc
abstract mixin class $QuestionCheckCopyWith<$Res>  {
  factory $QuestionCheckCopyWith(QuestionCheck value, $Res Function(QuestionCheck) _then) = _$QuestionCheckCopyWithImpl;
@useResult
$Res call({
 String? question, int length, QuestionProblem? problem, bool personalDetailsWarning
});




}
/// @nodoc
class _$QuestionCheckCopyWithImpl<$Res>
    implements $QuestionCheckCopyWith<$Res> {
  _$QuestionCheckCopyWithImpl(this._self, this._then);

  final QuestionCheck _self;
  final $Res Function(QuestionCheck) _then;

/// Create a copy of QuestionCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = freezed,Object? length = null,Object? problem = freezed,Object? personalDetailsWarning = null,}) {
  return _then(_self.copyWith(
question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as QuestionProblem?,personalDetailsWarning: null == personalDetailsWarning ? _self.personalDetailsWarning : personalDetailsWarning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionCheck].
extension QuestionCheckPatterns on QuestionCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionCheck value)  $default,){
final _that = this;
switch (_that) {
case _QuestionCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionCheck value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? question,  int length,  QuestionProblem? problem,  bool personalDetailsWarning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionCheck() when $default != null:
return $default(_that.question,_that.length,_that.problem,_that.personalDetailsWarning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? question,  int length,  QuestionProblem? problem,  bool personalDetailsWarning)  $default,) {final _that = this;
switch (_that) {
case _QuestionCheck():
return $default(_that.question,_that.length,_that.problem,_that.personalDetailsWarning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? question,  int length,  QuestionProblem? problem,  bool personalDetailsWarning)?  $default,) {final _that = this;
switch (_that) {
case _QuestionCheck() when $default != null:
return $default(_that.question,_that.length,_that.problem,_that.personalDetailsWarning);case _:
  return null;

}
}

}

/// @nodoc


class _QuestionCheck extends QuestionCheck {
  const _QuestionCheck({required this.question, required this.length, required this.problem, required this.personalDetailsWarning}): super._();
  

/// The trimmed question; `null` when empty (the question is optional).
@override final  String? question;
/// Grapheme clusters in [question].
@override final  int length;
/// Why it cannot be sent; `null` when it can.
@override final  QuestionProblem? problem;
/// Whether it looks like it contains an email address or phone number:
/// warn "Avoid sharing personal details", never block.
@override final  bool personalDetailsWarning;

/// Create a copy of QuestionCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCheckCopyWith<_QuestionCheck> get copyWith => __$QuestionCheckCopyWithImpl<_QuestionCheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionCheck&&(identical(other.question, question) || other.question == question)&&(identical(other.length, length) || other.length == length)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.personalDetailsWarning, personalDetailsWarning) || other.personalDetailsWarning == personalDetailsWarning));
}


@override
int get hashCode => Object.hash(runtimeType,question,length,problem,personalDetailsWarning);

@override
String toString() {
  return 'QuestionCheck(question: $question, length: $length, problem: $problem, personalDetailsWarning: $personalDetailsWarning)';
}


}

/// @nodoc
abstract mixin class _$QuestionCheckCopyWith<$Res> implements $QuestionCheckCopyWith<$Res> {
  factory _$QuestionCheckCopyWith(_QuestionCheck value, $Res Function(_QuestionCheck) _then) = __$QuestionCheckCopyWithImpl;
@override @useResult
$Res call({
 String? question, int length, QuestionProblem? problem, bool personalDetailsWarning
});




}
/// @nodoc
class __$QuestionCheckCopyWithImpl<$Res>
    implements _$QuestionCheckCopyWith<$Res> {
  __$QuestionCheckCopyWithImpl(this._self, this._then);

  final _QuestionCheck _self;
  final $Res Function(_QuestionCheck) _then;

/// Create a copy of QuestionCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = freezed,Object? length = null,Object? problem = freezed,Object? personalDetailsWarning = null,}) {
  return _then(_QuestionCheck(
question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as int,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as QuestionProblem?,personalDetailsWarning: null == personalDetailsWarning ? _self.personalDetailsWarning : personalDetailsWarning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
