// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spread_guide_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpreadGuideEntry {

 SpreadDefinition get spread;/// "Start this spread" is offered (not disabled by `spreads.enabled`).
 bool get startable;
/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadGuideEntryCopyWith<SpreadGuideEntry> get copyWith => _$SpreadGuideEntryCopyWithImpl<SpreadGuideEntry>(this as SpreadGuideEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadGuideEntry&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.startable, startable) || other.startable == startable));
}


@override
int get hashCode => Object.hash(runtimeType,spread,startable);

@override
String toString() {
  return 'SpreadGuideEntry(spread: $spread, startable: $startable)';
}


}

/// @nodoc
abstract mixin class $SpreadGuideEntryCopyWith<$Res>  {
  factory $SpreadGuideEntryCopyWith(SpreadGuideEntry value, $Res Function(SpreadGuideEntry) _then) = _$SpreadGuideEntryCopyWithImpl;
@useResult
$Res call({
 SpreadDefinition spread, bool startable
});


$SpreadDefinitionCopyWith<$Res> get spread;

}
/// @nodoc
class _$SpreadGuideEntryCopyWithImpl<$Res>
    implements $SpreadGuideEntryCopyWith<$Res> {
  _$SpreadGuideEntryCopyWithImpl(this._self, this._then);

  final SpreadGuideEntry _self;
  final $Res Function(SpreadGuideEntry) _then;

/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spread = null,Object? startable = null,}) {
  return _then(_self.copyWith(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,startable: null == startable ? _self.startable : startable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}
}


/// Adds pattern-matching-related methods to [SpreadGuideEntry].
extension SpreadGuideEntryPatterns on SpreadGuideEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpreadGuideEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpreadGuideEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpreadGuideEntry value)  $default,){
final _that = this;
switch (_that) {
case _SpreadGuideEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpreadGuideEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SpreadGuideEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadDefinition spread,  bool startable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpreadGuideEntry() when $default != null:
return $default(_that.spread,_that.startable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadDefinition spread,  bool startable)  $default,) {final _that = this;
switch (_that) {
case _SpreadGuideEntry():
return $default(_that.spread,_that.startable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadDefinition spread,  bool startable)?  $default,) {final _that = this;
switch (_that) {
case _SpreadGuideEntry() when $default != null:
return $default(_that.spread,_that.startable);case _:
  return null;

}
}

}

/// @nodoc


class _SpreadGuideEntry implements SpreadGuideEntry {
  const _SpreadGuideEntry({required this.spread, required this.startable});
  

@override final  SpreadDefinition spread;
/// "Start this spread" is offered (not disabled by `spreads.enabled`).
@override final  bool startable;

/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpreadGuideEntryCopyWith<_SpreadGuideEntry> get copyWith => __$SpreadGuideEntryCopyWithImpl<_SpreadGuideEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpreadGuideEntry&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.startable, startable) || other.startable == startable));
}


@override
int get hashCode => Object.hash(runtimeType,spread,startable);

@override
String toString() {
  return 'SpreadGuideEntry(spread: $spread, startable: $startable)';
}


}

/// @nodoc
abstract mixin class _$SpreadGuideEntryCopyWith<$Res> implements $SpreadGuideEntryCopyWith<$Res> {
  factory _$SpreadGuideEntryCopyWith(_SpreadGuideEntry value, $Res Function(_SpreadGuideEntry) _then) = __$SpreadGuideEntryCopyWithImpl;
@override @useResult
$Res call({
 SpreadDefinition spread, bool startable
});


@override $SpreadDefinitionCopyWith<$Res> get spread;

}
/// @nodoc
class __$SpreadGuideEntryCopyWithImpl<$Res>
    implements _$SpreadGuideEntryCopyWith<$Res> {
  __$SpreadGuideEntryCopyWithImpl(this._self, this._then);

  final _SpreadGuideEntry _self;
  final $Res Function(_SpreadGuideEntry) _then;

/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spread = null,Object? startable = null,}) {
  return _then(_SpreadGuideEntry(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,startable: null == startable ? _self.startable : startable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SpreadGuideEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}
}

/// @nodoc
mixin _$SpreadGuideState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadGuideState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpreadGuideState()';
}


}

