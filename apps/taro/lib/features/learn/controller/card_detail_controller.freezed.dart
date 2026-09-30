// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_detail_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CardDetailArgs {

 CardId get cardId; LearnCardOrigin get origin;
/// Create a copy of CardDetailArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDetailArgsCopyWith<CardDetailArgs> get copyWith => _$CardDetailArgsCopyWithImpl<CardDetailArgs>(this as CardDetailArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailArgs&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,origin);

@override
String toString() {
  return 'CardDetailArgs(cardId: $cardId, origin: $origin)';
}


}

/// @nodoc
abstract mixin class $CardDetailArgsCopyWith<$Res>  {
  factory $CardDetailArgsCopyWith(CardDetailArgs value, $Res Function(CardDetailArgs) _then) = _$CardDetailArgsCopyWithImpl;
@useResult
$Res call({
 CardId cardId, LearnCardOrigin origin
});




}
/// @nodoc
class _$CardDetailArgsCopyWithImpl<$Res>
    implements $CardDetailArgsCopyWith<$Res> {
  _$CardDetailArgsCopyWithImpl(this._self, this._then);

  final CardDetailArgs _self;
  final $Res Function(CardDetailArgs) _then;

/// Create a copy of CardDetailArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardId = null,Object? origin = null,}) {
  return _then(_self.copyWith(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LearnCardOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [CardDetailArgs].
extension CardDetailArgsPatterns on CardDetailArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardDetailArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardDetailArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardDetailArgs value)  $default,){
final _that = this;
switch (_that) {
case _CardDetailArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardDetailArgs value)?  $default,){
final _that = this;
switch (_that) {
case _CardDetailArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardId cardId,  LearnCardOrigin origin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardDetailArgs() when $default != null:
return $default(_that.cardId,_that.origin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardId cardId,  LearnCardOrigin origin)  $default,) {final _that = this;
switch (_that) {
case _CardDetailArgs():
return $default(_that.cardId,_that.origin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardId cardId,  LearnCardOrigin origin)?  $default,) {final _that = this;
switch (_that) {
case _CardDetailArgs() when $default != null:
return $default(_that.cardId,_that.origin);case _:
  return null;

}
}

}

/// @nodoc


class _CardDetailArgs implements CardDetailArgs {
  const _CardDetailArgs({required this.cardId, this.origin = LearnCardOrigin.deck});
  

@override final  CardId cardId;
@override@JsonKey() final  LearnCardOrigin origin;

/// Create a copy of CardDetailArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardDetailArgsCopyWith<_CardDetailArgs> get copyWith => __$CardDetailArgsCopyWithImpl<_CardDetailArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardDetailArgs&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.origin, origin) || other.origin == origin));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,origin);

@override
String toString() {
  return 'CardDetailArgs(cardId: $cardId, origin: $origin)';
}


}

/// @nodoc
abstract mixin class _$CardDetailArgsCopyWith<$Res> implements $CardDetailArgsCopyWith<$Res> {
  factory _$CardDetailArgsCopyWith(_CardDetailArgs value, $Res Function(_CardDetailArgs) _then) = __$CardDetailArgsCopyWithImpl;
@override @useResult
$Res call({
 CardId cardId, LearnCardOrigin origin
});




}
/// @nodoc
class __$CardDetailArgsCopyWithImpl<$Res>
    implements _$CardDetailArgsCopyWith<$Res> {
  __$CardDetailArgsCopyWithImpl(this._self, this._then);

  final _CardDetailArgs _self;
  final $Res Function(_CardDetailArgs) _then;

/// Create a copy of CardDetailArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardId = null,Object? origin = null,}) {
  return _then(_CardDetailArgs(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LearnCardOrigin,
  ));
}


}

/// @nodoc
mixin _$CardDetailView {

 DeckCard get card; CardText get text;/// "In your journal: drawn N times" (local count, links to a filtered
/// journal; 0 = "Not in your journal yet").
 int get drawnCount;/// 1-based position within its section ("Cups · 3 of 14").
 int get position;/// The section size.
 int get sectionSize;/// The previous card in deck order, if any.
 CardId? get previous;/// The next card in deck order, if any.
 CardId? get next;
/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDetailViewCopyWith<CardDetailView> get copyWith => _$CardDetailViewCopyWithImpl<CardDetailView>(this as CardDetailView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailView&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.drawnCount, drawnCount) || other.drawnCount == drawnCount)&&(identical(other.position, position) || other.position == position)&&(identical(other.sectionSize, sectionSize) || other.sectionSize == sectionSize)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,drawnCount,position,sectionSize,previous,next);

