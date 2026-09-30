// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draw_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrawView {

 SpreadDefinition get spread; Draw get draw; bool get classic; int get placed; int get revealed; bool get autoDraw; bool get reducedMotion; ReadingId? get readingId; String? get question;
/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawViewCopyWith<DrawView> get copyWith => _$DrawViewCopyWithImpl<DrawView>(this as DrawView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawView&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.classic, classic) || other.classic == classic)&&(identical(other.placed, placed) || other.placed == placed)&&(identical(other.revealed, revealed) || other.revealed == revealed)&&(identical(other.autoDraw, autoDraw) || other.autoDraw == autoDraw)&&(identical(other.reducedMotion, reducedMotion) || other.reducedMotion == reducedMotion)&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.question, question) || other.question == question));
}


@override
int get hashCode => Object.hash(runtimeType,spread,draw,classic,placed,revealed,autoDraw,reducedMotion,readingId,question);

@override
String toString() {
  return 'DrawView(spread: $spread, draw: $draw, classic: $classic, placed: $placed, revealed: $revealed, autoDraw: $autoDraw, reducedMotion: $reducedMotion, readingId: $readingId, question: $question)';
}


}

/// @nodoc
abstract mixin class $DrawViewCopyWith<$Res>  {
  factory $DrawViewCopyWith(DrawView value, $Res Function(DrawView) _then) = _$DrawViewCopyWithImpl;
@useResult
$Res call({
 SpreadDefinition spread, Draw draw, bool classic, int placed, int revealed, bool autoDraw, bool reducedMotion, ReadingId? readingId, String? question
});


$SpreadDefinitionCopyWith<$Res> get spread;$DrawCopyWith<$Res> get draw;

}
/// @nodoc
class _$DrawViewCopyWithImpl<$Res>
    implements $DrawViewCopyWith<$Res> {
  _$DrawViewCopyWithImpl(this._self, this._then);

  final DrawView _self;
  final $Res Function(DrawView) _then;

/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spread = null,Object? draw = null,Object? classic = null,Object? placed = null,Object? revealed = null,Object? autoDraw = null,Object? reducedMotion = null,Object? readingId = freezed,Object? question = freezed,}) {
  return _then(_self.copyWith(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,classic: null == classic ? _self.classic : classic // ignore: cast_nullable_to_non_nullable
as bool,placed: null == placed ? _self.placed : placed // ignore: cast_nullable_to_non_nullable
as int,revealed: null == revealed ? _self.revealed : revealed // ignore: cast_nullable_to_non_nullable
as int,autoDraw: null == autoDraw ? _self.autoDraw : autoDraw // ignore: cast_nullable_to_non_nullable
as bool,reducedMotion: null == reducedMotion ? _self.reducedMotion : reducedMotion // ignore: cast_nullable_to_non_nullable
as bool,readingId: freezed == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawCopyWith<$Res> get draw {
  
  return $DrawCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrawView].
extension DrawViewPatterns on DrawView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawView value)  $default,){
final _that = this;
switch (_that) {
case _DrawView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawView value)?  $default,){
final _that = this;
switch (_that) {
case _DrawView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadDefinition spread,  Draw draw,  bool classic,  int placed,  int revealed,  bool autoDraw,  bool reducedMotion,  ReadingId? readingId,  String? question)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawView() when $default != null:
return $default(_that.spread,_that.draw,_that.classic,_that.placed,_that.revealed,_that.autoDraw,_that.reducedMotion,_that.readingId,_that.question);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadDefinition spread,  Draw draw,  bool classic,  int placed,  int revealed,  bool autoDraw,  bool reducedMotion,  ReadingId? readingId,  String? question)  $default,) {final _that = this;
switch (_that) {
case _DrawView():
return $default(_that.spread,_that.draw,_that.classic,_that.placed,_that.revealed,_that.autoDraw,_that.reducedMotion,_that.readingId,_that.question);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadDefinition spread,  Draw draw,  bool classic,  int placed,  int revealed,  bool autoDraw,  bool reducedMotion,  ReadingId? readingId,  String? question)?  $default,) {final _that = this;
switch (_that) {
case _DrawView() when $default != null:
return $default(_that.spread,_that.draw,_that.classic,_that.placed,_that.revealed,_that.autoDraw,_that.reducedMotion,_that.readingId,_that.question);case _:
  return null;

}
}

}

