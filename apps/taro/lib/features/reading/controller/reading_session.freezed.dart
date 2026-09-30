// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresetCard {

 CardId get cardId; bool get reversed;
/// Create a copy of PresetCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresetCardCopyWith<PresetCard> get copyWith => _$PresetCardCopyWithImpl<PresetCard>(this as PresetCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetCard&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,reversed);

@override
String toString() {
  return 'PresetCard(cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class $PresetCardCopyWith<$Res>  {
  factory $PresetCardCopyWith(PresetCard value, $Res Function(PresetCard) _then) = _$PresetCardCopyWithImpl;
@useResult
$Res call({
 CardId cardId, bool reversed
});




}
/// @nodoc
class _$PresetCardCopyWithImpl<$Res>
    implements $PresetCardCopyWith<$Res> {
  _$PresetCardCopyWithImpl(this._self, this._then);

  final PresetCard _self;
  final $Res Function(PresetCard) _then;

/// Create a copy of PresetCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cardId = null,Object? reversed = null,}) {
  return _then(_self.copyWith(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PresetCard].
extension PresetCardPatterns on PresetCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresetCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresetCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresetCard value)  $default,){
final _that = this;
switch (_that) {
case _PresetCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresetCard value)?  $default,){
final _that = this;
switch (_that) {
case _PresetCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CardId cardId,  bool reversed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresetCard() when $default != null:
return $default(_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CardId cardId,  bool reversed)  $default,) {final _that = this;
switch (_that) {
case _PresetCard():
return $default(_that.cardId,_that.reversed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CardId cardId,  bool reversed)?  $default,) {final _that = this;
switch (_that) {
case _PresetCard() when $default != null:
return $default(_that.cardId,_that.reversed);case _:
  return null;

}
}

}

/// @nodoc


class _PresetCard implements PresetCard {
  const _PresetCard({required this.cardId, required this.reversed});
  

@override final  CardId cardId;
@override final  bool reversed;

/// Create a copy of PresetCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresetCardCopyWith<_PresetCard> get copyWith => __$PresetCardCopyWithImpl<_PresetCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresetCard&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.reversed, reversed) || other.reversed == reversed));
}


@override
int get hashCode => Object.hash(runtimeType,cardId,reversed);

@override
String toString() {
  return 'PresetCard(cardId: $cardId, reversed: $reversed)';
}


}

/// @nodoc
abstract mixin class _$PresetCardCopyWith<$Res> implements $PresetCardCopyWith<$Res> {
  factory _$PresetCardCopyWith(_PresetCard value, $Res Function(_PresetCard) _then) = __$PresetCardCopyWithImpl;
@override @useResult
$Res call({
 CardId cardId, bool reversed
});




}
/// @nodoc
class __$PresetCardCopyWithImpl<$Res>
    implements _$PresetCardCopyWith<$Res> {
  __$PresetCardCopyWithImpl(this._self, this._then);

  final _PresetCard _self;
  final $Res Function(_PresetCard) _then;

/// Create a copy of PresetCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cardId = null,Object? reversed = null,}) {
  return _then(_PresetCard(
cardId: null == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as CardId,reversed: null == reversed ? _self.reversed : reversed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ReadingSession {

 SpreadDefinition get spread; ReadingFlowSource get source; String get locale; String? get question; List<PresetCard> get presetCards; ReadingHold? get hold; ClassicReadingReason? get classicReason; ReadingId? get resumeReadingId;
/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingSessionCopyWith<ReadingSession> get copyWith => _$ReadingSessionCopyWithImpl<ReadingSession>(this as ReadingSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingSession&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.source, source) || other.source == source)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.presetCards, presetCards)&&(identical(other.hold, hold) || other.hold == hold)&&(identical(other.classicReason, classicReason) || other.classicReason == classicReason)&&(identical(other.resumeReadingId, resumeReadingId) || other.resumeReadingId == resumeReadingId));
}


@override
int get hashCode => Object.hash(runtimeType,spread,source,locale,question,const DeepCollectionEquality().hash(presetCards),hold,classicReason,resumeReadingId);

@override
String toString() {
  return 'ReadingSession(spread: $spread, source: $source, locale: $locale, question: $question, presetCards: $presetCards, hold: $hold, classicReason: $classicReason, resumeReadingId: $resumeReadingId)';
}


}

