// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_gate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaywallOptions {

/// Why the paywall opens.
 PaywallReason get reason;/// Enabled `store.packs` in `sortOrder`; empty when `store.enabled` is
/// off.
 List<StorePack> get packs;/// Whether a rewarded ad may be offered (RC34: only when
/// `free.remaining == 0`).
 bool get rewardedAvailable;/// When the next free reading arrives (`free.resetsAt`, server time);
/// `null` when no free reading is coming (low-trust cap, zero limit).
 DateTime? get nextFreeAt;
/// Create a copy of PaywallOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaywallOptionsCopyWith<PaywallOptions> get copyWith => _$PaywallOptionsCopyWithImpl<PaywallOptions>(this as PaywallOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaywallOptions&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.packs, packs)&&(identical(other.rewardedAvailable, rewardedAvailable) || other.rewardedAvailable == rewardedAvailable)&&(identical(other.nextFreeAt, nextFreeAt) || other.nextFreeAt == nextFreeAt));
}


@override
int get hashCode => Object.hash(runtimeType,reason,const DeepCollectionEquality().hash(packs),rewardedAvailable,nextFreeAt);

@override
String toString() {
  return 'PaywallOptions(reason: $reason, packs: $packs, rewardedAvailable: $rewardedAvailable, nextFreeAt: $nextFreeAt)';
}


}

/// @nodoc
abstract mixin class $PaywallOptionsCopyWith<$Res>  {
  factory $PaywallOptionsCopyWith(PaywallOptions value, $Res Function(PaywallOptions) _then) = _$PaywallOptionsCopyWithImpl;
@useResult
$Res call({
 PaywallReason reason, List<StorePack> packs, bool rewardedAvailable, DateTime? nextFreeAt
});




}
/// @nodoc
class _$PaywallOptionsCopyWithImpl<$Res>
    implements $PaywallOptionsCopyWith<$Res> {
  _$PaywallOptionsCopyWithImpl(this._self, this._then);

  final PaywallOptions _self;
  final $Res Function(PaywallOptions) _then;

/// Create a copy of PaywallOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,Object? packs = null,Object? rewardedAvailable = null,Object? nextFreeAt = freezed,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PaywallReason,packs: null == packs ? _self.packs : packs // ignore: cast_nullable_to_non_nullable
as List<StorePack>,rewardedAvailable: null == rewardedAvailable ? _self.rewardedAvailable : rewardedAvailable // ignore: cast_nullable_to_non_nullable
as bool,nextFreeAt: freezed == nextFreeAt ? _self.nextFreeAt : nextFreeAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaywallOptions].
extension PaywallOptionsPatterns on PaywallOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaywallOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaywallOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaywallOptions value)  $default,){
final _that = this;
switch (_that) {
case _PaywallOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaywallOptions value)?  $default,){
final _that = this;
switch (_that) {
case _PaywallOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaywallReason reason,  List<StorePack> packs,  bool rewardedAvailable,  DateTime? nextFreeAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaywallOptions() when $default != null:
return $default(_that.reason,_that.packs,_that.rewardedAvailable,_that.nextFreeAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaywallReason reason,  List<StorePack> packs,  bool rewardedAvailable,  DateTime? nextFreeAt)  $default,) {final _that = this;
switch (_that) {
case _PaywallOptions():
return $default(_that.reason,_that.packs,_that.rewardedAvailable,_that.nextFreeAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaywallReason reason,  List<StorePack> packs,  bool rewardedAvailable,  DateTime? nextFreeAt)?  $default,) {final _that = this;
switch (_that) {
case _PaywallOptions() when $default != null:
return $default(_that.reason,_that.packs,_that.rewardedAvailable,_that.nextFreeAt);case _:
  return null;

}
}

}

/// @nodoc


class _PaywallOptions implements PaywallOptions {
  const _PaywallOptions({required this.reason, required final  List<StorePack> packs, required this.rewardedAvailable, required this.nextFreeAt}): _packs = packs;
  

/// Why the paywall opens.
@override final  PaywallReason reason;
/// Enabled `store.packs` in `sortOrder`; empty when `store.enabled` is
/// off.
 final  List<StorePack> _packs;
/// Enabled `store.packs` in `sortOrder`; empty when `store.enabled` is
/// off.
@override List<StorePack> get packs {
  if (_packs is EqualUnmodifiableListView) return _packs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_packs);
}

/// Whether a rewarded ad may be offered (RC34: only when
/// `free.remaining == 0`).
@override final  bool rewardedAvailable;
/// When the next free reading arrives (`free.resetsAt`, server time);
/// `null` when no free reading is coming (low-trust cap, zero limit).
@override final  DateTime? nextFreeAt;

/// Create a copy of PaywallOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaywallOptionsCopyWith<_PaywallOptions> get copyWith => __$PaywallOptionsCopyWithImpl<_PaywallOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaywallOptions&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._packs, _packs)&&(identical(other.rewardedAvailable, rewardedAvailable) || other.rewardedAvailable == rewardedAvailable)&&(identical(other.nextFreeAt, nextFreeAt) || other.nextFreeAt == nextFreeAt));
}


