// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_result_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingResultArgs {

 ReadingId get id; ReadingViewOrigin get origin;
/// Create a copy of ReadingResultArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultArgsCopyWith<ReadingResultArgs> get copyWith => _$ReadingResultArgsCopyWithImpl<ReadingResultArgs>(this as ReadingResultArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultArgs&&(identical(other.id, id) || other.id == id)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,id,origin);

@override
String toString() {
  return 'ReadingResultArgs(id: $id, origin: $origin)';
}


}

/// @nodoc
abstract mixin class $ReadingResultArgsCopyWith<$Res>  {
  factory $ReadingResultArgsCopyWith(ReadingResultArgs value, $Res Function(ReadingResultArgs) _then) = _$ReadingResultArgsCopyWithImpl;
@useResult
$Res call({
 ReadingId id, ReadingViewOrigin origin
});




}
/// @nodoc
class _$ReadingResultArgsCopyWithImpl<$Res>
    implements $ReadingResultArgsCopyWith<$Res> {
  _$ReadingResultArgsCopyWithImpl(this._self, this._then);

  final ReadingResultArgs _self;
  final $Res Function(ReadingResultArgs) _then;

/// Create a copy of ReadingResultArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? origin = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ReadingId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ReadingViewOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingResultArgs].
extension ReadingResultArgsPatterns on ReadingResultArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingResultArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingResultArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingResultArgs value)  $default,){
final _that = this;
switch (_that) {
case _ReadingResultArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingResultArgs value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingResultArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReadingId id,  ReadingViewOrigin origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingResultArgs() when $default != null:
return $default(_that.id,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReadingId id,  ReadingViewOrigin origin)  $default,) {final _that = this;
switch (_that) {
case _ReadingResultArgs():
return $default(_that.id,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReadingId id,  ReadingViewOrigin origin)?  $default,) {final _that = this;
switch (_that) {
case _ReadingResultArgs() when $default != null:
return $default(_that.id,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingResultArgs implements ReadingResultArgs {
  const _ReadingResultArgs({required this.id, this.origin = ReadingViewOrigin.fresh});
  

@override final  ReadingId id;
@override@JsonKey() final  ReadingViewOrigin origin;

/// Create a copy of ReadingResultArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingResultArgsCopyWith<_ReadingResultArgs> get copyWith => __$ReadingResultArgsCopyWithImpl<_ReadingResultArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingResultArgs&&(identical(other.id, id) || other.id == id)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,id,origin);

@override
String toString() {
  return 'ReadingResultArgs(id: $id, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$ReadingResultArgsCopyWith<$Res> implements $ReadingResultArgsCopyWith<$Res> {
  factory _$ReadingResultArgsCopyWith(_ReadingResultArgs value, $Res Function(_ReadingResultArgs) _then) = __$ReadingResultArgsCopyWithImpl;
@override @useResult
$Res call({
 ReadingId id, ReadingViewOrigin origin
});




}
/// @nodoc
class __$ReadingResultArgsCopyWithImpl<$Res>
    implements _$ReadingResultArgsCopyWith<$Res> {
  __$ReadingResultArgsCopyWithImpl(this._self, this._then);

  final _ReadingResultArgs _self;
  final $Res Function(_ReadingResultArgs) _then;

/// Create a copy of ReadingResultArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? origin = null,}) {
  return _then(_ReadingResultArgs(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ReadingId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ReadingViewOrigin,
  ));
}


}

/// @nodoc
mixin _$ReadingResultView {

 Reading get reading; Map<CardId, CardText> get cardTexts;/// The spread geometry of the S09 mini spread (null: a plain row).
 SpreadDefinition? get spread;
/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultViewCopyWith<ReadingResultView> get copyWith => _$ReadingResultViewCopyWithImpl<ReadingResultView>(this as ReadingResultView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultView&&(identical(other.reading, reading) || other.reading == reading)&&const DeepCollectionEquality().equals(other.cardTexts, cardTexts)&&(identical(other.spread, spread) || other.spread == spread));
}


@override
int get hashCode => Object.hash(runtimeType,reading,const DeepCollectionEquality().hash(cardTexts),spread);

@override
String toString() {
  return 'ReadingResultView(reading: $reading, cardTexts: $cardTexts, spread: $spread)';
}


}

/// @nodoc
abstract mixin class $ReadingResultViewCopyWith<$Res>  {
  factory $ReadingResultViewCopyWith(ReadingResultView value, $Res Function(ReadingResultView) _then) = _$ReadingResultViewCopyWithImpl;
@useResult
$Res call({
 Reading reading, Map<CardId, CardText> cardTexts, SpreadDefinition? spread
});


$ReadingCopyWith<$Res> get reading;$SpreadDefinitionCopyWith<$Res>? get spread;

}
/// @nodoc
class _$ReadingResultViewCopyWithImpl<$Res>
    implements $ReadingResultViewCopyWith<$Res> {
  _$ReadingResultViewCopyWithImpl(this._self, this._then);

  final ReadingResultView _self;
  final $Res Function(ReadingResultView) _then;

/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reading = null,Object? cardTexts = null,Object? spread = freezed,}) {
  return _then(_self.copyWith(
reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,cardTexts: null == cardTexts ? _self.cardTexts : cardTexts // ignore: cast_nullable_to_non_nullable
as Map<CardId, CardText>,spread: freezed == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition?,
  ));
}
/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingCopyWith<$Res> get reading {
  
  return $ReadingCopyWith<$Res>(_self.reading, (value) {
    return _then(_self.copyWith(reading: value));
  });
}/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res>? get spread {
    if (_self.spread == null) {
    return null;
  }

  return $SpreadDefinitionCopyWith<$Res>(_self.spread!, (value) {
    return _then(_self.copyWith(spread: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingResultView].
extension ReadingResultViewPatterns on ReadingResultView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingResultView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingResultView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingResultView value)  $default,){
final _that = this;
switch (_that) {
case _ReadingResultView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingResultView value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingResultView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reading reading,  Map<CardId, CardText> cardTexts,  SpreadDefinition? spread)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingResultView() when $default != null:
return $default(_that.reading,_that.cardTexts,_that.spread);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reading reading,  Map<CardId, CardText> cardTexts,  SpreadDefinition? spread)  $default,) {final _that = this;
switch (_that) {
case _ReadingResultView():
return $default(_that.reading,_that.cardTexts,_that.spread);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reading reading,  Map<CardId, CardText> cardTexts,  SpreadDefinition? spread)?  $default,) {final _that = this;
switch (_that) {
case _ReadingResultView() when $default != null:
return $default(_that.reading,_that.cardTexts,_that.spread);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingResultView extends ReadingResultView {
  const _ReadingResultView({required this.reading, required final  Map<CardId, CardText> cardTexts, this.spread}): _cardTexts = cardTexts,super._();
  

@override final  Reading reading;
 final  Map<CardId, CardText> _cardTexts;
@override Map<CardId, CardText> get cardTexts {
  if (_cardTexts is EqualUnmodifiableMapView) return _cardTexts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cardTexts);
}

/// The spread geometry of the S09 mini spread (null: a plain row).
@override final  SpreadDefinition? spread;

/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingResultViewCopyWith<_ReadingResultView> get copyWith => __$ReadingResultViewCopyWithImpl<_ReadingResultView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingResultView&&(identical(other.reading, reading) || other.reading == reading)&&const DeepCollectionEquality().equals(other._cardTexts, _cardTexts)&&(identical(other.spread, spread) || other.spread == spread));
}


@override
int get hashCode => Object.hash(runtimeType,reading,const DeepCollectionEquality().hash(_cardTexts),spread);

@override
String toString() {
  return 'ReadingResultView(reading: $reading, cardTexts: $cardTexts, spread: $spread)';
}


}

/// @nodoc
abstract mixin class _$ReadingResultViewCopyWith<$Res> implements $ReadingResultViewCopyWith<$Res> {
  factory _$ReadingResultViewCopyWith(_ReadingResultView value, $Res Function(_ReadingResultView) _then) = __$ReadingResultViewCopyWithImpl;
@override @useResult
$Res call({
 Reading reading, Map<CardId, CardText> cardTexts, SpreadDefinition? spread
});


@override $ReadingCopyWith<$Res> get reading;@override $SpreadDefinitionCopyWith<$Res>? get spread;

}
/// @nodoc
class __$ReadingResultViewCopyWithImpl<$Res>
    implements _$ReadingResultViewCopyWith<$Res> {
  __$ReadingResultViewCopyWithImpl(this._self, this._then);

  final _ReadingResultView _self;
  final $Res Function(_ReadingResultView) _then;

/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reading = null,Object? cardTexts = null,Object? spread = freezed,}) {
  return _then(_ReadingResultView(
reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,cardTexts: null == cardTexts ? _self._cardTexts : cardTexts // ignore: cast_nullable_to_non_nullable
as Map<CardId, CardText>,spread: freezed == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition?,
  ));
}

/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingCopyWith<$Res> get reading {
  
  return $ReadingCopyWith<$Res>(_self.reading, (value) {
    return _then(_self.copyWith(reading: value));
  });
}/// Create a copy of ReadingResultView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res>? get spread {
    if (_self.spread == null) {
    return null;
  }

  return $SpreadDefinitionCopyWith<$Res>(_self.spread!, (value) {
    return _then(_self.copyWith(spread: value));
  });
}
}