/// @nodoc
abstract mixin class $ReadingSessionCopyWith<$Res>  {
  factory $ReadingSessionCopyWith(ReadingSession value, $Res Function(ReadingSession) _then) = _$ReadingSessionCopyWithImpl;
@useResult
$Res call({
 SpreadDefinition spread, ReadingFlowSource source, String locale, String? question, List<PresetCard> presetCards, ReadingHold? hold, ClassicReadingReason? classicReason, ReadingId? resumeReadingId
});


$SpreadDefinitionCopyWith<$Res> get spread;$ReadingHoldCopyWith<$Res>? get hold;

}
/// @nodoc
class _$ReadingSessionCopyWithImpl<$Res>
    implements $ReadingSessionCopyWith<$Res> {
  _$ReadingSessionCopyWithImpl(this._self, this._then);

  final ReadingSession _self;
  final $Res Function(ReadingSession) _then;

/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spread = null,Object? source = null,Object? locale = null,Object? question = freezed,Object? presetCards = null,Object? hold = freezed,Object? classicReason = freezed,Object? resumeReadingId = freezed,}) {
  return _then(_self.copyWith(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReadingFlowSource,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,presetCards: null == presetCards ? _self.presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,hold: freezed == hold ? _self.hold : hold // ignore: cast_nullable_to_non_nullable
as ReadingHold?,classicReason: freezed == classicReason ? _self.classicReason : classicReason // ignore: cast_nullable_to_non_nullable
as ClassicReadingReason?,resumeReadingId: freezed == resumeReadingId ? _self.resumeReadingId : resumeReadingId // ignore: cast_nullable_to_non_nullable
as ReadingId?,
  ));
}
/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingHoldCopyWith<$Res>? get hold {
    if (_self.hold == null) {
    return null;
  }

  return $ReadingHoldCopyWith<$Res>(_self.hold!, (value) {
    return _then(_self.copyWith(hold: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingSession].
extension ReadingSessionPatterns on ReadingSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingSession value)  $default,){
final _that = this;
switch (_that) {
case _ReadingSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingSession value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadDefinition spread,  ReadingFlowSource source,  String locale,  String? question,  List<PresetCard> presetCards,  ReadingHold? hold,  ClassicReadingReason? classicReason,  ReadingId? resumeReadingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingSession() when $default != null:
return $default(_that.spread,_that.source,_that.locale,_that.question,_that.presetCards,_that.hold,_that.classicReason,_that.resumeReadingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadDefinition spread,  ReadingFlowSource source,  String locale,  String? question,  List<PresetCard> presetCards,  ReadingHold? hold,  ClassicReadingReason? classicReason,  ReadingId? resumeReadingId)  $default,) {final _that = this;
switch (_that) {
case _ReadingSession():
return $default(_that.spread,_that.source,_that.locale,_that.question,_that.presetCards,_that.hold,_that.classicReason,_that.resumeReadingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadDefinition spread,  ReadingFlowSource source,  String locale,  String? question,  List<PresetCard> presetCards,  ReadingHold? hold,  ClassicReadingReason? classicReason,  ReadingId? resumeReadingId)?  $default,) {final _that = this;
switch (_that) {
case _ReadingSession() when $default != null:
return $default(_that.spread,_that.source,_that.locale,_that.question,_that.presetCards,_that.hold,_that.classicReason,_that.resumeReadingId);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingSession extends ReadingSession {
  const _ReadingSession({required this.spread, required this.source, required this.locale, this.question, final  List<PresetCard> presetCards = const <PresetCard>[], this.hold, this.classicReason, this.resumeReadingId}): _presetCards = presetCards,super._();
  

@override final  SpreadDefinition spread;
@override final  ReadingFlowSource source;
@override final  String locale;
@override final  String? question;
 final  List<PresetCard> _presetCards;
@override@JsonKey() List<PresetCard> get presetCards {
  if (_presetCards is EqualUnmodifiableListView) return _presetCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presetCards);
}

@override final  ReadingHold? hold;
@override final  ClassicReadingReason? classicReason;
@override final  ReadingId? resumeReadingId;

/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingSessionCopyWith<_ReadingSession> get copyWith => __$ReadingSessionCopyWithImpl<_ReadingSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingSession&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.source, source) || other.source == source)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._presetCards, _presetCards)&&(identical(other.hold, hold) || other.hold == hold)&&(identical(other.classicReason, classicReason) || other.classicReason == classicReason)&&(identical(other.resumeReadingId, resumeReadingId) || other.resumeReadingId == resumeReadingId));
}


@override
int get hashCode => Object.hash(runtimeType,spread,source,locale,question,const DeepCollectionEquality().hash(_presetCards),hold,classicReason,resumeReadingId);

@override
String toString() {
  return 'ReadingSession(spread: $spread, source: $source, locale: $locale, question: $question, presetCards: $presetCards, hold: $hold, classicReason: $classicReason, resumeReadingId: $resumeReadingId)';
}


}

