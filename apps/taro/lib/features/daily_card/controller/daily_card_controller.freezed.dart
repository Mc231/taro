// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_card_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyCardView {

 DailyCard get card; CardText get text; DeckCard get deckCard;
/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardViewCopyWith<DailyCardView> get copyWith => _$DailyCardViewCopyWithImpl<DailyCardView>(this as DailyCardView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardView&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.deckCard, deckCard) || other.deckCard == deckCard));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,deckCard);

@override
String toString() {
  return 'DailyCardView(card: $card, text: $text, deckCard: $deckCard)';
}


}

/// @nodoc
abstract mixin class $DailyCardViewCopyWith<$Res>  {
  factory $DailyCardViewCopyWith(DailyCardView value, $Res Function(DailyCardView) _then) = _$DailyCardViewCopyWithImpl;
@useResult
$Res call({
 DailyCard card, CardText text, DeckCard deckCard
});


$DailyCardCopyWith<$Res> get card;$CardTextCopyWith<$Res> get text;$DeckCardCopyWith<$Res> get deckCard;

}
/// @nodoc
class _$DailyCardViewCopyWithImpl<$Res>
    implements $DailyCardViewCopyWith<$Res> {
  _$DailyCardViewCopyWithImpl(this._self, this._then);

  final DailyCardView _self;
  final $Res Function(DailyCardView) _then;

/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? text = null,Object? deckCard = null,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DailyCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,deckCard: null == deckCard ? _self.deckCard : deckCard // ignore: cast_nullable_to_non_nullable
as DeckCard,
  ));
}
/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res> get card {
  
  return $DailyCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get deckCard {
  
  return $DeckCardCopyWith<$Res>(_self.deckCard, (value) {
    return _then(_self.copyWith(deckCard: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailyCardView].
extension DailyCardViewPatterns on DailyCardView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyCardView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyCardView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyCardView value)  $default,){
final _that = this;
switch (_that) {
case _DailyCardView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyCardView value)?  $default,){
final _that = this;
switch (_that) {
case _DailyCardView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DailyCard card,  CardText text,  DeckCard deckCard)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyCardView() when $default != null:
return $default(_that.card,_that.text,_that.deckCard);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DailyCard card,  CardText text,  DeckCard deckCard)  $default,) {final _that = this;
switch (_that) {
case _DailyCardView():
return $default(_that.card,_that.text,_that.deckCard);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DailyCard card,  CardText text,  DeckCard deckCard)?  $default,) {final _that = this;
switch (_that) {
case _DailyCardView() when $default != null:
return $default(_that.card,_that.text,_that.deckCard);case _:
  return null;

}
}

}

/// @nodoc


class _DailyCardView extends DailyCardView {
  const _DailyCardView({required this.card, required this.text, required this.deckCard}): super._();
  

@override final  DailyCard card;
@override final  CardText text;
@override final  DeckCard deckCard;

/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyCardViewCopyWith<_DailyCardView> get copyWith => __$DailyCardViewCopyWithImpl<_DailyCardView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyCardView&&(identical(other.card, card) || other.card == card)&&(identical(other.text, text) || other.text == text)&&(identical(other.deckCard, deckCard) || other.deckCard == deckCard));
}


@override
int get hashCode => Object.hash(runtimeType,card,text,deckCard);

@override
String toString() {
  return 'DailyCardView(card: $card, text: $text, deckCard: $deckCard)';
}


}

/// @nodoc
abstract mixin class _$DailyCardViewCopyWith<$Res> implements $DailyCardViewCopyWith<$Res> {
  factory _$DailyCardViewCopyWith(_DailyCardView value, $Res Function(_DailyCardView) _then) = __$DailyCardViewCopyWithImpl;
@override @useResult
$Res call({
 DailyCard card, CardText text, DeckCard deckCard
});


@override $DailyCardCopyWith<$Res> get card;@override $CardTextCopyWith<$Res> get text;@override $DeckCardCopyWith<$Res> get deckCard;

}
/// @nodoc
class __$DailyCardViewCopyWithImpl<$Res>
    implements _$DailyCardViewCopyWith<$Res> {
  __$DailyCardViewCopyWithImpl(this._self, this._then);

  final _DailyCardView _self;
  final $Res Function(_DailyCardView) _then;

/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? text = null,Object? deckCard = null,}) {
  return _then(_DailyCardView(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as DailyCard,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as CardText,deckCard: null == deckCard ? _self.deckCard : deckCard // ignore: cast_nullable_to_non_nullable
as DeckCard,
  ));
}

