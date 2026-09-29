// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalItem {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalItem()';
}


}

/// @nodoc
class $JournalItemCopyWith<$Res>  {
$JournalItemCopyWith(JournalItem _, $Res Function(JournalItem) __);
}


/// Adds pattern-matching-related methods to [JournalItem].
extension JournalItemPatterns on JournalItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( JournalReadingItem value)?  reading,TResult Function( JournalDailyCardItem value)?  dailyCard,required TResult orElse(),}){
final _that = this;
switch (_that) {
case JournalReadingItem() when reading != null:
return reading(_that);case JournalDailyCardItem() when dailyCard != null:
return dailyCard(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( JournalReadingItem value)  reading,required TResult Function( JournalDailyCardItem value)  dailyCard,}){
final _that = this;
switch (_that) {
case JournalReadingItem():
return reading(_that);case JournalDailyCardItem():
return dailyCard(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( JournalReadingItem value)?  reading,TResult? Function( JournalDailyCardItem value)?  dailyCard,}){
final _that = this;
switch (_that) {
case JournalReadingItem() when reading != null:
return reading(_that);case JournalDailyCardItem() when dailyCard != null:
return dailyCard(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Reading reading)?  reading,TResult Function( DailyCard card)?  dailyCard,required TResult orElse(),}) {final _that = this;
switch (_that) {
case JournalReadingItem() when reading != null:
return reading(_that.reading);case JournalDailyCardItem() when dailyCard != null:
return dailyCard(_that.card);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Reading reading)  reading,required TResult Function( DailyCard card)  dailyCard,}) {final _that = this;
switch (_that) {
case JournalReadingItem():
return reading(_that.reading);case JournalDailyCardItem():
return dailyCard(_that.card);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Reading reading)?  reading,TResult? Function( DailyCard card)?  dailyCard,}) {final _that = this;
switch (_that) {
case JournalReadingItem() when reading != null:
return reading(_that.reading);case JournalDailyCardItem() when dailyCard != null:
return dailyCard(_that.card);case _:
  return null;

}
}

}

/// @nodoc


class JournalReadingItem extends JournalItem {
  const JournalReadingItem(this.reading): super._();
  

 final  Reading reading;

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalReadingItemCopyWith<JournalReadingItem> get copyWith => _$JournalReadingItemCopyWithImpl<JournalReadingItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalReadingItem&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,reading);

@override
String toString() {
  return 'JournalItem.reading(reading: $reading)';
}


}

/// @nodoc
abstract mixin class $JournalReadingItemCopyWith<$Res> implements $JournalItemCopyWith<$Res> {
  factory $JournalReadingItemCopyWith(JournalReadingItem value, $Res Function(JournalReadingItem) _then) = _$JournalReadingItemCopyWithImpl;
@useResult
$Res call({
 Reading reading
});


$ReadingCopyWith<$Res> get reading;

}
/// @nodoc
class _$JournalReadingItemCopyWithImpl<$Res>
    implements $JournalReadingItemCopyWith<$Res> {
  _$JournalReadingItemCopyWithImpl(this._self, this._then);

  final JournalReadingItem _self;
  final $Res Function(JournalReadingItem) _then;

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reading = null,}) {
  return _then(JournalReadingItem(
null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,
  ));
}

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingCopyWith<$Res> get reading {
  
  return $ReadingCopyWith<$Res>(_self.reading, (value) {
    return _then(_self.copyWith(reading: value));
  });
}
}

/// @nodoc


class JournalDailyCardItem extends JournalItem {
  const JournalDailyCardItem(this.card): super._();
  

 final  DailyCard card;

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalDailyCardItemCopyWith<JournalDailyCardItem> get copyWith => _$JournalDailyCardItemCopyWithImpl<JournalDailyCardItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalDailyCardItem&&(identical(other.card, card) || other.card == card));
}


@override
int get hashCode => Object.hash(runtimeType,card);

@override
String toString() {
  return 'JournalItem.dailyCard(card: $card)';
}


}

/// @nodoc
abstract mixin class $JournalDailyCardItemCopyWith<$Res> implements $JournalItemCopyWith<$Res> {
  factory $JournalDailyCardItemCopyWith(JournalDailyCardItem value, $Res Function(JournalDailyCardItem) _then) = _$JournalDailyCardItemCopyWithImpl;
@useResult
$Res call({
 DailyCard card
});


$DailyCardCopyWith<$Res> get card;

}
/// @nodoc
class _$JournalDailyCardItemCopyWithImpl<$Res>
    implements $JournalDailyCardItemCopyWith<$Res> {
  _$JournalDailyCardItemCopyWithImpl(this._self, this._then);

  final JournalDailyCardItem _self;
  final $Res Function(JournalDailyCardItem) _then;

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? card = null,}) {
  return _then(JournalDailyCardItem(
null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DailyCard,
  ));
}

/// Create a copy of JournalItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res> get card {
  
  return $DailyCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}

