// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draw.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Draw {

/// The spread.
 SpreadId get spreadId;/// The spread content version.
 int get spreadVersion;/// One card per position, in position order.
 List<DrawnCard> get cards;/// When the cards were drawn (UTC).
 DateTime get drawnAt;
/// Create a copy of Draw
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawCopyWith<Draw> get copyWith => _$DrawCopyWithImpl<Draw>(this as Draw, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Draw&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.spreadVersion, spreadVersion) || other.spreadVersion == spreadVersion)&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.drawnAt, drawnAt) || other.drawnAt == drawnAt));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,spreadVersion,const DeepCollectionEquality().hash(cards),drawnAt);

@override
String toString() {
  return 'Draw(spreadId: $spreadId, spreadVersion: $spreadVersion, cards: $cards, drawnAt: $drawnAt)';
}


}

/// @nodoc
abstract mixin class $DrawCopyWith<$Res>  {
  factory $DrawCopyWith(Draw value, $Res Function(Draw) _then) = _$DrawCopyWithImpl;
@useResult
$Res call({
 SpreadId spreadId, int spreadVersion, List<DrawnCard> cards, DateTime drawnAt
});




}
/// @nodoc
class _$DrawCopyWithImpl<$Res>
    implements $DrawCopyWith<$Res> {
  _$DrawCopyWithImpl(this._self, this._then);

  final Draw _self;
  final $Res Function(Draw) _then;

/// Create a copy of Draw
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spreadId = null,Object? spreadVersion = null,Object? cards = null,Object? drawnAt = null,}) {
  return _then(_self.copyWith(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,spreadVersion: null == spreadVersion ? _self.spreadVersion : spreadVersion // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<DrawnCard>,drawnAt: null == drawnAt ? _self.drawnAt : drawnAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Draw].
extension DrawPatterns on Draw {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Draw value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Draw() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Draw value)  $default,){
final _that = this;
switch (_that) {
case _Draw():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Draw value)?  $default,){
final _that = this;
switch (_that) {
case _Draw() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadId spreadId,  int spreadVersion,  List<DrawnCard> cards,  DateTime drawnAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Draw() when $default != null:
return $default(_that.spreadId,_that.spreadVersion,_that.cards,_that.drawnAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadId spreadId,  int spreadVersion,  List<DrawnCard> cards,  DateTime drawnAt)  $default,) {final _that = this;
switch (_that) {
case _Draw():
return $default(_that.spreadId,_that.spreadVersion,_that.cards,_that.drawnAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadId spreadId,  int spreadVersion,  List<DrawnCard> cards,  DateTime drawnAt)?  $default,) {final _that = this;
switch (_that) {
case _Draw() when $default != null:
return $default(_that.spreadId,_that.spreadVersion,_that.cards,_that.drawnAt);case _:
  return null;

}
}

}

/// @nodoc


class _Draw extends Draw {
  const _Draw({required this.spreadId, required this.spreadVersion, required final  List<DrawnCard> cards, required this.drawnAt}): _cards = cards,super._();
  

/// The spread.
@override final  SpreadId spreadId;
/// The spread content version.
@override final  int spreadVersion;
/// One card per position, in position order.
 final  List<DrawnCard> _cards;
/// One card per position, in position order.
@override List<DrawnCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

/// When the cards were drawn (UTC).
@override final  DateTime drawnAt;

/// Create a copy of Draw
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawCopyWith<_Draw> get copyWith => __$DrawCopyWithImpl<_Draw>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Draw&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.spreadVersion, spreadVersion) || other.spreadVersion == spreadVersion)&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.drawnAt, drawnAt) || other.drawnAt == drawnAt));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,spreadVersion,const DeepCollectionEquality().hash(_cards),drawnAt);

@override
String toString() {
  return 'Draw(spreadId: $spreadId, spreadVersion: $spreadVersion, cards: $cards, drawnAt: $drawnAt)';
}


}

/// @nodoc
abstract mixin class _$DrawCopyWith<$Res> implements $DrawCopyWith<$Res> {
  factory _$DrawCopyWith(_Draw value, $Res Function(_Draw) _then) = __$DrawCopyWithImpl;
@override @useResult
$Res call({
 SpreadId spreadId, int spreadVersion, List<DrawnCard> cards, DateTime drawnAt
});




}
/// @nodoc
class __$DrawCopyWithImpl<$Res>
    implements _$DrawCopyWith<$Res> {
  __$DrawCopyWithImpl(this._self, this._then);

  final _Draw _self;
  final $Res Function(_Draw) _then;

/// Create a copy of Draw
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spreadId = null,Object? spreadVersion = null,Object? cards = null,Object? drawnAt = null,}) {
  return _then(_Draw(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,spreadVersion: null == spreadVersion ? _self.spreadVersion : spreadVersion // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<DrawnCard>,drawnAt: null == drawnAt ? _self.drawnAt : drawnAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