/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res> get card {
  
  return $DailyCardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTextCopyWith<$Res> get text {
  
  return $CardTextCopyWith<$Res>(_self.text, (value) {
    return _then(_self.copyWith(text: value));
  });
}/// Create a copy of DailyCardView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeckCardCopyWith<$Res> get deckCard {
  
  return $DeckCardCopyWith<$Res>(_self.deckCard, (value) {
    return _then(_self.copyWith(deckCard: value));
  });
}
}

/// @nodoc
mixin _$DailyCardDeeper {

 SpreadId get spreadId; CardId get cardId; bool get reversed;
/// Create a copy of DailyCardDeeper
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardDeeperCopyWith<DailyCardDeeper> get copyWith => _$DailyCardDeeperCopyWithImpl<DailyCardDeeper>(this as DailyCardDeeper, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardDeeper&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,cardId,reversed);

@override
String toString() {
  return 'DailyCardDeeper(spreadId: $spreadId, cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class $DailyCardDeeperCopyWith<$Res>  {
  factory $DailyCardDeeperCopyWith(DailyCardDeeper value, $Res Function(DailyCardDeeper) _then) = _$DailyCardDeeperCopyWithImpl;
@useResult
$Res call({
 SpreadId spreadId, CardId cardId, bool reversed
});




}
/// @nodoc
class _$DailyCardDeeperCopyWithImpl<$Res>
    implements $DailyCardDeeperCopyWith<$Res> {
  _$DailyCardDeeperCopyWithImpl(this._self, this._then);

  final DailyCardDeeper _self;
  final $Res Function(DailyCardDeeper) _then;

/// Create a copy of DailyCardDeeper
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spreadId = null,Object? cardId = null,Object? reversed = null,}) {
  return _then(_self.copyWith(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyCardDeeper].
extension DailyCardDeeperPatterns on DailyCardDeeper {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyCardDeeper value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyCardDeeper() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyCardDeeper value)  $default,){
final _that = this;
switch (_that) {
case _DailyCardDeeper():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyCardDeeper value)?  $default,){
final _that = this;
switch (_that) {
case _DailyCardDeeper() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadId spreadId,  CardId cardId,  bool reversed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyCardDeeper() when $default != null:
return $default(_that.spreadId,_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadId spreadId,  CardId cardId,  bool reversed)  $default,) {final _that = this;
switch (_that) {
case _DailyCardDeeper():
return $default(_that.spreadId,_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadId spreadId,  CardId cardId,  bool reversed)?  $default,) {final _that = this;
switch (_that) {
case _DailyCardDeeper() when $default != null:
return $default(_that.spreadId,_that.cardId,_that.reversed);case _:
  return null;

}
}

}

/// @nodoc


class _DailyCardDeeper implements DailyCardDeeper {
  const _DailyCardDeeper({required this.spreadId, required this.cardId, required this.reversed});
  

@override final  SpreadId spreadId;
@override final  CardId cardId;
@override final  bool reversed;

/// Create a copy of DailyCardDeeper
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyCardDeeperCopyWith<_DailyCardDeeper> get copyWith => __$DailyCardDeeperCopyWithImpl<_DailyCardDeeper>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyCardDeeper&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,cardId,reversed);

@override
String toString() {
  return 'DailyCardDeeper(spreadId: $spreadId, cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class _$DailyCardDeeperCopyWith<$Res> implements $DailyCardDeeperCopyWith<$Res> {
  factory _$DailyCardDeeperCopyWith(_DailyCardDeeper value, $Res Function(_DailyCardDeeper) _then) = __$DailyCardDeeperCopyWithImpl;
@override @useResult
$Res call({
 SpreadId spreadId, CardId cardId, bool reversed
});




}
/// @nodoc
class __$DailyCardDeeperCopyWithImpl<$Res>
    implements _$DailyCardDeeperCopyWith<$Res> {
  __$DailyCardDeeperCopyWithImpl(this._self, this._then);

  final _DailyCardDeeper _self;
  final $Res Function(_DailyCardDeeper) _then;

/// Create a copy of DailyCardDeeper
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spreadId = null,Object? cardId = null,Object? reversed = null,}) {
  return _then(_DailyCardDeeper(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$DailyCardState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyCardState()';
}


}

/// @nodoc
class $DailyCardStateCopyWith<$Res>  {
$DailyCardStateCopyWith(DailyCardState _, $Res Function(DailyCardState) __);
}


/// Adds pattern-matching-related methods to [DailyCardState].
extension DailyCardStatePatterns on DailyCardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DailyCardLoading value)?  loading,TResult Function( DailyCardNotDrawn value)?  notDrawn,TResult Function( DailyCardRevealing value)?  revealing,TResult Function( DailyCardDrawn value)?  drawn,TResult Function( DailyCardNoteEditing value)?  noteEditing,TResult Function( DailyCardReminderOffer value)?  reminderOffer,TResult Function( DailyCardFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DailyCardLoading() when loading != null:
return loading(_that);case DailyCardNotDrawn() when notDrawn != null:
return notDrawn(_that);case DailyCardRevealing() when revealing != null:
return revealing(_that);case DailyCardDrawn() when drawn != null:
return drawn(_that);case DailyCardNoteEditing() when noteEditing != null:
return noteEditing(_that);case DailyCardReminderOffer() when reminderOffer != null:
return reminderOffer(_that);case DailyCardFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DailyCardLoading value)  loading,required TResult Function( DailyCardNotDrawn value)  notDrawn,required TResult Function( DailyCardRevealing value)  revealing,required TResult Function( DailyCardDrawn value)  drawn,required TResult Function( DailyCardNoteEditing value)  noteEditing,required TResult Function( DailyCardReminderOffer value)  reminderOffer,required TResult Function( DailyCardFailed value)  failed,}){
final _that = this;
switch (_that) {
case DailyCardLoading():
return loading(_that);case DailyCardNotDrawn():
return notDrawn(_that);case DailyCardRevealing():
return revealing(_that);case DailyCardDrawn():
return drawn(_that);case DailyCardNoteEditing():
return noteEditing(_that);case DailyCardReminderOffer():
return reminderOffer(_that);case DailyCardFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DailyCardLoading value)?  loading,TResult? Function( DailyCardNotDrawn value)?  notDrawn,TResult? Function( DailyCardRevealing value)?  revealing,TResult? Function( DailyCardDrawn value)?  drawn,TResult? Function( DailyCardNoteEditing value)?  noteEditing,TResult? Function( DailyCardReminderOffer value)?  reminderOffer,TResult? Function( DailyCardFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DailyCardLoading() when loading != null:
return loading(_that);case DailyCardNotDrawn() when notDrawn != null:
return notDrawn(_that);case DailyCardRevealing() when revealing != null:
return revealing(_that);case DailyCardDrawn() when drawn != null:
return drawn(_that);case DailyCardNoteEditing() when noteEditing != null:
return noteEditing(_that);case DailyCardReminderOffer() when reminderOffer != null:
return reminderOffer(_that);case DailyCardFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  notDrawn,TResult Function()?  revealing,TResult Function( DailyCardView view)?  drawn,TResult Function( DailyCardView view)?  noteEditing,TResult Function( DailyCardView view)?  reminderOffer,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DailyCardLoading() when loading != null:
return loading();case DailyCardNotDrawn() when notDrawn != null:
return notDrawn();case DailyCardRevealing() when revealing != null:
return revealing();case DailyCardDrawn() when drawn != null:
return drawn(_that.view);case DailyCardNoteEditing() when noteEditing != null:
return noteEditing(_that.view);case DailyCardReminderOffer() when reminderOffer != null:
return reminderOffer(_that.view);case DailyCardFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  notDrawn,required TResult Function()  revealing,required TResult Function( DailyCardView view)  drawn,required TResult Function( DailyCardView view)  noteEditing,required TResult Function( DailyCardView view)  reminderOffer,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case DailyCardLoading():
return loading();case DailyCardNotDrawn():
return notDrawn();case DailyCardRevealing():
return revealing();case DailyCardDrawn():
return drawn(_that.view);case DailyCardNoteEditing():
return noteEditing(_that.view);case DailyCardReminderOffer():
return reminderOffer(_that.view);case DailyCardFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  notDrawn,TResult? Function()?  revealing,TResult? Function( DailyCardView view)?  drawn,TResult? Function( DailyCardView view)?  noteEditing,TResult? Function( DailyCardView view)?  reminderOffer,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case DailyCardLoading() when loading != null:
return loading();case DailyCardNotDrawn() when notDrawn != null:
return notDrawn();case DailyCardRevealing() when revealing != null:
return revealing();case DailyCardDrawn() when drawn != null:
return drawn(_that.view);case DailyCardNoteEditing() when noteEditing != null:
return noteEditing(_that.view);case DailyCardReminderOffer() when reminderOffer != null:
return reminderOffer(_that.view);case DailyCardFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DailyCardLoading implements DailyCardState {
  const DailyCardLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyCardState.loading()';
}


}




/// @nodoc


class DailyCardNotDrawn implements DailyCardState {
  const DailyCardNotDrawn();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardNotDrawn);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyCardState.notDrawn()';
}


}




