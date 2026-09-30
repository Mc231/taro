// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'privacy_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PrivacyView {

/// AI readings: "Allowed" (Withdraw) or "Not allowed" (Allow → S04).
 bool get aiGranted;/// "Ad personalisation" + "Review ad choices" is shown only when UMP
/// reports `privacyOptionsRequirementStatus == required`.
 bool get adsPrivacyOptionsRequired;/// The ATT status (iOS only; `null` on Android: no Tracking row).
 TrackingStatus? get tracking;/// "Usage analytics" (also binds crash reports, 02 §13).
 bool get analyticsEnabled;
/// Create a copy of PrivacyView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyViewCopyWith<PrivacyView> get copyWith => _$PrivacyViewCopyWithImpl<PrivacyView>(this as PrivacyView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyView&&(identical(other.aiGranted, aiGranted) || other.aiGranted == aiGranted)&&(identical(other.adsPrivacyOptionsRequired, adsPrivacyOptionsRequired) || other.adsPrivacyOptionsRequired == adsPrivacyOptionsRequired)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.analyticsEnabled, analyticsEnabled) || other.analyticsEnabled == analyticsEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,aiGranted,adsPrivacyOptionsRequired,tracking,analyticsEnabled);

@override
String toString() {
  return 'PrivacyView(aiGranted: $aiGranted, adsPrivacyOptionsRequired: $adsPrivacyOptionsRequired, tracking: $tracking, analyticsEnabled: $analyticsEnabled)';
}


}