@override
int get hashCode => Object.hash(runtimeType,reason,const DeepCollectionEquality().hash(_packs),rewardedAvailable,nextFreeAt);

@override
String toString() {
  return 'PaywallOptions(reason: $reason, packs: $packs, rewardedAvailable: $rewardedAvailable, nextFreeAt: $nextFreeAt)';
}


}

/// @nodoc
abstract mixin class _$PaywallOptionsCopyWith<$Res> implements $PaywallOptionsCopyWith<$Res> {
  factory _$PaywallOptionsCopyWith(_PaywallOptions value, $Res Function(_PaywallOptions) _then) = __$PaywallOptionsCopyWithImpl;
@override @useResult
$Res call({
 PaywallReason reason, List<StorePack> packs, bool rewardedAvailable, DateTime? nextFreeAt
});




}
/// @nodoc
class __$PaywallOptionsCopyWithImpl<$Res>
    implements _$PaywallOptionsCopyWith<$Res> {
  __$PaywallOptionsCopyWithImpl(this._self, this._then);

  final _PaywallOptions _self;
  final $Res Function(_PaywallOptions) _then;

/// Create a copy of PaywallOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? packs = null,Object? rewardedAvailable = null,Object? nextFreeAt = freezed,}) {
  return _then(_PaywallOptions(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as PaywallReason,packs: null == packs ? _self._packs : packs // ignore: cast_nullable_to_non_nullable
as List<StorePack>,rewardedAvailable: null == rewardedAvailable ? _self.rewardedAvailable : rewardedAvailable // ignore: cast_nullable_to_non_nullable
as bool,nextFreeAt: freezed == nextFreeAt ? _self.nextFreeAt : nextFreeAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$GateDecision {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateDecision);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision()';
}


}

/// @nodoc
class $GateDecisionCopyWith<$Res>  {
$GateDecisionCopyWith(GateDecision _, $Res Function(GateDecision) __);
}


/// Adds pattern-matching-related methods to [GateDecision].
extension GateDecisionPatterns on GateDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GateDeviceUnverified value)?  deviceUnverified,TResult Function( GateNeedsAiConsent value)?  needsAiConsent,TResult Function( GateOffline value)?  offline,TResult Function( GateReadingsPaused value)?  readingsPaused,TResult Function( GateAiUnavailableRegion value)?  aiUnavailableRegion,TResult Function( GateSpreadDisabled value)?  spreadDisabled,TResult Function( GateNeedsCredits value)?  needsCredits,TResult Function( GateDailyLimitReached value)?  dailyLimitReached,TResult Function( GateNeedsSync value)?  needsSync,TResult Function( GateAllowed value)?  allowed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GateDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that);case GateNeedsAiConsent() when needsAiConsent != null:
return needsAiConsent(_that);case GateOffline() when offline != null:
return offline(_that);case GateReadingsPaused() when readingsPaused != null:
return readingsPaused(_that);case GateAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case GateSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that);case GateNeedsCredits() when needsCredits != null:
return needsCredits(_that);case GateDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that);case GateNeedsSync() when needsSync != null:
return needsSync(_that);case GateAllowed() when allowed != null:
return allowed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GateDeviceUnverified value)  deviceUnverified,required TResult Function( GateNeedsAiConsent value)  needsAiConsent,required TResult Function( GateOffline value)  offline,required TResult Function( GateReadingsPaused value)  readingsPaused,required TResult Function( GateAiUnavailableRegion value)  aiUnavailableRegion,required TResult Function( GateSpreadDisabled value)  spreadDisabled,required TResult Function( GateNeedsCredits value)  needsCredits,required TResult Function( GateDailyLimitReached value)  dailyLimitReached,required TResult Function( GateNeedsSync value)  needsSync,required TResult Function( GateAllowed value)  allowed,}){
final _that = this;
switch (_that) {
case GateDeviceUnverified():
return deviceUnverified(_that);case GateNeedsAiConsent():
return needsAiConsent(_that);case GateOffline():
return offline(_that);case GateReadingsPaused():
return readingsPaused(_that);case GateAiUnavailableRegion():
return aiUnavailableRegion(_that);case GateSpreadDisabled():
return spreadDisabled(_that);case GateNeedsCredits():
return needsCredits(_that);case GateDailyLimitReached():
return dailyLimitReached(_that);case GateNeedsSync():
return needsSync(_that);case GateAllowed():
return allowed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GateDeviceUnverified value)?  deviceUnverified,TResult? Function( GateNeedsAiConsent value)?  needsAiConsent,TResult? Function( GateOffline value)?  offline,TResult? Function( GateReadingsPaused value)?  readingsPaused,TResult? Function( GateAiUnavailableRegion value)?  aiUnavailableRegion,TResult? Function( GateSpreadDisabled value)?  spreadDisabled,TResult? Function( GateNeedsCredits value)?  needsCredits,TResult? Function( GateDailyLimitReached value)?  dailyLimitReached,TResult? Function( GateNeedsSync value)?  needsSync,TResult? Function( GateAllowed value)?  allowed,}){
final _that = this;
switch (_that) {
case GateDeviceUnverified() when deviceUnverified != null:
return deviceUnverified(_that);case GateNeedsAiConsent() when needsAiConsent != null:
return needsAiConsent(_that);case GateOffline() when offline != null:
return offline(_that);case GateReadingsPaused() when readingsPaused != null:
return readingsPaused(_that);case GateAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion(_that);case GateSpreadDisabled() when spreadDisabled != null:
return spreadDisabled(_that);case GateNeedsCredits() when needsCredits != null:
return needsCredits(_that);case GateDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached(_that);case GateNeedsSync() when needsSync != null:
return needsSync(_that);case GateAllowed() when allowed != null:
return allowed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  deviceUnverified,TResult Function()?  needsAiConsent,TResult Function()?  offline,TResult Function( bool freePaused)?  readingsPaused,TResult Function()?  aiUnavailableRegion,TResult Function()?  spreadDisabled,TResult Function( PaywallOptions options)?  needsCredits,TResult Function()?  dailyLimitReached,TResult Function()?  needsSync,TResult Function( ChargeSource expected)?  allowed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GateDeviceUnverified() when deviceUnverified != null:
return deviceUnverified();case GateNeedsAiConsent() when needsAiConsent != null:
return needsAiConsent();case GateOffline() when offline != null:
return offline();case GateReadingsPaused() when readingsPaused != null:
return readingsPaused(_that.freePaused);case GateAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion();case GateSpreadDisabled() when spreadDisabled != null:
return spreadDisabled();case GateNeedsCredits() when needsCredits != null:
return needsCredits(_that.options);case GateDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached();case GateNeedsSync() when needsSync != null:
return needsSync();case GateAllowed() when allowed != null:
return allowed(_that.expected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  deviceUnverified,required TResult Function()  needsAiConsent,required TResult Function()  offline,required TResult Function( bool freePaused)  readingsPaused,required TResult Function()  aiUnavailableRegion,required TResult Function()  spreadDisabled,required TResult Function( PaywallOptions options)  needsCredits,required TResult Function()  dailyLimitReached,required TResult Function()  needsSync,required TResult Function( ChargeSource expected)  allowed,}) {final _that = this;
switch (_that) {
case GateDeviceUnverified():
return deviceUnverified();case GateNeedsAiConsent():
return needsAiConsent();case GateOffline():
return offline();case GateReadingsPaused():
return readingsPaused(_that.freePaused);case GateAiUnavailableRegion():
return aiUnavailableRegion();case GateSpreadDisabled():
return spreadDisabled();case GateNeedsCredits():
return needsCredits(_that.options);case GateDailyLimitReached():
return dailyLimitReached();case GateNeedsSync():
return needsSync();case GateAllowed():
return allowed(_that.expected);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  deviceUnverified,TResult? Function()?  needsAiConsent,TResult? Function()?  offline,TResult? Function( bool freePaused)?  readingsPaused,TResult? Function()?  aiUnavailableRegion,TResult? Function()?  spreadDisabled,TResult? Function( PaywallOptions options)?  needsCredits,TResult? Function()?  dailyLimitReached,TResult? Function()?  needsSync,TResult? Function( ChargeSource expected)?  allowed,}) {final _that = this;
switch (_that) {
case GateDeviceUnverified() when deviceUnverified != null:
return deviceUnverified();case GateNeedsAiConsent() when needsAiConsent != null:
return needsAiConsent();case GateOffline() when offline != null:
return offline();case GateReadingsPaused() when readingsPaused != null:
return readingsPaused(_that.freePaused);case GateAiUnavailableRegion() when aiUnavailableRegion != null:
return aiUnavailableRegion();case GateSpreadDisabled() when spreadDisabled != null:
return spreadDisabled();case GateNeedsCredits() when needsCredits != null:
return needsCredits(_that.options);case GateDailyLimitReached() when dailyLimitReached != null:
return dailyLimitReached();case GateNeedsSync() when needsSync != null:
return needsSync();case GateAllowed() when allowed != null:
return allowed(_that.expected);case _:
  return null;

}
}

}

