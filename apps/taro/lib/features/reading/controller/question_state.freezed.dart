// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuestionArgs {

 SpreadId get spreadId; ReadingFlowSource get source; List<PresetCard> get presetCards;
/// Create a copy of QuestionArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionArgsCopyWith<QuestionArgs> get copyWith => _$QuestionArgsCopyWithImpl<QuestionArgs>(this as QuestionArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionArgs&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.presetCards, presetCards));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,source,const DeepCollectionEquality().hash(presetCards));

@override
String toString() {
  return 'QuestionArgs(spreadId: $spreadId, source: $source, presetCards: $presetCards)';
}


}

/// @nodoc
abstract mixin class $QuestionArgsCopyWith<$Res>  {
  factory $QuestionArgsCopyWith(QuestionArgs value, $Res Function(QuestionArgs) _then) = _$QuestionArgsCopyWithImpl;
@useResult
$Res call({
 SpreadId spreadId, ReadingFlowSource source, List<PresetCard> presetCards
});




}
/// @nodoc
class _$QuestionArgsCopyWithImpl<$Res>
    implements $QuestionArgsCopyWith<$Res> {
  _$QuestionArgsCopyWithImpl(this._self, this._then);

  final QuestionArgs _self;
  final $Res Function(QuestionArgs) _then;

/// Create a copy of QuestionArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spreadId = null,Object? source = null,Object? presetCards = null,}) {
  return _then(_self.copyWith(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReadingFlowSource,presetCards: null == presetCards ? _self.presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionArgs].
extension QuestionArgsPatterns on QuestionArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionArgs value)  $default,){
final _that = this;
switch (_that) {
case _QuestionArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionArgs value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadId spreadId,  ReadingFlowSource source,  List<PresetCard> presetCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionArgs() when $default != null:
return $default(_that.spreadId,_that.source,_that.presetCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadId spreadId,  ReadingFlowSource source,  List<PresetCard> presetCards)  $default,) {final _that = this;
switch (_that) {
case _QuestionArgs():
return $default(_that.spreadId,_that.source,_that.presetCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadId spreadId,  ReadingFlowSource source,  List<PresetCard> presetCards)?  $default,) {final _that = this;
switch (_that) {
case _QuestionArgs() when $default != null:
return $default(_that.spreadId,_that.source,_that.presetCards);case _:
  return null;

}
}

}

/// @nodoc


class _QuestionArgs implements QuestionArgs {
  const _QuestionArgs({required this.spreadId, this.source = ReadingFlowSource.home, final  List<PresetCard> presetCards = const <PresetCard>[]}): _presetCards = presetCards;
  

@override final  SpreadId spreadId;
@override@JsonKey() final  ReadingFlowSource source;
 final  List<PresetCard> _presetCards;
@override@JsonKey() List<PresetCard> get presetCards {
  if (_presetCards is EqualUnmodifiableListView) return _presetCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presetCards);
}


/// Create a copy of QuestionArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionArgsCopyWith<_QuestionArgs> get copyWith => __$QuestionArgsCopyWithImpl<_QuestionArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionArgs&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._presetCards, _presetCards));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,source,const DeepCollectionEquality().hash(_presetCards));

@override
String toString() {
  return 'QuestionArgs(spreadId: $spreadId, source: $source, presetCards: $presetCards)';
}


}

/// @nodoc
abstract mixin class _$QuestionArgsCopyWith<$Res> implements $QuestionArgsCopyWith<$Res> {
  factory _$QuestionArgsCopyWith(_QuestionArgs value, $Res Function(_QuestionArgs) _then) = __$QuestionArgsCopyWithImpl;
@override @useResult
$Res call({
 SpreadId spreadId, ReadingFlowSource source, List<PresetCard> presetCards
});




}
/// @nodoc
class __$QuestionArgsCopyWithImpl<$Res>
    implements _$QuestionArgsCopyWith<$Res> {
  __$QuestionArgsCopyWithImpl(this._self, this._then);

  final _QuestionArgs _self;
  final $Res Function(_QuestionArgs) _then;

/// Create a copy of QuestionArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spreadId = null,Object? source = null,Object? presetCards = null,}) {
  return _then(_QuestionArgs(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ReadingFlowSource,presetCards: null == presetCards ? _self._presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,
  ));
}


}

/// @nodoc
mixin _$QuestionDraft {

 SpreadId get spreadId; QuestionCheck get check; int get maxChars; SpreadDefinition? get spread; String get text; bool get usedSuggestion; List<PresetCard> get presetCards;
/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<QuestionDraft> get copyWith => _$QuestionDraftCopyWithImpl<QuestionDraft>(this as QuestionDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionDraft&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.check, check) || other.check == check)&&(identical(other.maxChars, maxChars) || other.maxChars == maxChars)&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.text, text) || other.text == text)&&(identical(other.usedSuggestion, usedSuggestion) || other.usedSuggestion == usedSuggestion)&&const DeepCollectionEquality().equals(other.presetCards, presetCards));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,check,maxChars,spread,text,usedSuggestion,const DeepCollectionEquality().hash(presetCards));

@override
String toString() {
  return 'QuestionDraft(spreadId: $spreadId, check: $check, maxChars: $maxChars, spread: $spread, text: $text, usedSuggestion: $usedSuggestion, presetCards: $presetCards)';
}


}

