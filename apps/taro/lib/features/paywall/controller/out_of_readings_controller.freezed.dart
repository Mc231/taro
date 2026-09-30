// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'out_of_readings_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutOfReadingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutOfReadingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OutOfReadingsState()';
}


}

/// @nodoc
class $OutOfReadingsStateCopyWith<$Res>  {
$OutOfReadingsStateCopyWith(OutOfReadingsState _, $Res Function(OutOfReadingsState) __);
}


/// Adds pattern-matching-related methods to [OutOfReadingsState].
extension OutOfReadingsStatePatterns on OutOfReadingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OutOfReadingsContent value)?  content,TResult Function( OutOfReadingsResolved value)?  resolved,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OutOfReadingsContent() when content != null:
return content(_that);case OutOfReadingsResolved() when resolved != null:
return resolved(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OutOfReadingsContent value)  content,required TResult Function( OutOfReadingsResolved value)  resolved,}){
final _that = this;
switch (_that) {
case OutOfReadingsContent():
return content(_that);case OutOfReadingsResolved():
return resolved(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OutOfReadingsContent value)?  content,TResult? Function( OutOfReadingsResolved value)?  resolved,}){
final _that = this;
switch (_that) {
case OutOfReadingsContent() when content != null:
return content(_that);case OutOfReadingsResolved() when resolved != null:
return resolved(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RewardedOption rewarded,  PaywallPacks packs,  bool lowTrustLimited,  Duration? nextFreeIn,  DateTime? nextFreeAt)?  content,TResult Function()?  resolved,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OutOfReadingsContent() when content != null:
return content(_that.rewarded,_that.packs,_that.lowTrustLimited,_that.nextFreeIn,_that.nextFreeAt);case OutOfReadingsResolved() when resolved != null:
return resolved();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RewardedOption rewarded,  PaywallPacks packs,  bool lowTrustLimited,  Duration? nextFreeIn,  DateTime? nextFreeAt)  content,required TResult Function()  resolved,}) {final _that = this;
switch (_that) {
case OutOfReadingsContent():
return content(_that.rewarded,_that.packs,_that.lowTrustLimited,_that.nextFreeIn,_that.nextFreeAt);case OutOfReadingsResolved():
return resolved();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RewardedOption rewarded,  PaywallPacks packs,  bool lowTrustLimited,  Duration? nextFreeIn,  DateTime? nextFreeAt)?  content,TResult? Function()?  resolved,}) {final _that = this;
switch (_that) {
case OutOfReadingsContent() when content != null:
return content(_that.rewarded,_that.packs,_that.lowTrustLimited,_that.nextFreeIn,_that.nextFreeAt);case OutOfReadingsResolved() when resolved != null:
return resolved();case _:
  return null;

}
}

}

/// @nodoc


class OutOfReadingsContent implements OutOfReadingsState {
  const OutOfReadingsContent({required this.rewarded, required this.packs, required this.lowTrustLimited, this.nextFreeIn, this.nextFreeAt});
  

/// The rewarded row (RC34, RC35).
 final  RewardedOption rewarded;
/// The pack area.
 final  PaywallPacks packs;
/// The `lowTrustLimited` copy variant (RC74): "Free readings aren't
/// available on this device right now".
 final  bool lowTrustLimited;
/// Time until the next free reading, from server time (`free.resetsAt`,
/// 01 §7.1); `null` before the first balance.
 final  Duration? nextFreeIn;
/// The reset instant on the device clock ("at 00:00").
 final  DateTime? nextFreeAt;

/// Create a copy of OutOfReadingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutOfReadingsContentCopyWith<OutOfReadingsContent> get copyWith => _$OutOfReadingsContentCopyWithImpl<OutOfReadingsContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutOfReadingsContent&&(identical(other.rewarded, rewarded) || other.rewarded == rewarded)&&(identical(other.packs, packs) || other.packs == packs)&&(identical(other.lowTrustLimited, lowTrustLimited) || other.lowTrustLimited == lowTrustLimited)&&(identical(other.nextFreeIn, nextFreeIn) || other.nextFreeIn == nextFreeIn)&&(identical(other.nextFreeAt, nextFreeAt) || other.nextFreeAt == nextFreeAt));
}


@override
int get hashCode => Object.hash(runtimeType,rewarded,packs,lowTrustLimited,nextFreeIn,nextFreeAt);

@override
String toString() {
  return 'OutOfReadingsState.content(rewarded: $rewarded, packs: $packs, lowTrustLimited: $lowTrustLimited, nextFreeIn: $nextFreeIn, nextFreeAt: $nextFreeAt)';
}


}

/// @nodoc
abstract mixin class $OutOfReadingsContentCopyWith<$Res> implements $OutOfReadingsStateCopyWith<$Res> {
  factory $OutOfReadingsContentCopyWith(OutOfReadingsContent value, $Res Function(OutOfReadingsContent) _then) = _$OutOfReadingsContentCopyWithImpl;
@useResult
$Res call({
 RewardedOption rewarded, PaywallPacks packs, bool lowTrustLimited, Duration? nextFreeIn, DateTime? nextFreeAt
});


$RewardedOptionCopyWith<$Res> get rewarded;$PaywallPacksCopyWith<$Res> get packs;

}
/// @nodoc
class _$OutOfReadingsContentCopyWithImpl<$Res>
    implements $OutOfReadingsContentCopyWith<$Res> {
  _$OutOfReadingsContentCopyWithImpl(this._self, this._then);

  final OutOfReadingsContent _self;
  final $Res Function(OutOfReadingsContent) _then;

/// Create a copy of OutOfReadingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rewarded = null,Object? packs = null,Object? lowTrustLimited = null,Object? nextFreeIn = freezed,Object? nextFreeAt = freezed,}) {
  return _then(OutOfReadingsContent(
rewarded: null == rewarded ? _self.rewarded : rewarded // ignore: cast_nullable_to_non_nullable
as RewardedOption,packs: null == packs ? _self.packs : packs // ignore: cast_nullable_to_non_nullable
as PaywallPacks,lowTrustLimited: null == lowTrustLimited ? _self.lowTrustLimited : lowTrustLimited // ignore: cast_nullable_to_non_nullable
as bool,nextFreeIn: freezed == nextFreeIn ? _self.nextFreeIn : nextFreeIn // ignore: cast_nullable_to_non_nullable
as Duration?,nextFreeAt: freezed == nextFreeAt ? _self.nextFreeAt : nextFreeAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OutOfReadingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RewardedOptionCopyWith<$Res> get rewarded {
  
  return $RewardedOptionCopyWith<$Res>(_self.rewarded, (value) {
    return _then(_self.copyWith(rewarded: value));
  });
}/// Create a copy of OutOfReadingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaywallPacksCopyWith<$Res> get packs {
  
  return $PaywallPacksCopyWith<$Res>(_self.packs, (value) {
    return _then(_self.copyWith(packs: value));
  });
}
}

/// @nodoc


class OutOfReadingsResolved implements OutOfReadingsState {
  const OutOfReadingsResolved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutOfReadingsResolved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OutOfReadingsState.resolved()';
}


}




// dart format on
