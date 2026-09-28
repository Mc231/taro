// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CardAspects {

/// Relationships, upright.
 String get relationshipsUpright;/// Relationships, reversed.
 String get relationshipsReversed;/// Work, upright.
 String get workUpright;/// Work, reversed.
 String get workReversed;/// Personal growth, upright.
 String get growthUpright;/// Personal growth, reversed.
 String get growthReversed;
/// Create a copy of CardAspects
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardAspectsCopyWith<CardAspects> get copyWith => _$CardAspectsCopyWithImpl<CardAspects>(this as CardAspects, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardAspects&&(identical(other.relationshipsUpright, relationshipsUpright) || other.relationshipsUpright == relationshipsUpright)&&(identical(other.relationshipsReversed, relationshipsReversed) || other.relationshipsReversed == relationshipsReversed)&&(identical(other.workUpright, workUpright) || other.workUpright == workUpright)&&(identical(other.workReversed, workReversed) || other.workReversed == workReversed)&&(identical(other.growthUpright, growthUpright) || other.growthUpright == growthUpright)&&(identical(other.growthReversed, growthReversed) || other.growthReversed == growthReversed));
}


@override
int get hashCode => Object.hash(runtimeType,relationshipsUpright,relationshipsReversed,workUpright,workReversed,growthUpright,growthReversed);

@override
String toString() {
  return 'CardAspects(relationshipsUpright: $relationshipsUpright, relationshipsReversed: $relationshipsReversed, workUpright: $workUpright, workReversed: $workReversed, growthUpright: $growthUpright, growthReversed: $growthReversed)';
}


}