/// @nodoc
abstract mixin class _$ReadingSessionCopyWith<$Res> implements $ReadingSessionCopyWith<$Res> {
  factory _$ReadingSessionCopyWith(_ReadingSession value, $Res Function(_ReadingSession) _then) = __$ReadingSessionCopyWithImpl;
@override @useResult
$Res call({
 SpreadDefinition spread, ReadingFlowSource source, String locale, String? question, List<PresetCard> presetCards, ReadingHold? hold, ClassicReadingReason? classicReason, ReadingId? resumeReadingId
});


@override $SpreadDefinitionCopyWith<$Res> get spread;@override $ReadingHoldCopyWith<$Res>? get hold;

}
/// @nodoc
class __$ReadingSessionCopyWithImpl<$Res>
    implements _$ReadingSessionCopyWith<$Res> {
  __$ReadingSessionCopyWithImpl(this._self, this._then);

  final _ReadingSession _self;
  final $Res Function(_ReadingSession) _then;

/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spread = null,Object? source = null,Object? locale = null,Object? question = freezed,Object? presetCards = null,Object? hold = freezed,Object? classicReason = freezed,Object? resumeReadingId = freezed,}) {
  return _then(_ReadingSession(
spread: null == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReadingFlowSource,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,presetCards: null == presetCards ? _self._presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,hold: freezed == hold ? _self.hold : hold // ignore: cast_nullable_to_non_nullable
as ReadingHold?,classicReason: freezed == classicReason ? _self.classicReason : classicReason // ignore: cast_nullable_to_non_nullable
as ClassicReadingReason?,resumeReadingId: freezed == resumeReadingId ? _self.resumeReadingId : resumeReadingId // ignore: cast_nullable_to_non_nullable
as ReadingId?,
  ));
}

/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SpreadDefinitionCopyWith<$Res> get spread {
  
  return $SpreadDefinitionCopyWith<$Res>(_self.spread, (value) {
    return _then(_self.copyWith(spread: value));
  });
}/// Create a copy of ReadingSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingHoldCopyWith<$Res>? get hold {
    if (_self.hold == null) {
    return null;
  }

  return $ReadingHoldCopyWith<$Res>(_self.hold!, (value) {
    return _then(_self.copyWith(hold: value));
  });
}
}

/// @nodoc
mixin _$ReadingHandoff {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHandoff);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingHandoff()';
}


}

/// @nodoc
class $ReadingHandoffCopyWith<$Res>  {
$ReadingHandoffCopyWith(ReadingHandoff _, $Res Function(ReadingHandoff) __);
}


/// Adds pattern-matching-related methods to [ReadingHandoff].
extension ReadingHandoffPatterns on ReadingHandoff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadingHandoffDeclined value)?  declined,TResult Function( ReadingHandoffPaused value)?  paused,TResult Function( ReadingHandoffConsent value)?  consentRequired,TResult Function( ReadingHandoffRegion value)?  aiUnavailableRegion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadingHandoffDeclined() when declined != null:
return declined(_that);case ReadingHandoffPaused() when paused != null:
return paused(_that);case ReadingHandoffConsent() when consentRequired != null:
return consentRequired(_that);case ReadingHandoffRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadingHandoffDeclined value)  declined,required TResult Function( ReadingHandoffPaused value)  paused,required TResult Function( ReadingHandoffConsent value)  consentRequired,required TResult Function( ReadingHandoffRegion value)  aiUnavailableRegion,}){
final _that = this;
switch (_that) {
case ReadingHandoffDeclined():
return declined(_that);case ReadingHandoffPaused():
return paused(_that);case ReadingHandoffConsent():
return consentRequired(_that);case ReadingHandoffRegion():
return aiUnavailableRegion(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadingHandoffDeclined value)?  declined,TResult? Function( ReadingHandoffPaused value)?  paused,TResult? Function( ReadingHandoffConsent value)?  consentRequired,TResult? Function( ReadingHandoffRegion value)?  aiUnavailableRegion,}){
final _that = this;
switch (_that) {
case ReadingHandoffDeclined() when declined != null:
return declined(_that);case ReadingHandoffPaused() when paused != null:
return paused(_that);case ReadingHandoffConsent() when consentRequired != null:
return consentRequired(_that);case ReadingHandoffRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SafetyInfo safety,  Draw draw)?  declined,TResult Function( bool freePaused)?  paused,TResult Function()?  consentRequired,TResult Function()?  aiUnavailableRegion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadingHandoffDeclined() when declined != null:
return declined(_that.safety,_that.draw);case ReadingHandoffPaused() when paused != null:
return paused(_that.freePaused);case ReadingHandoffConsent() when consentRequired != null:
return consentRequired();case ReadingHandoffRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SafetyInfo safety,  Draw draw)  declined,required TResult Function( bool freePaused)  paused,required TResult Function()  consentRequired,required TResult Function()  aiUnavailableRegion,}) {final _that = this;
switch (_that) {
case ReadingHandoffDeclined():
return declined(_that.safety,_that.draw);case ReadingHandoffPaused():
return paused(_that.freePaused);case ReadingHandoffConsent():
return consentRequired();case ReadingHandoffRegion():
return aiUnavailableRegion();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SafetyInfo safety,  Draw draw)?  declined,TResult? Function( bool freePaused)?  paused,TResult? Function()?  consentRequired,TResult? Function()?  aiUnavailableRegion,}) {final _that = this;
switch (_that) {
case ReadingHandoffDeclined() when declined != null:
return declined(_that.safety,_that.draw);case ReadingHandoffPaused() when paused != null:
return paused(_that.freePaused);case ReadingHandoffConsent() when consentRequired != null:
return consentRequired();case ReadingHandoffRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion();case _:
  return null;

}
}

}

