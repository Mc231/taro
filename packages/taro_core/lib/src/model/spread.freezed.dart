// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpreadPosition {

/// `past`, `challenge`, …
 PositionId get id;/// Draw and reveal order, 1-based.
 int get order;/// Normalized 0..1 horizontal layout coordinate (LTR; mirrored in RTL).
 double get x;/// Normalized 0..1 vertical layout coordinate.
 double get y;/// Card rotation in degrees, e.g. 90 for Celtic Cross `challenge`.
 double get rotationDeg;
/// Create a copy of SpreadPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadPositionCopyWith<SpreadPosition> get copyWith => _$SpreadPositionCopyWithImpl<SpreadPosition>(this as SpreadPosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadPosition&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.rotationDeg, rotationDeg) || other.rotationDeg == rotationDeg));
}


@override
int get hashCode => Object.hash(runtimeType,id,order,x,y,rotationDeg);

@override
String toString() {
  return 'SpreadPosition(id: $id, order: $order, x: $x, y: $y, rotationDeg: $rotationDeg)';
}


}

/// @nodoc
abstract mixin class $SpreadPositionCopyWith<$Res>  {
  factory $SpreadPositionCopyWith(SpreadPosition value, $Res Function(SpreadPosition) _then) = _$SpreadPositionCopyWithImpl;
@useResult
$Res call({
 PositionId id, int order, double x, double y, double rotationDeg
});




}
/// @nodoc
class _$SpreadPositionCopyWithImpl<$Res>
    implements $SpreadPositionCopyWith<$Res> {
  _$SpreadPositionCopyWithImpl(this._self, this._then);

  final SpreadPosition _self;
  final $Res Function(SpreadPosition) _then;

/// Create a copy of SpreadPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? order = null,Object? x = null,Object? y = null,Object? rotationDeg = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PositionId,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SpreadPosition].
extension SpreadPositionPatterns on SpreadPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpreadPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpreadPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpreadPosition value)  $default,){
final _that = this;
switch (_that) {
case _SpreadPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpreadPosition value)?  $default,){
final _that = this;
switch (_that) {
case _SpreadPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PositionId id,  int order,  double x,  double y,  double rotationDeg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpreadPosition() when $default != null:
return $default(_that.id,_that.order,_that.x,_that.y,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PositionId id,  int order,  double x,  double y,  double rotationDeg)  $default,) {final _that = this;
switch (_that) {
case _SpreadPosition():
return $default(_that.id,_that.order,_that.x,_that.y,_that.rotationDeg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PositionId id,  int order,  double x,  double y,  double rotationDeg)?  $default,) {final _that = this;
switch (_that) {
case _SpreadPosition() when $default != null:
return $default(_that.id,_that.order,_that.x,_that.y,_that.rotationDeg);case _:
  return null;

}
}

}

/// @nodoc


class _SpreadPosition implements SpreadPosition {
  const _SpreadPosition({required this.id, required this.order, required this.x, required this.y, this.rotationDeg = 0});
  

/// `past`, `challenge`, …
@override final  PositionId id;
/// Draw and reveal order, 1-based.
@override final  int order;
/// Normalized 0..1 horizontal layout coordinate (LTR; mirrored in RTL).
@override final  double x;
/// Normalized 0..1 vertical layout coordinate.
@override final  double y;
/// Card rotation in degrees, e.g. 90 for Celtic Cross `challenge`.
@override@JsonKey() final  double rotationDeg;

/// Create a copy of SpreadPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpreadPositionCopyWith<_SpreadPosition> get copyWith => __$SpreadPositionCopyWithImpl<_SpreadPosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpreadPosition&&(identical(other.id, id) || other.id == id)&&(identical(other.order, order) || other.order == order)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.rotationDeg, rotationDeg) || other.rotationDeg == rotationDeg));
}


@override
int get hashCode => Object.hash(runtimeType,id,order,x,y,rotationDeg);

@override
String toString() {
  return 'SpreadPosition(id: $id, order: $order, x: $x, y: $y, rotationDeg: $rotationDeg)';
}


}

