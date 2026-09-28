// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeckCard {

/// `major_00` … `pentacles_14` (RC1).
 CardId get id;/// Major or minor arcana.
 Arcana get arcana;/// The suit; `null` for major arcana.
 Suit? get suit;/// 0–21 for major arcana, 1–14 for minor (01 = Ace … 14 = King).
 int get number;/// Art asset key of the bundled art set.
 String get artKey;/// The suit element; authored for majors.
 Element? get element;/// Authored astrological correspondence key, e.g. `venus`.
 String? get astrology;
/// Create a copy of DeckCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckCardCopyWith<DeckCard> get copyWith => _$DeckCardCopyWithImpl<DeckCard>(this as DeckCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckCard&&(identical(other.id, id) || other.id == id)&&(identical(other.arcana, arcana) || other.arcana == arcana)&&(identical(other.suit, suit) || other.suit == suit)&&(identical(other.number, number) || other.number == number)&&(identical(other.artKey, artKey) || other.artKey == artKey)&&(identical(other.element, element) || other.element == element)&&(identical(other.astrology, astrology) || other.astrology == astrology));
}


@override
int get hashCode => Object.hash(runtimeType,id,arcana,suit,number,artKey,element,astrology);

@override
String toString() {
  return 'DeckCard(id: $id, arcana: $arcana, suit: $suit, number: $number, artKey: $artKey, element: $element, astrology: $astrology)';
}


}

/// @nodoc
abstract mixin class $DeckCardCopyWith<$Res>  {
  factory $DeckCardCopyWith(DeckCard value, $Res Function(DeckCard) _then) = _$DeckCardCopyWithImpl;
@useResult
$Res call({
 CardId id, Arcana arcana, Suit? suit, int number, String artKey, Element? element, String? astrology
});




}
/// @nodoc
class _$DeckCardCopyWithImpl<$Res>
    implements $DeckCardCopyWith<$Res> {
  _$DeckCardCopyWithImpl(this._self, this._then);

  final DeckCard _self;
  final $Res Function(DeckCard) _then;

/// Create a copy of DeckCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? arcana = null,Object? suit = freezed,Object? number = null,Object? artKey = null,Object? element = freezed,Object? astrology = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CardId,arcana: null == arcana ? _self.arcana : arcana // ignore: cast_nullable_to_non_nullable
as Arcana,suit: freezed == suit ? _self.suit : suit // ignore: cast_nullable_to_non_nullable
as Suit?,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,artKey: null == artKey ? _self.artKey : artKey // ignore: cast_nullable_to_non_nullable
as String,element: freezed == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as Element?,astrology: freezed == astrology ? _self.astrology : astrology // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeckCard].
extension DeckCardPatterns on DeckCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeckCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeckCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeckCard value)  $default,){
final _that = this;
switch (_that) {
case _DeckCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeckCard value)?  $default,){
final _that = this;
switch (_that) {
case _DeckCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardId id,  Arcana arcana,  Suit? suit,  int number,  String artKey,  Element? element,  String? astrology)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeckCard() when $default != null:
return $default(_that.id,_that.arcana,_that.suit,_that.number,_that.artKey,_that.element,_that.astrology);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardId id,  Arcana arcana,  Suit? suit,  int number,  String artKey,  Element? element,  String? astrology)  $default,) {final _that = this;
switch (_that) {
case _DeckCard():
return $default(_that.id,_that.arcana,_that.suit,_that.number,_that.artKey,_that.element,_that.astrology);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardId id,  Arcana arcana,  Suit? suit,  int number,  String artKey,  Element? element,  String? astrology)?  $default,) {final _that = this;
switch (_that) {
case _DeckCard() when $default != null:
return $default(_that.id,_that.arcana,_that.suit,_that.number,_that.artKey,_that.element,_that.astrology);case _:
  return null;

}
}

}

/// @nodoc


class _DeckCard extends DeckCard {
  const _DeckCard({required this.id, required this.arcana, required this.suit, required this.number, required this.artKey, this.element, this.astrology}): super._();
  

/// `major_00` … `pentacles_14` (RC1).
@override final  CardId id;
/// Major or minor arcana.
@override final  Arcana arcana;
/// The suit; `null` for major arcana.
@override final  Suit? suit;
/// 0–21 for major arcana, 1–14 for minor (01 = Ace … 14 = King).
@override final  int number;
/// Art asset key of the bundled art set.
@override final  String artKey;
/// The suit element; authored for majors.
@override final  Element? element;
/// Authored astrological correspondence key, e.g. `venus`.
@override final  String? astrology;

/// Create a copy of DeckCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeckCardCopyWith<_DeckCard> get copyWith => __$DeckCardCopyWithImpl<_DeckCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeckCard&&(identical(other.id, id) || other.id == id)&&(identical(other.arcana, arcana) || other.arcana == arcana)&&(identical(other.suit, suit) || other.suit == suit)&&(identical(other.number, number) || other.number == number)&&(identical(other.artKey, artKey) || other.artKey == artKey)&&(identical(other.element, element) || other.element == element)&&(identical(other.astrology, astrology) || other.astrology == astrology));
}


@override
int get hashCode => Object.hash(runtimeType,id,arcana,suit,number,artKey,element,astrology);

@override
String toString() {
  return 'DeckCard(id: $id, arcana: $arcana, suit: $suit, number: $number, artKey: $artKey, element: $element, astrology: $astrology)';
}


}

/// @nodoc
abstract mixin class _$DeckCardCopyWith<$Res> implements $DeckCardCopyWith<$Res> {
  factory _$DeckCardCopyWith(_DeckCard value, $Res Function(_DeckCard) _then) = __$DeckCardCopyWithImpl;
@override @useResult
$Res call({
 CardId id, Arcana arcana, Suit? suit, int number, String artKey, Element? element, String? astrology
});




}
/// @nodoc
class __$DeckCardCopyWithImpl<$Res>
    implements _$DeckCardCopyWith<$Res> {
  __$DeckCardCopyWithImpl(this._self, this._then);

  final _DeckCard _self;
  final $Res Function(_DeckCard) _then;

/// Create a copy of DeckCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? arcana = null,Object? suit = freezed,Object? number = null,Object? artKey = null,Object? element = freezed,Object? astrology = freezed,}) {
  return _then(_DeckCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as CardId,arcana: null == arcana ? _self.arcana : arcana // ignore: cast_nullable_to_non_nullable
as Arcana,suit: freezed == suit ? _self.suit : suit // ignore: cast_nullable_to_non_nullable
as Suit?,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,artKey: null == artKey ? _self.artKey : artKey // ignore: cast_nullable_to_non_nullable
as String,element: freezed == element ? _self.element : element // ignore: cast_nullable_to_non_nullable
as Element?,astrology: freezed == astrology ? _self.astrology : astrology // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
