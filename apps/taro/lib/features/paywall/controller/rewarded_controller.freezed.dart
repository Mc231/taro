// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rewarded_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RewardedState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState()';
}


}

/// @nodoc
class $RewardedStateCopyWith<$Res>  {
$RewardedStateCopyWith(RewardedState _, $Res Function(RewardedState) __);
}


/// Adds pattern-matching-related methods to [RewardedState].
extension RewardedStatePatterns on RewardedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RewardedLoadingAd value)?  loadingAd,TResult Function( RewardedShowing value)?  showing,TResult Function( RewardedGranting value)?  granting,TResult Function( RewardedGranted value)?  granted,TResult Function( RewardedGrantDelayed value)?  grantDelayed,TResult Function( RewardedDismissedEarly value)?  dismissedEarly,TResult Function( RewardedNoFill value)?  noFill,TResult Function( RewardedUnavailable value)?  unavailable,TResult Function( RewardedFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RewardedLoadingAd() when loadingAd != null:
return loadingAd(_that);case RewardedShowing() when showing != null:
return showing(_that);case RewardedGranting() when granting != null:
return granting(_that);case RewardedGranted() when granted != null:
return granted(_that);case RewardedGrantDelayed() when grantDelayed != null:
return grantDelayed(_that);case RewardedDismissedEarly() when dismissedEarly != null:
return dismissedEarly(_that);case RewardedNoFill() when noFill != null:
return noFill(_that);case RewardedUnavailable() when unavailable != null:
return unavailable(_that);case RewardedFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RewardedLoadingAd value)  loadingAd,required TResult Function( RewardedShowing value)  showing,required TResult Function( RewardedGranting value)  granting,required TResult Function( RewardedGranted value)  granted,required TResult Function( RewardedGrantDelayed value)  grantDelayed,required TResult Function( RewardedDismissedEarly value)  dismissedEarly,required TResult Function( RewardedNoFill value)  noFill,required TResult Function( RewardedUnavailable value)  unavailable,required TResult Function( RewardedFailed value)  failed,}){
final _that = this;
switch (_that) {
case RewardedLoadingAd():
return loadingAd(_that);case RewardedShowing():
return showing(_that);case RewardedGranting():
return granting(_that);case RewardedGranted():
return granted(_that);case RewardedGrantDelayed():
return grantDelayed(_that);case RewardedDismissedEarly():
return dismissedEarly(_that);case RewardedNoFill():
return noFill(_that);case RewardedUnavailable():
return unavailable(_that);case RewardedFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RewardedLoadingAd value)?  loadingAd,TResult? Function( RewardedShowing value)?  showing,TResult? Function( RewardedGranting value)?  granting,TResult? Function( RewardedGranted value)?  granted,TResult? Function( RewardedGrantDelayed value)?  grantDelayed,TResult? Function( RewardedDismissedEarly value)?  dismissedEarly,TResult? Function( RewardedNoFill value)?  noFill,TResult? Function( RewardedUnavailable value)?  unavailable,TResult? Function( RewardedFailed value)?  failed,}){
final _that = this;
switch (_that) {
case RewardedLoadingAd() when loadingAd != null:
return loadingAd(_that);case RewardedShowing() when showing != null:
return showing(_that);case RewardedGranting() when granting != null:
return granting(_that);case RewardedGranted() when granted != null:
return granted(_that);case RewardedGrantDelayed() when grantDelayed != null:
return grantDelayed(_that);case RewardedDismissedEarly() when dismissedEarly != null:
return dismissedEarly(_that);case RewardedNoFill() when noFill != null:
return noFill(_that);case RewardedUnavailable() when unavailable != null:
return unavailable(_that);case RewardedFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadingAd,TResult Function()?  showing,TResult Function()?  granting,TResult Function( int amount)?  granted,TResult Function()?  grantDelayed,TResult Function()?  dismissedEarly,TResult Function()?  noFill,TResult Function( RewardUnavailableReason reason)?  unavailable,TResult Function( ErrorKind kind)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RewardedLoadingAd() when loadingAd != null:
return loadingAd();case RewardedShowing() when showing != null:
return showing();case RewardedGranting() when granting != null:
return granting();case RewardedGranted() when granted != null:
return granted(_that.amount);case RewardedGrantDelayed() when grantDelayed != null:
return grantDelayed();case RewardedDismissedEarly() when dismissedEarly != null:
return dismissedEarly();case RewardedNoFill() when noFill != null:
return noFill();case RewardedUnavailable() when unavailable != null:
return unavailable(_that.reason);case RewardedFailed() when failed != null:
return failed(_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadingAd,required TResult Function()  showing,required TResult Function()  granting,required TResult Function( int amount)  granted,required TResult Function()  grantDelayed,required TResult Function()  dismissedEarly,required TResult Function()  noFill,required TResult Function( RewardUnavailableReason reason)  unavailable,required TResult Function( ErrorKind kind)  failed,}) {final _that = this;
switch (_that) {
case RewardedLoadingAd():
return loadingAd();case RewardedShowing():
return showing();case RewardedGranting():
return granting();case RewardedGranted():
return granted(_that.amount);case RewardedGrantDelayed():
return grantDelayed();case RewardedDismissedEarly():
return dismissedEarly();case RewardedNoFill():
return noFill();case RewardedUnavailable():
return unavailable(_that.reason);case RewardedFailed():
return failed(_that.kind);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadingAd,TResult? Function()?  showing,TResult? Function()?  granting,TResult? Function( int amount)?  granted,TResult? Function()?  grantDelayed,TResult? Function()?  dismissedEarly,TResult? Function()?  noFill,TResult? Function( RewardUnavailableReason reason)?  unavailable,TResult? Function( ErrorKind kind)?  failed,}) {final _that = this;
switch (_that) {
case RewardedLoadingAd() when loadingAd != null:
return loadingAd();case RewardedShowing() when showing != null:
return showing();case RewardedGranting() when granting != null:
return granting();case RewardedGranted() when granted != null:
return granted(_that.amount);case RewardedGrantDelayed() when grantDelayed != null:
return grantDelayed();case RewardedDismissedEarly() when dismissedEarly != null:
return dismissedEarly();case RewardedNoFill() when noFill != null:
return noFill();case RewardedUnavailable() when unavailable != null:
return unavailable(_that.reason);case RewardedFailed() when failed != null:
return failed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class RewardedLoadingAd implements RewardedState {
  const RewardedLoadingAd();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedLoadingAd);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.loadingAd()';
}


}




/// @nodoc


class RewardedShowing implements RewardedState {
  const RewardedShowing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedShowing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.showing()';
}


}