/// @nodoc


class _DrawView extends DrawView {
  const _DrawView({required this.spread, required this.draw, required this.classic, this.placed = 0, this.revealed = 0, this.autoDraw = false, this.reducedMotion = false, this.readingId, this.question}): super._();
  

@override final  SpreadDefinition spread;
@override final  Draw draw;
@override final  bool classic;
@override@JsonKey() final  int placed;
@override@JsonKey() final  int revealed;
@override@JsonKey() final  bool autoDraw;
@override@JsonKey() final  bool reducedMotion;
@override final  ReadingId? readingId;
@override final  String? question;

/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawViewCopyWith<_DrawView> get copyWith => __$DrawViewCopyWithImpl<_DrawView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawView&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.classic, classic) || other.classic == classic)&&(identical(other.placed, placed) || other.placed == placed)&&(identical(other.revealed, revealed) || other.revealed == revealed)&&(identical(other.autoDraw, autoDraw) || other.autoDraw == autoDraw)&&(identical(other.reducedMotion, reducedMotion) || other.reducedMotion == reducedMotion)&&(identical(other.readingId, readingId) || other.readingId == readingId)&&(identical(other.question, question) || other.question == question));
}


@override
int get hashCode => Object.hash(runtimeType,spread,draw,classic,placed,revealed,autoDraw,reducedMotion,readingId,question);

@override
String toString() {
  return 'DrawView(spread: $spread, draw: $draw, classic: $classic, placed: $placed, revealed: $revealed, autoDraw: $autoDraw, reducedMotion: $reducedMotion, readingId: $readingId, question: $question)';
}


}

/// @nodoc
abstract mixin class _$DrawViewCopyWith<$Res> implements $DrawViewCopyWith<$Res> {
  factory _$DrawViewCopyWith(_DrawView value, $Res Function(_DrawView) _then) = __$DrawViewCopyWithImpl;
@override @useResult
$Res call({
 SpreadDefinition spread, Draw draw, bool classic, int placed, int revealed, bool autoDraw, bool reducedMotion, ReadingId? readingId, String? question
});


@override $SpreadDefinitionCopyWith<$Res> get spread;@override $DrawCopyWith<$Res> get draw;

}
/// @nodoc
class __$DrawViewCopyWithImpl<$Res>
    implements _$DrawViewCopyWith<$Res> {
  __$DrawViewCopyWithImpl(this._self, this._then);

  final _DrawView _self;
  final $Res Function(_DrawView) _then;

/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spread = null,Object? draw = null,Object? classic = null,Object? placed = null,Object? revealed = null,Object? autoDraw = null,Object? reducedMotion = null,Object? readingId = freezed,Object? question = freezed,}) {
  return _then(_DrawView(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,classic: null == classic ? _self.classic : classic // ignore: cast_nullable_to_non_nullable
as bool,placed: null == placed ? _self.placed : placed // ignore: cast_nullable_to_non_nullable
as int,revealed: null == revealed ? _self.revealed : revealed // ignore: cast_nullable_to_non_nullable
as int,autoDraw: null == autoDraw ? _self.autoDraw : autoDraw // ignore: cast_nullable_to_non_nullable
as bool,reducedMotion: null == reducedMotion ? _self.reducedMotion : reducedMotion // ignore: cast_nullable_to_non_nullable
as bool,readingId: freezed == readingId ? _self.readingId : readingId // ignore: cast_nullable_to_non_nullable
as ReadingId?,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}/// Create a copy of DrawView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawCopyWith<$Res> get draw {
  
  return $DrawCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}
}

/// @nodoc
mixin _$DrawState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawState()';
}


}

