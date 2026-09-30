// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalFilters {

 JournalTypeFilter get type;/// Only readings of this spread.
 SpreadId? get spreadId;/// Only entries containing this card (the S17 "drawn N times" link).
 CardId? get cardId;
/// Create a copy of JournalFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalFiltersCopyWith<JournalFilters> get copyWith => _$JournalFiltersCopyWithImpl<JournalFilters>(this as JournalFilters, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalFilters&&(identical(other.type, type) || other.type == type)&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.cardId, cardId) || other.cardId == cardId));
}


@override
int get hashCode => Object.hash(runtimeType,type,spreadId,cardId);

@override
String toString() {
  return 'JournalFilters(type: $type, spreadId: $spreadId, cardId: $cardId)';
}


}

/// @nodoc
abstract mixin class $JournalFiltersCopyWith<$Res>  {
  factory $JournalFiltersCopyWith(JournalFilters value, $Res Function(JournalFilters) _then) = _$JournalFiltersCopyWithImpl;
@useResult
$Res call({
 JournalTypeFilter type, SpreadId? spreadId, CardId? cardId
});




}
/// @nodoc
class _$JournalFiltersCopyWithImpl<$Res>
    implements $JournalFiltersCopyWith<$Res> {
  _$JournalFiltersCopyWithImpl(this._self, this._then);

  final JournalFilters _self;
  final $Res Function(JournalFilters) _then;

/// Create a copy of JournalFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? spreadId = freezed,Object? cardId = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as JournalTypeFilter,spreadId: freezed == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalFilters].
extension JournalFiltersPatterns on JournalFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalFilters value)  $default,){
final _that = this;
switch (_that) {
case _JournalFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalFilters value)?  $default,){
final _that = this;
switch (_that) {
case _JournalFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JournalTypeFilter type,  SpreadId? spreadId,  CardId? cardId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalFilters() when $default != null:
return $default(_that.type,_that.spreadId,_that.cardId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JournalTypeFilter type,  SpreadId? spreadId,  CardId? cardId)  $default,) {final _that = this;
switch (_that) {
case _JournalFilters():
return $default(_that.type,_that.spreadId,_that.cardId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JournalTypeFilter type,  SpreadId? spreadId,  CardId? cardId)?  $default,) {final _that = this;
switch (_that) {
case _JournalFilters() when $default != null:
return $default(_that.type,_that.spreadId,_that.cardId);case _:
  return null;

}
}

}

/// @nodoc


class _JournalFilters extends JournalFilters {
  const _JournalFilters({this.type = JournalTypeFilter.all, this.spreadId, this.cardId}): super._();
  

@override@JsonKey() final  JournalTypeFilter type;
/// Only readings of this spread.
@override final  SpreadId? spreadId;
/// Only entries containing this card (the S17 "drawn N times" link).
@override final  CardId? cardId;

/// Create a copy of JournalFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalFiltersCopyWith<_JournalFilters> get copyWith => __$JournalFiltersCopyWithImpl<_JournalFilters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalFilters&&(identical(other.type, type) || other.type == type)&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.cardId, cardId) || other.cardId == cardId));
}


@override
int get hashCode => Object.hash(runtimeType,type,spreadId,cardId);

@override
String toString() {
  return 'JournalFilters(type: $type, spreadId: $spreadId, cardId: $cardId)';
}


}

/// @nodoc
abstract mixin class _$JournalFiltersCopyWith<$Res> implements $JournalFiltersCopyWith<$Res> {
  factory _$JournalFiltersCopyWith(_JournalFilters value, $Res Function(_JournalFilters) _then) = __$JournalFiltersCopyWithImpl;
@override @useResult
$Res call({
 JournalTypeFilter type, SpreadId? spreadId, CardId? cardId
});




}
/// @nodoc
class __$JournalFiltersCopyWithImpl<$Res>
    implements _$JournalFiltersCopyWith<$Res> {
  __$JournalFiltersCopyWithImpl(this._self, this._then);

  final _JournalFilters _self;
  final $Res Function(_JournalFilters) _then;

/// Create a copy of JournalFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? spreadId = freezed,Object? cardId = freezed,}) {
  return _then(_JournalFilters(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as JournalTypeFilter,spreadId: freezed == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}


}

/// @nodoc
mixin _$JournalMonth {

 String get yearMonth; List<JournalItem> get items;
/// Create a copy of JournalMonth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalMonthCopyWith<JournalMonth> get copyWith => _$JournalMonthCopyWithImpl<JournalMonth>(this as JournalMonth, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalMonth&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,yearMonth,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'JournalMonth(yearMonth: $yearMonth, items: $items)';
}


}