/// @nodoc
abstract mixin class $QuestionDraftCopyWith<$Res>  {
  factory $QuestionDraftCopyWith(QuestionDraft value, $Res Function(QuestionDraft) _then) = _$QuestionDraftCopyWithImpl;
@useResult
$Res call({
 SpreadId spreadId, QuestionCheck check, int maxChars, SpreadDefinition? spread, String text, bool usedSuggestion, List<PresetCard> presetCards
});


$QuestionCheckCopyWith<$Res> get check;$SpreadDefinitionCopyWith<$Res>? get spread;

}
/// @nodoc
class _$QuestionDraftCopyWithImpl<$Res>
    implements $QuestionDraftCopyWith<$Res> {
  _$QuestionDraftCopyWithImpl(this._self, this._then);

  final QuestionDraft _self;
  final $Res Function(QuestionDraft) _then;

/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spreadId = null,Object? check = null,Object? maxChars = null,Object? spread = freezed,Object? text = null,Object? usedSuggestion = null,Object? presetCards = null,}) {
  return _then(_self.copyWith(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as QuestionCheck,maxChars: null == maxChars ? _self.maxChars : maxChars // ignore: cast_nullable_to_non_nullable
as int,spread: freezed == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usedSuggestion: null == usedSuggestion ? _self.usedSuggestion : usedSuggestion // ignore: cast_nullable_to_non_nullable
as bool,presetCards: null == presetCards ? _self.presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,
  ));
}
/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCheckCopyWith<$Res> get check {
  
  return $QuestionCheckCopyWith<$Res>(_self.check, (value) {
    return _then(_self.copyWith(check: value));
  });
}/// Create a copy of QuestionDraft
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


/// Adds pattern-matching-related methods to [QuestionDraft].
extension QuestionDraftPatterns on QuestionDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionDraft value)  $default,){
final _that = this;
switch (_that) {
case _QuestionDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionDraft value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SpreadId spreadId,  QuestionCheck check,  int maxChars,  SpreadDefinition? spread,  String text,  bool usedSuggestion,  List<PresetCard> presetCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionDraft() when $default != null:
return $default(_that.spreadId,_that.check,_that.maxChars,_that.spread,_that.text,_that.usedSuggestion,_that.presetCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SpreadId spreadId,  QuestionCheck check,  int maxChars,  SpreadDefinition? spread,  String text,  bool usedSuggestion,  List<PresetCard> presetCards)  $default,) {final _that = this;
switch (_that) {
case _QuestionDraft():
return $default(_that.spreadId,_that.check,_that.maxChars,_that.spread,_that.text,_that.usedSuggestion,_that.presetCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SpreadId spreadId,  QuestionCheck check,  int maxChars,  SpreadDefinition? spread,  String text,  bool usedSuggestion,  List<PresetCard> presetCards)?  $default,) {final _that = this;
switch (_that) {
case _QuestionDraft() when $default != null:
return $default(_that.spreadId,_that.check,_that.maxChars,_that.spread,_that.text,_that.usedSuggestion,_that.presetCards);case _:
  return null;

}
}

}

/// @nodoc


class _QuestionDraft extends QuestionDraft {
  const _QuestionDraft({required this.spreadId, required this.check, required this.maxChars, this.spread, this.text = '', this.usedSuggestion = false, final  List<PresetCard> presetCards = const <PresetCard>[]}): _presetCards = presetCards,super._();
  

@override final  SpreadId spreadId;
@override final  QuestionCheck check;
@override final  int maxChars;
@override final  SpreadDefinition? spread;
@override@JsonKey() final  String text;
@override@JsonKey() final  bool usedSuggestion;
 final  List<PresetCard> _presetCards;
@override@JsonKey() List<PresetCard> get presetCards {
  if (_presetCards is EqualUnmodifiableListView) return _presetCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presetCards);
}


/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionDraftCopyWith<_QuestionDraft> get copyWith => __$QuestionDraftCopyWithImpl<_QuestionDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionDraft&&(identical(other.spreadId, spreadId) || other.spreadId == spreadId)&&(identical(other.check, check) || other.check == check)&&(identical(other.maxChars, maxChars) || other.maxChars == maxChars)&&(identical(other.spread, spread) || other.spread == spread)&&(identical(other.text, text) || other.text == text)&&(identical(other.usedSuggestion, usedSuggestion) || other.usedSuggestion == usedSuggestion)&&const DeepCollectionEquality().equals(other._presetCards, _presetCards));
}


@override
int get hashCode => Object.hash(runtimeType,spreadId,check,maxChars,spread,text,usedSuggestion,const DeepCollectionEquality().hash(_presetCards));

@override
String toString() {
  return 'QuestionDraft(spreadId: $spreadId, check: $check, maxChars: $maxChars, spread: $spread, text: $text, usedSuggestion: $usedSuggestion, presetCards: $presetCards)';
}


}

