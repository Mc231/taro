// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseOutcome {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome()';
}


}

/// @nodoc
class $PurchaseOutcomeCopyWith<$Res>  {
$PurchaseOutcomeCopyWith(PurchaseOutcome _, $Res Function(PurchaseOutcome) __);
}


/// Adds pattern-matching-related methods to [PurchaseOutcome].
extension PurchaseOutcomePatterns on PurchaseOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PurchaseGranted value)?  granted,TResult Function( PurchaseAlreadyGranted value)?  alreadyGranted,TResult Function( PurchaseOutcomePending value)?  pending,TResult Function( PurchaseOutcomeCancelled value)?  cancelled,TResult Function( PurchaseOutcomeFailed value)?  failed,TResult Function( PurchaseVerificationDelayed value)?  verificationDelayed,TResult Function( PurchaseNotAvailable value)?  notAvailable,TResult Function( PurchaseAlreadyOwned value)?  alreadyOwned,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PurchaseGranted() when granted != null:
return granted(_that);case PurchaseAlreadyGranted() when alreadyGranted != null:
return alreadyGranted(_that);case PurchaseOutcomePending() when pending != null:
return pending(_that);case PurchaseOutcomeCancelled() when cancelled != null:
return cancelled(_that);case PurchaseOutcomeFailed() when failed != null:
return failed(_that);case PurchaseVerificationDelayed() when verificationDelayed != null:
return verificationDelayed(_that);case PurchaseNotAvailable() when notAvailable != null:
return notAvailable(_that);case PurchaseAlreadyOwned() when alreadyOwned != null:
return alreadyOwned(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PurchaseGranted value)  granted,required TResult Function( PurchaseAlreadyGranted value)  alreadyGranted,required TResult Function( PurchaseOutcomePending value)  pending,required TResult Function( PurchaseOutcomeCancelled value)  cancelled,required TResult Function( PurchaseOutcomeFailed value)  failed,required TResult Function( PurchaseVerificationDelayed value)  verificationDelayed,required TResult Function( PurchaseNotAvailable value)  notAvailable,required TResult Function( PurchaseAlreadyOwned value)  alreadyOwned,}){
final _that = this;
switch (_that) {
case PurchaseGranted():
return granted(_that);case PurchaseAlreadyGranted():
return alreadyGranted(_that);case PurchaseOutcomePending():
return pending(_that);case PurchaseOutcomeCancelled():
return cancelled(_that);case PurchaseOutcomeFailed():
return failed(_that);case PurchaseVerificationDelayed():
return verificationDelayed(_that);case PurchaseNotAvailable():
return notAvailable(_that);case PurchaseAlreadyOwned():
return alreadyOwned(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PurchaseGranted value)?  granted,TResult? Function( PurchaseAlreadyGranted value)?  alreadyGranted,TResult? Function( PurchaseOutcomePending value)?  pending,TResult? Function( PurchaseOutcomeCancelled value)?  cancelled,TResult? Function( PurchaseOutcomeFailed value)?  failed,TResult? Function( PurchaseVerificationDelayed value)?  verificationDelayed,TResult? Function( PurchaseNotAvailable value)?  notAvailable,TResult? Function( PurchaseAlreadyOwned value)?  alreadyOwned,}){
final _that = this;
switch (_that) {
case PurchaseGranted() when granted != null:
return granted(_that);case PurchaseAlreadyGranted() when alreadyGranted != null:
return alreadyGranted(_that);case PurchaseOutcomePending() when pending != null:
return pending(_that);case PurchaseOutcomeCancelled() when cancelled != null:
return cancelled(_that);case PurchaseOutcomeFailed() when failed != null:
return failed(_that);case PurchaseVerificationDelayed() when verificationDelayed != null:
return verificationDelayed(_that);case PurchaseNotAvailable() when notAvailable != null:
return notAvailable(_that);case PurchaseAlreadyOwned() when alreadyOwned != null:
return alreadyOwned(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int credits,  bool isFirstPurchase)?  granted,TResult Function()?  alreadyGranted,TResult Function()?  pending,TResult Function()?  cancelled,TResult Function( Failure failure)?  failed,TResult Function()?  verificationDelayed,TResult Function()?  notAvailable,TResult Function()?  alreadyOwned,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PurchaseGranted() when granted != null:
return granted(_that.credits,_that.isFirstPurchase);case PurchaseAlreadyGranted() when alreadyGranted != null:
return alreadyGranted();case PurchaseOutcomePending() when pending != null:
return pending();case PurchaseOutcomeCancelled() when cancelled != null:
return cancelled();case PurchaseOutcomeFailed() when failed != null:
return failed(_that.failure);case PurchaseVerificationDelayed() when verificationDelayed != null:
return verificationDelayed();case PurchaseNotAvailable() when notAvailable != null:
return notAvailable();case PurchaseAlreadyOwned() when alreadyOwned != null:
return alreadyOwned();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int credits,  bool isFirstPurchase)  granted,required TResult Function()  alreadyGranted,required TResult Function()  pending,required TResult Function()  cancelled,required TResult Function( Failure failure)  failed,required TResult Function()  verificationDelayed,required TResult Function()  notAvailable,required TResult Function()  alreadyOwned,}) {final _that = this;
switch (_that) {
case PurchaseGranted():
return granted(_that.credits,_that.isFirstPurchase);case PurchaseAlreadyGranted():
return alreadyGranted();case PurchaseOutcomePending():
return pending();case PurchaseOutcomeCancelled():
return cancelled();case PurchaseOutcomeFailed():
return failed(_that.failure);case PurchaseVerificationDelayed():
return verificationDelayed();case PurchaseNotAvailable():
return notAvailable();case PurchaseAlreadyOwned():
return alreadyOwned();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int credits,  bool isFirstPurchase)?  granted,TResult? Function()?  alreadyGranted,TResult? Function()?  pending,TResult? Function()?  cancelled,TResult? Function( Failure failure)?  failed,TResult? Function()?  verificationDelayed,TResult? Function()?  notAvailable,TResult? Function()?  alreadyOwned,}) {final _that = this;
switch (_that) {
case PurchaseGranted() when granted != null:
return granted(_that.credits,_that.isFirstPurchase);case PurchaseAlreadyGranted() when alreadyGranted != null:
return alreadyGranted();case PurchaseOutcomePending() when pending != null:
return pending();case PurchaseOutcomeCancelled() when cancelled != null:
return cancelled();case PurchaseOutcomeFailed() when failed != null:
return failed(_that.failure);case PurchaseVerificationDelayed() when verificationDelayed != null:
return verificationDelayed();case PurchaseNotAvailable() when notAvailable != null:
return notAvailable();case PurchaseAlreadyOwned() when alreadyOwned != null:
return alreadyOwned();case _:
  return null;

}
}

}