/// @nodoc
abstract mixin class $JournalMonthCopyWith<$Res>  {
  factory $JournalMonthCopyWith(JournalMonth value, $Res Function(JournalMonth) _then) = _$JournalMonthCopyWithImpl;
@useResult
$Res call({
 String yearMonth, List<JournalItem> items
});




}
/// @nodoc
class _$JournalMonthCopyWithImpl<$Res>
    implements $JournalMonthCopyWith<$Res> {
  _$JournalMonthCopyWithImpl(this._self, this._then);

  final JournalMonth _self;
  final $Res Function(JournalMonth) _then;

/// Create a copy of JournalMonth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? yearMonth = null,Object? items = null,}) {
  return _then(_self.copyWith(
yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<JournalItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalMonth].
extension JournalMonthPatterns on JournalMonth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalMonth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalMonth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalMonth value)  $default,){
final _that = this;
switch (_that) {
case _JournalMonth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalMonth value)?  $default,){
final _that = this;
switch (_that) {
case _JournalMonth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String yearMonth,  List<JournalItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalMonth() when $default != null:
return $default(_that.yearMonth,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String yearMonth,  List<JournalItem> items)  $default,) {final _that = this;
switch (_that) {
case _JournalMonth():
return $default(_that.yearMonth,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String yearMonth,  List<JournalItem> items)?  $default,) {final _that = this;
switch (_that) {
case _JournalMonth() when $default != null:
return $default(_that.yearMonth,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _JournalMonth implements JournalMonth {
  const _JournalMonth({required this.yearMonth, required final  List<JournalItem> items}): _items = items;
  

@override final  String yearMonth;
 final  List<JournalItem> _items;
@override List<JournalItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of JournalMonth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalMonthCopyWith<_JournalMonth> get copyWith => __$JournalMonthCopyWithImpl<_JournalMonth>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalMonth&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,yearMonth,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'JournalMonth(yearMonth: $yearMonth, items: $items)';
}


}

/// @nodoc
abstract mixin class _$JournalMonthCopyWith<$Res> implements $JournalMonthCopyWith<$Res> {
  factory _$JournalMonthCopyWith(_JournalMonth value, $Res Function(_JournalMonth) _then) = __$JournalMonthCopyWithImpl;
@override @useResult
$Res call({
 String yearMonth, List<JournalItem> items
});




}
/// @nodoc
class __$JournalMonthCopyWithImpl<$Res>
    implements _$JournalMonthCopyWith<$Res> {
  __$JournalMonthCopyWithImpl(this._self, this._then);

  final _JournalMonth _self;
  final $Res Function(_JournalMonth) _then;

/// Create a copy of JournalMonth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? yearMonth = null,Object? items = null,}) {
  return _then(_JournalMonth(
yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<JournalItem>,
  ));
}


}

/// @nodoc
mixin _$JournalListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalListState()';
}


}

/// @nodoc
class $JournalListStateCopyWith<$Res>  {
$JournalListStateCopyWith(JournalListState _, $Res Function(JournalListState) __);
}


/// Adds pattern-matching-related methods to [JournalListState].
extension JournalListStatePatterns on JournalListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( JournalListLoading value)?  loading,TResult Function( JournalListEmpty value)?  empty,TResult Function( JournalListContent value)?  content,TResult Function( JournalListFilteredEmpty value)?  filteredEmpty,TResult Function( JournalListSearchEmpty value)?  searchEmpty,TResult Function( JournalListStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case JournalListLoading() when loading != null:
return loading(_that);case JournalListEmpty() when empty != null:
return empty(_that);case JournalListContent() when content != null:
return content(_that);case JournalListFilteredEmpty() when filteredEmpty != null:
return filteredEmpty(_that);case JournalListSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case JournalListStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( JournalListLoading value)  loading,required TResult Function( JournalListEmpty value)  empty,required TResult Function( JournalListContent value)  content,required TResult Function( JournalListFilteredEmpty value)  filteredEmpty,required TResult Function( JournalListSearchEmpty value)  searchEmpty,required TResult Function( JournalListStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case JournalListLoading():
return loading(_that);case JournalListEmpty():
return empty(_that);case JournalListContent():
return content(_that);case JournalListFilteredEmpty():
return filteredEmpty(_that);case JournalListSearchEmpty():
return searchEmpty(_that);case JournalListStorageError():
return storageError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( JournalListLoading value)?  loading,TResult? Function( JournalListEmpty value)?  empty,TResult? Function( JournalListContent value)?  content,TResult? Function( JournalListFilteredEmpty value)?  filteredEmpty,TResult? Function( JournalListSearchEmpty value)?  searchEmpty,TResult? Function( JournalListStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case JournalListLoading() when loading != null:
return loading(_that);case JournalListEmpty() when empty != null:
return empty(_that);case JournalListContent() when content != null:
return content(_that);case JournalListFilteredEmpty() when filteredEmpty != null:
return filteredEmpty(_that);case JournalListSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case JournalListStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  empty,TResult Function( List<JournalMonth> months,  JournalFilters filters,  String query,  JournalPatterns? patterns,  ReadingId? undoable)?  content,TResult Function( JournalFilters filters)?  filteredEmpty,TResult Function( String query)?  searchEmpty,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case JournalListLoading() when loading != null:
return loading();case JournalListEmpty() when empty != null:
return empty();case JournalListContent() when content != null:
return content(_that.months,_that.filters,_that.query,_that.patterns,_that.undoable);case JournalListFilteredEmpty() when filteredEmpty != null:
return filteredEmpty(_that.filters);case JournalListSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query);case JournalListStorageError() when storageError != null:
return storageError();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  empty,required TResult Function( List<JournalMonth> months,  JournalFilters filters,  String query,  JournalPatterns? patterns,  ReadingId? undoable)  content,required TResult Function( JournalFilters filters)  filteredEmpty,required TResult Function( String query)  searchEmpty,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case JournalListLoading():
return loading();case JournalListEmpty():
return empty();case JournalListContent():
return content(_that.months,_that.filters,_that.query,_that.patterns,_that.undoable);case JournalListFilteredEmpty():
return filteredEmpty(_that.filters);case JournalListSearchEmpty():
return searchEmpty(_that.query);case JournalListStorageError():
return storageError();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  empty,TResult? Function( List<JournalMonth> months,  JournalFilters filters,  String query,  JournalPatterns? patterns,  ReadingId? undoable)?  content,TResult? Function( JournalFilters filters)?  filteredEmpty,TResult? Function( String query)?  searchEmpty,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case JournalListLoading() when loading != null:
return loading();case JournalListEmpty() when empty != null:
return empty();case JournalListContent() when content != null:
return content(_that.months,_that.filters,_that.query,_that.patterns,_that.undoable);case JournalListFilteredEmpty() when filteredEmpty != null:
return filteredEmpty(_that.filters);case JournalListSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query);case JournalListStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class JournalListLoading implements JournalListState {
  const JournalListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalListState.loading()';
}


}




/// @nodoc


class JournalListEmpty implements JournalListState {
  const JournalListEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalListState.empty()';
}


}