/// @nodoc


class RewardedGranting implements RewardedState {
  const RewardedGranting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedGranting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.granting()';
}


}




/// @nodoc


class RewardedGranted implements RewardedState {
  const RewardedGranted({required this.amount});
  

 final  int amount;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedGrantedCopyWith<RewardedGranted> get copyWith => _$RewardedGrantedCopyWithImpl<RewardedGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedGranted&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,amount);

@override
String toString() {
  return 'RewardedState.granted(amount: $amount)';
}


}

/// @nodoc
abstract mixin class $RewardedGrantedCopyWith<$Res> implements $RewardedStateCopyWith<$Res> {
  factory $RewardedGrantedCopyWith(RewardedGranted value, $Res Function(RewardedGranted) _then) = _$RewardedGrantedCopyWithImpl;
@useResult
$Res call({
 int amount
});




}
/// @nodoc
class _$RewardedGrantedCopyWithImpl<$Res>
    implements $RewardedGrantedCopyWith<$Res> {
  _$RewardedGrantedCopyWithImpl(this._self, this._then);

  final RewardedGranted _self;
  final $Res Function(RewardedGranted) _then;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,}) {
  return _then(RewardedGranted(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RewardedGrantDelayed implements RewardedState {
  const RewardedGrantDelayed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedGrantDelayed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.grantDelayed()';
}


}




/// @nodoc


class RewardedDismissedEarly implements RewardedState {
  const RewardedDismissedEarly();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedDismissedEarly);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.dismissedEarly()';
}


}




/// @nodoc


class RewardedNoFill implements RewardedState {
  const RewardedNoFill();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedNoFill);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RewardedState.noFill()';
}


}




/// @nodoc


class RewardedUnavailable implements RewardedState {
  const RewardedUnavailable(this.reason);
  

 final  RewardUnavailableReason reason;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedUnavailableCopyWith<RewardedUnavailable> get copyWith => _$RewardedUnavailableCopyWithImpl<RewardedUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedUnavailable&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'RewardedState.unavailable(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $RewardedUnavailableCopyWith<$Res> implements $RewardedStateCopyWith<$Res> {
  factory $RewardedUnavailableCopyWith(RewardedUnavailable value, $Res Function(RewardedUnavailable) _then) = _$RewardedUnavailableCopyWithImpl;
@useResult
$Res call({
 RewardUnavailableReason reason
});




}
/// @nodoc
class _$RewardedUnavailableCopyWithImpl<$Res>
    implements $RewardedUnavailableCopyWith<$Res> {
  _$RewardedUnavailableCopyWithImpl(this._self, this._then);

  final RewardedUnavailable _self;
  final $Res Function(RewardedUnavailable) _then;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(RewardedUnavailable(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as RewardUnavailableReason,
  ));
}


}

/// @nodoc


class RewardedFailed implements RewardedState {
  const RewardedFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardedFailedCopyWith<RewardedFailed> get copyWith => _$RewardedFailedCopyWithImpl<RewardedFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardedFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'RewardedState.failed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $RewardedFailedCopyWith<$Res> implements $RewardedStateCopyWith<$Res> {
  factory $RewardedFailedCopyWith(RewardedFailed value, $Res Function(RewardedFailed) _then) = _$RewardedFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$RewardedFailedCopyWithImpl<$Res>
    implements $RewardedFailedCopyWith<$Res> {
  _$RewardedFailedCopyWithImpl(this._self, this._then);

  final RewardedFailed _self;
  final $Res Function(RewardedFailed) _then;

/// Create a copy of RewardedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(RewardedFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

// dart format on
