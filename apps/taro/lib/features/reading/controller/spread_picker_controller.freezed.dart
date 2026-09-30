// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spread_picker_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpreadPickerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadPickerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpreadPickerState()';
}


}

/// @nodoc
class $SpreadPickerStateCopyWith<$Res>  {
$SpreadPickerStateCopyWith(SpreadPickerState _, $Res Function(SpreadPickerState) __);
}


/// Adds pattern-matching-related methods to [SpreadPickerState].
extension SpreadPickerStatePatterns on SpreadPickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SpreadPickerLoading value)?  loading,TResult Function( SpreadPickerContent value)?  content,TResult Function( SpreadPickerFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SpreadPickerLoading() when loading != null:
return loading(_that);case SpreadPickerContent() when content != null:
return content(_that);case SpreadPickerFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SpreadPickerLoading value)  loading,required TResult Function( SpreadPickerContent value)  content,required TResult Function( SpreadPickerFailed value)  failed,}){
final _that = this;
switch (_that) {
case SpreadPickerLoading():
return loading(_that);case SpreadPickerContent():
return content(_that);case SpreadPickerFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SpreadPickerLoading value)?  loading,TResult? Function( SpreadPickerContent value)?  content,TResult? Function( SpreadPickerFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SpreadPickerLoading() when loading != null:
return loading(_that);case SpreadPickerContent() when content != null:
return content(_that);case SpreadPickerFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<SpreadDefinition> spreads)?  content,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SpreadPickerLoading() when loading != null:
return loading();case SpreadPickerContent() when content != null:
return content(_that.spreads);case SpreadPickerFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<SpreadDefinition> spreads)  content,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case SpreadPickerLoading():
return loading();case SpreadPickerContent():
return content(_that.spreads);case SpreadPickerFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<SpreadDefinition> spreads)?  content,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case SpreadPickerLoading() when loading != null:
return loading();case SpreadPickerContent() when content != null:
return content(_that.spreads);case SpreadPickerFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SpreadPickerLoading implements SpreadPickerState {
  const SpreadPickerLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadPickerLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpreadPickerState.loading()';
}


}




/// @nodoc


class SpreadPickerContent implements SpreadPickerState {
  const SpreadPickerContent(final  List<SpreadDefinition> spreads): _spreads = spreads;
  

 final  List<SpreadDefinition> _spreads;
 List<SpreadDefinition> get spreads {
  if (_spreads is EqualUnmodifiableListView) return _spreads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spreads);
}


/// Create a copy of SpreadPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadPickerContentCopyWith<SpreadPickerContent> get copyWith => _$SpreadPickerContentCopyWithImpl<SpreadPickerContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadPickerContent&&const DeepCollectionEquality().equals(other._spreads, _spreads));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_spreads));

@override
String toString() {
  return 'SpreadPickerState.content(spreads: $spreads)';
}


}

/// @nodoc
abstract mixin class $SpreadPickerContentCopyWith<$Res> implements $SpreadPickerStateCopyWith<$Res> {
  factory $SpreadPickerContentCopyWith(SpreadPickerContent value, $Res Function(SpreadPickerContent) _then) = _$SpreadPickerContentCopyWithImpl;
@useResult
$Res call({
 List<SpreadDefinition> spreads
});




}
/// @nodoc
class _$SpreadPickerContentCopyWithImpl<$Res>
    implements $SpreadPickerContentCopyWith<$Res> {
  _$SpreadPickerContentCopyWithImpl(this._self, this._then);

  final SpreadPickerContent _self;
  final $Res Function(SpreadPickerContent) _then;

/// Create a copy of SpreadPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? spreads = null,}) {
  return _then(SpreadPickerContent(
null == spreads ? _self._spreads : spreads // ignore: cast_nullable_to_non_nullable
as List<SpreadDefinition>,
  ));
}


}

/// @nodoc


class SpreadPickerFailed implements SpreadPickerState {
  const SpreadPickerFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of SpreadPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpreadPickerFailedCopyWith<SpreadPickerFailed> get copyWith => _$SpreadPickerFailedCopyWithImpl<SpreadPickerFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpreadPickerFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SpreadPickerState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SpreadPickerFailedCopyWith<$Res> implements $SpreadPickerStateCopyWith<$Res> {
  factory $SpreadPickerFailedCopyWith(SpreadPickerFailed value, $Res Function(SpreadPickerFailed) _then) = _$SpreadPickerFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SpreadPickerFailedCopyWithImpl<$Res>
    implements $SpreadPickerFailedCopyWith<$Res> {
  _$SpreadPickerFailedCopyWithImpl(this._self, this._then);

  final SpreadPickerFailed _self;
  final $Res Function(SpreadPickerFailed) _then;

/// Create a copy of SpreadPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SpreadPickerFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SpreadPickerState
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
