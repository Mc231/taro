// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_card_rules.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyCardPick {

/// The card of the day.
 DailyCard get card;/// `true` when it was drawn now and must be persisted; `false` when it
/// is the card already stored for today.
 bool get isNew;
/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardPickCopyWith<DailyCardPick> get copyWith => _$DailyCardPickCopyWithImpl<DailyCardPick>(this as DailyCardPick, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardPick&&(identical(other.card, card) || other.card == card)&&(identical(other.isNew, isNew) || other.isNew == isNew));
}


@override
int get hashCode => Object.hash(runtimeType,card,isNew);

@override
String toString() {
  return 'DailyCardPick(card: $card, isNew: $isNew)';
}


}

/// @nodoc
abstract mixin class $DailyCardPickCopyWith<$Res>  {
  factory $DailyCardPickCopyWith(DailyCardPick value, $Res Function(DailyCardPick) _then) = _$DailyCardPickCopyWithImpl;
@useResult
$Res call({
 DailyCard card, bool isNew
});


$DailyCardCopyWith<$Res> get card;

}
/// @nodoc
class _$DailyCardPickCopyWithImpl<$Res>
    implements $DailyCardPickCopyWith<$Res> {
  _$DailyCardPickCopyWithImpl(this._self, this._then);

  final DailyCardPick _self;
  final $Res Function(DailyCardPick) _then;

/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? isNew = null,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DailyCard,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res> get card {
  
  return $DailyCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailyCardPick].
extension DailyCardPickPatterns on DailyCardPick {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyCardPick value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyCardPick() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyCardPick value)  $default,){
final _that = this;
switch (_that) {
case _DailyCardPick():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyCardPick value)?  $default,){
final _that = this;
switch (_that) {
case _DailyCardPick() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DailyCard card,  bool isNew)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyCardPick() when $default != null:
return $default(_that.card,_that.isNew);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DailyCard card,  bool isNew)  $default,) {final _that = this;
switch (_that) {
case _DailyCardPick():
return $default(_that.card,_that.isNew);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DailyCard card,  bool isNew)?  $default,) {final _that = this;
switch (_that) {
case _DailyCardPick() when $default != null:
return $default(_that.card,_that.isNew);case _:
  return null;

}
}

}

/// @nodoc


class _DailyCardPick implements DailyCardPick {
  const _DailyCardPick({required this.card, required this.isNew});
  

/// The card of the day.
@override final  DailyCard card;
/// `true` when it was drawn now and must be persisted; `false` when it
/// is the card already stored for today.
@override final  bool isNew;

/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyCardPickCopyWith<_DailyCardPick> get copyWith => __$DailyCardPickCopyWithImpl<_DailyCardPick>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyCardPick&&(identical(other.card, card) || other.card == card)&&(identical(other.isNew, isNew) || other.isNew == isNew));
}


@override
int get hashCode => Object.hash(runtimeType,card,isNew);

@override
String toString() {
  return 'DailyCardPick(card: $card, isNew: $isNew)';
}


}

/// @nodoc
abstract mixin class _$DailyCardPickCopyWith<$Res> implements $DailyCardPickCopyWith<$Res> {
  factory _$DailyCardPickCopyWith(_DailyCardPick value, $Res Function(_DailyCardPick) _then) = __$DailyCardPickCopyWithImpl;
@override @useResult
$Res call({
 DailyCard card, bool isNew
});


@override $DailyCardCopyWith<$Res> get card;

}
/// @nodoc
class __$DailyCardPickCopyWithImpl<$Res>
    implements _$DailyCardPickCopyWith<$Res> {
  __$DailyCardPickCopyWithImpl(this._self, this._then);

  final _DailyCardPick _self;
  final $Res Function(_DailyCardPick) _then;

/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? isNew = null,}) {
  return _then(_DailyCardPick(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DailyCard,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DailyCardPick
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res> get card {
  
  return $DailyCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}

// dart format on
