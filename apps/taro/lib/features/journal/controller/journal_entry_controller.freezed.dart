// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalEntryKey {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryKey()';
}


}

/// @nodoc
class $JournalEntryKeyCopyWith<$Res>  {
$JournalEntryKeyCopyWith(JournalEntryKey _, $Res Function(JournalEntryKey) __);
}


/// Adds pattern-matching-related methods to [JournalEntryKey].
extension JournalEntryKeyPatterns on JournalEntryKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( JournalReadingKey value)?  reading,TResult Function( JournalDailyCardKey value)?  dailyCard,required TResult orElse(),}){
final _that = this;
switch (_that) {
case JournalReadingKey() when reading != null:
return reading(_that);case JournalDailyCardKey() when dailyCard != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( JournalReadingKey value)  reading,required TResult Function( JournalDailyCardKey value)  dailyCard,}){
final _that = this;
switch (_that) {
case JournalReadingKey():
return reading(_that);case JournalDailyCardKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( JournalReadingKey value)?  reading,TResult? Function( JournalDailyCardKey value)?  dailyCard,}){
final _that = this;
switch (_that) {
case JournalReadingKey() when reading != null:
return reading(_that);case JournalDailyCardKey() when dailyCard != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ReadingId id)?  reading,TResult Function( String localDate)?  dailyCard,required TResult orElse(),}) {final _that = this;
switch (_that) {
case JournalReadingKey() when reading != null:
return reading(_that.id);case JournalDailyCardKey() when dailyCard != null:
return dailyCard(_that.localDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ReadingId id)  reading,required TResult Function( String localDate)  dailyCard,}) {final _that = this;
switch (_that) {
case JournalReadingKey():
return reading(_that.id);case JournalDailyCardKey():
return dailyCard(_that.localDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ReadingId id)?  reading,TResult? Function( String localDate)?  dailyCard,}) {final _that = this;
switch (_that) {
case JournalReadingKey() when reading != null:
return reading(_that.id);case JournalDailyCardKey() when dailyCard != null:
return dailyCard(_that.localDate);case _:
  return null;

}
}

}

/// @nodoc


class JournalReadingKey implements JournalEntryKey {
  const JournalReadingKey(this.id);
  

 final  ReadingId id;

/// Create a copy of JournalEntryKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalReadingKeyCopyWith<JournalReadingKey> get copyWith => _$JournalReadingKeyCopyWithImpl<JournalReadingKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalReadingKey&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'JournalEntryKey.reading(id: $id)';
}


}

/// @nodoc
abstract mixin class $JournalReadingKeyCopyWith<$Res> implements $JournalEntryKeyCopyWith<$Res> {
  factory $JournalReadingKeyCopyWith(JournalReadingKey value, $Res Function(JournalReadingKey) _then) = _$JournalReadingKeyCopyWithImpl;
@useResult
$Res call({
 ReadingId id
});




}
/// @nodoc
class _$JournalReadingKeyCopyWithImpl<$Res>
    implements $JournalReadingKeyCopyWith<$Res> {
  _$JournalReadingKeyCopyWithImpl(this._self, this._then);

  final JournalReadingKey _self;
  final $Res Function(JournalReadingKey) _then;

/// Create a copy of JournalEntryKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(JournalReadingKey(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ReadingId,
  ));
}


}

/// @nodoc


class JournalDailyCardKey implements JournalEntryKey {
  const JournalDailyCardKey(this.localDate);
  

 final  String localDate;

/// Create a copy of JournalEntryKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalDailyCardKeyCopyWith<JournalDailyCardKey> get copyWith => _$JournalDailyCardKeyCopyWithImpl<JournalDailyCardKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalDailyCardKey&&(identical(other.localDate, localDate) || other.localDate == localDate));
}


@override
int get hashCode => Object.hash(runtimeType,localDate);

@override
String toString() {
  return 'JournalEntryKey.dailyCard(localDate: $localDate)';
}


}

