// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consent_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdsConsent {

/// UMP status.
 AdsConsentStatus get status;/// `ConsentInformation.canRequestAds`.
 bool get canRequestAds;/// Whether Settings must show "Privacy options".
 bool get privacyOptionsRequired;
/// Create a copy of AdsConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdsConsentCopyWith<AdsConsent> get copyWith => _$AdsConsentCopyWithImpl<AdsConsent>(this as AdsConsent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdsConsent&&(identical(other.status, status) || other.status == status)&&(identical(other.canRequestAds, canRequestAds) || other.canRequestAds == canRequestAds)&&(identical(other.privacyOptionsRequired, privacyOptionsRequired) || other.privacyOptionsRequired == privacyOptionsRequired));
}


@override
int get hashCode => Object.hash(runtimeType,status,canRequestAds,privacyOptionsRequired);

@override
String toString() {
  return 'AdsConsent(status: $status, canRequestAds: $canRequestAds, privacyOptionsRequired: $privacyOptionsRequired)';
}


}

/// @nodoc
abstract mixin class $AdsConsentCopyWith<$Res>  {
  factory $AdsConsentCopyWith(AdsConsent value, $Res Function(AdsConsent) _then) = _$AdsConsentCopyWithImpl;
@useResult
$Res call({
 AdsConsentStatus status, bool canRequestAds, bool privacyOptionsRequired
});




}
/// @nodoc
class _$AdsConsentCopyWithImpl<$Res>
    implements $AdsConsentCopyWith<$Res> {
  _$AdsConsentCopyWithImpl(this._self, this._then);

  final AdsConsent _self;
  final $Res Function(AdsConsent) _then;

/// Create a copy of AdsConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? canRequestAds = null,Object? privacyOptionsRequired = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AdsConsentStatus,canRequestAds: null == canRequestAds ? _self.canRequestAds : canRequestAds // ignore: cast_nullable_to_non_nullable
as bool,privacyOptionsRequired: null == privacyOptionsRequired ? _self.privacyOptionsRequired : privacyOptionsRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdsConsent].
extension AdsConsentPatterns on AdsConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdsConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdsConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdsConsent value)  $default,){
final _that = this;
switch (_that) {
case _AdsConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdsConsent value)?  $default,){
final _that = this;
switch (_that) {
case _AdsConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdsConsentStatus status,  bool canRequestAds,  bool privacyOptionsRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdsConsent() when $default != null:
return $default(_that.status,_that.canRequestAds,_that.privacyOptionsRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdsConsentStatus status,  bool canRequestAds,  bool privacyOptionsRequired)  $default,) {final _that = this;
switch (_that) {
case _AdsConsent():
return $default(_that.status,_that.canRequestAds,_that.privacyOptionsRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdsConsentStatus status,  bool canRequestAds,  bool privacyOptionsRequired)?  $default,) {final _that = this;
switch (_that) {
case _AdsConsent() when $default != null:
return $default(_that.status,_that.canRequestAds,_that.privacyOptionsRequired);case _:
  return null;

}
}

}

/// @nodoc


class _AdsConsent implements AdsConsent {
  const _AdsConsent({this.status = AdsConsentStatus.unknown, this.canRequestAds = false, this.privacyOptionsRequired = false});
  

/// UMP status.
@override@JsonKey() final  AdsConsentStatus status;
/// `ConsentInformation.canRequestAds`.
@override@JsonKey() final  bool canRequestAds;
/// Whether Settings must show "Privacy options".
@override@JsonKey() final  bool privacyOptionsRequired;

/// Create a copy of AdsConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdsConsentCopyWith<_AdsConsent> get copyWith => __$AdsConsentCopyWithImpl<_AdsConsent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdsConsent&&(identical(other.status, status) || other.status == status)&&(identical(other.canRequestAds, canRequestAds) || other.canRequestAds == canRequestAds)&&(identical(other.privacyOptionsRequired, privacyOptionsRequired) || other.privacyOptionsRequired == privacyOptionsRequired));
}


@override
int get hashCode => Object.hash(runtimeType,status,canRequestAds,privacyOptionsRequired);

@override
String toString() {
  return 'AdsConsent(status: $status, canRequestAds: $canRequestAds, privacyOptionsRequired: $privacyOptionsRequired)';
}


}