/// @nodoc
abstract mixin class _$SpreadPositionCopyWith<$Res> implements $SpreadPositionCopyWith<$Res> {
  factory _$SpreadPositionCopyWith(_SpreadPosition value, $Res Function(_SpreadPosition) _then) = __$SpreadPositionCopyWithImpl;
@override @useResult
$Res call({
 PositionId id, int order, double x, double y, double rotationDeg
});




}
/// @nodoc
class __$SpreadPositionCopyWithImpl<$Res>
    implements _$SpreadPositionCopyWith<$Res> {
  __$SpreadPositionCopyWithImpl(this._self, this._then);

  final _SpreadPosition _self;
  final $Res Function(_SpreadPosition) _then;

/// Create a copy of SpreadPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? order = null,Object? x = null,Object? y = null,Object? rotationDeg = null,}) {
  return _then(_SpreadPosition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PositionId,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,rotationDeg: null == rotationDeg ? _self.rotationDeg : rotationDeg // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$SpreadDefinition {

/// One of [kSpreadIds].
 SpreadId get id;/// Content version (sent as `spread.version`, 03 §9.1).
 int get version;/// Positions in draw order.
 List<SpreadPosition> get positions;/// ARB keys of the question suggestions.
 List<String> get questionSuggestionKeys;/// Whether cards of this spread may be reversed.
 bool get allowsReversals;/// Whether the spread is offered (`spreads.enabled`).
 bool get enabled;
/// Create a copy of SpreadDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<SpreadDefinition> get copyWith => _$SpreadDefinitionCopyWithImpl<SpreadDefinition>(this as SpreadDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.positions, positions)&&const DeepCollectionEquality().equals(other.questionSuggestionKeys, questionSuggestionKeys)&&(identical(other.allowsReversals, allowsReversals) || other.allowsReversals == allowsReversals)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,const DeepCollectionEquality().hash(positions),const DeepCollectionEquality().hash(questionSuggestionKeys),allowsReversals,enabled);

@override
String toString() {
  return 'SpreadDefinition(id: $id, version: $version, positions: $positions, questionSuggestionKeys: $questionSuggestionKeys, allowsReversals: $allowsReversals, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $SpreadDefinitionCopyWith<$Res>  {
  factory $SpreadDefinitionCopyWith(SpreadDefinition value, $Res Function(SpreadDefinition) _then) = _$SpreadDefinitionCopyWithImpl;
@useResult
$Res call({
 SpreadId id, int version, List<SpreadPosition> positions, List<String> questionSuggestionKeys, bool allowsReversals, bool enabled
});




}
/// @nodoc
class _$SpreadDefinitionCopyWithImpl<$Res>
    implements $SpreadDefinitionCopyWith<$Res> {
  _$SpreadDefinitionCopyWithImpl(this._self, this._then);

  final SpreadDefinition _self;
  final $Res Function(SpreadDefinition) _then;

/// Create a copy of SpreadDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? positions = null,Object? questionSuggestionKeys = null,Object? allowsReversals = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as SpreadId,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,positions: null == positions ? _self.positions : positions // ignore: cast_nullable_to_non_nullable
as List<SpreadPosition>,questionSuggestionKeys: null == questionSuggestionKeys ? _self.questionSuggestionKeys : questionSuggestionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,allowsReversals: null == allowsReversals ? _self.allowsReversals : allowsReversals // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SpreadDefinition].
extension SpreadDefinitionPatterns on SpreadDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpreadDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpreadDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpreadDefinition value)  $default,){
final _that = this;
switch (_that) {
case _SpreadDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpreadDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _SpreadDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadId id,  int version,  List<SpreadPosition> positions,  List<String> questionSuggestionKeys,  bool allowsReversals,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpreadDefinition() when $default != null:
return $default(_that.id,_that.version,_that.positions,_that.questionSuggestionKeys,_that.allowsReversals,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadId id,  int version,  List<SpreadPosition> positions,  List<String> questionSuggestionKeys,  bool allowsReversals,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _SpreadDefinition():
return $default(_that.id,_that.version,_that.positions,_that.questionSuggestionKeys,_that.allowsReversals,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadId id,  int version,  List<SpreadPosition> positions,  List<String> questionSuggestionKeys,  bool allowsReversals,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _SpreadDefinition() when $default != null:
return $default(_that.id,_that.version,_that.positions,_that.questionSuggestionKeys,_that.allowsReversals,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _SpreadDefinition extends SpreadDefinition {
  const _SpreadDefinition({required this.id, required this.version, required final  List<SpreadPosition> positions, final  List<String> questionSuggestionKeys = const <String>[], this.allowsReversals = true, this.enabled = true}): _positions = positions,_questionSuggestionKeys = questionSuggestionKeys,super._();
  

/// One of [kSpreadIds].
@override final  SpreadId id;
/// Content version (sent as `spread.version`, 03 §9.1).
@override final  int version;
/// Positions in draw order.
 final  List<SpreadPosition> _positions;
/// Positions in draw order.
@override List<SpreadPosition> get positions {
  if (_positions is EqualUnmodifiableListView) return _positions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positions);
}

/// ARB keys of the question suggestions.
 final  List<String> _questionSuggestionKeys;
/// ARB keys of the question suggestions.
@override@JsonKey() List<String> get questionSuggestionKeys {
  if (_questionSuggestionKeys is EqualUnmodifiableListView) return _questionSuggestionKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questionSuggestionKeys);
}

/// Whether cards of this spread may be reversed.
@override@JsonKey() final  bool allowsReversals;
/// Whether the spread is offered (`spreads.enabled`).
@override@JsonKey() final  bool enabled;

/// Create a copy of SpreadDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpreadDefinitionCopyWith<_SpreadDefinition> get copyWith => __$SpreadDefinitionCopyWithImpl<_SpreadDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpreadDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._positions, _positions)&&const DeepCollectionEquality().equals(other._questionSuggestionKeys, _questionSuggestionKeys)&&(identical(other.allowsReversals, allowsReversals) || other.allowsReversals == allowsReversals)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,id,version,const DeepCollectionEquality().hash(_positions),const DeepCollectionEquality().hash(_questionSuggestionKeys),allowsReversals,enabled);

@override
String toString() {
  return 'SpreadDefinition(id: $id, version: $version, positions: $positions, questionSuggestionKeys: $questionSuggestionKeys, allowsReversals: $allowsReversals, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$SpreadDefinitionCopyWith<$Res> implements $SpreadDefinitionCopyWith<$Res> {
  factory _$SpreadDefinitionCopyWith(_SpreadDefinition value, $Res Function(_SpreadDefinition) _then) = __$SpreadDefinitionCopyWithImpl;
@override @useResult
$Res call({
 SpreadId id, int version, List<SpreadPosition> positions, List<String> questionSuggestionKeys, bool allowsReversals, bool enabled
});




}
/// @nodoc
class __$SpreadDefinitionCopyWithImpl<$Res>
    implements _$SpreadDefinitionCopyWith<$Res> {
  __$SpreadDefinitionCopyWithImpl(this._self, this._then);

  final _SpreadDefinition _self;
  final $Res Function(_SpreadDefinition) _then;

/// Create a copy of SpreadDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? positions = null,Object? questionSuggestionKeys = null,Object? allowsReversals = null,Object? enabled = null,}) {
  return _then(_SpreadDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as SpreadId,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,positions: null == positions ? _self._positions : positions // ignore: cast_nullable_to_non_nullable
as List<SpreadPosition>,questionSuggestionKeys: null == questionSuggestionKeys ? _self._questionSuggestionKeys : questionSuggestionKeys // ignore: cast_nullable_to_non_nullable
as List<String>,allowsReversals: null == allowsReversals ? _self.allowsReversals : allowsReversals // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