/// @nodoc
mixin _$ReadingResultState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingResultState()';
}


}

/// @nodoc
class $ReadingResultStateCopyWith<$Res>  {
$ReadingResultStateCopyWith(ReadingResultState _, $Res Function(ReadingResultState) __);
}


/// Adds pattern-matching-related methods to [ReadingResultState].
extension ReadingResultStatePatterns on ReadingResultState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadingResultLoadingFromStorage value)?  loadingFromStorage,TResult Function( ReadingResultContent value)?  content,TResult Function( ReadingResultRatingGiven value)?  ratingGiven,TResult Function( ReadingResultSharing value)?  sharing,TResult Function( ReadingResultNotFound value)?  notFound,TResult Function( ReadingResultFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage(_that);case ReadingResultContent() when content != null:
return content(_that);case ReadingResultRatingGiven() when ratingGiven != null:
return ratingGiven(_that);case ReadingResultSharing() when sharing != null:
return sharing(_that);case ReadingResultNotFound() when notFound != null:
return notFound(_that);case ReadingResultFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadingResultLoadingFromStorage value)  loadingFromStorage,required TResult Function( ReadingResultContent value)  content,required TResult Function( ReadingResultRatingGiven value)  ratingGiven,required TResult Function( ReadingResultSharing value)  sharing,required TResult Function( ReadingResultNotFound value)  notFound,required TResult Function( ReadingResultFailed value)  failed,}){
final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage():
return loadingFromStorage(_that);case ReadingResultContent():
return content(_that);case ReadingResultRatingGiven():
return ratingGiven(_that);case ReadingResultSharing():
return sharing(_that);case ReadingResultNotFound():
return notFound(_that);case ReadingResultFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadingResultLoadingFromStorage value)?  loadingFromStorage,TResult? Function( ReadingResultContent value)?  content,TResult? Function( ReadingResultRatingGiven value)?  ratingGiven,TResult? Function( ReadingResultSharing value)?  sharing,TResult? Function( ReadingResultNotFound value)?  notFound,TResult? Function( ReadingResultFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage(_that);case ReadingResultContent() when content != null:
return content(_that);case ReadingResultRatingGiven() when ratingGiven != null:
return ratingGiven(_that);case ReadingResultSharing() when sharing != null:
return sharing(_that);case ReadingResultNotFound() when notFound != null:
return notFound(_that);case ReadingResultFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadingFromStorage,TResult Function( ReadingResultView view)?  content,TResult Function( ReadingResultView view)?  ratingGiven,TResult Function( ReadingResultView view)?  sharing,TResult Function()?  notFound,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage();case ReadingResultContent() when content != null:
return content(_that.view);case ReadingResultRatingGiven() when ratingGiven != null:
return ratingGiven(_that.view);case ReadingResultSharing() when sharing != null:
return sharing(_that.view);case ReadingResultNotFound() when notFound != null:
return notFound();case ReadingResultFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadingFromStorage,required TResult Function( ReadingResultView view)  content,required TResult Function( ReadingResultView view)  ratingGiven,required TResult Function( ReadingResultView view)  sharing,required TResult Function()  notFound,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage():
return loadingFromStorage();case ReadingResultContent():
return content(_that.view);case ReadingResultRatingGiven():
return ratingGiven(_that.view);case ReadingResultSharing():
return sharing(_that.view);case ReadingResultNotFound():
return notFound();case ReadingResultFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadingFromStorage,TResult? Function( ReadingResultView view)?  content,TResult? Function( ReadingResultView view)?  ratingGiven,TResult? Function( ReadingResultView view)?  sharing,TResult? Function()?  notFound,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case ReadingResultLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage();case ReadingResultContent() when content != null:
return content(_that.view);case ReadingResultRatingGiven() when ratingGiven != null:
return ratingGiven(_that.view);case ReadingResultSharing() when sharing != null:
return sharing(_that.view);case ReadingResultNotFound() when notFound != null:
return notFound();case ReadingResultFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ReadingResultLoadingFromStorage implements ReadingResultState {
  const ReadingResultLoadingFromStorage();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultLoadingFromStorage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingResultState.loadingFromStorage()';
}


}