/// @nodoc
abstract mixin class $PrivacyViewCopyWith<$Res>  {
  factory $PrivacyViewCopyWith(PrivacyView value, $Res Function(PrivacyView) _then) = _$PrivacyViewCopyWithImpl;
@useResult
$Res call({
 bool aiGranted, bool adsPrivacyOptionsRequired, TrackingStatus? tracking, bool analyticsEnabled
});




}
/// @nodoc
class _$PrivacyViewCopyWithImpl<$Res>
    implements $PrivacyViewCopyWith<$Res> {
  _$PrivacyViewCopyWithImpl(this._self, this._then);

  final PrivacyView _self;
  final $Res Function(PrivacyView) _then;

/// Create a copy of PrivacyView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aiGranted = null,Object? adsPrivacyOptionsRequired = null,Object? tracking = freezed,Object? analyticsEnabled = null,}) {
  return _then(_self.copyWith(
aiGranted: null == aiGranted ? _self.aiGranted : aiGranted // ignore: cast_nullable_to_non_nullable
as bool,adsPrivacyOptionsRequired: null == adsPrivacyOptionsRequired ? _self.adsPrivacyOptionsRequired : adsPrivacyOptionsRequired // ignore: cast_nullable_to_non_nullable
as bool,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingStatus?,analyticsEnabled: null == analyticsEnabled ? _self.analyticsEnabled : analyticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacyView].
extension PrivacyViewPatterns on PrivacyView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacyView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacyView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacyView value)  $default,){
final _that = this;
switch (_that) {
case _PrivacyView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacyView value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacyView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool aiGranted,  bool adsPrivacyOptionsRequired,  TrackingStatus? tracking,  bool analyticsEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacyView() when $default != null:
return $default(_that.aiGranted,_that.adsPrivacyOptionsRequired,_that.tracking,_that.analyticsEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool aiGranted,  bool adsPrivacyOptionsRequired,  TrackingStatus? tracking,  bool analyticsEnabled)  $default,) {final _that = this;
switch (_that) {
case _PrivacyView():
return $default(_that.aiGranted,_that.adsPrivacyOptionsRequired,_that.tracking,_that.analyticsEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool aiGranted,  bool adsPrivacyOptionsRequired,  TrackingStatus? tracking,  bool analyticsEnabled)?  $default,) {final _that = this;
switch (_that) {
case _PrivacyView() when $default != null:
return $default(_that.aiGranted,_that.adsPrivacyOptionsRequired,_that.tracking,_that.analyticsEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _PrivacyView implements PrivacyView {
  const _PrivacyView({required this.aiGranted, required this.adsPrivacyOptionsRequired, required this.tracking, required this.analyticsEnabled});
  

/// AI readings: "Allowed" (Withdraw) or "Not allowed" (Allow → S04).
@override final  bool aiGranted;
/// "Ad personalisation" + "Review ad choices" is shown only when UMP
/// reports `privacyOptionsRequirementStatus == required`.
@override final  bool adsPrivacyOptionsRequired;
/// The ATT status (iOS only; `null` on Android: no Tracking row).
@override final  TrackingStatus? tracking;
/// "Usage analytics" (also binds crash reports, 02 §13).
@override final  bool analyticsEnabled;

/// Create a copy of PrivacyView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacyViewCopyWith<_PrivacyView> get copyWith => __$PrivacyViewCopyWithImpl<_PrivacyView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacyView&&(identical(other.aiGranted, aiGranted) || other.aiGranted == aiGranted)&&(identical(other.adsPrivacyOptionsRequired, adsPrivacyOptionsRequired) || other.adsPrivacyOptionsRequired == adsPrivacyOptionsRequired)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&(identical(other.analyticsEnabled, analyticsEnabled) || other.analyticsEnabled == analyticsEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,aiGranted,adsPrivacyOptionsRequired,tracking,analyticsEnabled);

@override
String toString() {
  return 'PrivacyView(aiGranted: $aiGranted, adsPrivacyOptionsRequired: $adsPrivacyOptionsRequired, tracking: $tracking, analyticsEnabled: $analyticsEnabled)';
}


}

/// @nodoc
abstract mixin class _$PrivacyViewCopyWith<$Res> implements $PrivacyViewCopyWith<$Res> {
  factory _$PrivacyViewCopyWith(_PrivacyView value, $Res Function(_PrivacyView) _then) = __$PrivacyViewCopyWithImpl;
@override @useResult
$Res call({
 bool aiGranted, bool adsPrivacyOptionsRequired, TrackingStatus? tracking, bool analyticsEnabled
});




}
/// @nodoc
class __$PrivacyViewCopyWithImpl<$Res>
    implements _$PrivacyViewCopyWith<$Res> {
  __$PrivacyViewCopyWithImpl(this._self, this._then);

  final _PrivacyView _self;
  final $Res Function(_PrivacyView) _then;

/// Create a copy of PrivacyView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aiGranted = null,Object? adsPrivacyOptionsRequired = null,Object? tracking = freezed,Object? analyticsEnabled = null,}) {
  return _then(_PrivacyView(
aiGranted: null == aiGranted ? _self.aiGranted : aiGranted // ignore: cast_nullable_to_non_nullable
as bool,adsPrivacyOptionsRequired: null == adsPrivacyOptionsRequired ? _self.adsPrivacyOptionsRequired : adsPrivacyOptionsRequired // ignore: cast_nullable_to_non_nullable
as bool,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as TrackingStatus?,analyticsEnabled: null == analyticsEnabled ? _self.analyticsEnabled : analyticsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$PrivacyState {

 PrivacyView get view;
/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyStateCopyWith<PrivacyState> get copyWith => _$PrivacyStateCopyWithImpl<PrivacyState>(this as PrivacyState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyState&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'PrivacyState(view: $view)';
}


}

/// @nodoc
abstract mixin class $PrivacyStateCopyWith<$Res>  {
  factory $PrivacyStateCopyWith(PrivacyState value, $Res Function(PrivacyState) _then) = _$PrivacyStateCopyWithImpl;
@useResult
$Res call({
 PrivacyView view
});


$PrivacyViewCopyWith<$Res> get view;

}
/// @nodoc
class _$PrivacyStateCopyWithImpl<$Res>
    implements $PrivacyStateCopyWith<$Res> {
  _$PrivacyStateCopyWithImpl(this._self, this._then);

  final PrivacyState _self;
  final $Res Function(PrivacyState) _then;

/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? view = null,}) {
  return _then(_self.copyWith(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as PrivacyView,
  ));
}
/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyViewCopyWith<$Res> get view {
  
  return $PrivacyViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}


/// Adds pattern-matching-related methods to [PrivacyState].
extension PrivacyStatePatterns on PrivacyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PrivacyContent value)?  content,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PrivacyContent() when content != null:
return content(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PrivacyContent value)  content,}){
final _that = this;
switch (_that) {
case PrivacyContent():
return content(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PrivacyContent value)?  content,}){
final _that = this;
switch (_that) {
case PrivacyContent() when content != null:
return content(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PrivacyView view)?  content,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PrivacyContent() when content != null:
return content(_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PrivacyView view)  content,}) {final _that = this;
switch (_that) {
case PrivacyContent():
return content(_that.view);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PrivacyView view)?  content,}) {final _that = this;
switch (_that) {
case PrivacyContent() when content != null:
return content(_that.view);case _:
  return null;

}
}

}

/// @nodoc


class PrivacyContent implements PrivacyState {
  const PrivacyContent(this.view);
  

@override final  PrivacyView view;

/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyContentCopyWith<PrivacyContent> get copyWith => _$PrivacyContentCopyWithImpl<PrivacyContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyContent&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'PrivacyState.content(view: $view)';
}


}

/// @nodoc
abstract mixin class $PrivacyContentCopyWith<$Res> implements $PrivacyStateCopyWith<$Res> {
  factory $PrivacyContentCopyWith(PrivacyContent value, $Res Function(PrivacyContent) _then) = _$PrivacyContentCopyWithImpl;
@override @useResult
$Res call({
 PrivacyView view
});


@override $PrivacyViewCopyWith<$Res> get view;

}
/// @nodoc
class _$PrivacyContentCopyWithImpl<$Res>
    implements $PrivacyContentCopyWith<$Res> {
  _$PrivacyContentCopyWithImpl(this._self, this._then);

  final PrivacyContent _self;
  final $Res Function(PrivacyContent) _then;

/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(PrivacyContent(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as PrivacyView,
  ));
}

/// Create a copy of PrivacyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyViewCopyWith<$Res> get view {
  
  return $PrivacyViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

// dart format on
