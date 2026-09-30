// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState()';
}


}

/// @nodoc
class $OnboardingStateCopyWith<$Res>  {
$OnboardingStateCopyWith(OnboardingState _, $Res Function(OnboardingState) __);
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OnboardingWelcome value)?  welcome,TResult Function( OnboardingDisclaimer value)?  disclaimer,TResult Function( OnboardingAcknowledged value)?  acknowledged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OnboardingWelcome() when welcome != null:
return welcome(_that);case OnboardingDisclaimer() when disclaimer != null:
return disclaimer(_that);case OnboardingAcknowledged() when acknowledged != null:
return acknowledged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OnboardingWelcome value)  welcome,required TResult Function( OnboardingDisclaimer value)  disclaimer,required TResult Function( OnboardingAcknowledged value)  acknowledged,}){
final _that = this;
switch (_that) {
case OnboardingWelcome():
return welcome(_that);case OnboardingDisclaimer():
return disclaimer(_that);case OnboardingAcknowledged():
return acknowledged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OnboardingWelcome value)?  welcome,TResult? Function( OnboardingDisclaimer value)?  disclaimer,TResult? Function( OnboardingAcknowledged value)?  acknowledged,}){
final _that = this;
switch (_that) {
case OnboardingWelcome() when welcome != null:
return welcome(_that);case OnboardingDisclaimer() when disclaimer != null:
return disclaimer(_that);case OnboardingAcknowledged() when acknowledged != null:
return acknowledged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int page,  int pageCount)?  welcome,TResult Function()?  disclaimer,TResult Function()?  acknowledged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OnboardingWelcome() when welcome != null:
return welcome(_that.page,_that.pageCount);case OnboardingDisclaimer() when disclaimer != null:
return disclaimer();case OnboardingAcknowledged() when acknowledged != null:
return acknowledged();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int page,  int pageCount)  welcome,required TResult Function()  disclaimer,required TResult Function()  acknowledged,}) {final _that = this;
switch (_that) {
case OnboardingWelcome():
return welcome(_that.page,_that.pageCount);case OnboardingDisclaimer():
return disclaimer();case OnboardingAcknowledged():
return acknowledged();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int page,  int pageCount)?  welcome,TResult? Function()?  disclaimer,TResult? Function()?  acknowledged,}) {final _that = this;
switch (_that) {
case OnboardingWelcome() when welcome != null:
return welcome(_that.page,_that.pageCount);case OnboardingDisclaimer() when disclaimer != null:
return disclaimer();case OnboardingAcknowledged() when acknowledged != null:
return acknowledged();case _:
  return null;

}
}

}

/// @nodoc


class OnboardingWelcome implements OnboardingState {
  const OnboardingWelcome({required this.page, this.pageCount = OnboardingController.welcomePages});
  

 final  int page;
@JsonKey() final  int pageCount;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingWelcomeCopyWith<OnboardingWelcome> get copyWith => _$OnboardingWelcomeCopyWithImpl<OnboardingWelcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingWelcome&&(identical(other.page, page) || other.page == page)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount));
}


@override
int get hashCode => Object.hash(runtimeType,page,pageCount);

@override
String toString() {
  return 'OnboardingState.welcome(page: $page, pageCount: $pageCount)';
}


}

/// @nodoc
abstract mixin class $OnboardingWelcomeCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingWelcomeCopyWith(OnboardingWelcome value, $Res Function(OnboardingWelcome) _then) = _$OnboardingWelcomeCopyWithImpl;
@useResult
$Res call({
 int page, int pageCount
});




}
/// @nodoc
class _$OnboardingWelcomeCopyWithImpl<$Res>
    implements $OnboardingWelcomeCopyWith<$Res> {
  _$OnboardingWelcomeCopyWithImpl(this._self, this._then);

  final OnboardingWelcome _self;
  final $Res Function(OnboardingWelcome) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? page = null,Object? pageCount = null,}) {
  return _then(OnboardingWelcome(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class OnboardingDisclaimer implements OnboardingState {
  const OnboardingDisclaimer();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDisclaimer);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.disclaimer()';
}


}




/// @nodoc


class OnboardingAcknowledged implements OnboardingState {
  const OnboardingAcknowledged();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingAcknowledged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.acknowledged()';
}


}




// dart format on