/// @nodoc
abstract mixin class _$AdsConsentCopyWith<$Res> implements $AdsConsentCopyWith<$Res> {
  factory _$AdsConsentCopyWith(_AdsConsent value, $Res Function(_AdsConsent) _then) = __$AdsConsentCopyWithImpl;
@override @useResult
$Res call({
 AdsConsentStatus status, bool canRequestAds, bool privacyOptionsRequired
});




}
/// @nodoc
class __$AdsConsentCopyWithImpl<$Res>
    implements _$AdsConsentCopyWith<$Res> {
  __$AdsConsentCopyWithImpl(this._self, this._then);

  final _AdsConsent _self;
  final $Res Function(_AdsConsent) _then;

/// Create a copy of AdsConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? canRequestAds = null,Object? privacyOptionsRequired = null,}) {
  return _then(_AdsConsent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AdsConsentStatus,canRequestAds: null == canRequestAds ? _self.canRequestAds : canRequestAds // ignore: cast_nullable_to_non_nullable
as bool,privacyOptionsRequired: null == privacyOptionsRequired ? _self.privacyOptionsRequired : privacyOptionsRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AiConsent {

/// The decision.
 AiConsentDecision get decision;/// The disclosure version the decision applies to.
 int? get version;/// When the decision was made.
 DateTime? get at;
/// Create a copy of AiConsent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiConsentCopyWith<AiConsent> get copyWith => _$AiConsentCopyWithImpl<AiConsent>(this as AiConsent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiConsent&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.version, version) || other.version == version)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,decision,version,at);

@override
String toString() {
  return 'AiConsent(decision: $decision, version: $version, at: $at)';
}


}

/// @nodoc
abstract mixin class $AiConsentCopyWith<$Res>  {
  factory $AiConsentCopyWith(AiConsent value, $Res Function(AiConsent) _then) = _$AiConsentCopyWithImpl;
@useResult
$Res call({
 AiConsentDecision decision, int? version, DateTime? at
});




}
/// @nodoc
class _$AiConsentCopyWithImpl<$Res>
    implements $AiConsentCopyWith<$Res> {
  _$AiConsentCopyWithImpl(this._self, this._then);

  final AiConsent _self;
  final $Res Function(AiConsent) _then;

/// Create a copy of AiConsent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decision = null,Object? version = freezed,Object? at = freezed,}) {
  return _then(_self.copyWith(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as AiConsentDecision,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiConsent].
extension AiConsentPatterns on AiConsent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiConsent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiConsent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiConsent value)  $default,){
final _that = this;
switch (_that) {
case _AiConsent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiConsent value)?  $default,){
final _that = this;
switch (_that) {
case _AiConsent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AiConsentDecision decision,  int? version,  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiConsent() when $default != null:
return $default(_that.decision,_that.version,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AiConsentDecision decision,  int? version,  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _AiConsent():
return $default(_that.decision,_that.version,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AiConsentDecision decision,  int? version,  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _AiConsent() when $default != null:
return $default(_that.decision,_that.version,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _AiConsent extends AiConsent {
  const _AiConsent({this.decision = AiConsentDecision.unknown, this.version, this.at}): super._();
  

/// The decision.
@override@JsonKey() final  AiConsentDecision decision;
/// The disclosure version the decision applies to.
@override final  int? version;
/// When the decision was made.
@override final  DateTime? at;

/// Create a copy of AiConsent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiConsentCopyWith<_AiConsent> get copyWith => __$AiConsentCopyWithImpl<_AiConsent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiConsent&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.version, version) || other.version == version)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,decision,version,at);

@override
String toString() {
  return 'AiConsent(decision: $decision, version: $version, at: $at)';
}


}

/// @nodoc
abstract mixin class _$AiConsentCopyWith<$Res> implements $AiConsentCopyWith<$Res> {
  factory _$AiConsentCopyWith(_AiConsent value, $Res Function(_AiConsent) _then) = __$AiConsentCopyWithImpl;
@override @useResult
$Res call({
 AiConsentDecision decision, int? version, DateTime? at
});




}
/// @nodoc
class __$AiConsentCopyWithImpl<$Res>
    implements _$AiConsentCopyWith<$Res> {
  __$AiConsentCopyWithImpl(this._self, this._then);

  final _AiConsent _self;
  final $Res Function(_AiConsent) _then;

/// Create a copy of AiConsent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decision = null,Object? version = freezed,Object? at = freezed,}) {
  return _then(_AiConsent(
decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as AiConsentDecision,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$ConsentState {

/// UMP state.
 AdsConsent get ads;/// ATT status.
 TrackingStatus get tracking;/// AI consent.
 AiConsent get ai;/// Whether analytics collection is on.
 bool get analyticsEnabled;/// The onboarding step to resume at.
 OnboardingStep get onboardingStep;
/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentStateCopyWith<ConsentState> get copyWith => _$ConsentStateCopyWithImpl<ConsentState>(this as ConsentState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsentState&&(identical(other.ads, ads) || other.ads == ads)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.ai, ai) || other.ai == ai)&&(identical(other.analyticsEnabled, analyticsEnabled) || other.analyticsEnabled == analyticsEnabled)&&(identical(other.onboardingStep, onboardingStep) || other.onboardingStep == onboardingStep));
}


@override
int get hashCode => Object.hash(runtimeType,ads,tracking,ai,analyticsEnabled,onboardingStep);

@override
String toString() {
  return 'ConsentState(ads: $ads, tracking: $tracking, ai: $ai, analyticsEnabled: $analyticsEnabled, onboardingStep: $onboardingStep)';
}


}

/// @nodoc
abstract mixin class $ConsentStateCopyWith<$Res>  {
  factory $ConsentStateCopyWith(ConsentState value, $Res Function(ConsentState) _then) = _$ConsentStateCopyWithImpl;
@useResult
$Res call({
 AdsConsent ads, TrackingStatus tracking, AiConsent ai, bool analyticsEnabled, OnboardingStep onboardingStep
});


$AdsConsentCopyWith<$Res> get ads;$AiConsentCopyWith<$Res> get ai;

}
/// @nodoc
class _$ConsentStateCopyWithImpl<$Res>
    implements $ConsentStateCopyWith<$Res> {
  _$ConsentStateCopyWithImpl(this._self, this._then);

  final ConsentState _self;
  final $Res Function(ConsentState) _then;

/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ads = null,Object? tracking = null,Object? ai = null,Object? analyticsEnabled = null,Object? onboardingStep = null,}) {
  return _then(_self.copyWith(
ads: null == ads ? _self.ads : ads // ignore: cast_nullable_to_non_nullable
as AdsConsent,tracking: null == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingStatus,ai: null == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as AiConsent,analyticsEnabled: null == analyticsEnabled ? _self.analyticsEnabled : analyticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingStep: null == onboardingStep ? _self.onboardingStep : onboardingStep // ignore: cast_nullable_to_non_nullable
as OnboardingStep,
  ));
}
/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdsConsentCopyWith<$Res> get ads {
  
  return $AdsConsentCopyWith<$Res>(_self.ads, (value) {
    return _then(_self.copyWith(ads: value));
  });
}/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiConsentCopyWith<$Res> get ai {
  
  return $AiConsentCopyWith<$Res>(_self.ai, (value) {
    return _then(_self.copyWith(ai: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConsentState].
extension ConsentStatePatterns on ConsentState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsentState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsentState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsentState value)  $default,){
final _that = this;
switch (_that) {
case _ConsentState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsentState value)?  $default,){
final _that = this;
switch (_that) {
case _ConsentState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdsConsent ads,  TrackingStatus tracking,  AiConsent ai,  bool analyticsEnabled,  OnboardingStep onboardingStep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsentState() when $default != null:
return $default(_that.ads,_that.tracking,_that.ai,_that.analyticsEnabled,_that.onboardingStep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdsConsent ads,  TrackingStatus tracking,  AiConsent ai,  bool analyticsEnabled,  OnboardingStep onboardingStep)  $default,) {final _that = this;
switch (_that) {
case _ConsentState():
return $default(_that.ads,_that.tracking,_that.ai,_that.analyticsEnabled,_that.onboardingStep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdsConsent ads,  TrackingStatus tracking,  AiConsent ai,  bool analyticsEnabled,  OnboardingStep onboardingStep)?  $default,) {final _that = this;
switch (_that) {
case _ConsentState() when $default != null:
return $default(_that.ads,_that.tracking,_that.ai,_that.analyticsEnabled,_that.onboardingStep);case _:
  return null;

}
}

}

/// @nodoc


class _ConsentState extends ConsentState {
  const _ConsentState({this.ads = const AdsConsent(), this.tracking = TrackingStatus.notDetermined, this.ai = const AiConsent(), this.analyticsEnabled = false, this.onboardingStep = OnboardingStep.welcome}): super._();
  

/// UMP state.
@override@JsonKey() final  AdsConsent ads;
/// ATT status.
@override@JsonKey() final  TrackingStatus tracking;
/// AI consent.
@override@JsonKey() final  AiConsent ai;
/// Whether analytics collection is on.
@override@JsonKey() final  bool analyticsEnabled;
/// The onboarding step to resume at.
@override@JsonKey() final  OnboardingStep onboardingStep;

/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentStateCopyWith<_ConsentState> get copyWith => __$ConsentStateCopyWithImpl<_ConsentState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsentState&&(identical(other.ads, ads) || other.ads == ads)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.ai, ai) || other.ai == ai)&&(identical(other.analyticsEnabled, analyticsEnabled) || other.analyticsEnabled == analyticsEnabled)&&(identical(other.onboardingStep, onboardingStep) || other.onboardingStep == onboardingStep));
}


@override
int get hashCode => Object.hash(runtimeType,ads,tracking,ai,analyticsEnabled,onboardingStep);

@override
String toString() {
  return 'ConsentState(ads: $ads, tracking: $tracking, ai: $ai, analyticsEnabled: $analyticsEnabled, onboardingStep: $onboardingStep)';
}


}

/// @nodoc
abstract mixin class _$ConsentStateCopyWith<$Res> implements $ConsentStateCopyWith<$Res> {
  factory _$ConsentStateCopyWith(_ConsentState value, $Res Function(_ConsentState) _then) = __$ConsentStateCopyWithImpl;
@override @useResult
$Res call({
 AdsConsent ads, TrackingStatus tracking, AiConsent ai, bool analyticsEnabled, OnboardingStep onboardingStep
});


@override $AdsConsentCopyWith<$Res> get ads;@override $AiConsentCopyWith<$Res> get ai;

}
/// @nodoc
class __$ConsentStateCopyWithImpl<$Res>
    implements _$ConsentStateCopyWith<$Res> {
  __$ConsentStateCopyWithImpl(this._self, this._then);

  final _ConsentState _self;
  final $Res Function(_ConsentState) _then;

/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ads = null,Object? tracking = null,Object? ai = null,Object? analyticsEnabled = null,Object? onboardingStep = null,}) {
  return _then(_ConsentState(
ads: null == ads ? _self.ads : ads // ignore: cast_nullable_to_non_nullable
as AdsConsent,tracking: null == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingStatus,ai: null == ai ? _self.ai : ai // ignore: cast_nullable_to_non_nullable
as AiConsent,analyticsEnabled: null == analyticsEnabled ? _self.analyticsEnabled : analyticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingStep: null == onboardingStep ? _self.onboardingStep : onboardingStep // ignore: cast_nullable_to_non_nullable
as OnboardingStep,
  ));
}

/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdsConsentCopyWith<$Res> get ads {
  
  return $AdsConsentCopyWith<$Res>(_self.ads, (value) {
    return _then(_self.copyWith(ads: value));
  });
}/// Create a copy of ConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiConsentCopyWith<$Res> get ai {
  
  return $AiConsentCopyWith<$Res>(_self.ai, (value) {
    return _then(_self.copyWith(ai: value));
  });
}
}

// dart format on