/// @nodoc


class GateDeviceUnverified extends GateDecision {
  const GateDeviceUnverified(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateDeviceUnverified);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.deviceUnverified()';
}


}




/// @nodoc


class GateNeedsAiConsent extends GateDecision {
  const GateNeedsAiConsent(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateNeedsAiConsent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.needsAiConsent()';
}


}




/// @nodoc


class GateOffline extends GateDecision {
  const GateOffline(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.offline()';
}


}




/// @nodoc


class GateReadingsPaused extends GateDecision {
  const GateReadingsPaused({this.freePaused = false}): super._();
  

@JsonKey() final  bool freePaused;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GateReadingsPausedCopyWith<GateReadingsPaused> get copyWith => _$GateReadingsPausedCopyWithImpl<GateReadingsPaused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateReadingsPaused&&(identical(other.freePaused, freePaused) || other.freePaused == freePaused));
}


@override
int get hashCode => Object.hash(runtimeType,freePaused);

@override
String toString() {
  return 'GateDecision.readingsPaused(freePaused: $freePaused)';
}


}

/// @nodoc
abstract mixin class $GateReadingsPausedCopyWith<$Res> implements $GateDecisionCopyWith<$Res> {
  factory $GateReadingsPausedCopyWith(GateReadingsPaused value, $Res Function(GateReadingsPaused) _then) = _$GateReadingsPausedCopyWithImpl;
@useResult
$Res call({
 bool freePaused
});




}
/// @nodoc
class _$GateReadingsPausedCopyWithImpl<$Res>
    implements $GateReadingsPausedCopyWith<$Res> {
  _$GateReadingsPausedCopyWithImpl(this._self, this._then);

  final GateReadingsPaused _self;
  final $Res Function(GateReadingsPaused) _then;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? freePaused = null,}) {
  return _then(GateReadingsPaused(
freePaused: null == freePaused ? _self.freePaused : freePaused // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class GateAiUnavailableRegion extends GateDecision {
  const GateAiUnavailableRegion(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateAiUnavailableRegion);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.aiUnavailableRegion()';
}


}




/// @nodoc


class GateSpreadDisabled extends GateDecision {
  const GateSpreadDisabled(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateSpreadDisabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.spreadDisabled()';
}


}




/// @nodoc


class GateNeedsCredits extends GateDecision {
  const GateNeedsCredits(this.options): super._();
  

 final  PaywallOptions options;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GateNeedsCreditsCopyWith<GateNeedsCredits> get copyWith => _$GateNeedsCreditsCopyWithImpl<GateNeedsCredits>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateNeedsCredits&&(identical(other.options, options) || other.options == options));
}


