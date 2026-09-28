// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PositionText {

/// The spread position.
 PositionId get positionId;/// The interpretation (wire `cards[].interpretation`).
 String get text;
/// Create a copy of PositionText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionTextCopyWith<PositionText> get copyWith => _$PositionTextCopyWithImpl<PositionText>(this as PositionText, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionText&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,text);

@override
String toString() {
  return 'PositionText(positionId: $positionId, text: $text)';
}


}

/// @nodoc
abstract mixin class $PositionTextCopyWith<$Res>  {
  factory $PositionTextCopyWith(PositionText value, $Res Function(PositionText) _then) = _$PositionTextCopyWithImpl;
@useResult
$Res call({
 PositionId positionId, String text
});




}
/// @nodoc
class _$PositionTextCopyWithImpl<$Res>
    implements $PositionTextCopyWith<$Res> {
  _$PositionTextCopyWithImpl(this._self, this._then);

  final PositionText _self;
  final $Res Function(PositionText) _then;

/// Create a copy of PositionText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = null,Object? text = null,}) {
  return _then(_self.copyWith(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as PositionId,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionText].
extension PositionTextPatterns on PositionText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionText value)  $default,){
final _that = this;
switch (_that) {
case _PositionText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionText value)?  $default,){
final _that = this;
switch (_that) {
case _PositionText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PositionId positionId,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionText() when $default != null:
return $default(_that.positionId,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PositionId positionId,  String text)  $default,) {final _that = this;
switch (_that) {
case _PositionText():
return $default(_that.positionId,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PositionId positionId,  String text)?  $default,) {final _that = this;
switch (_that) {
case _PositionText() when $default != null:
return $default(_that.positionId,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _PositionText implements PositionText {
  const _PositionText({required this.positionId, required this.text});
  

/// The spread position.
@override final  PositionId positionId;
/// The interpretation (wire `cards[].interpretation`).
@override final  String text;

/// Create a copy of PositionText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionTextCopyWith<_PositionText> get copyWith => __$PositionTextCopyWithImpl<_PositionText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionText&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,text);

@override
String toString() {
  return 'PositionText(positionId: $positionId, text: $text)';
}


}

/// @nodoc
abstract mixin class _$PositionTextCopyWith<$Res> implements $PositionTextCopyWith<$Res> {
  factory _$PositionTextCopyWith(_PositionText value, $Res Function(_PositionText) _then) = __$PositionTextCopyWithImpl;
@override @useResult
$Res call({
 PositionId positionId, String text
});




}
/// @nodoc
class __$PositionTextCopyWithImpl<$Res>
    implements _$PositionTextCopyWith<$Res> {
  __$PositionTextCopyWithImpl(this._self, this._then);

  final _PositionText _self;
  final $Res Function(_PositionText) _then;

/// Create a copy of PositionText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = null,Object? text = null,}) {
  return _then(_PositionText(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as PositionId,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ReadingContent {

/// Title.
 String get title;/// Overview (wire `overview`).
 String get summary;/// One interpretation per position (wire `cards[]`).
 List<PositionText> get positions;/// Synthesis across the cards.
 String get synthesis;/// Up to three reflection prompts.
 List<String> get reflectionPrompts;
/// Create a copy of ReadingContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingContentCopyWith<ReadingContent> get copyWith => _$ReadingContentCopyWithImpl<ReadingContent>(this as ReadingContent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingContent&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.positions, positions)&&(identical(other.synthesis, synthesis) || other.synthesis == synthesis)&&const DeepCollectionEquality().equals(other.reflectionPrompts, reflectionPrompts));
}


@override
int get hashCode => Object.hash(runtimeType,title,summary,const DeepCollectionEquality().hash(positions),synthesis,const DeepCollectionEquality().hash(reflectionPrompts));

@override
String toString() {
  return 'ReadingContent(title: $title, summary: $summary, positions: $positions, synthesis: $synthesis, reflectionPrompts: $reflectionPrompts)';
}


}

/// @nodoc
abstract mixin class $ReadingContentCopyWith<$Res>  {
  factory $ReadingContentCopyWith(ReadingContent value, $Res Function(ReadingContent) _then) = _$ReadingContentCopyWithImpl;
@useResult
$Res call({
 String title, String summary, List<PositionText> positions, String synthesis, List<String> reflectionPrompts
});




}
/// @nodoc
class _$ReadingContentCopyWithImpl<$Res>
    implements $ReadingContentCopyWith<$Res> {
  _$ReadingContentCopyWithImpl(this._self, this._then);

  final ReadingContent _self;
  final $Res Function(ReadingContent) _then;

/// Create a copy of ReadingContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? summary = null,Object? positions = null,Object? synthesis = null,Object? reflectionPrompts = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,positions: null == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<PositionText>,synthesis: null == synthesis ? _self.synthesis : synthesis // ignore: cast_nullable_to_non_nullable
as String,reflectionPrompts: null == reflectionPrompts ? _self.reflectionPrompts : reflectionPrompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingContent].
extension ReadingContentPatterns on ReadingContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingContent value)  $default,){
final _that = this;
switch (_that) {
case _ReadingContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingContent value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String summary,  List<PositionText> positions,  String synthesis,  List<String> reflectionPrompts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingContent() when $default != null:
return $default(_that.title,_that.summary,_that.positions,_that.synthesis,_that.reflectionPrompts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String summary,  List<PositionText> positions,  String synthesis,  List<String> reflectionPrompts)  $default,) {final _that = this;
switch (_that) {
case _ReadingContent():
return $default(_that.title,_that.summary,_that.positions,_that.synthesis,_that.reflectionPrompts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String summary,  List<PositionText> positions,  String synthesis,  List<String> reflectionPrompts)?  $default,) {final _that = this;
switch (_that) {
case _ReadingContent() when $default != null:
return $default(_that.title,_that.summary,_that.positions,_that.synthesis,_that.reflectionPrompts);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingContent extends ReadingContent {
  const _ReadingContent({required this.title, required this.summary, required final  List<PositionText> positions, required this.synthesis, required final  List<String> reflectionPrompts}): _positions = positions,_reflectionPrompts = reflectionPrompts,super._();
  

/// Title.
@override final  String title;
/// Overview (wire `overview`).
@override final  String summary;
/// One interpretation per position (wire `cards[]`).
 final  List<PositionText> _positions;
/// One interpretation per position (wire `cards[]`).
@override List<PositionText> get positions {
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positions);
}

/// Synthesis across the cards.
@override final  String synthesis;
/// Up to three reflection prompts.
 final  List<String> _reflectionPrompts;
/// Up to three reflection prompts.
@override List<String> get reflectionPrompts {
  if (_reflectionPrompts is EqualUnmodifiableListView) return _reflectionPrompts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reflectionPrompts);
}


/// Create a copy of ReadingContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingContentCopyWith<_ReadingContent> get copyWith => __$ReadingContentCopyWithImpl<_ReadingContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingContent&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._positions, _positions)&&(identical(other.synthesis, synthesis) || other.synthesis == synthesis)&&const DeepCollectionEquality().equals(other._reflectionPrompts, _reflectionPrompts));
}


@override
int get hashCode => Object.hash(runtimeType,title,summary,const DeepCollectionEquality().hash(_positions),synthesis,const DeepCollectionEquality().hash(_reflectionPrompts));

@override
String toString() {
  return 'ReadingContent(title: $title, summary: $summary, positions: $positions, synthesis: $synthesis, reflectionPrompts: $reflectionPrompts)';
}


}

/// @nodoc
abstract mixin class _$ReadingContentCopyWith<$Res> implements $ReadingContentCopyWith<$Res> {
  factory _$ReadingContentCopyWith(_ReadingContent value, $Res Function(_ReadingContent) _then) = __$ReadingContentCopyWithImpl;
@override @useResult
$Res call({
 String title, String summary, List<PositionText> positions, String synthesis, List<String> reflectionPrompts
});




}
/// @nodoc
class __$ReadingContentCopyWithImpl<$Res>
    implements _$ReadingContentCopyWith<$Res> {
  __$ReadingContentCopyWithImpl(this._self, this._then);

  final _ReadingContent _self;
  final $Res Function(_ReadingContent) _then;

/// Create a copy of ReadingContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? summary = null,Object? positions = null,Object? synthesis = null,Object? reflectionPrompts = null,}) {
  return _then(_ReadingContent(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,positions: null == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<PositionText>,synthesis: null == synthesis ? _self.synthesis : synthesis // ignore: cast_nullable_to_non_nullable
as String,reflectionPrompts: null == reflectionPrompts ? _self._reflectionPrompts : reflectionPrompts // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
