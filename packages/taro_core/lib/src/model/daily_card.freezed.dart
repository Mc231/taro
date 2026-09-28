// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyCard {

/// Local calendar date `YYYY-MM-DD` (primary key).
 String get localDate;/// The card.
 CardId get cardId;/// Whether the card is reversed.
 bool get reversed;/// When the card was drawn (UTC).
 DateTime get drawnAt;/// Row creation time (UTC; backup `createdAt`, RC70).
 DateTime get createdAt;/// Last change (UTC); the newer one wins a backup merge.
 DateTime get updatedAt;/// The user's note.
 String? get note;/// Favourite flag.
 bool get favourite;
/// Create a copy of DailyCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardCopyWith<DailyCard> get copyWith => _$DailyCardCopyWithImpl<DailyCard>(this as DailyCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCard&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed)&&(identical(other.drawnAt, drawnAt) || other.drawnAt == drawnAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.favourite, favourite) || other.favourite == favourite));
}


@override
int get hashCode => Object.hash(runtimeType,localDate,cardId,reversed,drawnAt,createdAt,updatedAt,note,favourite);

@override
String toString() {
  return 'DailyCard(localDate: $localDate, cardId: $cardId, reversed: $reversed, drawnAt: $drawnAt, createdAt: $createdAt, updatedAt: $updatedAt, note: $note, favourite: $favourite)';
}


}

/// @nodoc
abstract mixin class $DailyCardCopyWith<$Res>  {
  factory $DailyCardCopyWith(DailyCard value, $Res Function(DailyCard) _then) = _$DailyCardCopyWithImpl;
@useResult
$Res call({
 String localDate, CardId cardId, bool reversed, DateTime drawnAt, DateTime createdAt, DateTime updatedAt, String? note, bool favourite
});




}
/// @nodoc
class _$DailyCardCopyWithImpl<$Res>
    implements $DailyCardCopyWith<$Res> {
  _$DailyCardCopyWithImpl(this._self, this._then);

  final DailyCard _self;
  final $Res Function(DailyCard) _then;

/// Create a copy of DailyCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localDate = null,Object? cardId = null,Object? reversed = null,Object? drawnAt = null,Object? createdAt = null,Object? updatedAt = null,Object? note = freezed,Object? favourite = null,}) {
  return _then(_self.copyWith(
localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,drawnAt: null == drawnAt ? _self.drawnAt : drawnAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,favourite: null == favourite ? _self.favourite : favourite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyCard].
extension DailyCardPatterns on DailyCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyCard value)  $default,){
final _that = this;
switch (_that) {
case _DailyCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyCard value)?  $default,){
final _that = this;
switch (_that) {
case _DailyCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localDate,  CardId cardId,  bool reversed,  DateTime drawnAt,  DateTime createdAt,  DateTime updatedAt,  String? note,  bool favourite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyCard() when $default != null:
return $default(_that.localDate,_that.cardId,_that.reversed,_that.drawnAt,_that.createdAt,_that.updatedAt,_that.note,_that.favourite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localDate,  CardId cardId,  bool reversed,  DateTime drawnAt,  DateTime createdAt,  DateTime updatedAt,  String? note,  bool favourite)  $default,) {final _that = this;
switch (_that) {
case _DailyCard():
return $default(_that.localDate,_that.cardId,_that.reversed,_that.drawnAt,_that.createdAt,_that.updatedAt,_that.note,_that.favourite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localDate,  CardId cardId,  bool reversed,  DateTime drawnAt,  DateTime createdAt,  DateTime updatedAt,  String? note,  bool favourite)?  $default,) {final _that = this;
switch (_that) {
case _DailyCard() when $default != null:
return $default(_that.localDate,_that.cardId,_that.reversed,_that.drawnAt,_that.createdAt,_that.updatedAt,_that.note,_that.favourite);case _:
  return null;

}
}

}

/// @nodoc


class _DailyCard extends DailyCard {
  const _DailyCard({required this.localDate, required this.cardId, required this.reversed, required this.drawnAt, required this.createdAt, required this.updatedAt, this.note, this.favourite = false}): super._();
  

/// Local calendar date `YYYY-MM-DD` (primary key).
@override final  String localDate;
/// The card.
@override final  CardId cardId;
/// Whether the card is reversed.
@override final  bool reversed;
/// When the card was drawn (UTC).
@override final  DateTime drawnAt;
/// Row creation time (UTC; backup `createdAt`, RC70).
@override final  DateTime createdAt;
/// Last change (UTC); the newer one wins a backup merge.
@override final  DateTime updatedAt;
/// The user's note.
@override final  String? note;
/// Favourite flag.
@override@JsonKey() final  bool favourite;

/// Create a copy of DailyCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyCardCopyWith<_DailyCard> get copyWith => __$DailyCardCopyWithImpl<_DailyCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyCard&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed)&&(identical(other.drawnAt, drawnAt) || other.drawnAt == drawnAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.favourite, favourite) || other.favourite == favourite));
}


@override
int get hashCode => Object.hash(runtimeType,localDate,cardId,reversed,drawnAt,createdAt,updatedAt,note,favourite);

@override
String toString() {
  return 'DailyCard(localDate: $localDate, cardId: $cardId, reversed: $reversed, drawnAt: $drawnAt, createdAt: $createdAt, updatedAt: $updatedAt, note: $note, favourite: $favourite)';
}


}

/// @nodoc
abstract mixin class _$DailyCardCopyWith<$Res> implements $DailyCardCopyWith<$Res> {
  factory _$DailyCardCopyWith(_DailyCard value, $Res Function(_DailyCard) _then) = __$DailyCardCopyWithImpl;
@override @useResult
$Res call({
 String localDate, CardId cardId, bool reversed, DateTime drawnAt, DateTime createdAt, DateTime updatedAt, String? note, bool favourite
});




}
/// @nodoc
class __$DailyCardCopyWithImpl<$Res>
    implements _$DailyCardCopyWith<$Res> {
  __$DailyCardCopyWithImpl(this._self, this._then);

  final _DailyCard _self;
  final $Res Function(_DailyCard) _then;

/// Create a copy of DailyCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localDate = null,Object? cardId = null,Object? reversed = null,Object? drawnAt = null,Object? createdAt = null,Object? updatedAt = null,Object? note = freezed,Object? favourite = null,}) {
  return _then(_DailyCard(
localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,drawnAt: null == drawnAt ? _self.drawnAt : drawnAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,favourite: null == favourite ? _self.favourite : favourite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