/// @nodoc
abstract mixin class $JournalDailyCardKeyCopyWith<$Res> implements $JournalEntryKeyCopyWith<$Res> {
  factory $JournalDailyCardKeyCopyWith(JournalDailyCardKey value, $Res Function(JournalDailyCardKey) _then) = _$JournalDailyCardKeyCopyWithImpl;
@useResult
$Res call({
 String localDate
});




}
/// @nodoc
class _$JournalDailyCardKeyCopyWithImpl<$Res>
    implements $JournalDailyCardKeyCopyWith<$Res> {
  _$JournalDailyCardKeyCopyWithImpl(this._self, this._then);

  final JournalDailyCardKey _self;
  final $Res Function(JournalDailyCardKey) _then;

/// Create a copy of JournalEntryKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? localDate = null,}) {
  return _then(JournalDailyCardKey(
null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$JournalEntryView {

 JournalItem get item;/// The note text in the editor (≤ [kJournalNoteMaxChars]).
 String get note; NoteStatus get noteStatus;
/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryViewCopyWith<JournalEntryView> get copyWith => _$JournalEntryViewCopyWithImpl<JournalEntryView>(this as JournalEntryView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryView&&(identical(other.item, item) || other.item == item)&&(identical(other.note, note) || other.note == note)&&(identical(other.noteStatus, noteStatus) || other.noteStatus == noteStatus));
}


@override
int get hashCode => Object.hash(runtimeType,item,note,noteStatus);

@override
String toString() {
  return 'JournalEntryView(item: $item, note: $note, noteStatus: $noteStatus)';
}


}

/// @nodoc
abstract mixin class $JournalEntryViewCopyWith<$Res>  {
  factory $JournalEntryViewCopyWith(JournalEntryView value, $Res Function(JournalEntryView) _then) = _$JournalEntryViewCopyWithImpl;
@useResult
$Res call({
 JournalItem item, String note, NoteStatus noteStatus
});


$JournalItemCopyWith<$Res> get item;

}
/// @nodoc
class _$JournalEntryViewCopyWithImpl<$Res>
    implements $JournalEntryViewCopyWith<$Res> {
  _$JournalEntryViewCopyWithImpl(this._self, this._then);

  final JournalEntryView _self;
  final $Res Function(JournalEntryView) _then;

/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? note = null,Object? noteStatus = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as JournalItem,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,noteStatus: null == noteStatus ? _self.noteStatus : noteStatus // ignore: cast_nullable_to_non_nullable
as NoteStatus,
  ));
}
/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalItemCopyWith<$Res> get item {
  
  return $JournalItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}


/// Adds pattern-matching-related methods to [JournalEntryView].
extension JournalEntryViewPatterns on JournalEntryView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalEntryView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalEntryView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalEntryView value)  $default,){
final _that = this;
switch (_that) {
case _JournalEntryView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalEntryView value)?  $default,){
final _that = this;
switch (_that) {
case _JournalEntryView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JournalItem item,  String note,  NoteStatus noteStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalEntryView() when $default != null:
return $default(_that.item,_that.note,_that.noteStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JournalItem item,  String note,  NoteStatus noteStatus)  $default,) {final _that = this;
switch (_that) {
case _JournalEntryView():
return $default(_that.item,_that.note,_that.noteStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JournalItem item,  String note,  NoteStatus noteStatus)?  $default,) {final _that = this;
switch (_that) {
case _JournalEntryView() when $default != null:
return $default(_that.item,_that.note,_that.noteStatus);case _:
  return null;

}
}

}

/// @nodoc


class _JournalEntryView extends JournalEntryView {
  const _JournalEntryView({required this.item, required this.note, required this.noteStatus}): super._();
  

@override final  JournalItem item;
/// The note text in the editor (≤ [kJournalNoteMaxChars]).
@override final  String note;
@override final  NoteStatus noteStatus;

/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalEntryViewCopyWith<_JournalEntryView> get copyWith => __$JournalEntryViewCopyWithImpl<_JournalEntryView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalEntryView&&(identical(other.item, item) || other.item == item)&&(identical(other.note, note) || other.note == note)&&(identical(other.noteStatus, noteStatus) || other.noteStatus == noteStatus));
}


