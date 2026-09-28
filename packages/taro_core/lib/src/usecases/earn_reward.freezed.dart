// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earn_reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RewardOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardOutcome()';
}


}

/// @nodoc
class $RewardOutcomeCopyWith<$Res>  {
$RewardOutcomeCopyWith(RewardOutcome _, $Res Function(RewardOutcome) __);
}


/// Adds pattern-matching-related methods to [RewardOutcome].
extension RewardOutcomePatterns on RewardOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RewardGranted value)?  granted,TResult Function( RewardDelayed value)?  delayed,TResult Function( RewardDismissed value)?  dismissed,TResult Function( RewardNotGranted value)?  notGranted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RewardGranted() when granted != null:
return granted(_that);case RewardDelayed() when delayed != null:
return delayed(_that);case RewardDismissed() when dismissed != null:
return dismissed(_that);case RewardNotGranted() when notGranted != null:
return notGranted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RewardGranted value)  granted,required TResult Function( RewardDelayed value)  delayed,required TResult Function( RewardDismissed value)  dismissed,required TResult Function( RewardNotGranted value)  notGranted,}){
final _that = this;
switch (_that) {
case RewardGranted():
return granted(_that);case RewardDelayed():
return delayed(_that);case RewardDismissed():
return dismissed(_that);case RewardNotGranted():
return notGranted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RewardGranted value)?  granted,TResult? Function( RewardDelayed value)?  delayed,TResult? Function( RewardDismissed value)?  dismissed,TResult? Function( RewardNotGranted value)?  notGranted,}){
final _that = this;
switch (_that) {
case RewardGranted() when granted != null:
return granted(_that);case RewardDelayed() when delayed != null:
return delayed(_that);case RewardDismissed() when dismissed != null:
return dismissed(_that);case RewardNotGranted() when notGranted != null:
return notGranted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int amount)?  granted,TResult Function()?  delayed,TResult Function()?  dismissed,TResult Function( RewardIntentState state)?  notGranted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RewardGranted() when granted != null:
return granted(_that.amount);case RewardDelayed() when delayed != null:
return delayed();case RewardDismissed() when dismissed != null:
return dismissed();case RewardNotGranted() when notGranted != null:
return notGranted(_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int amount)  granted,required TResult Function()  delayed,required TResult Function()  dismissed,required TResult Function( RewardIntentState state)  notGranted,}) {final _that = this;
switch (_that) {
case RewardGranted():
return granted(_that.amount);case RewardDelayed():
return delayed();case RewardDismissed():
return dismissed();case RewardNotGranted():
return notGranted(_that.state);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int amount)?  granted,TResult? Function()?  delayed,TResult? Function()?  dismissed,TResult? Function( RewardIntentState state)?  notGranted,}) {final _that = this;
switch (_that) {
case RewardGranted() when granted != null:
return granted(_that.amount);case RewardDelayed() when delayed != null:
return delayed();case RewardDismissed() when dismissed != null:
return dismissed();case RewardNotGranted() when notGranted != null:
return notGranted(_that.state);case _:
  return null;

}
}

}

/// @nodoc


class RewardGranted implements RewardOutcome {
  const RewardGranted({required this.amount});
  

 final  int amount;

/// Create a copy of RewardOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardGrantedCopyWith<RewardGranted> get copyWith => _$RewardGrantedCopyWithImpl<RewardGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardGranted&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,amount);

@override
String toString() {
  return 'RewardOutcome.granted(amount: $amount)';
}


}

/// @nodoc
abstract mixin class $RewardGrantedCopyWith<$Res> implements $RewardOutcomeCopyWith<$Res> {
  factory $RewardGrantedCopyWith(RewardGranted value, $Res Function(RewardGranted) _then) = _$RewardGrantedCopyWithImpl;
@useResult
$Res call({
 int amount
});




}
/// @nodoc
class _$RewardGrantedCopyWithImpl<$Res>
    implements $RewardGrantedCopyWith<$Res> {
  _$RewardGrantedCopyWithImpl(this._self, this._then);

  final RewardGranted _self;
  final $Res Function(RewardGranted) _then;

/// Create a copy of RewardOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,}) {
  return _then(RewardGranted(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RewardDelayed implements RewardOutcome {
  const RewardDelayed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardDelayed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardOutcome.delayed()';
}


}




/// @nodoc


class RewardDismissed implements RewardOutcome {
  const RewardDismissed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardDismissed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardOutcome.dismissed()';
}


}




/// @nodoc


class RewardNotGranted implements RewardOutcome {
  const RewardNotGranted(this.state);
  

 final  RewardIntentState state;

/// Create a copy of RewardOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardNotGrantedCopyWith<RewardNotGranted> get copyWith => _$RewardNotGrantedCopyWithImpl<RewardNotGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardNotGranted&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,state);

@override
String toString() {
  return 'RewardOutcome.notGranted(state: $state)';
}


}

/// @nodoc
abstract mixin class $RewardNotGrantedCopyWith<$Res> implements $RewardOutcomeCopyWith<$Res> {
  factory $RewardNotGrantedCopyWith(RewardNotGranted value, $Res Function(RewardNotGranted) _then) = _$RewardNotGrantedCopyWithImpl;
@useResult
$Res call({
 RewardIntentState state
});




}
/// @nodoc
class _$RewardNotGrantedCopyWithImpl<$Res>
    implements $RewardNotGrantedCopyWith<$Res> {
  _$RewardNotGrantedCopyWithImpl(this._self, this._then);

  final RewardNotGranted _self;
  final $Res Function(RewardNotGranted) _then;

/// Create a copy of RewardOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? state = null,}) {
  return _then(RewardNotGranted(
null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as RewardIntentState,
  ));
}


}

// dart format on
