// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deck_browser_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeckTile {

 DeckCard get card; String get name;
/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckTileCopyWith<DeckTile> get copyWith => _$DeckTileCopyWithImpl<DeckTile>(this as DeckTile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckTile&&(identical(other.card, card) || other.card == card)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,card,name);

@override
String toString() {
  return 'DeckTile(card: $card, name: $name)';
}


}

/// @nodoc
abstract mixin class $DeckTileCopyWith<$Res>  {
  factory $DeckTileCopyWith(DeckTile value, $Res Function(DeckTile) _then) = _$DeckTileCopyWithImpl;
@useResult
$Res call({
 DeckCard card, String name
});


$DeckCardCopyWith<$Res> get card;

}
/// @nodoc
class _$DeckTileCopyWithImpl<$Res>
    implements $DeckTileCopyWith<$Res> {
  _$DeckTileCopyWithImpl(this._self, this._then);

  final DeckTile _self;
  final $Res Function(DeckTile) _then;

/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? name = null,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DeckCard,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get card {
  
  return $DeckCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeckTile].
extension DeckTilePatterns on DeckTile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeckTile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeckTile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeckTile value)  $default,){
final _that = this;
switch (_that) {
case _DeckTile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeckTile value)?  $default,){
final _that = this;
switch (_that) {
case _DeckTile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeckCard card,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeckTile() when $default != null:
return $default(_that.card,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeckCard card,  String name)  $default,) {final _that = this;
switch (_that) {
case _DeckTile():
return $default(_that.card,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeckCard card,  String name)?  $default,) {final _that = this;
switch (_that) {
case _DeckTile() when $default != null:
return $default(_that.card,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _DeckTile implements DeckTile {
  const _DeckTile({required this.card, required this.name});
  

@override final  DeckCard card;
@override final  String name;

/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeckTileCopyWith<_DeckTile> get copyWith => __$DeckTileCopyWithImpl<_DeckTile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeckTile&&(identical(other.card, card) || other.card == card)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,card,name);

@override
String toString() {
  return 'DeckTile(card: $card, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DeckTileCopyWith<$Res> implements $DeckTileCopyWith<$Res> {
  factory _$DeckTileCopyWith(_DeckTile value, $Res Function(_DeckTile) _then) = __$DeckTileCopyWithImpl;
@override @useResult
$Res call({
 DeckCard card, String name
});


@override $DeckCardCopyWith<$Res> get card;

}
/// @nodoc
class __$DeckTileCopyWithImpl<$Res>
    implements _$DeckTileCopyWith<$Res> {
  __$DeckTileCopyWithImpl(this._self, this._then);

  final _DeckTile _self;
  final $Res Function(_DeckTile) _then;

/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? name = null,}) {
  return _then(_DeckTile(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DeckCard,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DeckTile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get card {
  
  return $DeckCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}
}

/// @nodoc
mixin _$DeckSection {

 DeckSectionKind get kind; List<DeckTile> get tiles;
/// Create a copy of DeckSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckSectionCopyWith<DeckSection> get copyWith => _$DeckSectionCopyWithImpl<DeckSection>(this as DeckSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckSection&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.tiles, tiles));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(tiles));

@override
String toString() {
  return 'DeckSection(kind: $kind, tiles: $tiles)';
}


}

/// @nodoc
abstract mixin class $DeckSectionCopyWith<$Res>  {
  factory $DeckSectionCopyWith(DeckSection value, $Res Function(DeckSection) _then) = _$DeckSectionCopyWithImpl;
@useResult
$Res call({
 DeckSectionKind kind, List<DeckTile> tiles
});




}
/// @nodoc
class _$DeckSectionCopyWithImpl<$Res>
    implements $DeckSectionCopyWith<$Res> {
  _$DeckSectionCopyWithImpl(this._self, this._then);

  final DeckSection _self;
  final $Res Function(DeckSection) _then;

/// Create a copy of DeckSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? tiles = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DeckSectionKind,tiles: null == tiles ? _self.tiles : tiles // ignore: cast_nullable_to_non_nullable
as List<DeckTile>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeckSection].
extension DeckSectionPatterns on DeckSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeckSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeckSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeckSection value)  $default,){
final _that = this;
switch (_that) {
case _DeckSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeckSection value)?  $default,){
final _that = this;
switch (_that) {
case _DeckSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeckSectionKind kind,  List<DeckTile> tiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeckSection() when $default != null:
return $default(_that.kind,_that.tiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeckSectionKind kind,  List<DeckTile> tiles)  $default,) {final _that = this;
switch (_that) {
case _DeckSection():
return $default(_that.kind,_that.tiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeckSectionKind kind,  List<DeckTile> tiles)?  $default,) {final _that = this;
switch (_that) {
case _DeckSection() when $default != null:
return $default(_that.kind,_that.tiles);case _:
  return null;

}
}

}

/// @nodoc


class _DeckSection implements DeckSection {
  const _DeckSection({required this.kind, required final  List<DeckTile> tiles}): _tiles = tiles;
  

@override final  DeckSectionKind kind;
 final  List<DeckTile> _tiles;
@override List<DeckTile> get tiles {
  if (_tiles is EqualUnmodifiableListView) return _tiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiles);
}


/// Create a copy of DeckSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeckSectionCopyWith<_DeckSection> get copyWith => __$DeckSectionCopyWithImpl<_DeckSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeckSection&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._tiles, _tiles));
}


@override
int get hashCode => Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_tiles));

@override
String toString() {
  return 'DeckSection(kind: $kind, tiles: $tiles)';
}


}

/// @nodoc
abstract mixin class _$DeckSectionCopyWith<$Res> implements $DeckSectionCopyWith<$Res> {
  factory _$DeckSectionCopyWith(_DeckSection value, $Res Function(_DeckSection) _then) = __$DeckSectionCopyWithImpl;
@override @useResult
$Res call({
 DeckSectionKind kind, List<DeckTile> tiles
});




}
/// @nodoc
class __$DeckSectionCopyWithImpl<$Res>
    implements _$DeckSectionCopyWith<$Res> {
  __$DeckSectionCopyWithImpl(this._self, this._then);

  final _DeckSection _self;
  final $Res Function(_DeckSection) _then;

/// Create a copy of DeckSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? tiles = null,}) {
  return _then(_DeckSection(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DeckSectionKind,tiles: null == tiles ? _self._tiles : tiles // ignore: cast_nullable_to_non_nullable
as List<DeckTile>,
  ));
}


}