/// @nodoc


class ReadingHandoffDeclined implements ReadingHandoff {
  const ReadingHandoffDeclined({required this.safety, required this.draw});
  

 final  SafetyInfo safety;
 final  Draw draw;

/// Create a copy of ReadingHandoff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingHandoffDeclinedCopyWith<ReadingHandoffDeclined> get copyWith => _$ReadingHandoffDeclinedCopyWithImpl<ReadingHandoffDeclined>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHandoffDeclined&&(identical(other.safety, safety) || other.safety == safety)&&(identical(other.draw, draw) || other.draw == draw));
}


@override
int get hashCode => Object.hash(runtimeType,safety,draw);

@override
String toString() {
  return 'ReadingHandoff.declined(safety: $safety, draw: $draw)';
}


}

/// @nodoc
abstract mixin class $ReadingHandoffDeclinedCopyWith<$Res> implements $ReadingHandoffCopyWith<$Res> {
  factory $ReadingHandoffDeclinedCopyWith(ReadingHandoffDeclined value, $Res Function(ReadingHandoffDeclined) _then) = _$ReadingHandoffDeclinedCopyWithImpl;
@useResult
$Res call({
 SafetyInfo safety, Draw draw
});


$SafetyInfoCopyWith<$Res> get safety;$DrawCopyWith<$Res> get draw;

}
/// @nodoc
class _$ReadingHandoffDeclinedCopyWithImpl<$Res>
    implements $ReadingHandoffDeclinedCopyWith<$Res> {
  _$ReadingHandoffDeclinedCopyWithImpl(this._self, this._then);

  final ReadingHandoffDeclined _self;
  final $Res Function(ReadingHandoffDeclined) _then;

/// Create a copy of ReadingHandoff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? safety = null,Object? draw = null,}) {
  return _then(ReadingHandoffDeclined(
safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as SafetyInfo,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,
  ));
}

/// Create a copy of ReadingHandoff
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<$Res> get safety {
  
  return $SafetyInfoCopyWith<$Res>(_self.safety, (value) {
    return _then(_self.copyWith(safety: value));
  });
}/// Create a copy of ReadingHandoff
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


class ReadingHandoffPaused implements ReadingHandoff {
  const ReadingHandoffPaused({this.freePaused = false});
  

@JsonKey() final  bool freePaused;

/// Create a copy of ReadingHandoff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingHandoffPausedCopyWith<ReadingHandoffPaused> get copyWith => _$ReadingHandoffPausedCopyWithImpl<ReadingHandoffPaused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHandoffPaused&&(identical(other.freePaused, freePaused) || other.freePaused == freePaused));
}


@override
int get hashCode => Object.hash(runtimeType,freePaused);

@override
String toString() {
  return 'ReadingHandoff.paused(freePaused: $freePaused)';
}


}

/// @nodoc
abstract mixin class $ReadingHandoffPausedCopyWith<$Res> implements $ReadingHandoffCopyWith<$Res> {
  factory $ReadingHandoffPausedCopyWith(ReadingHandoffPaused value, $Res Function(ReadingHandoffPaused) _then) = _$ReadingHandoffPausedCopyWithImpl;
@useResult
$Res call({
 bool freePaused
});




}
/// @nodoc
class _$ReadingHandoffPausedCopyWithImpl<$Res>
    implements $ReadingHandoffPausedCopyWith<$Res> {
  _$ReadingHandoffPausedCopyWithImpl(this._self, this._then);

  final ReadingHandoffPaused _self;
  final $Res Function(ReadingHandoffPaused) _then;

/// Create a copy of ReadingHandoff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? freePaused = null,}) {
  return _then(ReadingHandoffPaused(
freePaused: null == freePaused ? _self.freePaused : freePaused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ReadingHandoffConsent implements ReadingHandoff {
  const ReadingHandoffConsent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHandoffConsent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingHandoff.consentRequired()';
}


}




/// @nodoc


class ReadingHandoffRegion implements ReadingHandoff {
  const ReadingHandoffRegion();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingHandoffRegion);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingHandoff.aiUnavailableRegion()';
}


}




// dart format on