@override
int get hashCode => Object.hash(runtimeType,item,note,noteStatus);

@override
String toString() {
  return 'JournalEntryView(item: $item, note: $note, noteStatus: $noteStatus)';
}


}

/// @nodoc
abstract mixin class _$JournalEntryViewCopyWith<$Res> implements $JournalEntryViewCopyWith<$Res> {
  factory _$JournalEntryViewCopyWith(_JournalEntryView value, $Res Function(_JournalEntryView) _then) = __$JournalEntryViewCopyWithImpl;
@override @useResult
$Res call({
 JournalItem item, String note, NoteStatus noteStatus
});


@override $JournalItemCopyWith<$Res> get item;

}
/// @nodoc
class __$JournalEntryViewCopyWithImpl<$Res>
    implements _$JournalEntryViewCopyWith<$Res> {
  __$JournalEntryViewCopyWithImpl(this._self, this._then);

  final _JournalEntryView _self;
  final $Res Function(_JournalEntryView) _then;

/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? note = null,Object? noteStatus = null,}) {
  return _then(_JournalEntryView(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as JournalItem,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,noteStatus: null == noteStatus ? _self.noteStatus : noteStatus // ignore: cast_nullable_to_non_nullable
as NoteStatus,
  ));
}

/// Create a copy of JournalEntryView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalItemCopyWith<$Res> get item {
  
  return $JournalItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

/// @nodoc
mixin _$JournalEntryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState()';
}


}

/// @nodoc
class $JournalEntryStateCopyWith<$Res>  {
$JournalEntryStateCopyWith(JournalEntryState _, $Res Function(JournalEntryState) __);
}