/// @nodoc


class JournalListContent implements JournalListState {
  const JournalListContent({required final  List<JournalMonth> months, required this.filters, this.query = '', this.patterns, this.undoable}): _months = months;
  

 final  List<JournalMonth> _months;
 List<JournalMonth> get months {
  if (_months is EqualUnmodifiableListView) return _months;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_months);
}

 final  JournalFilters filters;
/// The search text (empty when not searching).
@JsonKey() final  String query;
/// The Patterns card, when there are ≥ 5 entries (01 §7.8).
 final  JournalPatterns? patterns;
/// The reading just deleted from the list (the 5 s Undo snackbar).
 final  ReadingId? undoable;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalListContentCopyWith<JournalListContent> get copyWith => _$JournalListContentCopyWithImpl<JournalListContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListContent&&const DeepCollectionEquality().equals(other._months, _months)&&(identical(other.filters, filters) || other.filters == filters)&&(identical(other.query, query) || other.query == query)&&(identical(other.patterns, patterns) || other.patterns == patterns)&&(identical(other.undoable, undoable) || other.undoable == undoable));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_months),filters,query,patterns,undoable);

@override
String toString() {
  return 'JournalListState.content(months: $months, filters: $filters, query: $query, patterns: $patterns, undoable: $undoable)';
}


}

