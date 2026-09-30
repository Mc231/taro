// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'share_reading_use_case.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShareCopy {

/// The disclaimer line (05 §3 `disclaimerShort`).
 String get disclaimerLine;/// The label before the question, e.g. "My question".
 String get questionLabel;/// The orientation label appended to a reversed card, e.g. "Reversed".
 String get reversedLabel;/// The title when the reading has none (Classic): the spread name.
 String get fallbackTitle;
/// Create a copy of ShareCopy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareCopyCopyWith<ShareCopy> get copyWith => _$ShareCopyCopyWithImpl<ShareCopy>(this as ShareCopy, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareCopy&&(identical(other.disclaimerLine, disclaimerLine) || other.disclaimerLine == disclaimerLine)&&(identical(other.questionLabel, questionLabel) || other.questionLabel == questionLabel)&&(identical(other.reversedLabel, reversedLabel) || other.reversedLabel == reversedLabel)&&(identical(other.fallbackTitle, fallbackTitle) || other.fallbackTitle == fallbackTitle));
}


@override
int get hashCode => Object.hash(runtimeType,disclaimerLine,questionLabel,reversedLabel,fallbackTitle);

@override
String toString() {
  return 'ShareCopy(disclaimerLine: $disclaimerLine, questionLabel: $questionLabel, reversedLabel: $reversedLabel, fallbackTitle: $fallbackTitle)';
}


}

/// @nodoc
abstract mixin class $ShareCopyCopyWith<$Res>  {
  factory $ShareCopyCopyWith(ShareCopy value, $Res Function(ShareCopy) _then) = _$ShareCopyCopyWithImpl;
@useResult
$Res call({
 String disclaimerLine, String questionLabel, String reversedLabel, String fallbackTitle
});




}
/// @nodoc
class _$ShareCopyCopyWithImpl<$Res>
    implements $ShareCopyCopyWith<$Res> {
  _$ShareCopyCopyWithImpl(this._self, this._then);

  final ShareCopy _self;
  final $Res Function(ShareCopy) _then;

/// Create a copy of ShareCopy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? disclaimerLine = null,Object? questionLabel = null,Object? reversedLabel = null,Object? fallbackTitle = null,}) {
  return _then(_self.copyWith(
disclaimerLine: null == disclaimerLine ? _self.disclaimerLine : disclaimerLine // ignore: cast_nullable_to_non_nullable
as String,questionLabel: null == questionLabel ? _self.questionLabel : questionLabel // ignore: cast_nullable_to_non_nullable
as String,reversedLabel: null == reversedLabel ? _self.reversedLabel : reversedLabel // ignore: cast_nullable_to_non_nullable
as String,fallbackTitle: null == fallbackTitle ? _self.fallbackTitle : fallbackTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareCopy].
extension ShareCopyPatterns on ShareCopy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareCopy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareCopy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareCopy value)  $default,){
final _that = this;
switch (_that) {
case _ShareCopy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareCopy value)?  $default,){
final _that = this;
switch (_that) {
case _ShareCopy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String disclaimerLine,  String questionLabel,  String reversedLabel,  String fallbackTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareCopy() when $default != null:
return $default(_that.disclaimerLine,_that.questionLabel,_that.reversedLabel,_that.fallbackTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String disclaimerLine,  String questionLabel,  String reversedLabel,  String fallbackTitle)  $default,) {final _that = this;
switch (_that) {
case _ShareCopy():
return $default(_that.disclaimerLine,_that.questionLabel,_that.reversedLabel,_that.fallbackTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String disclaimerLine,  String questionLabel,  String reversedLabel,  String fallbackTitle)?  $default,) {final _that = this;
switch (_that) {
case _ShareCopy() when $default != null:
return $default(_that.disclaimerLine,_that.questionLabel,_that.reversedLabel,_that.fallbackTitle);case _:
  return null;

}
}

}

/// @nodoc


class _ShareCopy implements ShareCopy {
  const _ShareCopy({required this.disclaimerLine, required this.questionLabel, required this.reversedLabel, required this.fallbackTitle});
  

/// The disclaimer line (05 §3 `disclaimerShort`).
@override final  String disclaimerLine;
/// The label before the question, e.g. "My question".
@override final  String questionLabel;
/// The orientation label appended to a reversed card, e.g. "Reversed".
@override final  String reversedLabel;
/// The title when the reading has none (Classic): the spread name.
@override final  String fallbackTitle;

/// Create a copy of ShareCopy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareCopyCopyWith<_ShareCopy> get copyWith => __$ShareCopyCopyWithImpl<_ShareCopy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareCopy&&(identical(other.disclaimerLine, disclaimerLine) || other.disclaimerLine == disclaimerLine)&&(identical(other.questionLabel, questionLabel) || other.questionLabel == questionLabel)&&(identical(other.reversedLabel, reversedLabel) || other.reversedLabel == reversedLabel)&&(identical(other.fallbackTitle, fallbackTitle) || other.fallbackTitle == fallbackTitle));
}


@override
int get hashCode => Object.hash(runtimeType,disclaimerLine,questionLabel,reversedLabel,fallbackTitle);

@override
String toString() {
  return 'ShareCopy(disclaimerLine: $disclaimerLine, questionLabel: $questionLabel, reversedLabel: $reversedLabel, fallbackTitle: $fallbackTitle)';
}


}

/// @nodoc
abstract mixin class _$ShareCopyCopyWith<$Res> implements $ShareCopyCopyWith<$Res> {
  factory _$ShareCopyCopyWith(_ShareCopy value, $Res Function(_ShareCopy) _then) = __$ShareCopyCopyWithImpl;
@override @useResult
$Res call({
 String disclaimerLine, String questionLabel, String reversedLabel, String fallbackTitle
});




}
/// @nodoc
class __$ShareCopyCopyWithImpl<$Res>
    implements _$ShareCopyCopyWith<$Res> {
  __$ShareCopyCopyWithImpl(this._self, this._then);

  final _ShareCopy _self;
  final $Res Function(_ShareCopy) _then;

/// Create a copy of ShareCopy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? disclaimerLine = null,Object? questionLabel = null,Object? reversedLabel = null,Object? fallbackTitle = null,}) {
  return _then(_ShareCopy(
disclaimerLine: null == disclaimerLine ? _self.disclaimerLine : disclaimerLine // ignore: cast_nullable_to_non_nullable
as String,questionLabel: null == questionLabel ? _self.questionLabel : questionLabel // ignore: cast_nullable_to_non_nullable
as String,reversedLabel: null == reversedLabel ? _self.reversedLabel : reversedLabel // ignore: cast_nullable_to_non_nullable
as String,fallbackTitle: null == fallbackTitle ? _self.fallbackTitle : fallbackTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