/// @nodoc


class ReadingResultContent implements ReadingResultState {
  const ReadingResultContent(this.view);
  

 final  ReadingResultView view;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultContentCopyWith<ReadingResultContent> get copyWith => _$ReadingResultContentCopyWithImpl<ReadingResultContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultContent&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'ReadingResultState.content(view: $view)';
}


}

/// @nodoc
abstract mixin class $ReadingResultContentCopyWith<$Res> implements $ReadingResultStateCopyWith<$Res> {
  factory $ReadingResultContentCopyWith(ReadingResultContent value, $Res Function(ReadingResultContent) _then) = _$ReadingResultContentCopyWithImpl;
@useResult
$Res call({
 ReadingResultView view
});


$ReadingResultViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ReadingResultContentCopyWithImpl<$Res>
    implements $ReadingResultContentCopyWith<$Res> {
  _$ReadingResultContentCopyWithImpl(this._self, this._then);

  final ReadingResultContent _self;
  final $Res Function(ReadingResultContent) _then;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(ReadingResultContent(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ReadingResultView,
  ));
}

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingResultViewCopyWith<$Res> get view {
  
  return $ReadingResultViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class ReadingResultRatingGiven implements ReadingResultState {
  const ReadingResultRatingGiven(this.view);
  

 final  ReadingResultView view;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultRatingGivenCopyWith<ReadingResultRatingGiven> get copyWith => _$ReadingResultRatingGivenCopyWithImpl<ReadingResultRatingGiven>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultRatingGiven&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'ReadingResultState.ratingGiven(view: $view)';
}


}

/// @nodoc
abstract mixin class $ReadingResultRatingGivenCopyWith<$Res> implements $ReadingResultStateCopyWith<$Res> {
  factory $ReadingResultRatingGivenCopyWith(ReadingResultRatingGiven value, $Res Function(ReadingResultRatingGiven) _then) = _$ReadingResultRatingGivenCopyWithImpl;
@useResult
$Res call({
 ReadingResultView view
});


$ReadingResultViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ReadingResultRatingGivenCopyWithImpl<$Res>
    implements $ReadingResultRatingGivenCopyWith<$Res> {
  _$ReadingResultRatingGivenCopyWithImpl(this._self, this._then);

  final ReadingResultRatingGiven _self;
  final $Res Function(ReadingResultRatingGiven) _then;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(ReadingResultRatingGiven(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ReadingResultView,
  ));
}

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingResultViewCopyWith<$Res> get view {
  
  return $ReadingResultViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class ReadingResultSharing implements ReadingResultState {
  const ReadingResultSharing(this.view);
  

 final  ReadingResultView view;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultSharingCopyWith<ReadingResultSharing> get copyWith => _$ReadingResultSharingCopyWithImpl<ReadingResultSharing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultSharing&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'ReadingResultState.sharing(view: $view)';
}


}

/// @nodoc
abstract mixin class $ReadingResultSharingCopyWith<$Res> implements $ReadingResultStateCopyWith<$Res> {
  factory $ReadingResultSharingCopyWith(ReadingResultSharing value, $Res Function(ReadingResultSharing) _then) = _$ReadingResultSharingCopyWithImpl;
@useResult
$Res call({
 ReadingResultView view
});


$ReadingResultViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ReadingResultSharingCopyWithImpl<$Res>
    implements $ReadingResultSharingCopyWith<$Res> {
  _$ReadingResultSharingCopyWithImpl(this._self, this._then);

  final ReadingResultSharing _self;
  final $Res Function(ReadingResultSharing) _then;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(ReadingResultSharing(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ReadingResultView,
  ));
}

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingResultViewCopyWith<$Res> get view {
  
  return $ReadingResultViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class ReadingResultNotFound implements ReadingResultState {
  const ReadingResultNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingResultState.notFound()';
}


}




/// @nodoc


class ReadingResultFailed implements ReadingResultState {
  const ReadingResultFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingResultFailedCopyWith<ReadingResultFailed> get copyWith => _$ReadingResultFailedCopyWithImpl<ReadingResultFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingResultFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ReadingResultState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ReadingResultFailedCopyWith<$Res> implements $ReadingResultStateCopyWith<$Res> {
  factory $ReadingResultFailedCopyWith(ReadingResultFailed value, $Res Function(ReadingResultFailed) _then) = _$ReadingResultFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ReadingResultFailedCopyWithImpl<$Res>
    implements $ReadingResultFailedCopyWith<$Res> {
  _$ReadingResultFailedCopyWithImpl(this._self, this._then);

  final ReadingResultFailed _self;
  final $Res Function(ReadingResultFailed) _then;

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ReadingResultFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ReadingResultState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
