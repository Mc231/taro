// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patterns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CardCount {

/// The card.
 CardId get cardId;/// Times drawn.
 int get count;
/// Create a copy of CardCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardCountCopyWith<CardCount> get copyWith => _$CardCountCopyWithImpl<CardCount>(this as CardCount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardCount&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,count);

@override
String toString() {
  return 'CardCount(cardId: $cardId, count: $count)';
}


}

/// @nodoc
abstract mixin class $CardCountCopyWith<$Res>  {
  factory $CardCountCopyWith(CardCount value, $Res Function(CardCount) _then) = _$CardCountCopyWithImpl;
@useResult
$Res call({
 CardId cardId, int count
});




}
/// @nodoc
class _$CardCountCopyWithImpl<$Res>
    implements $CardCountCopyWith<$Res> {
  _$CardCountCopyWithImpl(this._self, this._then);

  final CardCount _self;
  final $Res Function(CardCount) _then;

/// Create a copy of CardCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardId = null,Object? count = null,}) {
  return _then(_self.copyWith(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CardCount].
extension CardCountPatterns on CardCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardCount value)  $default,){
final _that = this;
switch (_that) {
case _CardCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardCount value)?  $default,){
final _that = this;
switch (_that) {
case _CardCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardId cardId,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardCount() when $default != null:
return $default(_that.cardId,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardId cardId,  int count)  $default,) {final _that = this;
switch (_that) {
case _CardCount():
return $default(_that.cardId,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardId cardId,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CardCount() when $default != null:
return $default(_that.cardId,_that.count);case _:
  return null;

}
}

}

/// @nodoc


class _CardCount implements CardCount {
  const _CardCount({required this.cardId, required this.count});
  

/// The card.
@override final  CardId cardId;
/// Times drawn.
@override final  int count;

/// Create a copy of CardCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardCountCopyWith<_CardCount> get copyWith => __$CardCountCopyWithImpl<_CardCount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardCount&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,count);

@override
String toString() {
  return 'CardCount(cardId: $cardId, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CardCountCopyWith<$Res> implements $CardCountCopyWith<$Res> {
  factory _$CardCountCopyWith(_CardCount value, $Res Function(_CardCount) _then) = __$CardCountCopyWithImpl;
@override @useResult
$Res call({
 CardId cardId, int count
});




}
/// @nodoc
class __$CardCountCopyWithImpl<$Res>
    implements _$CardCountCopyWith<$Res> {
  __$CardCountCopyWithImpl(this._self, this._then);

  final _CardCount _self;
  final $Res Function(_CardCount) _then;

/// Create a copy of CardCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardId = null,Object? count = null,}) {
  return _then(_CardCount(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PatternWindow {

/// Length of the window in local days, today included.
 int get days;/// Journal entries (readings + daily cards) in the window.
 int get entries;/// Cards drawn in the window.
 int get cards;/// The most-drawn cards, count descending, ties in canonical card
/// order; only cards drawn at least twice, at most
/// [JournalPatterns.topCards].
 List<CardCount> get mostDrawn;/// Cards per suit (every suit present, zero when none).
 Map<Suit, int> get suits;/// Major arcana cards.
 int get major;/// Reversed cards.
 int get reversed;
/// Create a copy of PatternWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatternWindowCopyWith<PatternWindow> get copyWith => _$PatternWindowCopyWithImpl<PatternWindow>(this as PatternWindow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatternWindow&&(identical(other.days, days) || other.days == days)&&(identical(other.entries, entries) || other.entries == entries)&&(identical(other.cards, cards) || other.cards == cards)&&const DeepCollectionEquality().equals(other.mostDrawn, mostDrawn)&&const DeepCollectionEquality().equals(other.suits, suits)&&(identical(other.major, major) || other.major == major)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,days,entries,cards,const DeepCollectionEquality().hash(mostDrawn),const DeepCollectionEquality().hash(suits),major,reversed);

@override
String toString() {
  return 'PatternWindow(days: $days, entries: $entries, cards: $cards, mostDrawn: $mostDrawn, suits: $suits, major: $major, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class $PatternWindowCopyWith<$Res>  {
  factory $PatternWindowCopyWith(PatternWindow value, $Res Function(PatternWindow) _then) = _$PatternWindowCopyWithImpl;
@useResult
$Res call({
 int days, int entries, int cards, List<CardCount> mostDrawn, Map<Suit, int> suits, int major, int reversed
});




}
/// @nodoc
class _$PatternWindowCopyWithImpl<$Res>
    implements $PatternWindowCopyWith<$Res> {
  _$PatternWindowCopyWithImpl(this._self, this._then);

  final PatternWindow _self;
  final $Res Function(PatternWindow) _then;

/// Create a copy of PatternWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? entries = null,Object? cards = null,Object? mostDrawn = null,Object? suits = null,Object? major = null,Object? reversed = null,}) {
  return _then(_self.copyWith(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int,mostDrawn: null == mostDrawn ? _self.mostDrawn : mostDrawn // ignore: cast_nullable_to_non_nullable
as List<CardCount>,suits: null == suits ? _self.suits : suits // ignore: cast_nullable_to_non_nullable
as Map<Suit, int>,major: null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PatternWindow].
extension PatternWindowPatterns on PatternWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatternWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatternWindow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatternWindow value)  $default,){
final _that = this;
switch (_that) {
case _PatternWindow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatternWindow value)?  $default,){
final _that = this;
switch (_that) {
case _PatternWindow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int days,  int entries,  int cards,  List<CardCount> mostDrawn,  Map<Suit, int> suits,  int major,  int reversed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatternWindow() when $default != null:
return $default(_that.days,_that.entries,_that.cards,_that.mostDrawn,_that.suits,_that.major,_that.reversed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int days,  int entries,  int cards,  List<CardCount> mostDrawn,  Map<Suit, int> suits,  int major,  int reversed)  $default,) {final _that = this;
switch (_that) {
case _PatternWindow():
return $default(_that.days,_that.entries,_that.cards,_that.mostDrawn,_that.suits,_that.major,_that.reversed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int days,  int entries,  int cards,  List<CardCount> mostDrawn,  Map<Suit, int> suits,  int major,  int reversed)?  $default,) {final _that = this;
switch (_that) {
case _PatternWindow() when $default != null:
return $default(_that.days,_that.entries,_that.cards,_that.mostDrawn,_that.suits,_that.major,_that.reversed);case _:
  return null;

}
}

}

/// @nodoc


class _PatternWindow extends PatternWindow {
  const _PatternWindow({required this.days, required this.entries, required this.cards, required final  List<CardCount> mostDrawn, required final  Map<Suit, int> suits, required this.major, required this.reversed}): _mostDrawn = mostDrawn,_suits = suits,super._();
  

/// Length of the window in local days, today included.
@override final  int days;
/// Journal entries (readings + daily cards) in the window.
@override final  int entries;
/// Cards drawn in the window.
@override final  int cards;
/// The most-drawn cards, count descending, ties in canonical card
/// order; only cards drawn at least twice, at most
/// [JournalPatterns.topCards].
 final  List<CardCount> _mostDrawn;
/// The most-drawn cards, count descending, ties in canonical card
/// order; only cards drawn at least twice, at most
/// [JournalPatterns.topCards].
@override List<CardCount> get mostDrawn {
  if (_mostDrawn is EqualUnmodifiableListView) return _mostDrawn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mostDrawn);
}

/// Cards per suit (every suit present, zero when none).
 final  Map<Suit, int> _suits;
/// Cards per suit (every suit present, zero when none).
@override Map<Suit, int> get suits {
  if (_suits is EqualUnmodifiableMapView) return _suits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_suits);
}

/// Major arcana cards.
@override final  int major;
/// Reversed cards.
@override final  int reversed;

/// Create a copy of PatternWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternWindowCopyWith<_PatternWindow> get copyWith => __$PatternWindowCopyWithImpl<_PatternWindow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternWindow&&(identical(other.days, days) || other.days == days)&&(identical(other.entries, entries) || other.entries == entries)&&(identical(other.cards, cards) || other.cards == cards)&&const DeepCollectionEquality().equals(other._mostDrawn, _mostDrawn)&&const DeepCollectionEquality().equals(other._suits, _suits)&&(identical(other.major, major) || other.major == major)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,days,entries,cards,const DeepCollectionEquality().hash(_mostDrawn),const DeepCollectionEquality().hash(_suits),major,reversed);

@override
String toString() {
  return 'PatternWindow(days: $days, entries: $entries, cards: $cards, mostDrawn: $mostDrawn, suits: $suits, major: $major, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class _$PatternWindowCopyWith<$Res> implements $PatternWindowCopyWith<$Res> {
  factory _$PatternWindowCopyWith(_PatternWindow value, $Res Function(_PatternWindow) _then) = __$PatternWindowCopyWithImpl;
@override @useResult
$Res call({
 int days, int entries, int cards, List<CardCount> mostDrawn, Map<Suit, int> suits, int major, int reversed
});




}
/// @nodoc
class __$PatternWindowCopyWithImpl<$Res>
    implements _$PatternWindowCopyWith<$Res> {
  __$PatternWindowCopyWithImpl(this._self, this._then);

  final _PatternWindow _self;
  final $Res Function(_PatternWindow) _then;

/// Create a copy of PatternWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? entries = null,Object? cards = null,Object? mostDrawn = null,Object? suits = null,Object? major = null,Object? reversed = null,}) {
  return _then(_PatternWindow(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int,mostDrawn: null == mostDrawn ? _self._mostDrawn : mostDrawn // ignore: cast_nullable_to_non_nullable
as List<CardCount>,suits: null == suits ? _self._suits : suits // ignore: cast_nullable_to_non_nullable
as Map<Suit, int>,major: null == major ? _self.major : major // ignore: cast_nullable_to_non_nullable
as int,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$JournalPatterns {

/// All journal entries (readings + daily cards).
 int get totalEntries;/// The last 30 local days.
 PatternWindow get last30;/// The last 90 local days.
 PatternWindow get last90;
/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalPatternsCopyWith<JournalPatterns> get copyWith => _$JournalPatternsCopyWithImpl<JournalPatterns>(this as JournalPatterns, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalPatterns&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.last30, last30) || other.last30 == last30)&&(identical(other.last90, last90) || other.last90 == last90));
}


@override
int get hashCode => Object.hash(runtimeType,totalEntries,last30,last90);

@override
String toString() {
  return 'JournalPatterns(totalEntries: $totalEntries, last30: $last30, last90: $last90)';
}


}

/// @nodoc
abstract mixin class $JournalPatternsCopyWith<$Res>  {
  factory $JournalPatternsCopyWith(JournalPatterns value, $Res Function(JournalPatterns) _then) = _$JournalPatternsCopyWithImpl;
@useResult
$Res call({
 int totalEntries, PatternWindow last30, PatternWindow last90
});


$PatternWindowCopyWith<$Res> get last30;$PatternWindowCopyWith<$Res> get last90;

}
/// @nodoc
class _$JournalPatternsCopyWithImpl<$Res>
    implements $JournalPatternsCopyWith<$Res> {
  _$JournalPatternsCopyWithImpl(this._self, this._then);

  final JournalPatterns _self;
  final $Res Function(JournalPatterns) _then;

/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEntries = null,Object? last30 = null,Object? last90 = null,}) {
  return _then(_self.copyWith(
totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,last30: null == last30 ? _self.last30 : last30 // ignore: cast_nullable_to_non_nullable
as PatternWindow,last90: null == last90 ? _self.last90 : last90 // ignore: cast_nullable_to_non_nullable
as PatternWindow,
  ));
}
/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatternWindowCopyWith<$Res> get last30 {
  
  return $PatternWindowCopyWith<$Res>(_self.last30, (value) {
    return _then(_self.copyWith(last30: value));
  });
}/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatternWindowCopyWith<$Res> get last90 {
  
  return $PatternWindowCopyWith<$Res>(_self.last90, (value) {
    return _then(_self.copyWith(last90: value));
  });
}
}


/// Adds pattern-matching-related methods to [JournalPatterns].
extension JournalPatternsPatterns on JournalPatterns {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalPatterns value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalPatterns() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalPatterns value)  $default,){
final _that = this;
switch (_that) {
case _JournalPatterns():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalPatterns value)?  $default,){
final _that = this;
switch (_that) {
case _JournalPatterns() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalEntries,  PatternWindow last30,  PatternWindow last90)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalPatterns() when $default != null:
return $default(_that.totalEntries,_that.last30,_that.last90);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalEntries,  PatternWindow last30,  PatternWindow last90)  $default,) {final _that = this;
switch (_that) {
case _JournalPatterns():
return $default(_that.totalEntries,_that.last30,_that.last90);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalEntries,  PatternWindow last30,  PatternWindow last90)?  $default,) {final _that = this;
switch (_that) {
case _JournalPatterns() when $default != null:
return $default(_that.totalEntries,_that.last30,_that.last90);case _:
  return null;

}
}

}

/// @nodoc


class _JournalPatterns extends JournalPatterns {
  const _JournalPatterns({required this.totalEntries, required this.last30, required this.last90}): super._();
  

/// All journal entries (readings + daily cards).
@override final  int totalEntries;
/// The last 30 local days.
@override final  PatternWindow last30;
/// The last 90 local days.
@override final  PatternWindow last90;

/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalPatternsCopyWith<_JournalPatterns> get copyWith => __$JournalPatternsCopyWithImpl<_JournalPatterns>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalPatterns&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.last30, last30) || other.last30 == last30)&&(identical(other.last90, last90) || other.last90 == last90));
}