/// @nodoc
abstract mixin class _$QuestionDraftCopyWith<$Res> implements $QuestionDraftCopyWith<$Res> {
  factory _$QuestionDraftCopyWith(_QuestionDraft value, $Res Function(_QuestionDraft) _then) = __$QuestionDraftCopyWithImpl;
@override @useResult
$Res call({
 SpreadId spreadId, QuestionCheck check, int maxChars, SpreadDefinition? spread, String text, bool usedSuggestion, List<PresetCard> presetCards
});


@override $QuestionCheckCopyWith<$Res> get check;@override $SpreadDefinitionCopyWith<$Res>? get spread;

}
/// @nodoc
class __$QuestionDraftCopyWithImpl<$Res>
    implements _$QuestionDraftCopyWith<$Res> {
  __$QuestionDraftCopyWithImpl(this._self, this._then);

  final _QuestionDraft _self;
  final $Res Function(_QuestionDraft) _then;

/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spreadId = null,Object? check = null,Object? maxChars = null,Object? spread = freezed,Object? text = null,Object? usedSuggestion = null,Object? presetCards = null,}) {
  return _then(_QuestionDraft(
spreadId: null == spreadId ? _self.spreadId : spreadId // ignore: cast_nullable_to_non_nullable
as SpreadId,check: null == check ? _self.check : check // ignore: cast_nullable_to_non_nullable
as QuestionCheck,maxChars: null == maxChars ? _self.maxChars : maxChars // ignore: cast_nullable_to_non_nullable
as int,spread: freezed == spread ? _self.spread : spread // ignore: cast_nullable_to_non_nullable
as SpreadDefinition?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,usedSuggestion: null == usedSuggestion ? _self.usedSuggestion : usedSuggestion // ignore: cast_nullable_to_non_nullable
as bool,presetCards: null == presetCards ? _self._presetCards : presetCards // ignore: cast_nullable_to_non_nullable
as List<PresetCard>,
  ));
}