/// @nodoc


class DailyCardRevealing implements DailyCardState {
  const DailyCardRevealing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardRevealing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyCardState.revealing()';
}


}




/// @nodoc


class DailyCardDrawn implements DailyCardState {
  const DailyCardDrawn(this.view);
  

 final  DailyCardView view;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardDrawnCopyWith<DailyCardDrawn> get copyWith => _$DailyCardDrawnCopyWithImpl<DailyCardDrawn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardDrawn&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DailyCardState.drawn(view: $view)';
}


}

/// @nodoc
abstract mixin class $DailyCardDrawnCopyWith<$Res> implements $DailyCardStateCopyWith<$Res> {
  factory $DailyCardDrawnCopyWith(DailyCardDrawn value, $Res Function(DailyCardDrawn) _then) = _$DailyCardDrawnCopyWithImpl;
@useResult
$Res call({
 DailyCardView view
});


$DailyCardViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DailyCardDrawnCopyWithImpl<$Res>
    implements $DailyCardDrawnCopyWith<$Res> {
  _$DailyCardDrawnCopyWithImpl(this._self, this._then);

  final DailyCardDrawn _self;
  final $Res Function(DailyCardDrawn) _then;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DailyCardDrawn(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DailyCardView,
  ));
}

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardViewCopyWith<$Res> get view {
  
  return $DailyCardViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DailyCardNoteEditing implements DailyCardState {
  const DailyCardNoteEditing(this.view);
  

 final  DailyCardView view;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardNoteEditingCopyWith<DailyCardNoteEditing> get copyWith => _$DailyCardNoteEditingCopyWithImpl<DailyCardNoteEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardNoteEditing&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DailyCardState.noteEditing(view: $view)';
}


}