/// Adds pattern-matching-related methods to [JournalEntryState].
extension JournalEntryStatePatterns on JournalEntryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( JournalEntryLoading value)?  loading,TResult Function( JournalEntryContent value)?  content,TResult Function( JournalEntryPending value)?  pending,TResult Function( JournalEntryFailed value)?  failed,TResult Function( JournalEntryDeleted value)?  deleted,TResult Function( JournalEntryNotFound value)?  notFound,TResult Function( JournalEntryStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case JournalEntryLoading() when loading != null:
return loading(_that);case JournalEntryContent() when content != null:
return content(_that);case JournalEntryPending() when pending != null:
return pending(_that);case JournalEntryFailed() when failed != null:
return failed(_that);case JournalEntryDeleted() when deleted != null:
return deleted(_that);case JournalEntryNotFound() when notFound != null:
return notFound(_that);case JournalEntryStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( JournalEntryLoading value)  loading,required TResult Function( JournalEntryContent value)  content,required TResult Function( JournalEntryPending value)  pending,required TResult Function( JournalEntryFailed value)  failed,required TResult Function( JournalEntryDeleted value)  deleted,required TResult Function( JournalEntryNotFound value)  notFound,required TResult Function( JournalEntryStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case JournalEntryLoading():
return loading(_that);case JournalEntryContent():
return content(_that);case JournalEntryPending():
return pending(_that);case JournalEntryFailed():
return failed(_that);case JournalEntryDeleted():
return deleted(_that);case JournalEntryNotFound():
return notFound(_that);case JournalEntryStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( JournalEntryLoading value)?  loading,TResult? Function( JournalEntryContent value)?  content,TResult? Function( JournalEntryPending value)?  pending,TResult? Function( JournalEntryFailed value)?  failed,TResult? Function( JournalEntryDeleted value)?  deleted,TResult? Function( JournalEntryNotFound value)?  notFound,TResult? Function( JournalEntryStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case JournalEntryLoading() when loading != null:
return loading(_that);case JournalEntryContent() when content != null:
return content(_that);case JournalEntryPending() when pending != null:
return pending(_that);case JournalEntryFailed() when failed != null:
return failed(_that);case JournalEntryDeleted() when deleted != null:
return deleted(_that);case JournalEntryNotFound() when notFound != null:
return notFound(_that);case JournalEntryStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( JournalEntryView view)?  content,TResult Function( JournalEntryView view)?  pending,TResult Function( JournalEntryView view,  bool refunded)?  failed,TResult Function( DateTime undoUntil)?  deleted,TResult Function()?  notFound,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case JournalEntryLoading() when loading != null:
return loading();case JournalEntryContent() when content != null:
return content(_that.view);case JournalEntryPending() when pending != null:
return pending(_that.view);case JournalEntryFailed() when failed != null:
return failed(_that.view,_that.refunded);case JournalEntryDeleted() when deleted != null:
return deleted(_that.undoUntil);case JournalEntryNotFound() when notFound != null:
return notFound();case JournalEntryStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( JournalEntryView view)  content,required TResult Function( JournalEntryView view)  pending,required TResult Function( JournalEntryView view,  bool refunded)  failed,required TResult Function( DateTime undoUntil)  deleted,required TResult Function()  notFound,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case JournalEntryLoading():
return loading();case JournalEntryContent():
return content(_that.view);case JournalEntryPending():
return pending(_that.view);case JournalEntryFailed():
return failed(_that.view,_that.refunded);case JournalEntryDeleted():
return deleted(_that.undoUntil);case JournalEntryNotFound():
return notFound();case JournalEntryStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( JournalEntryView view)?  content,TResult? Function( JournalEntryView view)?  pending,TResult? Function( JournalEntryView view,  bool refunded)?  failed,TResult? Function( DateTime undoUntil)?  deleted,TResult? Function()?  notFound,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case JournalEntryLoading() when loading != null:
return loading();case JournalEntryContent() when content != null:
return content(_that.view);case JournalEntryPending() when pending != null:
return pending(_that.view);case JournalEntryFailed() when failed != null:
return failed(_that.view,_that.refunded);case JournalEntryDeleted() when deleted != null:
return deleted(_that.undoUntil);case JournalEntryNotFound() when notFound != null:
return notFound();case JournalEntryStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class JournalEntryLoading implements JournalEntryState {
  const JournalEntryLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.loading()';
}


}




/// @nodoc


class JournalEntryContent implements JournalEntryState {
  const JournalEntryContent(this.view);
  

 final  JournalEntryView view;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryContentCopyWith<JournalEntryContent> get copyWith => _$JournalEntryContentCopyWithImpl<JournalEntryContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryContent&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'JournalEntryState.content(view: $view)';
}


}

/// @nodoc
abstract mixin class $JournalEntryContentCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory $JournalEntryContentCopyWith(JournalEntryContent value, $Res Function(JournalEntryContent) _then) = _$JournalEntryContentCopyWithImpl;
@useResult
$Res call({
 JournalEntryView view
});


$JournalEntryViewCopyWith<$Res> get view;

}
/// @nodoc
class _$JournalEntryContentCopyWithImpl<$Res>
    implements $JournalEntryContentCopyWith<$Res> {
  _$JournalEntryContentCopyWithImpl(this._self, this._then);

  final JournalEntryContent _self;
  final $Res Function(JournalEntryContent) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(JournalEntryContent(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as JournalEntryView,
  ));
}

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalEntryViewCopyWith<$Res> get view {
  
  return $JournalEntryViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class JournalEntryPending implements JournalEntryState {
  const JournalEntryPending(this.view);
  

 final  JournalEntryView view;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryPendingCopyWith<JournalEntryPending> get copyWith => _$JournalEntryPendingCopyWithImpl<JournalEntryPending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryPending&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'JournalEntryState.pending(view: $view)';
}


}

