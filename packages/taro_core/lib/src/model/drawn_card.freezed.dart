// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawn_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrawnCard {

/// The spread position.
 PositionId get positionId;/// The card.
 CardId get cardId;/// Whether the card is reversed.
 bool get reversed;
/// Create a copy of DrawnCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawnCardCopyWith<DrawnCard> get copyWith => _$DrawnCardCopyWithImpl<DrawnCard>(this as DrawnCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawnCard&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,cardId,reversed);

@override
String toString() {
  return 'DrawnCard(positionId: $positionId, cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class $DrawnCardCopyWith<$Res>  {
  factory $DrawnCardCopyWith(DrawnCard value, $Res Function(DrawnCard) _then) = _$DrawnCardCopyWithImpl;
@useResult
$Res call({
 PositionId positionId, CardId cardId, bool reversed
});




}
/// @nodoc
class _$DrawnCardCopyWithImpl<$Res>
    implements $DrawnCardCopyWith<$Res> {
  _$DrawnCardCopyWithImpl(this._self, this._then);

  final DrawnCard _self;
  final $Res Function(DrawnCard) _then;

/// Create a copy of DrawnCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionId = null,Object? cardId = null,Object? reversed = null,}) {
  return _then(_self.copyWith(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as PositionId,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawnCard].
extension DrawnCardPatterns on DrawnCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawnCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawnCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawnCard value)  $default,){
final _that = this;
switch (_that) {
case _DrawnCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawnCard value)?  $default,){
final _that = this;
switch (_that) {
case _DrawnCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PositionId positionId,  CardId cardId,  bool reversed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawnCard() when $default != null:
return $default(_that.positionId,_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PositionId positionId,  CardId cardId,  bool reversed)  $default,) {final _that = this;
switch (_that) {
case _DrawnCard():
return $default(_that.positionId,_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PositionId positionId,  CardId cardId,  bool reversed)?  $default,) {final _that = this;
switch (_that) {
case _DrawnCard() when $default != null:
return $default(_that.positionId,_that.cardId,_that.reversed);case _:
  return null;

}
}

}

/// @nodoc


class _DrawnCard extends DrawnCard {
  const _DrawnCard({required this.positionId, required this.cardId, required this.reversed}): super._();
  

/// The spread position.
@override final  PositionId positionId;
/// The card.
@override final  CardId cardId;
/// Whether the card is reversed.
@override final  bool reversed;

/// Create a copy of DrawnCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawnCardCopyWith<_DrawnCard> get copyWith => __$DrawnCardCopyWithImpl<_DrawnCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawnCard&&(identical(other.positionId, positionId) || other.positionId == positionId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,positionId,cardId,reversed);

@override
String toString() {
  return 'DrawnCard(positionId: $positionId, cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class _$DrawnCardCopyWith<$Res> implements $DrawnCardCopyWith<$Res> {
  factory _$DrawnCardCopyWith(_DrawnCard value, $Res Function(_DrawnCard) _then) = __$DrawnCardCopyWithImpl;
@override @useResult
$Res call({
 PositionId positionId, CardId cardId, bool reversed
});




}
/// @nodoc
class __$DrawnCardCopyWithImpl<$Res>
    implements _$DrawnCardCopyWith<$Res> {
  __$DrawnCardCopyWithImpl(this._self, this._then);

  final _DrawnCard _self;
  final $Res Function(_DrawnCard) _then;

/// Create a copy of DrawnCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionId = null,Object? cardId = null,Object? reversed = null,}) {
  return _then(_DrawnCard(
positionId: null == positionId ? _self.positionId : positionId // ignore: cast_nullable_to_non_nullable
as PositionId,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
