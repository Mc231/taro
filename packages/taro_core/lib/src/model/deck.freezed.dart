// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Deck {

/// Deck ID, `rws_original`.
 String get id;/// Content version.
 int get version;/// The 78 cards.
 List<DeckCard> get cards;/// Art set key.
 String get artSet;
/// Create a copy of Deck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckCopyWith<Deck> get copyWith => _$DeckCopyWithImpl<Deck>(this as Deck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Deck&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.artSet, artSet) || other.artSet == artSet));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,const DeepCollectionEquality().hash(cards),artSet);

@override
String toString() {
  return 'Deck(id: $id, version: $version, cards: $cards, artSet: $artSet)';
}


}

/// @nodoc
abstract mixin class $DeckCopyWith<$Res>  {
  factory $DeckCopyWith(Deck value, $Res Function(Deck) _then) = _$DeckCopyWithImpl;
@useResult
$Res call({
 String id, int version, List<DeckCard> cards, String artSet
});




}
/// @nodoc
class _$DeckCopyWithImpl<$Res>
    implements $DeckCopyWith<$Res> {
  _$DeckCopyWithImpl(this._self, this._then);

  final Deck _self;
  final $Res Function(Deck) _then;

/// Create a copy of Deck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? cards = null,Object? artSet = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<DeckCard>,artSet: null == artSet ? _self.artSet : artSet // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Deck].
extension DeckPatterns on Deck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Deck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Deck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Deck value)  $default,){
final _that = this;
switch (_that) {
case _Deck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Deck value)?  $default,){
final _that = this;
switch (_that) {
case _Deck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int version,  List<DeckCard> cards,  String artSet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Deck() when $default != null:
return $default(_that.id,_that.version,_that.cards,_that.artSet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int version,  List<DeckCard> cards,  String artSet)  $default,) {final _that = this;
switch (_that) {
case _Deck():
return $default(_that.id,_that.version,_that.cards,_that.artSet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int version,  List<DeckCard> cards,  String artSet)?  $default,) {final _that = this;
switch (_that) {
case _Deck() when $default != null:
return $default(_that.id,_that.version,_that.cards,_that.artSet);case _:
  return null;

}
}

}

/// @nodoc


class _Deck extends Deck {
  const _Deck({required this.id, required this.version, required final  List<DeckCard> cards, required this.artSet}): _cards = cards,super._();
  

/// Deck ID, `rws_original`.
@override final  String id;
/// Content version.
@override final  int version;
/// The 78 cards.
 final  List<DeckCard> _cards;
/// The 78 cards.
@override List<DeckCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

/// Art set key.
@override final  String artSet;

/// Create a copy of Deck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeckCopyWith<_Deck> get copyWith => __$DeckCopyWithImpl<_Deck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Deck&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.artSet, artSet) || other.artSet == artSet));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,const DeepCollectionEquality().hash(_cards),artSet);

@override
String toString() {
  return 'Deck(id: $id, version: $version, cards: $cards, artSet: $artSet)';
}


}

/// @nodoc
abstract mixin class _$DeckCopyWith<$Res> implements $DeckCopyWith<$Res> {
  factory _$DeckCopyWith(_Deck value, $Res Function(_Deck) _then) = __$DeckCopyWithImpl;
@override @useResult
$Res call({
 String id, int version, List<DeckCard> cards, String artSet
});




}
/// @nodoc
class __$DeckCopyWithImpl<$Res>
    implements _$DeckCopyWith<$Res> {
  __$DeckCopyWithImpl(this._self, this._then);

  final _Deck _self;
  final $Res Function(_Deck) _then;

/// Create a copy of Deck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? cards = null,Object? artSet = null,}) {
  return _then(_Deck(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<DeckCard>,artSet: null == artSet ? _self.artSet : artSet // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