@override
String toString() {
  return 'CardDetailView(card: $card, text: $text, drawnCount: $drawnCount, position: $position, sectionSize: $sectionSize, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class $CardDetailViewCopyWith<$Res>  {
  factory $CardDetailViewCopyWith(CardDetailView value, $Res Function(CardDetailView) _then) = _$CardDetailViewCopyWithImpl;
@useResult
$Res call({
 DeckCard card, CardText text, int drawnCount, int position, int sectionSize, CardId? previous, CardId? next
});


$DeckCardCopyWith<$Res> get card;$CardTextCopyWith<$Res> get text;

}
/// @nodoc
class _$CardDetailViewCopyWithImpl<$Res>
    implements $CardDetailViewCopyWith<$Res> {
  _$CardDetailViewCopyWithImpl(this._self, this._then);

  final CardDetailView _self;
  final $Res Function(CardDetailView) _then;

/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? text = null,Object? drawnCount = null,Object? position = null,Object? sectionSize = null,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DeckCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,drawnCount: null == drawnCount ? _self.drawnCount : drawnCount // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,sectionSize: null == sectionSize ? _self.sectionSize : sectionSize // ignore: cast_nullable_to_non_nullable
as int,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as CardId?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}
/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get card {
  
  return $DeckCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardDetailView].
extension CardDetailViewPatterns on CardDetailView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardDetailView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardDetailView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardDetailView value)  $default,){
final _that = this;
switch (_that) {
case _CardDetailView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardDetailView value)?  $default,){
final _that = this;
switch (_that) {
case _CardDetailView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeckCard card,  CardText text,  int drawnCount,  int position,  int sectionSize,  CardId? previous,  CardId? next)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardDetailView() when $default != null:
return $default(_that.card,_that.text,_that.drawnCount,_that.position,_that.sectionSize,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeckCard card,  CardText text,  int drawnCount,  int position,  int sectionSize,  CardId? previous,  CardId? next)  $default,) {final _that = this;
switch (_that) {
case _CardDetailView():
return $default(_that.card,_that.text,_that.drawnCount,_that.position,_that.sectionSize,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeckCard card,  CardText text,  int drawnCount,  int position,  int sectionSize,  CardId? previous,  CardId? next)?  $default,) {final _that = this;
switch (_that) {
case _CardDetailView() when $default != null:
return $default(_that.card,_that.text,_that.drawnCount,_that.position,_that.sectionSize,_that.previous,_that.next);case _:
  return null;

}
}

}

/// @nodoc


class _CardDetailView implements CardDetailView {
  const _CardDetailView({required this.card, required this.text, required this.drawnCount, required this.position, required this.sectionSize, this.previous, this.next});
  

@override final  DeckCard card;
@override final  CardText text;
/// "In your journal: drawn N times" (local count, links to a filtered
/// journal; 0 = "Not in your journal yet").
@override final  int drawnCount;
/// 1-based position within its section ("Cups · 3 of 14").
@override final  int position;
/// The section size.
@override final  int sectionSize;
/// The previous card in deck order, if any.
@override final  CardId? previous;
/// The next card in deck order, if any.
@override final  CardId? next;

/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardDetailViewCopyWith<_CardDetailView> get copyWith => __$CardDetailViewCopyWithImpl<_CardDetailView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardDetailView&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.drawnCount, drawnCount) || other.drawnCount == drawnCount)&&(identical(other.position, position) || other.position == position)&&(identical(other.sectionSize, sectionSize) || other.sectionSize == sectionSize)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,drawnCount,position,sectionSize,previous,next);