@override
int get hashCode => Object.hash(runtimeType,totalEntries,last30,last90);

@override
String toString() {
  return 'JournalPatterns(totalEntries: $totalEntries, last30: $last30, last90: $last90)';
}


}

/// @nodoc
abstract mixin class _$JournalPatternsCopyWith<$Res> implements $JournalPatternsCopyWith<$Res> {
  factory _$JournalPatternsCopyWith(_JournalPatterns value, $Res Function(_JournalPatterns) _then) = __$JournalPatternsCopyWithImpl;
@override @useResult
$Res call({
 int totalEntries, PatternWindow last30, PatternWindow last90
});


@override $PatternWindowCopyWith<$Res> get last30;@override $PatternWindowCopyWith<$Res> get last90;

}
/// @nodoc
class __$JournalPatternsCopyWithImpl<$Res>
    implements _$JournalPatternsCopyWith<$Res> {
  __$JournalPatternsCopyWithImpl(this._self, this._then);

  final _JournalPatterns _self;
  final $Res Function(_JournalPatterns) _then;

/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEntries = null,Object? last30 = null,Object? last90 = null,}) {
  return _then(_JournalPatterns(
totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,last30: null == last30 ? _self.last30 : last30 // ignore: cast_nullable_to_non_nullable
as PatternWindow,last90: null == last90 ? _self.last90 : last90 // ignore: cast_nullable_to_non_nullable
as PatternWindow,
  ));
}

/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatternWindowCopyWith<$Res> get last30 {
  
  return $PatternWindowCopyWith<$Res>(_self.last30, (value) {
    return _then(_self.copyWith(last30: value));
  });
}/// Create a copy of JournalPatterns
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatternWindowCopyWith<$Res> get last90 {
  
  return $PatternWindowCopyWith<$Res>(_self.last90, (value) {
    return _then(_self.copyWith(last90: value));
  });
}
}

// dart format on
