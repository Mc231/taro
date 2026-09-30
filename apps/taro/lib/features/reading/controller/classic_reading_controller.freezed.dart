// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'classic_reading_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassicPosition {

 DrawnCard get card; CardText get text; SpreadPosition? get position;
/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassicPositionCopyWith<ClassicPosition> get copyWith => _$ClassicPositionCopyWithImpl<ClassicPosition>(this as ClassicPosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicPosition&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,position);

@override
String toString() {
  return 'ClassicPosition(card: $card, text: $text, position: $position)';
}


}

/// @nodoc
abstract mixin class $ClassicPositionCopyWith<$Res>  {
  factory $ClassicPositionCopyWith(ClassicPosition value, $Res Function(ClassicPosition) _then) = _$ClassicPositionCopyWithImpl;
@useResult
$Res call({
 DrawnCard card, CardText text, SpreadPosition? position
});


$DrawnCardCopyWith<$Res> get card;$CardTextCopyWith<$Res> get text;$SpreadPositionCopyWith<$Res>? get position;

}
/// @nodoc
class _$ClassicPositionCopyWithImpl<$Res>
    implements $ClassicPositionCopyWith<$Res> {
  _$ClassicPositionCopyWithImpl(this._self, this._then);

  final ClassicPosition _self;
  final $Res Function(ClassicPosition) _then;

/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? text = null,Object? position = freezed,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DrawnCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as SpreadPosition?,
  ));
}
/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawnCardCopyWith<$Res> get card {
  
  return $DrawnCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadPositionCopyWith<$Res>? get position {
    if (_self.position == null) {
    return null;
  }

  return $SpreadPositionCopyWith<$Res>(_self.position!, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClassicPosition].
extension ClassicPositionPatterns on ClassicPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassicPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassicPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassicPosition value)  $default,){
final _that = this;
switch (_that) {
case _ClassicPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassicPosition value)?  $default,){
final _that = this;
switch (_that) {
case _ClassicPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DrawnCard card,  CardText text,  SpreadPosition? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassicPosition() when $default != null:
return $default(_that.card,_that.text,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DrawnCard card,  CardText text,  SpreadPosition? position)  $default,) {final _that = this;
switch (_that) {
case _ClassicPosition():
return $default(_that.card,_that.text,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DrawnCard card,  CardText text,  SpreadPosition? position)?  $default,) {final _that = this;
switch (_that) {
case _ClassicPosition() when $default != null:
return $default(_that.card,_that.text,_that.position);case _:
  return null;

}
}

}

/// @nodoc


class _ClassicPosition extends ClassicPosition {
  const _ClassicPosition({required this.card, required this.text, this.position}): super._();
  

@override final  DrawnCard card;
@override final  CardText text;
@override final  SpreadPosition? position;

/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassicPositionCopyWith<_ClassicPosition> get copyWith => __$ClassicPositionCopyWithImpl<_ClassicPosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassicPosition&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,position);

@override
String toString() {
  return 'ClassicPosition(card: $card, text: $text, position: $position)';
}


}

/// @nodoc
abstract mixin class _$ClassicPositionCopyWith<$Res> implements $ClassicPositionCopyWith<$Res> {
  factory _$ClassicPositionCopyWith(_ClassicPosition value, $Res Function(_ClassicPosition) _then) = __$ClassicPositionCopyWithImpl;
@override @useResult
$Res call({
 DrawnCard card, CardText text, SpreadPosition? position
});


@override $DrawnCardCopyWith<$Res> get card;@override $CardTextCopyWith<$Res> get text;@override $SpreadPositionCopyWith<$Res>? get position;

}
/// @nodoc
class __$ClassicPositionCopyWithImpl<$Res>
    implements _$ClassicPositionCopyWith<$Res> {
  __$ClassicPositionCopyWithImpl(this._self, this._then);

  final _ClassicPosition _self;
  final $Res Function(_ClassicPosition) _then;

/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? text = null,Object? position = freezed,}) {
  return _then(_ClassicPosition(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DrawnCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as SpreadPosition?,
  ));
}

/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawnCardCopyWith<$Res> get card {
  
  return $DrawnCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}/// Create a copy of ClassicPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadPositionCopyWith<$Res>? get position {
    if (_self.position == null) {
    return null;
  }

  return $SpreadPositionCopyWith<$Res>(_self.position!, (value) {
    return _then(_self.copyWith(position: value));
  });
}
}

/// @nodoc
mixin _$ClassicReadingView {

 Reading get reading; List<ClassicPosition> get positions; bool get aiAvailable;
/// Create a copy of ClassicReadingView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassicReadingViewCopyWith<ClassicReadingView> get copyWith => _$ClassicReadingViewCopyWithImpl<ClassicReadingView>(this as ClassicReadingView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingView&&(identical(other.reading, reading) || other.reading == reading)&&const DeepCollectionEquality().equals(other.positions, positions)&&(identical(other.aiAvailable, aiAvailable) || other.aiAvailable == aiAvailable));
}