/// Create a copy of QuestionDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionCheckCopyWith<$Res> get check {
  
  return $QuestionCheckCopyWith<$Res>(_self.check, (value) {
    return _then(_self.copyWith(check: value));
  });
}/// Create a copy of QuestionDraft
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
mixin _$QuestionState {

 QuestionDraft get draft;
/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionStateCopyWith<QuestionState> get copyWith => _$QuestionStateCopyWithImpl<QuestionState>(this as QuestionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionState&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionStateCopyWith<$Res>  {
  factory $QuestionStateCopyWith(QuestionState value, $Res Function(QuestionState) _then) = _$QuestionStateCopyWithImpl;
@useResult
$Res call({
 QuestionDraft draft
});


$QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionStateCopyWithImpl<$Res>
    implements $QuestionStateCopyWith<$Res> {
  _$QuestionStateCopyWithImpl(this._self, this._then);

  final QuestionState _self;
  final $Res Function(QuestionState) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draft = null,}) {
  return _then(_self.copyWith(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}
/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuestionState].
extension QuestionStatePatterns on QuestionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QuestionEditing value)?  editing,TResult Function( QuestionChecking value)?  checking,TResult Function( QuestionReady value)?  ready,TResult Function( QuestionOffline value)?  offline,TResult Function( QuestionConsentRequired value)?  consentRequired,TResult Function( QuestionDeviceUnverified value)?  deviceUnverified,TResult Function( QuestionReadingsPaused value)?  readingsPaused,TResult Function( QuestionAiUnavailableRegion value)?  aiUnavailableRegion,TResult Function( QuestionOutOfReadings value)?  outOfReadings,TResult Function( QuestionDailyLimitReached value)?  dailyLimitReached,TResult Function( QuestionLowTrustLimited value)?  lowTrustLimited,TResult Function( QuestionRephrase value)?  rephrase,TResult Function( QuestionRefused value)?  refused,TResult Function( QuestionRateLimited value)?  rateLimited,TResult Function( QuestionSpreadDisabled value)?  spreadDisabled,TResult Function( QuestionFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QuestionEditing() when editing != null:
return editing(_that);case QuestionChecking() when checking != null:
return checking(_that);case QuestionReady() when ready != null:
return ready(_that);case QuestionOffline() when offline != null:
return offline(_that);case QuestionConsentRequired() when consentRequired != null:
return consentRequired(_that);case QuestionDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that);case QuestionReadingsPaused() when readingsPaused != null:
return readingsPaused(_that);case QuestionAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case QuestionOutOfReadings() when outOfReadings != null:
return outOfReadings(_that);case QuestionDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that);case QuestionLowTrustLimited() when lowTrustLimited != null:
return lowTrustLimited(_that);case QuestionRephrase() when rephrase != null:
return rephrase(_that);case QuestionRefused() when refused != null:
return refused(_that);case QuestionRateLimited() when rateLimited != null:
return rateLimited(_that);case QuestionSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that);case QuestionFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QuestionEditing value)  editing,required TResult Function( QuestionChecking value)  checking,required TResult Function( QuestionReady value)  ready,required TResult Function( QuestionOffline value)  offline,required TResult Function( QuestionConsentRequired value)  consentRequired,required TResult Function( QuestionDeviceUnverified value)  deviceUnverified,required TResult Function( QuestionReadingsPaused value)  readingsPaused,required TResult Function( QuestionAiUnavailableRegion value)  aiUnavailableRegion,required TResult Function( QuestionOutOfReadings value)  outOfReadings,required TResult Function( QuestionDailyLimitReached value)  dailyLimitReached,required TResult Function( QuestionLowTrustLimited value)  lowTrustLimited,required TResult Function( QuestionRephrase value)  rephrase,required TResult Function( QuestionRefused value)  refused,required TResult Function( QuestionRateLimited value)  rateLimited,required TResult Function( QuestionSpreadDisabled value)  spreadDisabled,required TResult Function( QuestionFailed value)  failed,}){
final _that = this;
switch (_that) {
case QuestionEditing():
return editing(_that);case QuestionChecking():
return checking(_that);case QuestionReady():
return ready(_that);case QuestionOffline():
return offline(_that);case QuestionConsentRequired():
return consentRequired(_that);case QuestionDeviceUnverified():
return deviceUnverified(_that);case QuestionReadingsPaused():
return readingsPaused(_that);case QuestionAiUnavailableRegion():
return aiUnavailableRegion(_that);case QuestionOutOfReadings():
return outOfReadings(_that);case QuestionDailyLimitReached():
return dailyLimitReached(_that);case QuestionLowTrustLimited():
return lowTrustLimited(_that);case QuestionRephrase():
return rephrase(_that);case QuestionRefused():
return refused(_that);case QuestionRateLimited():
return rateLimited(_that);case QuestionSpreadDisabled():
return spreadDisabled(_that);case QuestionFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QuestionEditing value)?  editing,TResult? Function( QuestionChecking value)?  checking,TResult? Function( QuestionReady value)?  ready,TResult? Function( QuestionOffline value)?  offline,TResult? Function( QuestionConsentRequired value)?  consentRequired,TResult? Function( QuestionDeviceUnverified value)?  deviceUnverified,TResult? Function( QuestionReadingsPaused value)?  readingsPaused,TResult? Function( QuestionAiUnavailableRegion value)?  aiUnavailableRegion,TResult? Function( QuestionOutOfReadings value)?  outOfReadings,TResult? Function( QuestionDailyLimitReached value)?  dailyLimitReached,TResult? Function( QuestionLowTrustLimited value)?  lowTrustLimited,TResult? Function( QuestionRephrase value)?  rephrase,TResult? Function( QuestionRefused value)?  refused,TResult? Function( QuestionRateLimited value)?  rateLimited,TResult? Function( QuestionSpreadDisabled value)?  spreadDisabled,TResult? Function( QuestionFailed value)?  failed,}){
final _that = this;
switch (_that) {
case QuestionEditing() when editing != null:
return editing(_that);case QuestionChecking() when checking != null:
return checking(_that);case QuestionReady() when ready != null:
return ready(_that);case QuestionOffline() when offline != null:
return offline(_that);case QuestionConsentRequired() when consentRequired != null:
return consentRequired(_that);case QuestionDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that);case QuestionReadingsPaused() when readingsPaused != null:
return readingsPaused(_that);case QuestionAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case QuestionOutOfReadings() when outOfReadings != null:
return outOfReadings(_that);case QuestionDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that);case QuestionLowTrustLimited() when lowTrustLimited != null:
return lowTrustLimited(_that);case QuestionRephrase() when rephrase != null:
return rephrase(_that);case QuestionRefused() when refused != null:
return refused(_that);case QuestionRateLimited() when rateLimited != null:
return rateLimited(_that);case QuestionSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that);case QuestionFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( QuestionDraft draft)?  editing,TResult Function( QuestionDraft draft)?  checking,TResult Function( QuestionDraft draft)?  ready,TResult Function( QuestionDraft draft)?  offline,TResult Function( QuestionDraft draft)?  consentRequired,TResult Function( QuestionDraft draft)?  deviceUnverified,TResult Function( QuestionDraft draft,  bool freePaused)?  readingsPaused,TResult Function( QuestionDraft draft)?  aiUnavailableRegion,TResult Function( QuestionDraft draft,  PaywallOptions options,  OutOfReadingsSource source)?  outOfReadings,TResult Function( QuestionDraft draft)?  dailyLimitReached,TResult Function( QuestionDraft draft,  PaywallOptions options)?  lowTrustLimited,TResult Function( QuestionDraft draft,  SafetyInfo safety,  Draw draw)?  rephrase,TResult Function( QuestionDraft draft,  RefusalCategory category,  SafetyInfo safety,  Draw? draw)?  refused,TResult Function( QuestionDraft draft,  Duration? retryAfter)?  rateLimited,TResult Function( QuestionDraft draft)?  spreadDisabled,TResult Function( QuestionDraft draft,  Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QuestionEditing() when editing != null:
return editing(_that.draft);case QuestionChecking() when checking != null:
return checking(_that.draft);case QuestionReady() when ready != null:
return ready(_that.draft);case QuestionOffline() when offline != null:
return offline(_that.draft);case QuestionConsentRequired() when consentRequired != null:
return consentRequired(_that.draft);case QuestionDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that.draft);case QuestionReadingsPaused() when readingsPaused != null:
return readingsPaused(_that.draft,_that.freePaused);case QuestionAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that.draft);case QuestionOutOfReadings() when outOfReadings != null:
return outOfReadings(_that.draft,_that.options,_that.source);case QuestionDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that.draft);case QuestionLowTrustLimited() when lowTrustLimited != null:
return lowTrustLimited(_that.draft,_that.options);case QuestionRephrase() when rephrase != null:
return rephrase(_that.draft,_that.safety,_that.draw);case QuestionRefused() when refused != null:
return refused(_that.draft,_that.category,_that.safety,_that.draw);case QuestionRateLimited() when rateLimited != null:
return rateLimited(_that.draft,_that.retryAfter);case QuestionSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that.draft);case QuestionFailed() when failed != null:
return failed(_that.draft,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( QuestionDraft draft)  editing,required TResult Function( QuestionDraft draft)  checking,required TResult Function( QuestionDraft draft)  ready,required TResult Function( QuestionDraft draft)  offline,required TResult Function( QuestionDraft draft)  consentRequired,required TResult Function( QuestionDraft draft)  deviceUnverified,required TResult Function( QuestionDraft draft,  bool freePaused)  readingsPaused,required TResult Function( QuestionDraft draft)  aiUnavailableRegion,required TResult Function( QuestionDraft draft,  PaywallOptions options,  OutOfReadingsSource source)  outOfReadings,required TResult Function( QuestionDraft draft)  dailyLimitReached,required TResult Function( QuestionDraft draft,  PaywallOptions options)  lowTrustLimited,required TResult Function( QuestionDraft draft,  SafetyInfo safety,  Draw draw)  rephrase,required TResult Function( QuestionDraft draft,  RefusalCategory category,  SafetyInfo safety,  Draw? draw)  refused,required TResult Function( QuestionDraft draft,  Duration? retryAfter)  rateLimited,required TResult Function( QuestionDraft draft)  spreadDisabled,required TResult Function( QuestionDraft draft,  Failure failure)  failed,}) {final _that = this;
switch (_that) {
case QuestionEditing():
return editing(_that.draft);case QuestionChecking():
return checking(_that.draft);case QuestionReady():
return ready(_that.draft);case QuestionOffline():
return offline(_that.draft);case QuestionConsentRequired():
return consentRequired(_that.draft);case QuestionDeviceUnverified():
return deviceUnverified(_that.draft);case QuestionReadingsPaused():
return readingsPaused(_that.draft,_that.freePaused);case QuestionAiUnavailableRegion():
return aiUnavailableRegion(_that.draft);case QuestionOutOfReadings():
return outOfReadings(_that.draft,_that.options,_that.source);case QuestionDailyLimitReached():
return dailyLimitReached(_that.draft);case QuestionLowTrustLimited():
return lowTrustLimited(_that.draft,_that.options);case QuestionRephrase():
return rephrase(_that.draft,_that.safety,_that.draw);case QuestionRefused():
return refused(_that.draft,_that.category,_that.safety,_that.draw);case QuestionRateLimited():
return rateLimited(_that.draft,_that.retryAfter);case QuestionSpreadDisabled():
return spreadDisabled(_that.draft);case QuestionFailed():
return failed(_that.draft,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( QuestionDraft draft)?  editing,TResult? Function( QuestionDraft draft)?  checking,TResult? Function( QuestionDraft draft)?  ready,TResult? Function( QuestionDraft draft)?  offline,TResult? Function( QuestionDraft draft)?  consentRequired,TResult? Function( QuestionDraft draft)?  deviceUnverified,TResult? Function( QuestionDraft draft,  bool freePaused)?  readingsPaused,TResult? Function( QuestionDraft draft)?  aiUnavailableRegion,TResult? Function( QuestionDraft draft,  PaywallOptions options,  OutOfReadingsSource source)?  outOfReadings,TResult? Function( QuestionDraft draft)?  dailyLimitReached,TResult? Function( QuestionDraft draft,  PaywallOptions options)?  lowTrustLimited,TResult? Function( QuestionDraft draft,  SafetyInfo safety,  Draw draw)?  rephrase,TResult? Function( QuestionDraft draft,  RefusalCategory category,  SafetyInfo safety,  Draw? draw)?  refused,TResult? Function( QuestionDraft draft,  Duration? retryAfter)?  rateLimited,TResult? Function( QuestionDraft draft)?  spreadDisabled,TResult? Function( QuestionDraft draft,  Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case QuestionEditing() when editing != null:
return editing(_that.draft);case QuestionChecking() when checking != null:
return checking(_that.draft);case QuestionReady() when ready != null:
return ready(_that.draft);case QuestionOffline() when offline != null:
return offline(_that.draft);case QuestionConsentRequired() when consentRequired != null:
return consentRequired(_that.draft);case QuestionDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that.draft);case QuestionReadingsPaused() when readingsPaused != null:
return readingsPaused(_that.draft,_that.freePaused);case QuestionAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that.draft);case QuestionOutOfReadings() when outOfReadings != null:
return outOfReadings(_that.draft,_that.options,_that.source);case QuestionDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that.draft);case QuestionLowTrustLimited() when lowTrustLimited != null:
return lowTrustLimited(_that.draft,_that.options);case QuestionRephrase() when rephrase != null:
return rephrase(_that.draft,_that.safety,_that.draw);case QuestionRefused() when refused != null:
return refused(_that.draft,_that.category,_that.safety,_that.draw);case QuestionRateLimited() when rateLimited != null:
return rateLimited(_that.draft,_that.retryAfter);case QuestionSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that.draft);case QuestionFailed() when failed != null:
return failed(_that.draft,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class QuestionEditing extends QuestionState {
  const QuestionEditing(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionEditingCopyWith<QuestionEditing> get copyWith => _$QuestionEditingCopyWithImpl<QuestionEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionEditing&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.editing(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionEditingCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionEditingCopyWith(QuestionEditing value, $Res Function(QuestionEditing) _then) = _$QuestionEditingCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionEditingCopyWithImpl<$Res>
    implements $QuestionEditingCopyWith<$Res> {
  _$QuestionEditingCopyWithImpl(this._self, this._then);

  final QuestionEditing _self;
  final $Res Function(QuestionEditing) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionEditing(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionChecking extends QuestionState {
  const QuestionChecking(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCheckingCopyWith<QuestionChecking> get copyWith => _$QuestionCheckingCopyWithImpl<QuestionChecking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionChecking&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.checking(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionCheckingCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionCheckingCopyWith(QuestionChecking value, $Res Function(QuestionChecking) _then) = _$QuestionCheckingCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionCheckingCopyWithImpl<$Res>
    implements $QuestionCheckingCopyWith<$Res> {
  _$QuestionCheckingCopyWithImpl(this._self, this._then);

  final QuestionChecking _self;
  final $Res Function(QuestionChecking) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionChecking(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionReady extends QuestionState {
  const QuestionReady(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionReadyCopyWith<QuestionReady> get copyWith => _$QuestionReadyCopyWithImpl<QuestionReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionReady&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.ready(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionReadyCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionReadyCopyWith(QuestionReady value, $Res Function(QuestionReady) _then) = _$QuestionReadyCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionReadyCopyWithImpl<$Res>
    implements $QuestionReadyCopyWith<$Res> {
  _$QuestionReadyCopyWithImpl(this._self, this._then);

  final QuestionReady _self;
  final $Res Function(QuestionReady) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionReady(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionOffline extends QuestionState {
  const QuestionOffline(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionOfflineCopyWith<QuestionOffline> get copyWith => _$QuestionOfflineCopyWithImpl<QuestionOffline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionOffline&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.offline(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionOfflineCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionOfflineCopyWith(QuestionOffline value, $Res Function(QuestionOffline) _then) = _$QuestionOfflineCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionOfflineCopyWithImpl<$Res>
    implements $QuestionOfflineCopyWith<$Res> {
  _$QuestionOfflineCopyWithImpl(this._self, this._then);

  final QuestionOffline _self;
  final $Res Function(QuestionOffline) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionOffline(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionConsentRequired extends QuestionState {
  const QuestionConsentRequired(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionConsentRequiredCopyWith<QuestionConsentRequired> get copyWith => _$QuestionConsentRequiredCopyWithImpl<QuestionConsentRequired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionConsentRequired&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.consentRequired(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionConsentRequiredCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionConsentRequiredCopyWith(QuestionConsentRequired value, $Res Function(QuestionConsentRequired) _then) = _$QuestionConsentRequiredCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionConsentRequiredCopyWithImpl<$Res>
    implements $QuestionConsentRequiredCopyWith<$Res> {
  _$QuestionConsentRequiredCopyWithImpl(this._self, this._then);

  final QuestionConsentRequired _self;
  final $Res Function(QuestionConsentRequired) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionConsentRequired(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionDeviceUnverified extends QuestionState {
  const QuestionDeviceUnverified(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionDeviceUnverifiedCopyWith<QuestionDeviceUnverified> get copyWith => _$QuestionDeviceUnverifiedCopyWithImpl<QuestionDeviceUnverified>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionDeviceUnverified&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.deviceUnverified(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionDeviceUnverifiedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionDeviceUnverifiedCopyWith(QuestionDeviceUnverified value, $Res Function(QuestionDeviceUnverified) _then) = _$QuestionDeviceUnverifiedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionDeviceUnverifiedCopyWithImpl<$Res>
    implements $QuestionDeviceUnverifiedCopyWith<$Res> {
  _$QuestionDeviceUnverifiedCopyWithImpl(this._self, this._then);

  final QuestionDeviceUnverified _self;
  final $Res Function(QuestionDeviceUnverified) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionDeviceUnverified(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionReadingsPaused extends QuestionState {
  const QuestionReadingsPaused(this.draft, {this.freePaused = false}): super._();
  

@override final  QuestionDraft draft;
@JsonKey() final  bool freePaused;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionReadingsPausedCopyWith<QuestionReadingsPaused> get copyWith => _$QuestionReadingsPausedCopyWithImpl<QuestionReadingsPaused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionReadingsPaused&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.freePaused, freePaused) || other.freePaused == freePaused));
}


@override
int get hashCode => Object.hash(runtimeType,draft,freePaused);

@override
String toString() {
  return 'QuestionState.readingsPaused(draft: $draft, freePaused: $freePaused)';
}


}

/// @nodoc
abstract mixin class $QuestionReadingsPausedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionReadingsPausedCopyWith(QuestionReadingsPaused value, $Res Function(QuestionReadingsPaused) _then) = _$QuestionReadingsPausedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, bool freePaused
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionReadingsPausedCopyWithImpl<$Res>
    implements $QuestionReadingsPausedCopyWith<$Res> {
  _$QuestionReadingsPausedCopyWithImpl(this._self, this._then);

  final QuestionReadingsPaused _self;
  final $Res Function(QuestionReadingsPaused) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? freePaused = null,}) {
  return _then(QuestionReadingsPaused(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,freePaused: null == freePaused ? _self.freePaused : freePaused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionAiUnavailableRegion extends QuestionState {
  const QuestionAiUnavailableRegion(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionAiUnavailableRegionCopyWith<QuestionAiUnavailableRegion> get copyWith => _$QuestionAiUnavailableRegionCopyWithImpl<QuestionAiUnavailableRegion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionAiUnavailableRegion&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.aiUnavailableRegion(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionAiUnavailableRegionCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionAiUnavailableRegionCopyWith(QuestionAiUnavailableRegion value, $Res Function(QuestionAiUnavailableRegion) _then) = _$QuestionAiUnavailableRegionCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionAiUnavailableRegionCopyWithImpl<$Res>
    implements $QuestionAiUnavailableRegionCopyWith<$Res> {
  _$QuestionAiUnavailableRegionCopyWithImpl(this._self, this._then);

  final QuestionAiUnavailableRegion _self;
  final $Res Function(QuestionAiUnavailableRegion) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionAiUnavailableRegion(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionOutOfReadings extends QuestionState {
  const QuestionOutOfReadings(this.draft, {required this.options, required this.source}): super._();
  

@override final  QuestionDraft draft;
 final  PaywallOptions options;
 final  OutOfReadingsSource source;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionOutOfReadingsCopyWith<QuestionOutOfReadings> get copyWith => _$QuestionOutOfReadingsCopyWithImpl<QuestionOutOfReadings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionOutOfReadings&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.options, options) || other.options == options)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,draft,options,source);

@override
String toString() {
  return 'QuestionState.outOfReadings(draft: $draft, options: $options, source: $source)';
}


}

/// @nodoc
abstract mixin class $QuestionOutOfReadingsCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionOutOfReadingsCopyWith(QuestionOutOfReadings value, $Res Function(QuestionOutOfReadings) _then) = _$QuestionOutOfReadingsCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, PaywallOptions options, OutOfReadingsSource source
});


@override $QuestionDraftCopyWith<$Res> get draft;$PaywallOptionsCopyWith<$Res> get options;

}
/// @nodoc
class _$QuestionOutOfReadingsCopyWithImpl<$Res>
    implements $QuestionOutOfReadingsCopyWith<$Res> {
  _$QuestionOutOfReadingsCopyWithImpl(this._self, this._then);

  final QuestionOutOfReadings _self;
  final $Res Function(QuestionOutOfReadings) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? options = null,Object? source = null,}) {
  return _then(QuestionOutOfReadings(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as PaywallOptions,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as OutOfReadingsSource,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallOptionsCopyWith<$Res> get options {
  
  return $PaywallOptionsCopyWith<$Res>(_self.options, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

/// @nodoc


class QuestionDailyLimitReached extends QuestionState {
  const QuestionDailyLimitReached(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionDailyLimitReachedCopyWith<QuestionDailyLimitReached> get copyWith => _$QuestionDailyLimitReachedCopyWithImpl<QuestionDailyLimitReached>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionDailyLimitReached&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.dailyLimitReached(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionDailyLimitReachedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionDailyLimitReachedCopyWith(QuestionDailyLimitReached value, $Res Function(QuestionDailyLimitReached) _then) = _$QuestionDailyLimitReachedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionDailyLimitReachedCopyWithImpl<$Res>
    implements $QuestionDailyLimitReachedCopyWith<$Res> {
  _$QuestionDailyLimitReachedCopyWithImpl(this._self, this._then);

  final QuestionDailyLimitReached _self;
  final $Res Function(QuestionDailyLimitReached) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionDailyLimitReached(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionLowTrustLimited extends QuestionState {
  const QuestionLowTrustLimited(this.draft, {required this.options}): super._();
  

@override final  QuestionDraft draft;
 final  PaywallOptions options;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionLowTrustLimitedCopyWith<QuestionLowTrustLimited> get copyWith => _$QuestionLowTrustLimitedCopyWithImpl<QuestionLowTrustLimited>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionLowTrustLimited&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.options, options) || other.options == options));
}


@override
int get hashCode => Object.hash(runtimeType,draft,options);

@override
String toString() {
  return 'QuestionState.lowTrustLimited(draft: $draft, options: $options)';
}


}

/// @nodoc
abstract mixin class $QuestionLowTrustLimitedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionLowTrustLimitedCopyWith(QuestionLowTrustLimited value, $Res Function(QuestionLowTrustLimited) _then) = _$QuestionLowTrustLimitedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, PaywallOptions options
});


@override $QuestionDraftCopyWith<$Res> get draft;$PaywallOptionsCopyWith<$Res> get options;

}
/// @nodoc
class _$QuestionLowTrustLimitedCopyWithImpl<$Res>
    implements $QuestionLowTrustLimitedCopyWith<$Res> {
  _$QuestionLowTrustLimitedCopyWithImpl(this._self, this._then);

  final QuestionLowTrustLimited _self;
  final $Res Function(QuestionLowTrustLimited) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? options = null,}) {
  return _then(QuestionLowTrustLimited(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as PaywallOptions,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallOptionsCopyWith<$Res> get options {
  
  return $PaywallOptionsCopyWith<$Res>(_self.options, (value) {
    return _then(_self.copyWith(options: value));
  });
}
}

/// @nodoc


class QuestionRephrase extends QuestionState {
  const QuestionRephrase(this.draft, {required this.safety, required this.draw}): super._();
  

@override final  QuestionDraft draft;
 final  SafetyInfo safety;
 final  Draw draw;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionRephraseCopyWith<QuestionRephrase> get copyWith => _$QuestionRephraseCopyWithImpl<QuestionRephrase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionRephrase&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.safety, safety) || other.safety == safety)&&(identical(other.draw, draw) || other.draw == draw));
}


@override
int get hashCode => Object.hash(runtimeType,draft,safety,draw);

@override
String toString() {
  return 'QuestionState.rephrase(draft: $draft, safety: $safety, draw: $draw)';
}


}

/// @nodoc
abstract mixin class $QuestionRephraseCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionRephraseCopyWith(QuestionRephrase value, $Res Function(QuestionRephrase) _then) = _$QuestionRephraseCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, SafetyInfo safety, Draw draw
});


@override $QuestionDraftCopyWith<$Res> get draft;$SafetyInfoCopyWith<$Res> get safety;$DrawCopyWith<$Res> get draw;

}
/// @nodoc
class _$QuestionRephraseCopyWithImpl<$Res>
    implements $QuestionRephraseCopyWith<$Res> {
  _$QuestionRephraseCopyWithImpl(this._self, this._then);

  final QuestionRephrase _self;
  final $Res Function(QuestionRephrase) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? safety = null,Object? draw = null,}) {
  return _then(QuestionRephrase(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as SafetyInfo,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<$Res> get safety {
  
  return $SafetyInfoCopyWith<$Res>(_self.safety, (value) {
    return _then(_self.copyWith(safety: value));
  });
}/// Create a copy of QuestionState
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


class QuestionRefused extends QuestionState {
  const QuestionRefused(this.draft, {required this.category, required this.safety, this.draw}): super._();
  

@override final  QuestionDraft draft;
 final  RefusalCategory category;
 final  SafetyInfo safety;
 final  Draw? draw;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionRefusedCopyWith<QuestionRefused> get copyWith => _$QuestionRefusedCopyWithImpl<QuestionRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionRefused&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.category, category) || other.category == category)&&(identical(other.safety, safety) || other.safety == safety)&&(identical(other.draw, draw) || other.draw == draw));
}


@override
int get hashCode => Object.hash(runtimeType,draft,category,safety,draw);

@override
String toString() {
  return 'QuestionState.refused(draft: $draft, category: $category, safety: $safety, draw: $draw)';
}


}

/// @nodoc
abstract mixin class $QuestionRefusedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionRefusedCopyWith(QuestionRefused value, $Res Function(QuestionRefused) _then) = _$QuestionRefusedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, RefusalCategory category, SafetyInfo safety, Draw? draw
});


@override $QuestionDraftCopyWith<$Res> get draft;$SafetyInfoCopyWith<$Res> get safety;$DrawCopyWith<$Res>? get draw;

}
/// @nodoc
class _$QuestionRefusedCopyWithImpl<$Res>
    implements $QuestionRefusedCopyWith<$Res> {
  _$QuestionRefusedCopyWithImpl(this._self, this._then);

  final QuestionRefused _self;
  final $Res Function(QuestionRefused) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? category = null,Object? safety = null,Object? draw = freezed,}) {
  return _then(QuestionRefused(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RefusalCategory,safety: null == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as SafetyInfo,draw: freezed == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw?,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<$Res> get safety {
  
  return $SafetyInfoCopyWith<$Res>(_self.safety, (value) {
    return _then(_self.copyWith(safety: value));
  });
}/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawCopyWith<$Res>? get draw {
    if (_self.draw == null) {
    return null;
  }

  return $DrawCopyWith<$Res>(_self.draw!, (value) {
    return _then(_self.copyWith(draw: value));
  });
}
}

/// @nodoc


class QuestionRateLimited extends QuestionState {
  const QuestionRateLimited(this.draft, {this.retryAfter}): super._();
  

@override final  QuestionDraft draft;
 final  Duration? retryAfter;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionRateLimitedCopyWith<QuestionRateLimited> get copyWith => _$QuestionRateLimitedCopyWithImpl<QuestionRateLimited>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionRateLimited&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.retryAfter, retryAfter) || other.retryAfter == retryAfter));
}


@override
int get hashCode => Object.hash(runtimeType,draft,retryAfter);

@override
String toString() {
  return 'QuestionState.rateLimited(draft: $draft, retryAfter: $retryAfter)';
}


}

/// @nodoc
abstract mixin class $QuestionRateLimitedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionRateLimitedCopyWith(QuestionRateLimited value, $Res Function(QuestionRateLimited) _then) = _$QuestionRateLimitedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, Duration? retryAfter
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionRateLimitedCopyWithImpl<$Res>
    implements $QuestionRateLimitedCopyWith<$Res> {
  _$QuestionRateLimitedCopyWithImpl(this._self, this._then);

  final QuestionRateLimited _self;
  final $Res Function(QuestionRateLimited) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? retryAfter = freezed,}) {
  return _then(QuestionRateLimited(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,retryAfter: freezed == retryAfter ? _self.retryAfter : retryAfter // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionSpreadDisabled extends QuestionState {
  const QuestionSpreadDisabled(this.draft): super._();
  

@override final  QuestionDraft draft;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionSpreadDisabledCopyWith<QuestionSpreadDisabled> get copyWith => _$QuestionSpreadDisabledCopyWithImpl<QuestionSpreadDisabled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionSpreadDisabled&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'QuestionState.spreadDisabled(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $QuestionSpreadDisabledCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionSpreadDisabledCopyWith(QuestionSpreadDisabled value, $Res Function(QuestionSpreadDisabled) _then) = _$QuestionSpreadDisabledCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft
});


@override $QuestionDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$QuestionSpreadDisabledCopyWithImpl<$Res>
    implements $QuestionSpreadDisabledCopyWith<$Res> {
  _$QuestionSpreadDisabledCopyWithImpl(this._self, this._then);

  final QuestionSpreadDisabled _self;
  final $Res Function(QuestionSpreadDisabled) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(QuestionSpreadDisabled(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class QuestionFailed extends QuestionState {
  const QuestionFailed(this.draft, {required this.failure}): super._();
  

@override final  QuestionDraft draft;
 final  Failure failure;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionFailedCopyWith<QuestionFailed> get copyWith => _$QuestionFailedCopyWithImpl<QuestionFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionFailed&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,draft,failure);

@override
String toString() {
  return 'QuestionState.failed(draft: $draft, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $QuestionFailedCopyWith<$Res> implements $QuestionStateCopyWith<$Res> {
  factory $QuestionFailedCopyWith(QuestionFailed value, $Res Function(QuestionFailed) _then) = _$QuestionFailedCopyWithImpl;
@override @useResult
$Res call({
 QuestionDraft draft, Failure failure
});


@override $QuestionDraftCopyWith<$Res> get draft;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$QuestionFailedCopyWithImpl<$Res>
    implements $QuestionFailedCopyWith<$Res> {
  _$QuestionFailedCopyWithImpl(this._self, this._then);

  final QuestionFailed _self;
  final $Res Function(QuestionFailed) _then;

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? failure = null,}) {
  return _then(QuestionFailed(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as QuestionDraft,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of QuestionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuestionDraftCopyWith<$Res> get draft {
  
  return $QuestionDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of QuestionState
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