@override
String toString() {
  return 'CardDetailView(card: $card, text: $text, drawnCount: $drawnCount, position: $position, sectionSize: $sectionSize, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class _$CardDetailViewCopyWith<$Res> implements $CardDetailViewCopyWith<$Res> {
  factory _$CardDetailViewCopyWith(_CardDetailView value, $Res Function(_CardDetailView) _then) = __$CardDetailViewCopyWithImpl;
@override @useResult
$Res call({
 DeckCard card, CardText text, int drawnCount, int position, int sectionSize, CardId? previous, CardId? next
});


@override $DeckCardCopyWith<$Res> get card;@override $CardTextCopyWith<$Res> get text;

}
/// @nodoc
class __$CardDetailViewCopyWithImpl<$Res>
    implements _$CardDetailViewCopyWith<$Res> {
  __$CardDetailViewCopyWithImpl(this._self, this._then);

  final _CardDetailView _self;
  final $Res Function(_CardDetailView) _then;

/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? text = null,Object? drawnCount = null,Object? position = null,Object? sectionSize = null,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_CardDetailView(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DeckCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,drawnCount: null == drawnCount ? _self.drawnCount : drawnCount // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,sectionSize: null == sectionSize ? _self.sectionSize : sectionSize // ignore: cast_nullable_to_non_nullable
as int,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as CardId?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as CardId?,
  ));
}

/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get card {
  
  return $DeckCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of CardDetailView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}
}

/// @nodoc
mixin _$CardDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CardDetailState()';
}


}

/// @nodoc
class $CardDetailStateCopyWith<$Res>  {
$CardDetailStateCopyWith(CardDetailState _, $Res Function(CardDetailState) __);
}


/// Adds pattern-matching-related methods to [CardDetailState].
extension CardDetailStatePatterns on CardDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CardDetailLoading value)?  loading,TResult Function( CardDetailUpright value)?  upright,TResult Function( CardDetailReversed value)?  reversed,TResult Function( CardDetailZoomed value)?  zoomed,TResult Function( CardDetailStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CardDetailLoading() when loading != null:
return loading(_that);case CardDetailUpright() when upright != null:
return upright(_that);case CardDetailReversed() when reversed != null:
return reversed(_that);case CardDetailZoomed() when zoomed != null:
return zoomed(_that);case CardDetailStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CardDetailLoading value)  loading,required TResult Function( CardDetailUpright value)  upright,required TResult Function( CardDetailReversed value)  reversed,required TResult Function( CardDetailZoomed value)  zoomed,required TResult Function( CardDetailStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case CardDetailLoading():
return loading(_that);case CardDetailUpright():
return upright(_that);case CardDetailReversed():
return reversed(_that);case CardDetailZoomed():
return zoomed(_that);case CardDetailStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CardDetailLoading value)?  loading,TResult? Function( CardDetailUpright value)?  upright,TResult? Function( CardDetailReversed value)?  reversed,TResult? Function( CardDetailZoomed value)?  zoomed,TResult? Function( CardDetailStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case CardDetailLoading() when loading != null:
return loading(_that);case CardDetailUpright() when upright != null:
return upright(_that);case CardDetailReversed() when reversed != null:
return reversed(_that);case CardDetailZoomed() when zoomed != null:
return zoomed(_that);case CardDetailStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( CardDetailView view)?  upright,TResult Function( CardDetailView view)?  reversed,TResult Function( CardDetailView view,  bool reversed)?  zoomed,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CardDetailLoading() when loading != null:
return loading();case CardDetailUpright() when upright != null:
return upright(_that.view);case CardDetailReversed() when reversed != null:
return reversed(_that.view);case CardDetailZoomed() when zoomed != null:
return zoomed(_that.view,_that.reversed);case CardDetailStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( CardDetailView view)  upright,required TResult Function( CardDetailView view)  reversed,required TResult Function( CardDetailView view,  bool reversed)  zoomed,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case CardDetailLoading():
return loading();case CardDetailUpright():
return upright(_that.view);case CardDetailReversed():
return reversed(_that.view);case CardDetailZoomed():
return zoomed(_that.view,_that.reversed);case CardDetailStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( CardDetailView view)?  upright,TResult? Function( CardDetailView view)?  reversed,TResult? Function( CardDetailView view,  bool reversed)?  zoomed,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case CardDetailLoading() when loading != null:
return loading();case CardDetailUpright() when upright != null:
return upright(_that.view);case CardDetailReversed() when reversed != null:
return reversed(_that.view);case CardDetailZoomed() when zoomed != null:
return zoomed(_that.view,_that.reversed);case CardDetailStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class CardDetailLoading implements CardDetailState {
  const CardDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CardDetailState.loading()';
}


}