/// @nodoc
abstract mixin class $JournalListContentCopyWith<$Res> implements $JournalListStateCopyWith<$Res> {
  factory $JournalListContentCopyWith(JournalListContent value, $Res Function(JournalListContent) _then) = _$JournalListContentCopyWithImpl;
@useResult
$Res call({
 List<JournalMonth> months, JournalFilters filters, String query, JournalPatterns? patterns, ReadingId? undoable
});


$JournalFiltersCopyWith<$Res> get filters;$JournalPatternsCopyWith<$Res>? get patterns;

}
/// @nodoc
class _$JournalListContentCopyWithImpl<$Res>
    implements $JournalListContentCopyWith<$Res> {
  _$JournalListContentCopyWithImpl(this._self, this._then);

  final JournalListContent _self;
  final $Res Function(JournalListContent) _then;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? months = null,Object? filters = null,Object? query = null,Object? patterns = freezed,Object? undoable = freezed,}) {
  return _then(JournalListContent(
months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<JournalMonth>,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as JournalFilters,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,patterns: freezed == patterns ? _self.patterns : patterns // ignore: cast_nullable_to_non_nullable
as JournalPatterns?,undoable: freezed == undoable ? _self.undoable : undoable // ignore: cast_nullable_to_non_nullable
as ReadingId?,
  ));
}

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalFiltersCopyWith<$Res> get filters {
  
  return $JournalFiltersCopyWith<$Res>(_self.filters, (value) {
    return _then(_self.copyWith(filters: value));
  });
}/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalPatternsCopyWith<$Res>? get patterns {
    if (_self.patterns == null) {
    return null;
  }

  return $JournalPatternsCopyWith<$Res>(_self.patterns!, (value) {
    return _then(_self.copyWith(patterns: value));
  });
}
}

/// @nodoc


class JournalListFilteredEmpty implements JournalListState {
  const JournalListFilteredEmpty({required this.filters});
  

 final  JournalFilters filters;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalListFilteredEmptyCopyWith<JournalListFilteredEmpty> get copyWith => _$JournalListFilteredEmptyCopyWithImpl<JournalListFilteredEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListFilteredEmpty&&(identical(other.filters, filters) || other.filters == filters));
}


@override
int get hashCode => Object.hash(runtimeType,filters);

@override
String toString() {
  return 'JournalListState.filteredEmpty(filters: $filters)';
}


}

/// @nodoc
abstract mixin class $JournalListFilteredEmptyCopyWith<$Res> implements $JournalListStateCopyWith<$Res> {
  factory $JournalListFilteredEmptyCopyWith(JournalListFilteredEmpty value, $Res Function(JournalListFilteredEmpty) _then) = _$JournalListFilteredEmptyCopyWithImpl;
@useResult
$Res call({
 JournalFilters filters
});


$JournalFiltersCopyWith<$Res> get filters;

}
/// @nodoc
class _$JournalListFilteredEmptyCopyWithImpl<$Res>
    implements $JournalListFilteredEmptyCopyWith<$Res> {
  _$JournalListFilteredEmptyCopyWithImpl(this._self, this._then);

  final JournalListFilteredEmpty _self;
  final $Res Function(JournalListFilteredEmpty) _then;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filters = null,}) {
  return _then(JournalListFilteredEmpty(
filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as JournalFilters,
  ));
}

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalFiltersCopyWith<$Res> get filters {
  
  return $JournalFiltersCopyWith<$Res>(_self.filters, (value) {
    return _then(_self.copyWith(filters: value));
  });
}
}

/// @nodoc


class JournalListSearchEmpty implements JournalListState {
  const JournalListSearchEmpty({required this.query});
  

 final  String query;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalListSearchEmptyCopyWith<JournalListSearchEmpty> get copyWith => _$JournalListSearchEmptyCopyWithImpl<JournalListSearchEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListSearchEmpty&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'JournalListState.searchEmpty(query: $query)';
}


}

/// @nodoc
abstract mixin class $JournalListSearchEmptyCopyWith<$Res> implements $JournalListStateCopyWith<$Res> {
  factory $JournalListSearchEmptyCopyWith(JournalListSearchEmpty value, $Res Function(JournalListSearchEmpty) _then) = _$JournalListSearchEmptyCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$JournalListSearchEmptyCopyWithImpl<$Res>
    implements $JournalListSearchEmptyCopyWith<$Res> {
  _$JournalListSearchEmptyCopyWithImpl(this._self, this._then);

  final JournalListSearchEmpty _self;
  final $Res Function(JournalListSearchEmpty) _then;

/// Create a copy of JournalListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(JournalListSearchEmpty(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class JournalListStorageError implements JournalListState {
  const JournalListStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalListStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalListState.storageError()';
}


}




// dart format on