/// @nodoc
abstract mixin class $CardAspectsCopyWith<$Res>  {
  factory $CardAspectsCopyWith(CardAspects value, $Res Function(CardAspects) _then) = _$CardAspectsCopyWithImpl;
@useResult
$Res call({
 String relationshipsUpright, String relationshipsReversed, String workUpright, String workReversed, String growthUpright, String growthReversed
});




}
/// @nodoc
class _$CardAspectsCopyWithImpl<$Res>
    implements $CardAspectsCopyWith<$Res> {
  _$CardAspectsCopyWithImpl(this._self, this._then);

  final CardAspects _self;
  final $Res Function(CardAspects) _then;

/// Create a copy of CardAspects
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? relationshipsUpright = null,Object? relationshipsReversed = null,Object? workUpright = null,Object? workReversed = null,Object? growthUpright = null,Object? growthReversed = null,}) {
  return _then(_self.copyWith(
relationshipsUpright: null == relationshipsUpright ? _self.relationshipsUpright : relationshipsUpright // ignore: cast_nullable_to_non_nullable
as String,relationshipsReversed: null == relationshipsReversed ? _self.relationshipsReversed : relationshipsReversed // ignore: cast_nullable_to_non_nullable
as String,workUpright: null == workUpright ? _self.workUpright : workUpright // ignore: cast_nullable_to_non_nullable
as String,workReversed: null == workReversed ? _self.workReversed : workReversed // ignore: cast_nullable_to_non_nullable
as String,growthUpright: null == growthUpright ? _self.growthUpright : growthUpright // ignore: cast_nullable_to_non_nullable
as String,growthReversed: null == growthReversed ? _self.growthReversed : growthReversed // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CardAspects].
extension CardAspectsPatterns on CardAspects {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardAspects value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardAspects() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardAspects value)  $default,){
final _that = this;
switch (_that) {
case _CardAspects():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardAspects value)?  $default,){
final _that = this;
switch (_that) {
case _CardAspects() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String relationshipsUpright,  String relationshipsReversed,  String workUpright,  String workReversed,  String growthUpright,  String growthReversed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardAspects() when $default != null:
return $default(_that.relationshipsUpright,_that.relationshipsReversed,_that.workUpright,_that.workReversed,_that.growthUpright,_that.growthReversed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String relationshipsUpright,  String relationshipsReversed,  String workUpright,  String workReversed,  String growthUpright,  String growthReversed)  $default,) {final _that = this;
switch (_that) {
case _CardAspects():
return $default(_that.relationshipsUpright,_that.relationshipsReversed,_that.workUpright,_that.workReversed,_that.growthUpright,_that.growthReversed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String relationshipsUpright,  String relationshipsReversed,  String workUpright,  String workReversed,  String growthUpright,  String growthReversed)?  $default,) {final _that = this;
switch (_that) {
case _CardAspects() when $default != null:
return $default(_that.relationshipsUpright,_that.relationshipsReversed,_that.workUpright,_that.workReversed,_that.growthUpright,_that.growthReversed);case _:
  return null;

}
}

}

/// @nodoc


class _CardAspects implements CardAspects {
  const _CardAspects({required this.relationshipsUpright, required this.relationshipsReversed, required this.workUpright, required this.workReversed, required this.growthUpright, required this.growthReversed});
  

/// Relationships, upright.
@override final  String relationshipsUpright;
/// Relationships, reversed.
@override final  String relationshipsReversed;
/// Work, upright.
@override final  String workUpright;
/// Work, reversed.
@override final  String workReversed;
/// Personal growth, upright.
@override final  String growthUpright;
/// Personal growth, reversed.
@override final  String growthReversed;

/// Create a copy of CardAspects
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardAspectsCopyWith<_CardAspects> get copyWith => __$CardAspectsCopyWithImpl<_CardAspects>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardAspects&&(identical(other.relationshipsUpright, relationshipsUpright) || other.relationshipsUpright == relationshipsUpright)&&(identical(other.relationshipsReversed, relationshipsReversed) || other.relationshipsReversed == relationshipsReversed)&&(identical(other.workUpright, workUpright) || other.workUpright == workUpright)&&(identical(other.workReversed, workReversed) || other.workReversed == workReversed)&&(identical(other.growthUpright, growthUpright) || other.growthUpright == growthUpright)&&(identical(other.growthReversed, growthReversed) || other.growthReversed == growthReversed));
}


@override
int get hashCode => Object.hash(runtimeType,relationshipsUpright,relationshipsReversed,workUpright,workReversed,growthUpright,growthReversed);

@override
String toString() {
  return 'CardAspects(relationshipsUpright: $relationshipsUpright, relationshipsReversed: $relationshipsReversed, workUpright: $workUpright, workReversed: $workReversed, growthUpright: $growthUpright, growthReversed: $growthReversed)';
}


}

/// @nodoc
abstract mixin class _$CardAspectsCopyWith<$Res> implements $CardAspectsCopyWith<$Res> {
  factory _$CardAspectsCopyWith(_CardAspects value, $Res Function(_CardAspects) _then) = __$CardAspectsCopyWithImpl;
@override @useResult
$Res call({
 String relationshipsUpright, String relationshipsReversed, String workUpright, String workReversed, String growthUpright, String growthReversed
});




}
/// @nodoc
class __$CardAspectsCopyWithImpl<$Res>
    implements _$CardAspectsCopyWith<$Res> {
  __$CardAspectsCopyWithImpl(this._self, this._then);

  final _CardAspects _self;
  final $Res Function(_CardAspects) _then;

/// Create a copy of CardAspects
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? relationshipsUpright = null,Object? relationshipsReversed = null,Object? workUpright = null,Object? workReversed = null,Object? growthUpright = null,Object? growthReversed = null,}) {
  return _then(_CardAspects(
relationshipsUpright: null == relationshipsUpright ? _self.relationshipsUpright : relationshipsUpright // ignore: cast_nullable_to_non_nullable
as String,relationshipsReversed: null == relationshipsReversed ? _self.relationshipsReversed : relationshipsReversed // ignore: cast_nullable_to_non_nullable
as String,workUpright: null == workUpright ? _self.workUpright : workUpright // ignore: cast_nullable_to_non_nullable
as String,workReversed: null == workReversed ? _self.workReversed : workReversed // ignore: cast_nullable_to_non_nullable
as String,growthUpright: null == growthUpright ? _self.growthUpright : growthUpright // ignore: cast_nullable_to_non_nullable
as String,growthReversed: null == growthReversed ? _self.growthReversed : growthReversed // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CardText {

/// The card this text belongs to.
 CardId get cardId;/// One of the 12 app locales.
 String get locale;/// Glossary-locked card name.
 String get name;/// 3–6 upright keywords.
 List<String> get keywordsUpright;/// 3–6 reversed keywords.
 List<String> get keywordsReversed;/// ≤ 160 chars; daily card and reveal.
 String get shortUpright;/// ≤ 160 chars.
 String get shortReversed;/// 120–220 words.
 String get meaningUpright;/// 100–200 words.
 String get meaningReversed;/// Aspect meanings.
 CardAspects get aspects;/// Three reflection questions.
 List<String> get reflectionQuestions;/// Hash of the `en` source this translation came from.
 String get sourceHash;/// Review state of this translation.
 ReviewStatus get reviewStatus;/// 40–100 words on the art's symbolism.
 String? get imageryNote;
/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardTextCopyWith<CardText> get copyWith => _$CardTextCopyWithImpl<CardText>(this as CardText, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardText&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.keywordsUpright, keywordsUpright)&&const DeepCollectionEquality().equals(other.keywordsReversed, keywordsReversed)&&(identical(other.shortUpright, shortUpright) || other.shortUpright == shortUpright)&&(identical(other.shortReversed, shortReversed) || other.shortReversed == shortReversed)&&(identical(other.meaningUpright, meaningUpright) || other.meaningUpright == meaningUpright)&&(identical(other.meaningReversed, meaningReversed) || other.meaningReversed == meaningReversed)&&(identical(other.aspects, aspects) || other.aspects == aspects)&&const DeepCollectionEquality().equals(other.reflectionQuestions, reflectionQuestions)&&(identical(other.sourceHash, sourceHash) || other.sourceHash == sourceHash)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.imageryNote, imageryNote) || other.imageryNote == imageryNote));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,locale,name,const DeepCollectionEquality().hash(keywordsUpright),const DeepCollectionEquality().hash(keywordsReversed),shortUpright,shortReversed,meaningUpright,meaningReversed,aspects,const DeepCollectionEquality().hash(reflectionQuestions),sourceHash,reviewStatus,imageryNote);