/// @nodoc


class PurchaseGranted implements PurchaseOutcome {
  const PurchaseGranted({required this.credits, required this.isFirstPurchase});
  

 final  int credits;
 final  bool isFirstPurchase;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseGrantedCopyWith<PurchaseGranted> get copyWith => _$PurchaseGrantedCopyWithImpl<PurchaseGranted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseGranted&&(identical(other.credits, credits) || other.credits == credits)&&(identical(other.isFirstPurchase, isFirstPurchase) || other.isFirstPurchase == isFirstPurchase));
}


@override
int get hashCode => Object.hash(runtimeType,credits,isFirstPurchase);

@override
String toString() {
  return 'PurchaseOutcome.granted(credits: $credits, isFirstPurchase: $isFirstPurchase)';
}


}

/// @nodoc
abstract mixin class $PurchaseGrantedCopyWith<$Res> implements $PurchaseOutcomeCopyWith<$Res> {
  factory $PurchaseGrantedCopyWith(PurchaseGranted value, $Res Function(PurchaseGranted) _then) = _$PurchaseGrantedCopyWithImpl;
@useResult
$Res call({
 int credits, bool isFirstPurchase
});




}
/// @nodoc
class _$PurchaseGrantedCopyWithImpl<$Res>
    implements $PurchaseGrantedCopyWith<$Res> {
  _$PurchaseGrantedCopyWithImpl(this._self, this._then);

  final PurchaseGranted _self;
  final $Res Function(PurchaseGranted) _then;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? credits = null,Object? isFirstPurchase = null,}) {
  return _then(PurchaseGranted(
credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int,isFirstPurchase: null == isFirstPurchase ? _self.isFirstPurchase : isFirstPurchase // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class PurchaseAlreadyGranted implements PurchaseOutcome {
  const PurchaseAlreadyGranted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseAlreadyGranted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.alreadyGranted()';
}


}




/// @nodoc


class PurchaseOutcomePending implements PurchaseOutcome {
  const PurchaseOutcomePending();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOutcomePending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.pending()';
}


}




/// @nodoc


class PurchaseOutcomeCancelled implements PurchaseOutcome {
  const PurchaseOutcomeCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOutcomeCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.cancelled()';
}


}




/// @nodoc


class PurchaseOutcomeFailed implements PurchaseOutcome {
  const PurchaseOutcomeFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOutcomeFailedCopyWith<PurchaseOutcomeFailed> get copyWith => _$PurchaseOutcomeFailedCopyWithImpl<PurchaseOutcomeFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOutcomeFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PurchaseOutcome.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PurchaseOutcomeFailedCopyWith<$Res> implements $PurchaseOutcomeCopyWith<$Res> {
  factory $PurchaseOutcomeFailedCopyWith(PurchaseOutcomeFailed value, $Res Function(PurchaseOutcomeFailed) _then) = _$PurchaseOutcomeFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PurchaseOutcomeFailedCopyWithImpl<$Res>
    implements $PurchaseOutcomeFailedCopyWith<$Res> {
  _$PurchaseOutcomeFailedCopyWithImpl(this._self, this._then);

  final PurchaseOutcomeFailed _self;
  final $Res Function(PurchaseOutcomeFailed) _then;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PurchaseOutcomeFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PurchaseOutcome
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


class PurchaseVerificationDelayed implements PurchaseOutcome {
  const PurchaseVerificationDelayed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseVerificationDelayed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.verificationDelayed()';
}


}




/// @nodoc


class PurchaseNotAvailable implements PurchaseOutcome {
  const PurchaseNotAvailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseNotAvailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.notAvailable()';
}


}




/// @nodoc


class PurchaseAlreadyOwned implements PurchaseOutcome {
  const PurchaseAlreadyOwned();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseAlreadyOwned);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PurchaseOutcome.alreadyOwned()';
}


}




// dart format on