/// @nodoc


class CardDetailUpright implements CardDetailState {
  const CardDetailUpright(this.view);
  

 final  CardDetailView view;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDetailUprightCopyWith<CardDetailUpright> get copyWith => _$CardDetailUprightCopyWithImpl<CardDetailUpright>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailUpright&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'CardDetailState.upright(view: $view)';
}


}

/// @nodoc
abstract mixin class $CardDetailUprightCopyWith<$Res> implements $CardDetailStateCopyWith<$Res> {
  factory $CardDetailUprightCopyWith(CardDetailUpright value, $Res Function(CardDetailUpright) _then) = _$CardDetailUprightCopyWithImpl;
@useResult
$Res call({
 CardDetailView view
});


$CardDetailViewCopyWith<$Res> get view;

}
/// @nodoc
class _$CardDetailUprightCopyWithImpl<$Res>
    implements $CardDetailUprightCopyWith<$Res> {
  _$CardDetailUprightCopyWithImpl(this._self, this._then);

  final CardDetailUpright _self;
  final $Res Function(CardDetailUpright) _then;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(CardDetailUpright(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as CardDetailView,
  ));
}

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardDetailViewCopyWith<$Res> get view {
  
  return $CardDetailViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class CardDetailReversed implements CardDetailState {
  const CardDetailReversed(this.view);
  

 final  CardDetailView view;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDetailReversedCopyWith<CardDetailReversed> get copyWith => _$CardDetailReversedCopyWithImpl<CardDetailReversed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailReversed&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'CardDetailState.reversed(view: $view)';
}


}

/// @nodoc
abstract mixin class $CardDetailReversedCopyWith<$Res> implements $CardDetailStateCopyWith<$Res> {
  factory $CardDetailReversedCopyWith(CardDetailReversed value, $Res Function(CardDetailReversed) _then) = _$CardDetailReversedCopyWithImpl;
@useResult
$Res call({
 CardDetailView view
});


$CardDetailViewCopyWith<$Res> get view;

}
/// @nodoc
class _$CardDetailReversedCopyWithImpl<$Res>
    implements $CardDetailReversedCopyWith<$Res> {
  _$CardDetailReversedCopyWithImpl(this._self, this._then);

  final CardDetailReversed _self;
  final $Res Function(CardDetailReversed) _then;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(CardDetailReversed(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as CardDetailView,
  ));
}

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardDetailViewCopyWith<$Res> get view {
  
  return $CardDetailViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class CardDetailZoomed implements CardDetailState {
  const CardDetailZoomed(this.view, {required this.reversed});
  

 final  CardDetailView view;
 final  bool reversed;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardDetailZoomedCopyWith<CardDetailZoomed> get copyWith => _$CardDetailZoomedCopyWithImpl<CardDetailZoomed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailZoomed&&(identical(other.view, view) || other.view == view)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,view,reversed);

@override
String toString() {
  return 'CardDetailState.zoomed(view: $view, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class $CardDetailZoomedCopyWith<$Res> implements $CardDetailStateCopyWith<$Res> {
  factory $CardDetailZoomedCopyWith(CardDetailZoomed value, $Res Function(CardDetailZoomed) _then) = _$CardDetailZoomedCopyWithImpl;
@useResult
$Res call({
 CardDetailView view, bool reversed
});


$CardDetailViewCopyWith<$Res> get view;

}
/// @nodoc
class _$CardDetailZoomedCopyWithImpl<$Res>
    implements $CardDetailZoomedCopyWith<$Res> {
  _$CardDetailZoomedCopyWithImpl(this._self, this._then);

  final CardDetailZoomed _self;
  final $Res Function(CardDetailZoomed) _then;

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,Object? reversed = null,}) {
  return _then(CardDetailZoomed(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as CardDetailView,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CardDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardDetailViewCopyWith<$Res> get view {
  
  return $CardDetailViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class CardDetailStorageError implements CardDetailState {
  const CardDetailStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardDetailStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CardDetailState.storageError()';
}


}




// dart format on