/// @nodoc
mixin _$DeckBrowserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckBrowserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeckBrowserState()';
}


}

/// @nodoc
class $DeckBrowserStateCopyWith<$Res>  {
$DeckBrowserStateCopyWith(DeckBrowserState _, $Res Function(DeckBrowserState) __);
}


/// Adds pattern-matching-related methods to [DeckBrowserState].
extension DeckBrowserStatePatterns on DeckBrowserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeckBrowserLoading value)?  loading,TResult Function( DeckBrowserContent value)?  content,TResult Function( DeckBrowserSearchEmpty value)?  searchEmpty,TResult Function( DeckBrowserStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeckBrowserLoading() when loading != null:
return loading(_that);case DeckBrowserContent() when content != null:
return content(_that);case DeckBrowserSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case DeckBrowserStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeckBrowserLoading value)  loading,required TResult Function( DeckBrowserContent value)  content,required TResult Function( DeckBrowserSearchEmpty value)  searchEmpty,required TResult Function( DeckBrowserStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case DeckBrowserLoading():
return loading(_that);case DeckBrowserContent():
return content(_that);case DeckBrowserSearchEmpty():
return searchEmpty(_that);case DeckBrowserStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeckBrowserLoading value)?  loading,TResult? Function( DeckBrowserContent value)?  content,TResult? Function( DeckBrowserSearchEmpty value)?  searchEmpty,TResult? Function( DeckBrowserStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case DeckBrowserLoading() when loading != null:
return loading(_that);case DeckBrowserContent() when content != null:
return content(_that);case DeckBrowserSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case DeckBrowserStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<DeckSection> sections,  String query)?  content,TResult Function( String query)?  searchEmpty,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeckBrowserLoading() when loading != null:
return loading();case DeckBrowserContent() when content != null:
return content(_that.sections,_that.query);case DeckBrowserSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query);case DeckBrowserStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<DeckSection> sections,  String query)  content,required TResult Function( String query)  searchEmpty,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case DeckBrowserLoading():
return loading();case DeckBrowserContent():
return content(_that.sections,_that.query);case DeckBrowserSearchEmpty():
return searchEmpty(_that.query);case DeckBrowserStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<DeckSection> sections,  String query)?  content,TResult? Function( String query)?  searchEmpty,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case DeckBrowserLoading() when loading != null:
return loading();case DeckBrowserContent() when content != null:
return content(_that.sections,_that.query);case DeckBrowserSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query);case DeckBrowserStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class DeckBrowserLoading implements DeckBrowserState {
  const DeckBrowserLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckBrowserLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeckBrowserState.loading()';
}


}