/// @nodoc
class $DrawStateCopyWith<$Res>  {
$DrawStateCopyWith(DrawState _, $Res Function(DrawState) __);
}


/// Adds pattern-matching-related methods to [DrawState].
extension DrawStatePatterns on DrawState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DrawUnavailable value)?  unavailable,TResult Function( DrawPreparing value)?  preparing,TResult Function( DrawShuffling value)?  shuffling,TResult Function( DrawPicking value)?  picking,TResult Function( DrawRevealing value)?  revealing,TResult Function( DrawAwaitingReading value)?  awaitingReading,TResult Function( DrawSlowReading value)?  slowReading,TResult Function( DrawTimeoutPolling value)?  timeoutPolling,TResult Function( DrawGenerationFailed value)?  generationFailed,TResult Function( DrawHoldLost value)?  holdLost,TResult Function( DrawDeliveryExpired value)?  deliveryExpired,TResult Function( DrawCrisis value)?  crisis,TResult Function( DrawReturnedToQuestion value)?  returnedToQuestion,TResult Function( DrawCompleted value)?  completed,TResult Function( DrawFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DrawUnavailable() when unavailable != null:
return unavailable(_that);case DrawPreparing() when preparing != null:
return preparing(_that);case DrawShuffling() when shuffling != null:
return shuffling(_that);case DrawPicking() when picking != null:
return picking(_that);case DrawRevealing() when revealing != null:
return revealing(_that);case DrawAwaitingReading() when awaitingReading != null:
return awaitingReading(_that);case DrawSlowReading() when slowReading != null:
return slowReading(_that);case DrawTimeoutPolling() when timeoutPolling != null:
return timeoutPolling(_that);case DrawGenerationFailed() when generationFailed != null:
return generationFailed(_that);case DrawHoldLost() when holdLost != null:
return holdLost(_that);case DrawDeliveryExpired() when deliveryExpired != null:
return deliveryExpired(_that);case DrawCrisis() when crisis != null:
return crisis(_that);case DrawReturnedToQuestion() when returnedToQuestion != null:
return returnedToQuestion(_that);case DrawCompleted() when completed != null:
return completed(_that);case DrawFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DrawUnavailable value)  unavailable,required TResult Function( DrawPreparing value)  preparing,required TResult Function( DrawShuffling value)  shuffling,required TResult Function( DrawPicking value)  picking,required TResult Function( DrawRevealing value)  revealing,required TResult Function( DrawAwaitingReading value)  awaitingReading,required TResult Function( DrawSlowReading value)  slowReading,required TResult Function( DrawTimeoutPolling value)  timeoutPolling,required TResult Function( DrawGenerationFailed value)  generationFailed,required TResult Function( DrawHoldLost value)  holdLost,required TResult Function( DrawDeliveryExpired value)  deliveryExpired,required TResult Function( DrawCrisis value)  crisis,required TResult Function( DrawReturnedToQuestion value)  returnedToQuestion,required TResult Function( DrawCompleted value)  completed,required TResult Function( DrawFailed value)  failed,}){
final _that = this;
switch (_that) {
case DrawUnavailable():
return unavailable(_that);case DrawPreparing():
return preparing(_that);case DrawShuffling():
return shuffling(_that);case DrawPicking():
return picking(_that);case DrawRevealing():
return revealing(_that);case DrawAwaitingReading():
return awaitingReading(_that);case DrawSlowReading():
return slowReading(_that);case DrawTimeoutPolling():
return timeoutPolling(_that);case DrawGenerationFailed():
return generationFailed(_that);case DrawHoldLost():
return holdLost(_that);case DrawDeliveryExpired():
return deliveryExpired(_that);case DrawCrisis():
return crisis(_that);case DrawReturnedToQuestion():
return returnedToQuestion(_that);case DrawCompleted():
return completed(_that);case DrawFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DrawUnavailable value)?  unavailable,TResult? Function( DrawPreparing value)?  preparing,TResult? Function( DrawShuffling value)?  shuffling,TResult? Function( DrawPicking value)?  picking,TResult? Function( DrawRevealing value)?  revealing,TResult? Function( DrawAwaitingReading value)?  awaitingReading,TResult? Function( DrawSlowReading value)?  slowReading,TResult? Function( DrawTimeoutPolling value)?  timeoutPolling,TResult? Function( DrawGenerationFailed value)?  generationFailed,TResult? Function( DrawHoldLost value)?  holdLost,TResult? Function( DrawDeliveryExpired value)?  deliveryExpired,TResult? Function( DrawCrisis value)?  crisis,TResult? Function( DrawReturnedToQuestion value)?  returnedToQuestion,TResult? Function( DrawCompleted value)?  completed,TResult? Function( DrawFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DrawUnavailable() when unavailable != null:
return unavailable(_that);case DrawPreparing() when preparing != null:
return preparing(_that);case DrawShuffling() when shuffling != null:
return shuffling(_that);case DrawPicking() when picking != null:
return picking(_that);case DrawRevealing() when revealing != null:
return revealing(_that);case DrawAwaitingReading() when awaitingReading != null:
return awaitingReading(_that);case DrawSlowReading() when slowReading != null:
return slowReading(_that);case DrawTimeoutPolling() when timeoutPolling != null:
return timeoutPolling(_that);case DrawGenerationFailed() when generationFailed != null:
return generationFailed(_that);case DrawHoldLost() when holdLost != null:
return holdLost(_that);case DrawDeliveryExpired() when deliveryExpired != null:
return deliveryExpired(_that);case DrawCrisis() when crisis != null:
return crisis(_that);case DrawReturnedToQuestion() when returnedToQuestion != null:
return returnedToQuestion(_that);case DrawCompleted() when completed != null:
return completed(_that);case DrawFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unavailable,TResult Function()?  preparing,TResult Function( DrawView view)?  shuffling,TResult Function( DrawView view)?  picking,TResult Function( DrawView view)?  revealing,TResult Function( DrawView view)?  awaitingReading,TResult Function( DrawView view)?  slowReading,TResult Function( DrawView view)?  timeoutPolling,TResult Function( DrawView view,  Failure failure)?  generationFailed,TResult Function( DrawView view)?  holdLost,TResult Function( DrawView view)?  deliveryExpired,TResult Function( DrawView view,  SafetyInfo safety)?  crisis,TResult Function( DrawView view)?  returnedToQuestion,TResult Function( DrawView view,  Reading reading)?  completed,TResult Function( Failure failure,  DrawView? view)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DrawUnavailable() when unavailable != null:
return unavailable();case DrawPreparing() when preparing != null:
return preparing();case DrawShuffling() when shuffling != null:
return shuffling(_that.view);case DrawPicking() when picking != null:
return picking(_that.view);case DrawRevealing() when revealing != null:
return revealing(_that.view);case DrawAwaitingReading() when awaitingReading != null:
return awaitingReading(_that.view);case DrawSlowReading() when slowReading != null:
return slowReading(_that.view);case DrawTimeoutPolling() when timeoutPolling != null:
return timeoutPolling(_that.view);case DrawGenerationFailed() when generationFailed != null:
return generationFailed(_that.view,_that.failure);case DrawHoldLost() when holdLost != null:
return holdLost(_that.view);case DrawDeliveryExpired() when deliveryExpired != null:
return deliveryExpired(_that.view);case DrawCrisis() when crisis != null:
return crisis(_that.view,_that.safety);case DrawReturnedToQuestion() when returnedToQuestion != null:
return returnedToQuestion(_that.view);case DrawCompleted() when completed != null:
return completed(_that.view,_that.reading);case DrawFailed() when failed != null:
return failed(_that.failure,_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unavailable,required TResult Function()  preparing,required TResult Function( DrawView view)  shuffling,required TResult Function( DrawView view)  picking,required TResult Function( DrawView view)  revealing,required TResult Function( DrawView view)  awaitingReading,required TResult Function( DrawView view)  slowReading,required TResult Function( DrawView view)  timeoutPolling,required TResult Function( DrawView view,  Failure failure)  generationFailed,required TResult Function( DrawView view)  holdLost,required TResult Function( DrawView view)  deliveryExpired,required TResult Function( DrawView view,  SafetyInfo safety)  crisis,required TResult Function( DrawView view)  returnedToQuestion,required TResult Function( DrawView view,  Reading reading)  completed,required TResult Function( Failure failure,  DrawView? view)  failed,}) {final _that = this;
switch (_that) {
case DrawUnavailable():
return unavailable();case DrawPreparing():
return preparing();case DrawShuffling():
return shuffling(_that.view);case DrawPicking():
return picking(_that.view);case DrawRevealing():
return revealing(_that.view);case DrawAwaitingReading():
return awaitingReading(_that.view);case DrawSlowReading():
return slowReading(_that.view);case DrawTimeoutPolling():
return timeoutPolling(_that.view);case DrawGenerationFailed():
return generationFailed(_that.view,_that.failure);case DrawHoldLost():
return holdLost(_that.view);case DrawDeliveryExpired():
return deliveryExpired(_that.view);case DrawCrisis():
return crisis(_that.view,_that.safety);case DrawReturnedToQuestion():
return returnedToQuestion(_that.view);case DrawCompleted():
return completed(_that.view,_that.reading);case DrawFailed():
return failed(_that.failure,_that.view);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unavailable,TResult? Function()?  preparing,TResult? Function( DrawView view)?  shuffling,TResult? Function( DrawView view)?  picking,TResult? Function( DrawView view)?  revealing,TResult? Function( DrawView view)?  awaitingReading,TResult? Function( DrawView view)?  slowReading,TResult? Function( DrawView view)?  timeoutPolling,TResult? Function( DrawView view,  Failure failure)?  generationFailed,TResult? Function( DrawView view)?  holdLost,TResult? Function( DrawView view)?  deliveryExpired,TResult? Function( DrawView view,  SafetyInfo safety)?  crisis,TResult? Function( DrawView view)?  returnedToQuestion,TResult? Function( DrawView view,  Reading reading)?  completed,TResult? Function( Failure failure,  DrawView? view)?  failed,}) {final _that = this;
switch (_that) {
case DrawUnavailable() when unavailable != null:
return unavailable();case DrawPreparing() when preparing != null:
return preparing();case DrawShuffling() when shuffling != null:
return shuffling(_that.view);case DrawPicking() when picking != null:
return picking(_that.view);case DrawRevealing() when revealing != null:
return revealing(_that.view);case DrawAwaitingReading() when awaitingReading != null:
return awaitingReading(_that.view);case DrawSlowReading() when slowReading != null:
return slowReading(_that.view);case DrawTimeoutPolling() when timeoutPolling != null:
return timeoutPolling(_that.view);case DrawGenerationFailed() when generationFailed != null:
return generationFailed(_that.view,_that.failure);case DrawHoldLost() when holdLost != null:
return holdLost(_that.view);case DrawDeliveryExpired() when deliveryExpired != null:
return deliveryExpired(_that.view);case DrawCrisis() when crisis != null:
return crisis(_that.view,_that.safety);case DrawReturnedToQuestion() when returnedToQuestion != null:
return returnedToQuestion(_that.view);case DrawCompleted() when completed != null:
return completed(_that.view,_that.reading);case DrawFailed() when failed != null:
return failed(_that.failure,_that.view);case _:
  return null;

}
}

}