@override
int get hashCode => Object.hash(runtimeType,reading,const DeepCollectionEquality().hash(positions),aiAvailable);

@override
String toString() {
  return 'ClassicReadingView(reading: $reading, positions: $positions, aiAvailable: $aiAvailable)';
}


}

/// @nodoc
abstract mixin class $ClassicReadingViewCopyWith<$Res>  {
  factory $ClassicReadingViewCopyWith(ClassicReadingView value, $Res Function(ClassicReadingView) _then) = _$ClassicReadingViewCopyWithImpl;
@useResult
$Res call({
 Reading reading, List<ClassicPosition> positions, bool aiAvailable
});


$ReadingCopyWith<$Res> get reading;

}
/// @nodoc
class _$ClassicReadingViewCopyWithImpl<$Res>
    implements $ClassicReadingViewCopyWith<$Res> {
  _$ClassicReadingViewCopyWithImpl(this._self, this._then);

  final ClassicReadingView _self;
  final $Res Function(ClassicReadingView) _then;

/// Create a copy of ClassicReadingView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reading = null,Object? positions = null,Object? aiAvailable = null,}) {
  return _then(_self.copyWith(
reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,positions: null == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<ClassicPosition>,aiAvailable: null == aiAvailable ? _self.aiAvailable : aiAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ClassicReadingView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingCopyWith<$Res> get reading {
  
  return $ReadingCopyWith<$Res>(_self.reading, (value) {
    return _then(_self.copyWith(reading: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClassicReadingView].
extension ClassicReadingViewPatterns on ClassicReadingView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassicReadingView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassicReadingView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassicReadingView value)  $default,){
final _that = this;
switch (_that) {
case _ClassicReadingView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassicReadingView value)?  $default,){
final _that = this;
switch (_that) {
case _ClassicReadingView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Reading reading,  List<ClassicPosition> positions,  bool aiAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassicReadingView() when $default != null:
return $default(_that.reading,_that.positions,_that.aiAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Reading reading,  List<ClassicPosition> positions,  bool aiAvailable)  $default,) {final _that = this;
switch (_that) {
case _ClassicReadingView():
return $default(_that.reading,_that.positions,_that.aiAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Reading reading,  List<ClassicPosition> positions,  bool aiAvailable)?  $default,) {final _that = this;
switch (_that) {
case _ClassicReadingView() when $default != null:
return $default(_that.reading,_that.positions,_that.aiAvailable);case _:
  return null;

}
}

}

/// @nodoc


class _ClassicReadingView implements ClassicReadingView {
  const _ClassicReadingView({required this.reading, required final  List<ClassicPosition> positions, this.aiAvailable = false}): _positions = positions;
  

@override final  Reading reading;
 final  List<ClassicPosition> _positions;
@override List<ClassicPosition> get positions {
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positions);
}

@override@JsonKey() final  bool aiAvailable;

/// Create a copy of ClassicReadingView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassicReadingViewCopyWith<_ClassicReadingView> get copyWith => __$ClassicReadingViewCopyWithImpl<_ClassicReadingView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassicReadingView&&(identical(other.reading, reading) || other.reading == reading)&&const DeepCollectionEquality().equals(other._positions, _positions)&&(identical(other.aiAvailable, aiAvailable) || other.aiAvailable == aiAvailable));
}


@override
int get hashCode => Object.hash(runtimeType,reading,const DeepCollectionEquality().hash(_positions),aiAvailable);

@override
String toString() {
  return 'ClassicReadingView(reading: $reading, positions: $positions, aiAvailable: $aiAvailable)';
}


}

/// @nodoc
abstract mixin class _$ClassicReadingViewCopyWith<$Res> implements $ClassicReadingViewCopyWith<$Res> {
  factory _$ClassicReadingViewCopyWith(_ClassicReadingView value, $Res Function(_ClassicReadingView) _then) = __$ClassicReadingViewCopyWithImpl;
@override @useResult
$Res call({
 Reading reading, List<ClassicPosition> positions, bool aiAvailable
});


@override $ReadingCopyWith<$Res> get reading;

}
/// @nodoc
class __$ClassicReadingViewCopyWithImpl<$Res>
    implements _$ClassicReadingViewCopyWith<$Res> {
  __$ClassicReadingViewCopyWithImpl(this._self, this._then);

  final _ClassicReadingView _self;
  final $Res Function(_ClassicReadingView) _then;

/// Create a copy of ClassicReadingView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reading = null,Object? positions = null,Object? aiAvailable = null,}) {
  return _then(_ClassicReadingView(
reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,positions: null == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<ClassicPosition>,aiAvailable: null == aiAvailable ? _self.aiAvailable : aiAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ClassicReadingView
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
mixin _$ClassicReadingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClassicReadingState()';
}


}

/// @nodoc
class $ClassicReadingStateCopyWith<$Res>  {
$ClassicReadingStateCopyWith(ClassicReadingState _, $Res Function(ClassicReadingState) __);
}


/// Adds pattern-matching-related methods to [ClassicReadingState].
extension ClassicReadingStatePatterns on ClassicReadingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ClassicReadingLoadingFromStorage value)?  loadingFromStorage,TResult Function( ClassicReadingContent value)?  content,TResult Function( ClassicReadingNotFound value)?  notFound,TResult Function( ClassicReadingFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage(_that);case ClassicReadingContent() when content != null:
return content(_that);case ClassicReadingNotFound() when notFound != null:
return notFound(_that);case ClassicReadingFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ClassicReadingLoadingFromStorage value)  loadingFromStorage,required TResult Function( ClassicReadingContent value)  content,required TResult Function( ClassicReadingNotFound value)  notFound,required TResult Function( ClassicReadingFailed value)  failed,}){
final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage():
return loadingFromStorage(_that);case ClassicReadingContent():
return content(_that);case ClassicReadingNotFound():
return notFound(_that);case ClassicReadingFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ClassicReadingLoadingFromStorage value)?  loadingFromStorage,TResult? Function( ClassicReadingContent value)?  content,TResult? Function( ClassicReadingNotFound value)?  notFound,TResult? Function( ClassicReadingFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage(_that);case ClassicReadingContent() when content != null:
return content(_that);case ClassicReadingNotFound() when notFound != null:
return notFound(_that);case ClassicReadingFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadingFromStorage,TResult Function( ClassicReadingView view)?  content,TResult Function()?  notFound,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage();case ClassicReadingContent() when content != null:
return content(_that.view);case ClassicReadingNotFound() when notFound != null:
return notFound();case ClassicReadingFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadingFromStorage,required TResult Function( ClassicReadingView view)  content,required TResult Function()  notFound,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage():
return loadingFromStorage();case ClassicReadingContent():
return content(_that.view);case ClassicReadingNotFound():
return notFound();case ClassicReadingFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadingFromStorage,TResult? Function( ClassicReadingView view)?  content,TResult? Function()?  notFound,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case ClassicReadingLoadingFromStorage() when loadingFromStorage != null:
return loadingFromStorage();case ClassicReadingContent() when content != null:
return content(_that.view);case ClassicReadingNotFound() when notFound != null:
return notFound();case ClassicReadingFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ClassicReadingLoadingFromStorage implements ClassicReadingState {
  const ClassicReadingLoadingFromStorage();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingLoadingFromStorage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClassicReadingState.loadingFromStorage()';
}


}




/// @nodoc


class ClassicReadingContent implements ClassicReadingState {
  const ClassicReadingContent(this.view);
  

 final  ClassicReadingView view;

/// Create a copy of ClassicReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassicReadingContentCopyWith<ClassicReadingContent> get copyWith => _$ClassicReadingContentCopyWithImpl<ClassicReadingContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingContent&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'ClassicReadingState.content(view: $view)';
}


}

/// @nodoc
abstract mixin class $ClassicReadingContentCopyWith<$Res> implements $ClassicReadingStateCopyWith<$Res> {
  factory $ClassicReadingContentCopyWith(ClassicReadingContent value, $Res Function(ClassicReadingContent) _then) = _$ClassicReadingContentCopyWithImpl;
@useResult
$Res call({
 ClassicReadingView view
});


$ClassicReadingViewCopyWith<$Res> get view;

}
/// @nodoc
class _$ClassicReadingContentCopyWithImpl<$Res>
    implements $ClassicReadingContentCopyWith<$Res> {
  _$ClassicReadingContentCopyWithImpl(this._self, this._then);

  final ClassicReadingContent _self;
  final $Res Function(ClassicReadingContent) _then;

/// Create a copy of ClassicReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(ClassicReadingContent(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as ClassicReadingView,
  ));
}

/// Create a copy of ClassicReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassicReadingViewCopyWith<$Res> get view {
  
  return $ClassicReadingViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class ClassicReadingNotFound implements ClassicReadingState {
  const ClassicReadingNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ClassicReadingState.notFound()';
}


}




/// @nodoc


class ClassicReadingFailed implements ClassicReadingState {
  const ClassicReadingFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of ClassicReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassicReadingFailedCopyWith<ClassicReadingFailed> get copyWith => _$ClassicReadingFailedCopyWithImpl<ClassicReadingFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassicReadingFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ClassicReadingState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ClassicReadingFailedCopyWith<$Res> implements $ClassicReadingStateCopyWith<$Res> {
  factory $ClassicReadingFailedCopyWith(ClassicReadingFailed value, $Res Function(ClassicReadingFailed) _then) = _$ClassicReadingFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ClassicReadingFailedCopyWithImpl<$Res>
    implements $ClassicReadingFailedCopyWith<$Res> {
  _$ClassicReadingFailedCopyWithImpl(this._self, this._then);

  final ClassicReadingFailed _self;
  final $Res Function(ClassicReadingFailed) _then;

/// Create a copy of ClassicReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ClassicReadingFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ClassicReadingState
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