/// @nodoc
mixin _$JournalQuery {

/// Only favourites.
 bool get favouritesOnly;/// Only readings of this spread (daily cards are excluded when set).
 SpreadId? get spreadId;/// Include daily cards.
 bool get includeDailyCards;/// Only readings containing this card, and the daily cards that drew
/// it.
 CardId? get cardId;
/// Create a copy of JournalQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalQueryCopyWith<JournalQuery> get copyWith => _$JournalQueryCopyWithImpl<JournalQuery>(this as JournalQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalQuery&&(identical(other.favouritesOnly, favouritesOnly) || other.favouritesOnly == favouritesOnly)&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.includeDailyCards, includeDailyCards) || other.includeDailyCards == includeDailyCards)&&(identical(other.cardId, cardId) || other.cardId == cardId));
}


@override
int get hashCode => Object.hash(runtimeType,favouritesOnly,spreadId,includeDailyCards,cardId);

@override
String toString() {
  return 'JournalQuery(favouritesOnly: $favouritesOnly, spreadId: $spreadId, includeDailyCards: $includeDailyCards, cardId: $cardId)';
}


}

/// @nodoc
abstract mixin class $JournalQueryCopyWith<$Res>  {
  factory $JournalQueryCopyWith(JournalQuery value, $Res Function(JournalQuery) _then) = _$JournalQueryCopyWithImpl;
@useResult
$Res call({
 bool favouritesOnly, SpreadId? spreadId, bool includeDailyCards, CardId? cardId
});




}
/// @nodoc
class _$JournalQueryCopyWithImpl<$Res>
    implements $JournalQueryCopyWith<$Res> {
  _$JournalQueryCopyWithImpl(this._self, this._then);

  final JournalQuery _self;
  final $Res Function(JournalQuery) _then;

/// Create a copy of JournalQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? favouritesOnly = null,Object? spreadId = freezed,Object? includeDailyCards = null,Object? cardId = freezed,}) {
  return _then(_self.copyWith(
favouritesOnly: null == favouritesOnly ? _self.favouritesOnly : favouritesOnly // ignore: cast_nullable_to_non_nullable
as bool,spreadId: freezed == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId?,includeDailyCards: null == includeDailyCards ? _self.includeDailyCards : includeDailyCards // ignore: cast_nullable_to_non_nullable
as bool,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalQuery].
extension JournalQueryPatterns on JournalQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalQuery value)  $default,){
final _that = this;
switch (_that) {
case _JournalQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalQuery value)?  $default,){
final _that = this;
switch (_that) {
case _JournalQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool favouritesOnly,  SpreadId? spreadId,  bool includeDailyCards,  CardId? cardId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalQuery() when $default != null:
return $default(_that.favouritesOnly,_that.spreadId,_that.includeDailyCards,_that.cardId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool favouritesOnly,  SpreadId? spreadId,  bool includeDailyCards,  CardId? cardId)  $default,) {final _that = this;
switch (_that) {
case _JournalQuery():
return $default(_that.favouritesOnly,_that.spreadId,_that.includeDailyCards,_that.cardId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool favouritesOnly,  SpreadId? spreadId,  bool includeDailyCards,  CardId? cardId)?  $default,) {final _that = this;
switch (_that) {
case _JournalQuery() when $default != null:
return $default(_that.favouritesOnly,_that.spreadId,_that.includeDailyCards,_that.cardId);case _:
  return null;

}
}

}

/// @nodoc


class _JournalQuery implements JournalQuery {
  const _JournalQuery({this.favouritesOnly = false, this.spreadId, this.includeDailyCards = true, this.cardId});
  

/// Only favourites.
@override@JsonKey() final  bool favouritesOnly;
/// Only readings of this spread (daily cards are excluded when set).
@override final  SpreadId? spreadId;
/// Include daily cards.
@override@JsonKey() final  bool includeDailyCards;
/// Only readings containing this card, and the daily cards that drew
/// it.
@override final  CardId? cardId;

/// Create a copy of JournalQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalQueryCopyWith<_JournalQuery> get copyWith => __$JournalQueryCopyWithImpl<_JournalQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalQuery&&(identical(other.favouritesOnly, favouritesOnly) || other.favouritesOnly == favouritesOnly)&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.includeDailyCards, includeDailyCards) || other.includeDailyCards == includeDailyCards)&&(identical(other.cardId, cardId) || other.cardId == cardId));
}


@override
int get hashCode => Object.hash(runtimeType,favouritesOnly,spreadId,includeDailyCards,cardId);

@override
String toString() {
  return 'JournalQuery(favouritesOnly: $favouritesOnly, spreadId: $spreadId, includeDailyCards: $includeDailyCards, cardId: $cardId)';
}


}