@override
String toString() {
  return 'CardText(cardId: $cardId, locale: $locale, name: $name, keywordsUpright: $keywordsUpright, keywordsReversed: $keywordsReversed, shortUpright: $shortUpright, shortReversed: $shortReversed, meaningUpright: $meaningUpright, meaningReversed: $meaningReversed, aspects: $aspects, reflectionQuestions: $reflectionQuestions, sourceHash: $sourceHash, reviewStatus: $reviewStatus, imageryNote: $imageryNote)';
}


}

/// @nodoc
abstract mixin class $CardTextCopyWith<$Res>  {
  factory $CardTextCopyWith(CardText value, $Res Function(CardText) _then) = _$CardTextCopyWithImpl;
@useResult
$Res call({
 CardId cardId, String locale, String name, List<String> keywordsUpright, List<String> keywordsReversed, String shortUpright, String shortReversed, String meaningUpright, String meaningReversed, CardAspects aspects, List<String> reflectionQuestions, String sourceHash, ReviewStatus reviewStatus, String? imageryNote
});


$CardAspectsCopyWith<$Res> get aspects;

}
/// @nodoc
class _$CardTextCopyWithImpl<$Res>
    implements $CardTextCopyWith<$Res> {
  _$CardTextCopyWithImpl(this._self, this._then);

  final CardText _self;
  final $Res Function(CardText) _then;

/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardId = null,Object? locale = null,Object? name = null,Object? keywordsUpright = null,Object? keywordsReversed = null,Object? shortUpright = null,Object? shortReversed = null,Object? meaningUpright = null,Object? meaningReversed = null,Object? aspects = null,Object? reflectionQuestions = null,Object? sourceHash = null,Object? reviewStatus = null,Object? imageryNote = freezed,}) {
  return _then(_self.copyWith(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keywordsUpright: null == keywordsUpright ? _self.keywordsUpright : keywordsUpright // ignore: cast_nullable_to_non_nullable
as List<String>,keywordsReversed: null == keywordsReversed ? _self.keywordsReversed : keywordsReversed // ignore: cast_nullable_to_non_nullable
as List<String>,shortUpright: null == shortUpright ? _self.shortUpright : shortUpright // ignore: cast_nullable_to_non_nullable
as String,shortReversed: null == shortReversed ? _self.shortReversed : shortReversed // ignore: cast_nullable_to_non_nullable
as String,meaningUpright: null == meaningUpright ? _self.meaningUpright : meaningUpright // ignore: cast_nullable_to_non_nullable
as String,meaningReversed: null == meaningReversed ? _self.meaningReversed : meaningReversed // ignore: cast_nullable_to_non_nullable
as String,aspects: null == aspects ? _self.aspects : aspects // ignore: cast_nullable_to_non_nullable
as CardAspects,reflectionQuestions: null == reflectionQuestions ? _self.reflectionQuestions : reflectionQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,sourceHash: null == sourceHash ? _self.sourceHash : sourceHash // ignore: cast_nullable_to_non_nullable
as String,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,imageryNote: freezed == imageryNote ? _self.imageryNote : imageryNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardAspectsCopyWith<$Res> get aspects {
  
  return $CardAspectsCopyWith<$Res>(_self.aspects, (value) {
    return _then(_self.copyWith(aspects: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardText].
extension CardTextPatterns on CardText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardText value)  $default,){
final _that = this;
switch (_that) {
case _CardText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardText value)?  $default,){
final _that = this;
switch (_that) {
case _CardText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardId cardId,  String locale,  String name,  List<String> keywordsUpright,  List<String> keywordsReversed,  String shortUpright,  String shortReversed,  String meaningUpright,  String meaningReversed,  CardAspects aspects,  List<String> reflectionQuestions,  String sourceHash,  ReviewStatus reviewStatus,  String? imageryNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardText() when $default != null:
return $default(_that.cardId,_that.locale,_that.name,_that.keywordsUpright,_that.keywordsReversed,_that.shortUpright,_that.shortReversed,_that.meaningUpright,_that.meaningReversed,_that.aspects,_that.reflectionQuestions,_that.sourceHash,_that.reviewStatus,_that.imageryNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardId cardId,  String locale,  String name,  List<String> keywordsUpright,  List<String> keywordsReversed,  String shortUpright,  String shortReversed,  String meaningUpright,  String meaningReversed,  CardAspects aspects,  List<String> reflectionQuestions,  String sourceHash,  ReviewStatus reviewStatus,  String? imageryNote)  $default,) {final _that = this;
switch (_that) {
case _CardText():
return $default(_that.cardId,_that.locale,_that.name,_that.keywordsUpright,_that.keywordsReversed,_that.shortUpright,_that.shortReversed,_that.meaningUpright,_that.meaningReversed,_that.aspects,_that.reflectionQuestions,_that.sourceHash,_that.reviewStatus,_that.imageryNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardId cardId,  String locale,  String name,  List<String> keywordsUpright,  List<String> keywordsReversed,  String shortUpright,  String shortReversed,  String meaningUpright,  String meaningReversed,  CardAspects aspects,  List<String> reflectionQuestions,  String sourceHash,  ReviewStatus reviewStatus,  String? imageryNote)?  $default,) {final _that = this;
switch (_that) {
case _CardText() when $default != null:
return $default(_that.cardId,_that.locale,_that.name,_that.keywordsUpright,_that.keywordsReversed,_that.shortUpright,_that.shortReversed,_that.meaningUpright,_that.meaningReversed,_that.aspects,_that.reflectionQuestions,_that.sourceHash,_that.reviewStatus,_that.imageryNote);case _:
  return null;

}
}

}

/// @nodoc


class _CardText extends CardText {
  const _CardText({required this.cardId, required this.locale, required this.name, required final  List<String> keywordsUpright, required final  List<String> keywordsReversed, required this.shortUpright, required this.shortReversed, required this.meaningUpright, required this.meaningReversed, required this.aspects, required final  List<String> reflectionQuestions, required this.sourceHash, required this.reviewStatus, this.imageryNote}): _keywordsUpright = keywordsUpright,_keywordsReversed = keywordsReversed,_reflectionQuestions = reflectionQuestions,super._();
  

/// The card this text belongs to.
@override final  CardId cardId;
/// One of the 12 app locales.
@override final  String locale;
/// Glossary-locked card name.
@override final  String name;
/// 3–6 upright keywords.
 final  List<String> _keywordsUpright;
/// 3–6 upright keywords.
@override List<String> get keywordsUpright {
  if (_keywordsUpright is EqualUnmodifiableListView) return _keywordsUpright;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywordsUpright);
}

/// 3–6 reversed keywords.
 final  List<String> _keywordsReversed;
/// 3–6 reversed keywords.
@override List<String> get keywordsReversed {
  if (_keywordsReversed is EqualUnmodifiableListView) return _keywordsReversed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keywordsReversed);
}

/// ≤ 160 chars; daily card and reveal.
@override final  String shortUpright;
/// ≤ 160 chars.
@override final  String shortReversed;
/// 120–220 words.
@override final  String meaningUpright;
/// 100–200 words.
@override final  String meaningReversed;
/// Aspect meanings.
@override final  CardAspects aspects;
/// Three reflection questions.
 final  List<String> _reflectionQuestions;
/// Three reflection questions.
@override List<String> get reflectionQuestions {
  if (_reflectionQuestions is EqualUnmodifiableListView) return _reflectionQuestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reflectionQuestions);
}

/// Hash of the `en` source this translation came from.
@override final  String sourceHash;
/// Review state of this translation.
@override final  ReviewStatus reviewStatus;
/// 40–100 words on the art's symbolism.
@override final  String? imageryNote;

/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardTextCopyWith<_CardText> get copyWith => __$CardTextCopyWithImpl<_CardText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardText&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._keywordsUpright, _keywordsUpright)&&const DeepCollectionEquality().equals(other._keywordsReversed, _keywordsReversed)&&(identical(other.shortUpright, shortUpright) || other.shortUpright == shortUpright)&&(identical(other.shortReversed, shortReversed) || other.shortReversed == shortReversed)&&(identical(other.meaningUpright, meaningUpright) || other.meaningUpright == meaningUpright)&&(identical(other.meaningReversed, meaningReversed) || other.meaningReversed == meaningReversed)&&(identical(other.aspects, aspects) || other.aspects == aspects)&&const DeepCollectionEquality().equals(other._reflectionQuestions, _reflectionQuestions)&&(identical(other.sourceHash, sourceHash) || other.sourceHash == sourceHash)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.imageryNote, imageryNote) || other.imageryNote == imageryNote));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,locale,name,const DeepCollectionEquality().hash(_keywordsUpright),const DeepCollectionEquality().hash(_keywordsReversed),shortUpright,shortReversed,meaningUpright,meaningReversed,aspects,const DeepCollectionEquality().hash(_reflectionQuestions),sourceHash,reviewStatus,imageryNote);