/// @nodoc
abstract mixin class $DailyCardNoteEditingCopyWith<$Res> implements $DailyCardStateCopyWith<$Res> {
  factory $DailyCardNoteEditingCopyWith(DailyCardNoteEditing value, $Res Function(DailyCardNoteEditing) _then) = _$DailyCardNoteEditingCopyWithImpl;
@useResult
$Res call({
 DailyCardView view
});


$DailyCardViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DailyCardNoteEditingCopyWithImpl<$Res>
    implements $DailyCardNoteEditingCopyWith<$Res> {
  _$DailyCardNoteEditingCopyWithImpl(this._self, this._then);

  final DailyCardNoteEditing _self;
  final $Res Function(DailyCardNoteEditing) _then;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DailyCardNoteEditing(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DailyCardView,
  ));
}

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardViewCopyWith<$Res> get view {
  
  return $DailyCardViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DailyCardReminderOffer implements DailyCardState {
  const DailyCardReminderOffer(this.view);
  

 final  DailyCardView view;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardReminderOfferCopyWith<DailyCardReminderOffer> get copyWith => _$DailyCardReminderOfferCopyWithImpl<DailyCardReminderOffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardReminderOffer&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'DailyCardState.reminderOffer(view: $view)';
}


}

/// @nodoc
abstract mixin class $DailyCardReminderOfferCopyWith<$Res> implements $DailyCardStateCopyWith<$Res> {
  factory $DailyCardReminderOfferCopyWith(DailyCardReminderOffer value, $Res Function(DailyCardReminderOffer) _then) = _$DailyCardReminderOfferCopyWithImpl;
@useResult
$Res call({
 DailyCardView view
});


$DailyCardViewCopyWith<$Res> get view;

}
/// @nodoc
class _$DailyCardReminderOfferCopyWithImpl<$Res>
    implements $DailyCardReminderOfferCopyWith<$Res> {
  _$DailyCardReminderOfferCopyWithImpl(this._self, this._then);

  final DailyCardReminderOffer _self;
  final $Res Function(DailyCardReminderOffer) _then;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(DailyCardReminderOffer(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as DailyCardView,
  ));
}

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardViewCopyWith<$Res> get view {
  
  return $DailyCardViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc


class DailyCardFailed implements DailyCardState {
  const DailyCardFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyCardFailedCopyWith<DailyCardFailed> get copyWith => _$DailyCardFailedCopyWithImpl<DailyCardFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyCardFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DailyCardState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DailyCardFailedCopyWith<$Res> implements $DailyCardStateCopyWith<$Res> {
  factory $DailyCardFailedCopyWith(DailyCardFailed value, $Res Function(DailyCardFailed) _then) = _$DailyCardFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DailyCardFailedCopyWithImpl<$Res>
    implements $DailyCardFailedCopyWith<$Res> {
  _$DailyCardFailedCopyWithImpl(this._self, this._then);

  final DailyCardFailed _self;
  final $Res Function(DailyCardFailed) _then;

/// Create a copy of DailyCardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DailyCardFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DailyCardState
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