@override
int get hashCode => Object.hash(runtimeType,options);

@override
String toString() {
  return 'GateDecision.needsCredits(options: $options)';
}


}

/// @nodoc
abstract mixin class $GateNeedsCreditsCopyWith<$Res> implements $GateDecisionCopyWith<$Res> {
  factory $GateNeedsCreditsCopyWith(GateNeedsCredits value, $Res Function(GateNeedsCredits) _then) = _$GateNeedsCreditsCopyWithImpl;
@useResult
$Res call({
 PaywallOptions options
});


$PaywallOptionsCopyWith<$Res> get options;

}
/// @nodoc
class _$GateNeedsCreditsCopyWithImpl<$Res>
    implements $GateNeedsCreditsCopyWith<$Res> {
  _$GateNeedsCreditsCopyWithImpl(this._self, this._then);

  final GateNeedsCredits _self;
  final $Res Function(GateNeedsCredits) _then;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? options = null,}) {
  return _then(GateNeedsCredits(
null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as PaywallOptions,
  ));
}

/// Create a copy of GateDecision
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


class GateDailyLimitReached extends GateDecision {
  const GateDailyLimitReached(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateDailyLimitReached);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.dailyLimitReached()';
}


}




/// @nodoc


class GateNeedsSync extends GateDecision {
  const GateNeedsSync(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateNeedsSync);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GateDecision.needsSync()';
}


}




/// @nodoc


class GateAllowed extends GateDecision {
  const GateAllowed(this.expected): super._();
  

 final  ChargeSource expected;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GateAllowedCopyWith<GateAllowed> get copyWith => _$GateAllowedCopyWithImpl<GateAllowed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GateAllowed&&(identical(other.expected, expected) || other.expected == expected));
}


@override
int get hashCode => Object.hash(runtimeType,expected);

@override
String toString() {
  return 'GateDecision.allowed(expected: $expected)';
}


}

/// @nodoc
abstract mixin class $GateAllowedCopyWith<$Res> implements $GateDecisionCopyWith<$Res> {
  factory $GateAllowedCopyWith(GateAllowed value, $Res Function(GateAllowed) _then) = _$GateAllowedCopyWithImpl;
@useResult
$Res call({
 ChargeSource expected
});




}
/// @nodoc
class _$GateAllowedCopyWithImpl<$Res>
    implements $GateAllowedCopyWith<$Res> {
  _$GateAllowedCopyWithImpl(this._self, this._then);

  final GateAllowed _self;
  final $Res Function(GateAllowed) _then;

/// Create a copy of GateDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? expected = null,}) {
  return _then(GateAllowed(
null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as ChargeSource,
  ));
}


}

// dart format on