/// @nodoc
abstract mixin class _$JournalQueryCopyWith<$Res> implements $JournalQueryCopyWith<$Res> {
  factory _$JournalQueryCopyWith(_JournalQuery value, $Res Function(_JournalQuery) _then) = __$JournalQueryCopyWithImpl;
@override @useResult
$Res call({
 bool favouritesOnly, SpreadId? spreadId, bool includeDailyCards, CardId? cardId
});




}
/// @nodoc
class __$JournalQueryCopyWithImpl<$Res>
    implements _$JournalQueryCopyWith<$Res> {
  __$JournalQueryCopyWithImpl(this._self, this._then);

  final _JournalQuery _self;
  final $Res Function(_JournalQuery) _then;

/// Create a copy of JournalQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? favouritesOnly = null,Object? spreadId = freezed,Object? includeDailyCards = null,Object? cardId = freezed,}) {
  return _then(_JournalQuery(
favouritesOnly: null == favouritesOnly ? _self.favouritesOnly : favouritesOnly // ignore: cast_nullable_to_non_nullable
as bool,spreadId: freezed == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId?,includeDailyCards: null == includeDailyCards ? _self.includeDailyCards : includeDailyCards // ignore: cast_nullable_to_non_nullable
as bool,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}


}

/// @nodoc
mixin _$JournalSnapshot {

/// Every reading, whatever its status.
 List<Reading> get readings;/// Every daily card.
 List<DailyCard> get dailyCards;
/// Create a copy of JournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalSnapshotCopyWith<JournalSnapshot> get copyWith => _$JournalSnapshotCopyWithImpl<JournalSnapshot>(this as JournalSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalSnapshot&&const DeepCollectionEquality().equals(other.readings, readings)&&const DeepCollectionEquality().equals(other.dailyCards, dailyCards));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(readings),const DeepCollectionEquality().hash(dailyCards));

@override
String toString() {
  return 'JournalSnapshot(readings: $readings, dailyCards: $dailyCards)';
}


}

/// @nodoc
abstract mixin class $JournalSnapshotCopyWith<$Res>  {
  factory $JournalSnapshotCopyWith(JournalSnapshot value, $Res Function(JournalSnapshot) _then) = _$JournalSnapshotCopyWithImpl;
@useResult
$Res call({
 List<Reading> readings, List<DailyCard> dailyCards
});




}
/// @nodoc
class _$JournalSnapshotCopyWithImpl<$Res>
    implements $JournalSnapshotCopyWith<$Res> {
  _$JournalSnapshotCopyWithImpl(this._self, this._then);

  final JournalSnapshot _self;
  final $Res Function(JournalSnapshot) _then;

/// Create a copy of JournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? readings = null,Object? dailyCards = null,}) {
  return _then(_self.copyWith(
readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self.dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalSnapshot].
extension JournalSnapshotPatterns on JournalSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _JournalSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _JournalSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Reading> readings,  List<DailyCard> dailyCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalSnapshot() when $default != null:
return $default(_that.readings,_that.dailyCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Reading> readings,  List<DailyCard> dailyCards)  $default,) {final _that = this;
switch (_that) {
case _JournalSnapshot():
return $default(_that.readings,_that.dailyCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Reading> readings,  List<DailyCard> dailyCards)?  $default,) {final _that = this;
switch (_that) {
case _JournalSnapshot() when $default != null:
return $default(_that.readings,_that.dailyCards);case _:
  return null;

}
}

}

/// @nodoc


class _JournalSnapshot implements JournalSnapshot {
  const _JournalSnapshot({required final  List<Reading> readings, required final  List<DailyCard> dailyCards}): _readings = readings,_dailyCards = dailyCards;
  

/// Every reading, whatever its status.
 final  List<Reading> _readings;
/// Every reading, whatever its status.
@override List<Reading> get readings {
  if (_readings is EqualUnmodifiableListView) return _readings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_readings);
}

/// Every daily card.
 final  List<DailyCard> _dailyCards;
/// Every daily card.
@override List<DailyCard> get dailyCards {
  if (_dailyCards is EqualUnmodifiableListView) return _dailyCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyCards);
}


/// Create a copy of JournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalSnapshotCopyWith<_JournalSnapshot> get copyWith => __$JournalSnapshotCopyWithImpl<_JournalSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalSnapshot&&const DeepCollectionEquality().equals(other._readings, _readings)&&const DeepCollectionEquality().equals(other._dailyCards, _dailyCards));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_readings),const DeepCollectionEquality().hash(_dailyCards));

@override
String toString() {
  return 'JournalSnapshot(readings: $readings, dailyCards: $dailyCards)';
}


}

/// @nodoc
abstract mixin class _$JournalSnapshotCopyWith<$Res> implements $JournalSnapshotCopyWith<$Res> {
  factory _$JournalSnapshotCopyWith(_JournalSnapshot value, $Res Function(_JournalSnapshot) _then) = __$JournalSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<Reading> readings, List<DailyCard> dailyCards
});




}
/// @nodoc
class __$JournalSnapshotCopyWithImpl<$Res>
    implements _$JournalSnapshotCopyWith<$Res> {
  __$JournalSnapshotCopyWithImpl(this._self, this._then);

  final _JournalSnapshot _self;
  final $Res Function(_JournalSnapshot) _then;

/// Create a copy of JournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? readings = null,Object? dailyCards = null,}) {
  return _then(_JournalSnapshot(
readings: null == readings ? _self._readings : readings // ignore: cast_nullable_to_non_nullable
as List<Reading>,dailyCards: null == dailyCards ? _self._dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as List<DailyCard>,
  ));
}


}

// dart format on