/// @nodoc


class DeckBrowserContent implements DeckBrowserState {
  const DeckBrowserContent({required final  List<DeckSection> sections, this.query = ''}): _sections = sections;
  

 final  List<DeckSection> _sections;
 List<DeckSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

@JsonKey() final  String query;

/// Create a copy of DeckBrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckBrowserContentCopyWith<DeckBrowserContent> get copyWith => _$DeckBrowserContentCopyWithImpl<DeckBrowserContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckBrowserContent&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sections),query);

@override
String toString() {
  return 'DeckBrowserState.content(sections: $sections, query: $query)';
}


}

/// @nodoc
abstract mixin class $DeckBrowserContentCopyWith<$Res> implements $DeckBrowserStateCopyWith<$Res> {
  factory $DeckBrowserContentCopyWith(DeckBrowserContent value, $Res Function(DeckBrowserContent) _then) = _$DeckBrowserContentCopyWithImpl;
@useResult
$Res call({
 List<DeckSection> sections, String query
});




}
/// @nodoc
class _$DeckBrowserContentCopyWithImpl<$Res>
    implements $DeckBrowserContentCopyWith<$Res> {
  _$DeckBrowserContentCopyWithImpl(this._self, this._then);

  final DeckBrowserContent _self;
  final $Res Function(DeckBrowserContent) _then;

/// Create a copy of DeckBrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sections = null,Object? query = null,}) {
  return _then(DeckBrowserContent(
sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<DeckSection>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeckBrowserSearchEmpty implements DeckBrowserState {
  const DeckBrowserSearchEmpty({required this.query});
  

 final  String query;

/// Create a copy of DeckBrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeckBrowserSearchEmptyCopyWith<DeckBrowserSearchEmpty> get copyWith => _$DeckBrowserSearchEmptyCopyWithImpl<DeckBrowserSearchEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckBrowserSearchEmpty&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'DeckBrowserState.searchEmpty(query: $query)';
}


}

/// @nodoc
abstract mixin class $DeckBrowserSearchEmptyCopyWith<$Res> implements $DeckBrowserStateCopyWith<$Res> {
  factory $DeckBrowserSearchEmptyCopyWith(DeckBrowserSearchEmpty value, $Res Function(DeckBrowserSearchEmpty) _then) = _$DeckBrowserSearchEmptyCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$DeckBrowserSearchEmptyCopyWithImpl<$Res>
    implements $DeckBrowserSearchEmptyCopyWith<$Res> {
  _$DeckBrowserSearchEmptyCopyWithImpl(this._self, this._then);

  final DeckBrowserSearchEmpty _self;
  final $Res Function(DeckBrowserSearchEmpty) _then;

/// Create a copy of DeckBrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(DeckBrowserSearchEmpty(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeckBrowserStorageError implements DeckBrowserState {
  const DeckBrowserStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeckBrowserStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeckBrowserState.storageError()';
}


}




// dart format on