/// @nodoc
class $SpreadGuideStateCopyWith<$Res>  {
$SpreadGuideStateCopyWith(SpreadGuideState _, $Res Function(SpreadGuideState) __);
}


/// Adds pattern-matching-related methods to [SpreadGuideState].
extension SpreadGuideStatePatterns on SpreadGuideState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SpreadGuideLoading value)?  loading,TResult Function( SpreadGuideContent value)?  content,TResult Function( SpreadGuideStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SpreadGuideLoading() when loading != null:
return loading(_that);case SpreadGuideContent() when content != null:
return content(_that);case SpreadGuideStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SpreadGuideLoading value)  loading,required TResult Function( SpreadGuideContent value)  content,required TResult Function( SpreadGuideStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case SpreadGuideLoading():
return loading(_that);case SpreadGuideContent():
return content(_that);case SpreadGuideStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SpreadGuideLoading value)?  loading,TResult? Function( SpreadGuideContent value)?  content,TResult? Function( SpreadGuideStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case SpreadGuideLoading() when loading != null:
return loading(_that);case SpreadGuideContent() when content != null:
return content(_that);case SpreadGuideStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<SpreadGuideEntry> spreads,  SpreadId? selected)?  content,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SpreadGuideLoading() when loading != null:
return loading();case SpreadGuideContent() when content != null:
return content(_that.spreads,_that.selected);case SpreadGuideStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<SpreadGuideEntry> spreads,  SpreadId? selected)  content,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case SpreadGuideLoading():
return loading();case SpreadGuideContent():
return content(_that.spreads,_that.selected);case SpreadGuideStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<SpreadGuideEntry> spreads,  SpreadId? selected)?  content,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case SpreadGuideLoading() when loading != null:
return loading();case SpreadGuideContent() when content != null:
return content(_that.spreads,_that.selected);case SpreadGuideStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class SpreadGuideLoading implements SpreadGuideState {
  const SpreadGuideLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadGuideLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpreadGuideState.loading()';
}


}




/// @nodoc


class SpreadGuideContent implements SpreadGuideState {
  const SpreadGuideContent({required final  List<SpreadGuideEntry> spreads, this.selected}): _spreads = spreads;
  

 final  List<SpreadGuideEntry> _spreads;
 List<SpreadGuideEntry> get spreads {
  if (_spreads is EqualUnmodifiableListView) return _spreads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spreads);
}

 final  SpreadId? selected;

/// Create a copy of SpreadGuideState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadGuideContentCopyWith<SpreadGuideContent> get copyWith => _$SpreadGuideContentCopyWithImpl<SpreadGuideContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadGuideContent&&const DeepCollectionEquality().equals(other._spreads, _spreads)&&(identical(other.selected, selected) || other.selected == selected));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_spreads),selected);

@override
String toString() {
  return 'SpreadGuideState.content(spreads: $spreads, selected: $selected)';
}


}

/// @nodoc
abstract mixin class $SpreadGuideContentCopyWith<$Res> implements $SpreadGuideStateCopyWith<$Res> {
  factory $SpreadGuideContentCopyWith(SpreadGuideContent value, $Res Function(SpreadGuideContent) _then) = _$SpreadGuideContentCopyWithImpl;
@useResult
$Res call({
 List<SpreadGuideEntry> spreads, SpreadId? selected
});




}
/// @nodoc
class _$SpreadGuideContentCopyWithImpl<$Res>
    implements $SpreadGuideContentCopyWith<$Res> {
  _$SpreadGuideContentCopyWithImpl(this._self, this._then);

  final SpreadGuideContent _self;
  final $Res Function(SpreadGuideContent) _then;

/// Create a copy of SpreadGuideState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? spreads = null,Object? selected = freezed,}) {
  return _then(SpreadGuideContent(
spreads: null == spreads ? _self._spreads : spreads // ignore: cast_nullable_to_non_nullable
as List<SpreadGuideEntry>,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as SpreadId?,
  ));
}


}

/// @nodoc


class SpreadGuideStorageError implements SpreadGuideState {
  const SpreadGuideStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadGuideStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpreadGuideState.storageError()';
}


}




// dart format on