@override
String toString() {
  return 'CardText(cardId: $cardId, locale: $locale, name: $name, keywordsUpright: $keywordsUpright, keywordsReversed: $keywordsReversed, shortUpright: $shortUpright, shortReversed: $shortReversed, meaningUpright: $meaningUpright, meaningReversed: $meaningReversed, aspects: $aspects, reflectionQuestions: $reflectionQuestions, sourceHash: $sourceHash, reviewStatus: $reviewStatus, imageryNote: $imageryNote)';
}


}

/// @nodoc
abstract mixin class _$CardTextCopyWith<$Res> implements $CardTextCopyWith<$Res> {
  factory _$CardTextCopyWith(_CardText value, $Res Function(_CardText) _then) = __$CardTextCopyWithImpl;
@override @useResult
$Res call({
 CardId cardId, String locale, String name, List<String> keywordsUpright, List<String> keywordsReversed, String shortUpright, String shortReversed, String meaningUpright, String meaningReversed, CardAspects aspects, List<String> reflectionQuestions, String sourceHash, ReviewStatus reviewStatus, String? imageryNote
});


@override $CardAspectsCopyWith<$Res> get aspects;

}
/// @nodoc
class __$CardTextCopyWithImpl<$Res>
    implements _$CardTextCopyWith<$Res> {
  __$CardTextCopyWithImpl(this._self, this._then);

  final _CardText _self;
  final $Res Function(_CardText) _then;

/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardId = null,Object? locale = null,Object? name = null,Object? keywordsUpright = null,Object? keywordsReversed = null,Object? shortUpright = null,Object? shortReversed = null,Object? meaningUpright = null,Object? meaningReversed = null,Object? aspects = null,Object? reflectionQuestions = null,Object? sourceHash = null,Object? reviewStatus = null,Object? imageryNote = freezed,}) {
  return _then(_CardText(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keywordsUpright: null == keywordsUpright ? _self._keywordsUpright : keywordsUpright // ignore: cast_nullable_to_non_nullable
as List<String>,keywordsReversed: null == keywordsReversed ? _self._keywordsReversed : keywordsReversed // ignore: cast_nullable_to_non_nullable
as List<String>,shortUpright: null == shortUpright ? _self.shortUpright : shortUpright // ignore: cast_nullable_to_non_nullable
as String,shortReversed: null == shortReversed ? _self.shortReversed : shortReversed // ignore: cast_nullable_to_non_nullable
as String,meaningUpright: null == meaningUpright ? _self.meaningUpright : meaningUpright // ignore: cast_nullable_to_non_nullable
as String,meaningReversed: null == meaningReversed ? _self.meaningReversed : meaningReversed // ignore: cast_nullable_to_non_nullable
as String,aspects: null == aspects ? _self.aspects : aspects // ignore: cast_nullable_to_non_nullable
as CardAspects,reflectionQuestions: null == reflectionQuestions ? _self._reflectionQuestions : reflectionQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,sourceHash: null == sourceHash ? _self.sourceHash : sourceHash // ignore: cast_nullable_to_non_nullable
as String,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,imageryNote: freezed == imageryNote ? _self.imageryNote : imageryNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CardText
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardAspectsCopyWith<$Res> get aspects {
  
  return $CardAspectsCopyWith<$Res>(_self.aspects, (value) {
    return _then(_self.copyWith(aspects: value));
  });
}
}

// dart format on