/// @nodoc
abstract mixin class $JournalEntryPendingCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory $JournalEntryPendingCopyWith(JournalEntryPending value, $Res Function(JournalEntryPending) _then) = _$JournalEntryPendingCopyWithImpl;
@useResult
$Res call({
 JournalEntryView view
});


$JournalEntryViewCopyWith<$Res> get view;

}
/// @nodoc
class _$JournalEntryPendingCopyWithImpl<$Res>
    implements $JournalEntryPendingCopyWith<$Res> {
  _$JournalEntryPendingCopyWithImpl(this._self, this._then);

  final JournalEntryPending _self;
  final $Res Function(JournalEntryPending) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(JournalEntryPending(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as JournalEntryView,
  ));
}

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalEntryViewCopyWith<$Res> get view {
  
  return $JournalEntryViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class JournalEntryFailed implements JournalEntryState {
  const JournalEntryFailed(this.view, {required this.refunded});
  

 final  JournalEntryView view;
 final  bool refunded;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryFailedCopyWith<JournalEntryFailed> get copyWith => _$JournalEntryFailedCopyWithImpl<JournalEntryFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryFailed&&(identical(other.view, view) || other.view == view)&&(identical(other.refunded, refunded) || other.refunded == refunded));
}


@override
int get hashCode => Object.hash(runtimeType,view,refunded);

@override
String toString() {
  return 'JournalEntryState.failed(view: $view, refunded: $refunded)';
}


}

/// @nodoc
abstract mixin class $JournalEntryFailedCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory $JournalEntryFailedCopyWith(JournalEntryFailed value, $Res Function(JournalEntryFailed) _then) = _$JournalEntryFailedCopyWithImpl;
@useResult
$Res call({
 JournalEntryView view, bool refunded
});


$JournalEntryViewCopyWith<$Res> get view;

}
/// @nodoc
class _$JournalEntryFailedCopyWithImpl<$Res>
    implements $JournalEntryFailedCopyWith<$Res> {
  _$JournalEntryFailedCopyWithImpl(this._self, this._then);

  final JournalEntryFailed _self;
  final $Res Function(JournalEntryFailed) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? refunded = null,}) {
  return _then(JournalEntryFailed(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as JournalEntryView,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JournalEntryViewCopyWith<$Res> get view {
  
  return $JournalEntryViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class JournalEntryDeleted implements JournalEntryState {
  const JournalEntryDeleted({required this.undoUntil});
  

 final  DateTime undoUntil;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryDeletedCopyWith<JournalEntryDeleted> get copyWith => _$JournalEntryDeletedCopyWithImpl<JournalEntryDeleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryDeleted&&(identical(other.undoUntil, undoUntil) || other.undoUntil == undoUntil));
}


@override
int get hashCode => Object.hash(runtimeType,undoUntil);

@override
String toString() {
  return 'JournalEntryState.deleted(undoUntil: $undoUntil)';
}


}

/// @nodoc
abstract mixin class $JournalEntryDeletedCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory $JournalEntryDeletedCopyWith(JournalEntryDeleted value, $Res Function(JournalEntryDeleted) _then) = _$JournalEntryDeletedCopyWithImpl;
@useResult
$Res call({
 DateTime undoUntil
});




}
/// @nodoc
class _$JournalEntryDeletedCopyWithImpl<$Res>
    implements $JournalEntryDeletedCopyWith<$Res> {
  _$JournalEntryDeletedCopyWithImpl(this._self, this._then);

  final JournalEntryDeleted _self;
  final $Res Function(JournalEntryDeleted) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? undoUntil = null,}) {
  return _then(JournalEntryDeleted(
undoUntil: null == undoUntil ? _self.undoUntil : undoUntil // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class JournalEntryNotFound implements JournalEntryState {
  const JournalEntryNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.notFound()';
}


}




/// @nodoc


class JournalEntryStorageError implements JournalEntryState {
  const JournalEntryStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.storageError()';
}


}




// dart format on