/// @nodoc


class DrawUnavailable extends DrawState {
  const DrawUnavailable(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawState.unavailable()';
}


}




/// @nodoc


class DrawPreparing extends DrawState {
  const DrawPreparing(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawPreparing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DrawState.preparing()';
}


}




/// @nodoc


class DrawShuffling extends DrawState {
  const DrawShuffling(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawShufflingCopyWith<DrawShuffling> get copyWith => _$DrawShufflingCopyWithImpl<DrawShuffling>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawShuffling&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.shuffling(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawShufflingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawShufflingCopyWith(DrawShuffling value, $Res Function(DrawShuffling) _then) = _$DrawShufflingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawShufflingCopyWithImpl<$Res>
    implements $DrawShufflingCopyWith<$Res> {
  _$DrawShufflingCopyWithImpl(this._self, this._then);

  final DrawShuffling _self;
  final $Res Function(DrawShuffling) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawShuffling(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawPicking extends DrawState {
  const DrawPicking(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawPickingCopyWith<DrawPicking> get copyWith => _$DrawPickingCopyWithImpl<DrawPicking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawPicking&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.picking(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawPickingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawPickingCopyWith(DrawPicking value, $Res Function(DrawPicking) _then) = _$DrawPickingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawPickingCopyWithImpl<$Res>
    implements $DrawPickingCopyWith<$Res> {
  _$DrawPickingCopyWithImpl(this._self, this._then);

  final DrawPicking _self;
  final $Res Function(DrawPicking) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawPicking(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawRevealing extends DrawState {
  const DrawRevealing(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawRevealingCopyWith<DrawRevealing> get copyWith => _$DrawRevealingCopyWithImpl<DrawRevealing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawRevealing&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.revealing(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawRevealingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawRevealingCopyWith(DrawRevealing value, $Res Function(DrawRevealing) _then) = _$DrawRevealingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawRevealingCopyWithImpl<$Res>
    implements $DrawRevealingCopyWith<$Res> {
  _$DrawRevealingCopyWithImpl(this._self, this._then);

  final DrawRevealing _self;
  final $Res Function(DrawRevealing) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawRevealing(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawAwaitingReading extends DrawState {
  const DrawAwaitingReading(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawAwaitingReadingCopyWith<DrawAwaitingReading> get copyWith => _$DrawAwaitingReadingCopyWithImpl<DrawAwaitingReading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawAwaitingReading&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.awaitingReading(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawAwaitingReadingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawAwaitingReadingCopyWith(DrawAwaitingReading value, $Res Function(DrawAwaitingReading) _then) = _$DrawAwaitingReadingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawAwaitingReadingCopyWithImpl<$Res>
    implements $DrawAwaitingReadingCopyWith<$Res> {
  _$DrawAwaitingReadingCopyWithImpl(this._self, this._then);

  final DrawAwaitingReading _self;
  final $Res Function(DrawAwaitingReading) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawAwaitingReading(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawSlowReading extends DrawState {
  const DrawSlowReading(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawSlowReadingCopyWith<DrawSlowReading> get copyWith => _$DrawSlowReadingCopyWithImpl<DrawSlowReading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawSlowReading&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.slowReading(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawSlowReadingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawSlowReadingCopyWith(DrawSlowReading value, $Res Function(DrawSlowReading) _then) = _$DrawSlowReadingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawSlowReadingCopyWithImpl<$Res>
    implements $DrawSlowReadingCopyWith<$Res> {
  _$DrawSlowReadingCopyWithImpl(this._self, this._then);

  final DrawSlowReading _self;
  final $Res Function(DrawSlowReading) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawSlowReading(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawTimeoutPolling extends DrawState {
  const DrawTimeoutPolling(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawTimeoutPollingCopyWith<DrawTimeoutPolling> get copyWith => _$DrawTimeoutPollingCopyWithImpl<DrawTimeoutPolling>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawTimeoutPolling&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.timeoutPolling(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawTimeoutPollingCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawTimeoutPollingCopyWith(DrawTimeoutPolling value, $Res Function(DrawTimeoutPolling) _then) = _$DrawTimeoutPollingCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawTimeoutPollingCopyWithImpl<$Res>
    implements $DrawTimeoutPollingCopyWith<$Res> {
  _$DrawTimeoutPollingCopyWithImpl(this._self, this._then);

  final DrawTimeoutPolling _self;
  final $Res Function(DrawTimeoutPolling) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawTimeoutPolling(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawGenerationFailed extends DrawState {
  const DrawGenerationFailed(this.view, {required this.failure}): super._();
  

 final  DrawView view;
 final  Failure failure;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawGenerationFailedCopyWith<DrawGenerationFailed> get copyWith => _$DrawGenerationFailedCopyWithImpl<DrawGenerationFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawGenerationFailed&&(identical(other.view, view) || other.view == view)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,view,failure);

@override
String toString() {
  return 'DrawState.generationFailed(view: $view, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DrawGenerationFailedCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawGenerationFailedCopyWith(DrawGenerationFailed value, $Res Function(DrawGenerationFailed) _then) = _$DrawGenerationFailedCopyWithImpl;
@useResult
$Res call({
 DrawView view, Failure failure
});


$DrawViewCopyWith<$Res> get view;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DrawGenerationFailedCopyWithImpl<$Res>
    implements $DrawGenerationFailedCopyWith<$Res> {
  _$DrawGenerationFailedCopyWithImpl(this._self, this._then);

  final DrawGenerationFailed _self;
  final $Res Function(DrawGenerationFailed) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? failure = null,}) {
  return _then(DrawGenerationFailed(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class DrawHoldLost extends DrawState {
  const DrawHoldLost(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawHoldLostCopyWith<DrawHoldLost> get copyWith => _$DrawHoldLostCopyWithImpl<DrawHoldLost>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawHoldLost&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.holdLost(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawHoldLostCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawHoldLostCopyWith(DrawHoldLost value, $Res Function(DrawHoldLost) _then) = _$DrawHoldLostCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawHoldLostCopyWithImpl<$Res>
    implements $DrawHoldLostCopyWith<$Res> {
  _$DrawHoldLostCopyWithImpl(this._self, this._then);

  final DrawHoldLost _self;
  final $Res Function(DrawHoldLost) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawHoldLost(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawDeliveryExpired extends DrawState {
  const DrawDeliveryExpired(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawDeliveryExpiredCopyWith<DrawDeliveryExpired> get copyWith => _$DrawDeliveryExpiredCopyWithImpl<DrawDeliveryExpired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawDeliveryExpired&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.deliveryExpired(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawDeliveryExpiredCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawDeliveryExpiredCopyWith(DrawDeliveryExpired value, $Res Function(DrawDeliveryExpired) _then) = _$DrawDeliveryExpiredCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawDeliveryExpiredCopyWithImpl<$Res>
    implements $DrawDeliveryExpiredCopyWith<$Res> {
  _$DrawDeliveryExpiredCopyWithImpl(this._self, this._then);

  final DrawDeliveryExpired _self;
  final $Res Function(DrawDeliveryExpired) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawDeliveryExpired(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawCrisis extends DrawState {
  const DrawCrisis(this.view, {required this.safety}): super._();
  

 final  DrawView view;
 final  SafetyInfo safety;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawCrisisCopyWith<DrawCrisis> get copyWith => _$DrawCrisisCopyWithImpl<DrawCrisis>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawCrisis&&(identical(other.view, view) || other.view == view)&&(identical(other.safety, safety) || other.safety == safety));
}


@override
int get hashCode => Object.hash(runtimeType,view,safety);

@override
String toString() {
  return 'DrawState.crisis(view: $view, safety: $safety)';
}


}

/// @nodoc
abstract mixin class $DrawCrisisCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawCrisisCopyWith(DrawCrisis value, $Res Function(DrawCrisis) _then) = _$DrawCrisisCopyWithImpl;
@useResult
$Res call({
 DrawView view, SafetyInfo safety
});


$DrawViewCopyWith<$Res> get view;$SafetyInfoCopyWith<$Res> get safety;

}
/// @nodoc
class _$DrawCrisisCopyWithImpl<$Res>
    implements $DrawCrisisCopyWith<$Res> {
  _$DrawCrisisCopyWithImpl(this._self, this._then);

  final DrawCrisis _self;
  final $Res Function(DrawCrisis) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? safety = null,}) {
  return _then(DrawCrisis(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as SafetyInfo,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<$Res> get safety {
  
  return $SafetyInfoCopyWith<$Res>(_self.safety, (value) {
    return _then(_self.copyWith(safety: value));
  });
}
}

/// @nodoc


class DrawReturnedToQuestion extends DrawState {
  const DrawReturnedToQuestion(this.view): super._();
  

 final  DrawView view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawReturnedToQuestionCopyWith<DrawReturnedToQuestion> get copyWith => _$DrawReturnedToQuestionCopyWithImpl<DrawReturnedToQuestion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawReturnedToQuestion&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DrawState.returnedToQuestion(view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawReturnedToQuestionCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawReturnedToQuestionCopyWith(DrawReturnedToQuestion value, $Res Function(DrawReturnedToQuestion) _then) = _$DrawReturnedToQuestionCopyWithImpl;
@useResult
$Res call({
 DrawView view
});


$DrawViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DrawReturnedToQuestionCopyWithImpl<$Res>
    implements $DrawReturnedToQuestionCopyWith<$Res> {
  _$DrawReturnedToQuestionCopyWithImpl(this._self, this._then);

  final DrawReturnedToQuestion _self;
  final $Res Function(DrawReturnedToQuestion) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DrawReturnedToQuestion(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DrawCompleted extends DrawState {
  const DrawCompleted(this.view, {required this.reading}): super._();
  

 final  DrawView view;
 final  Reading reading;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawCompletedCopyWith<DrawCompleted> get copyWith => _$DrawCompletedCopyWithImpl<DrawCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawCompleted&&(identical(other.view, view) || other.view == view)&&(identical(other.reading, reading) || other.reading == reading));
}


@override
int get hashCode => Object.hash(runtimeType,view,reading);

@override
String toString() {
  return 'DrawState.completed(view: $view, reading: $reading)';
}


}

/// @nodoc
abstract mixin class $DrawCompletedCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawCompletedCopyWith(DrawCompleted value, $Res Function(DrawCompleted) _then) = _$DrawCompletedCopyWithImpl;
@useResult
$Res call({
 DrawView view, Reading reading
});


$DrawViewCopyWith<$Res> get view;$ReadingCopyWith<$Res> get reading;

}
/// @nodoc
class _$DrawCompletedCopyWithImpl<$Res>
    implements $DrawCompletedCopyWith<$Res> {
  _$DrawCompletedCopyWithImpl(this._self, this._then);

  final DrawCompleted _self;
  final $Res Function(DrawCompleted) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? reading = null,}) {
  return _then(DrawCompleted(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView,reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as Reading,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res> get view {
  
  return $DrawViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of DrawState
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


class DrawFailed extends DrawState {
  const DrawFailed({required this.failure, this.view}): super._();
  

 final  Failure failure;
 final  DrawView? view;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawFailedCopyWith<DrawFailed> get copyWith => _$DrawFailedCopyWithImpl<DrawFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawFailed&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,failure,view);

@override
String toString() {
  return 'DrawState.failed(failure: $failure, view: $view)';
}


}

/// @nodoc
abstract mixin class $DrawFailedCopyWith<$Res> implements $DrawStateCopyWith<$Res> {
  factory $DrawFailedCopyWith(DrawFailed value, $Res Function(DrawFailed) _then) = _$DrawFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure, DrawView? view
});


$FailureCopyWith<$Res> get failure;$DrawViewCopyWith<$Res>? get view;

}
/// @nodoc
class _$DrawFailedCopyWithImpl<$Res>
    implements $DrawFailedCopyWith<$Res> {
  _$DrawFailedCopyWithImpl(this._self, this._then);

  final DrawFailed _self;
  final $Res Function(DrawFailed) _then;

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? view = freezed,}) {
  return _then(DrawFailed(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,view: freezed == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DrawView?,
  ));
}

/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of DrawState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawViewCopyWith<$Res>? get view {
    if (_self.view == null) {
    return null;
  }

  return $DrawViewCopyWith<$Res>(_self.view!, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

// dart format on
