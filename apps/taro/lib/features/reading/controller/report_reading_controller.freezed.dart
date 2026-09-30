// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_reading_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportDraft {

 ReportReason? get reason; String get note;
/// Create a copy of ReportDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<ReportDraft> get copyWith => _$ReportDraftCopyWithImpl<ReportDraft>(this as ReportDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportDraft&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,reason,note);

@override
String toString() {
  return 'ReportDraft(reason: $reason, note: $note)';
}


}

/// @nodoc
abstract mixin class $ReportDraftCopyWith<$Res>  {
  factory $ReportDraftCopyWith(ReportDraft value, $Res Function(ReportDraft) _then) = _$ReportDraftCopyWithImpl;
@useResult
$Res call({
 ReportReason? reason, String note
});




}
/// @nodoc
class _$ReportDraftCopyWithImpl<$Res>
    implements $ReportDraftCopyWith<$Res> {
  _$ReportDraftCopyWithImpl(this._self, this._then);

  final ReportDraft _self;
  final $Res Function(ReportDraft) _then;

/// Create a copy of ReportDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = freezed,Object? note = null,}) {
  return _then(_self.copyWith(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportDraft].
extension ReportDraftPatterns on ReportDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportDraft value)  $default,){
final _that = this;
switch (_that) {
case _ReportDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ReportDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportReason? reason,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportDraft() when $default != null:
return $default(_that.reason,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportReason? reason,  String note)  $default,) {final _that = this;
switch (_that) {
case _ReportDraft():
return $default(_that.reason,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportReason? reason,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ReportDraft() when $default != null:
return $default(_that.reason,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _ReportDraft extends ReportDraft {
  const _ReportDraft({this.reason, this.note = ''}): super._();
  

@override final  ReportReason? reason;
@override@JsonKey() final  String note;

/// Create a copy of ReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportDraftCopyWith<_ReportDraft> get copyWith => __$ReportDraftCopyWithImpl<_ReportDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportDraft&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,reason,note);

@override
String toString() {
  return 'ReportDraft(reason: $reason, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ReportDraftCopyWith<$Res> implements $ReportDraftCopyWith<$Res> {
  factory _$ReportDraftCopyWith(_ReportDraft value, $Res Function(_ReportDraft) _then) = __$ReportDraftCopyWithImpl;
@override @useResult
$Res call({
 ReportReason? reason, String note
});




}
/// @nodoc
class __$ReportDraftCopyWithImpl<$Res>
    implements _$ReportDraftCopyWith<$Res> {
  __$ReportDraftCopyWithImpl(this._self, this._then);

  final _ReportDraft _self;
  final $Res Function(_ReportDraft) _then;

/// Create a copy of ReportDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = freezed,Object? note = null,}) {
  return _then(_ReportDraft(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ReportReason?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ReportReadingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportReadingState()';
}


}

/// @nodoc
class $ReportReadingStateCopyWith<$Res>  {
$ReportReadingStateCopyWith(ReportReadingState _, $Res Function(ReportReadingState) __);
}


/// Adds pattern-matching-related methods to [ReportReadingState].
extension ReportReadingStatePatterns on ReportReadingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReportReadingEditing value)?  editing,TResult Function( ReportReadingSubmitting value)?  submitting,TResult Function( ReportReadingSubmitted value)?  submitted,TResult Function( ReportReadingFailed value)?  failed,TResult Function( ReportReadingOffline value)?  offline,TResult Function( ReportReadingRateLimited value)?  rateLimited,TResult Function( ReportReadingAlreadyReported value)?  alreadyReported,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReportReadingEditing() when editing != null:
return editing(_that);case ReportReadingSubmitting() when submitting != null:
return submitting(_that);case ReportReadingSubmitted() when submitted != null:
return submitted(_that);case ReportReadingFailed() when failed != null:
return failed(_that);case ReportReadingOffline() when offline != null:
return offline(_that);case ReportReadingRateLimited() when rateLimited != null:
return rateLimited(_that);case ReportReadingAlreadyReported() when alreadyReported != null:
return alreadyReported(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReportReadingEditing value)  editing,required TResult Function( ReportReadingSubmitting value)  submitting,required TResult Function( ReportReadingSubmitted value)  submitted,required TResult Function( ReportReadingFailed value)  failed,required TResult Function( ReportReadingOffline value)  offline,required TResult Function( ReportReadingRateLimited value)  rateLimited,required TResult Function( ReportReadingAlreadyReported value)  alreadyReported,}){
final _that = this;
switch (_that) {
case ReportReadingEditing():
return editing(_that);case ReportReadingSubmitting():
return submitting(_that);case ReportReadingSubmitted():
return submitted(_that);case ReportReadingFailed():
return failed(_that);case ReportReadingOffline():
return offline(_that);case ReportReadingRateLimited():
return rateLimited(_that);case ReportReadingAlreadyReported():
return alreadyReported(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReportReadingEditing value)?  editing,TResult? Function( ReportReadingSubmitting value)?  submitting,TResult? Function( ReportReadingSubmitted value)?  submitted,TResult? Function( ReportReadingFailed value)?  failed,TResult? Function( ReportReadingOffline value)?  offline,TResult? Function( ReportReadingRateLimited value)?  rateLimited,TResult? Function( ReportReadingAlreadyReported value)?  alreadyReported,}){
final _that = this;
switch (_that) {
case ReportReadingEditing() when editing != null:
return editing(_that);case ReportReadingSubmitting() when submitting != null:
return submitting(_that);case ReportReadingSubmitted() when submitted != null:
return submitted(_that);case ReportReadingFailed() when failed != null:
return failed(_that);case ReportReadingOffline() when offline != null:
return offline(_that);case ReportReadingRateLimited() when rateLimited != null:
return rateLimited(_that);case ReportReadingAlreadyReported() when alreadyReported != null:
return alreadyReported(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ReportDraft draft)?  editing,TResult Function( ReportDraft draft)?  submitting,TResult Function()?  submitted,TResult Function( ReportDraft draft,  Failure failure)?  failed,TResult Function( ReportDraft draft)?  offline,TResult Function( ReportDraft draft)?  rateLimited,TResult Function()?  alreadyReported,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReportReadingEditing() when editing != null:
return editing(_that.draft);case ReportReadingSubmitting() when submitting != null:
return submitting(_that.draft);case ReportReadingSubmitted() when submitted != null:
return submitted();case ReportReadingFailed() when failed != null:
return failed(_that.draft,_that.failure);case ReportReadingOffline() when offline != null:
return offline(_that.draft);case ReportReadingRateLimited() when rateLimited != null:
return rateLimited(_that.draft);case ReportReadingAlreadyReported() when alreadyReported != null:
return alreadyReported();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ReportDraft draft)  editing,required TResult Function( ReportDraft draft)  submitting,required TResult Function()  submitted,required TResult Function( ReportDraft draft,  Failure failure)  failed,required TResult Function( ReportDraft draft)  offline,required TResult Function( ReportDraft draft)  rateLimited,required TResult Function()  alreadyReported,}) {final _that = this;
switch (_that) {
case ReportReadingEditing():
return editing(_that.draft);case ReportReadingSubmitting():
return submitting(_that.draft);case ReportReadingSubmitted():
return submitted();case ReportReadingFailed():
return failed(_that.draft,_that.failure);case ReportReadingOffline():
return offline(_that.draft);case ReportReadingRateLimited():
return rateLimited(_that.draft);case ReportReadingAlreadyReported():
return alreadyReported();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ReportDraft draft)?  editing,TResult? Function( ReportDraft draft)?  submitting,TResult? Function()?  submitted,TResult? Function( ReportDraft draft,  Failure failure)?  failed,TResult? Function( ReportDraft draft)?  offline,TResult? Function( ReportDraft draft)?  rateLimited,TResult? Function()?  alreadyReported,}) {final _that = this;
switch (_that) {
case ReportReadingEditing() when editing != null:
return editing(_that.draft);case ReportReadingSubmitting() when submitting != null:
return submitting(_that.draft);case ReportReadingSubmitted() when submitted != null:
return submitted();case ReportReadingFailed() when failed != null:
return failed(_that.draft,_that.failure);case ReportReadingOffline() when offline != null:
return offline(_that.draft);case ReportReadingRateLimited() when rateLimited != null:
return rateLimited(_that.draft);case ReportReadingAlreadyReported() when alreadyReported != null:
return alreadyReported();case _:
  return null;

}
}

}

/// @nodoc


class ReportReadingEditing implements ReportReadingState {
  const ReportReadingEditing(this.draft);
  

 final  ReportDraft draft;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportReadingEditingCopyWith<ReportReadingEditing> get copyWith => _$ReportReadingEditingCopyWithImpl<ReportReadingEditing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingEditing&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'ReportReadingState.editing(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $ReportReadingEditingCopyWith<$Res> implements $ReportReadingStateCopyWith<$Res> {
  factory $ReportReadingEditingCopyWith(ReportReadingEditing value, $Res Function(ReportReadingEditing) _then) = _$ReportReadingEditingCopyWithImpl;
@useResult
$Res call({
 ReportDraft draft
});


$ReportDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$ReportReadingEditingCopyWithImpl<$Res>
    implements $ReportReadingEditingCopyWith<$Res> {
  _$ReportReadingEditingCopyWithImpl(this._self, this._then);

  final ReportReadingEditing _self;
  final $Res Function(ReportReadingEditing) _then;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(ReportReadingEditing(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as ReportDraft,
  ));
}

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<$Res> get draft {
  
  return $ReportDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class ReportReadingSubmitting implements ReportReadingState {
  const ReportReadingSubmitting(this.draft);
  

 final  ReportDraft draft;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportReadingSubmittingCopyWith<ReportReadingSubmitting> get copyWith => _$ReportReadingSubmittingCopyWithImpl<ReportReadingSubmitting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingSubmitting&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'ReportReadingState.submitting(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $ReportReadingSubmittingCopyWith<$Res> implements $ReportReadingStateCopyWith<$Res> {
  factory $ReportReadingSubmittingCopyWith(ReportReadingSubmitting value, $Res Function(ReportReadingSubmitting) _then) = _$ReportReadingSubmittingCopyWithImpl;
@useResult
$Res call({
 ReportDraft draft
});


$ReportDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$ReportReadingSubmittingCopyWithImpl<$Res>
    implements $ReportReadingSubmittingCopyWith<$Res> {
  _$ReportReadingSubmittingCopyWithImpl(this._self, this._then);

  final ReportReadingSubmitting _self;
  final $Res Function(ReportReadingSubmitting) _then;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(ReportReadingSubmitting(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as ReportDraft,
  ));
}

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<$Res> get draft {
  
  return $ReportDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class ReportReadingSubmitted implements ReportReadingState {
  const ReportReadingSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportReadingState.submitted()';
}


}




/// @nodoc


class ReportReadingFailed implements ReportReadingState {
  const ReportReadingFailed(this.draft, {required this.failure});
  

 final  ReportDraft draft;
 final  Failure failure;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportReadingFailedCopyWith<ReportReadingFailed> get copyWith => _$ReportReadingFailedCopyWithImpl<ReportReadingFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingFailed&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,draft,failure);

@override
String toString() {
  return 'ReportReadingState.failed(draft: $draft, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ReportReadingFailedCopyWith<$Res> implements $ReportReadingStateCopyWith<$Res> {
  factory $ReportReadingFailedCopyWith(ReportReadingFailed value, $Res Function(ReportReadingFailed) _then) = _$ReportReadingFailedCopyWithImpl;
@useResult
$Res call({
 ReportDraft draft, Failure failure
});


$ReportDraftCopyWith<$Res> get draft;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ReportReadingFailedCopyWithImpl<$Res>
    implements $ReportReadingFailedCopyWith<$Res> {
  _$ReportReadingFailedCopyWithImpl(this._self, this._then);

  final ReportReadingFailed _self;
  final $Res Function(ReportReadingFailed) _then;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? failure = null,}) {
  return _then(ReportReadingFailed(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as ReportDraft,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<$Res> get draft {
  
  return $ReportDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of ReportReadingState
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


class ReportReadingOffline implements ReportReadingState {
  const ReportReadingOffline(this.draft);
  

 final  ReportDraft draft;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportReadingOfflineCopyWith<ReportReadingOffline> get copyWith => _$ReportReadingOfflineCopyWithImpl<ReportReadingOffline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingOffline&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'ReportReadingState.offline(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $ReportReadingOfflineCopyWith<$Res> implements $ReportReadingStateCopyWith<$Res> {
  factory $ReportReadingOfflineCopyWith(ReportReadingOffline value, $Res Function(ReportReadingOffline) _then) = _$ReportReadingOfflineCopyWithImpl;
@useResult
$Res call({
 ReportDraft draft
});


$ReportDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$ReportReadingOfflineCopyWithImpl<$Res>
    implements $ReportReadingOfflineCopyWith<$Res> {
  _$ReportReadingOfflineCopyWithImpl(this._self, this._then);

  final ReportReadingOffline _self;
  final $Res Function(ReportReadingOffline) _then;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(ReportReadingOffline(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as ReportDraft,
  ));
}

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<$Res> get draft {
  
  return $ReportDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class ReportReadingRateLimited implements ReportReadingState {
  const ReportReadingRateLimited(this.draft);
  

 final  ReportDraft draft;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportReadingRateLimitedCopyWith<ReportReadingRateLimited> get copyWith => _$ReportReadingRateLimitedCopyWithImpl<ReportReadingRateLimited>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingRateLimited&&(identical(other.draft, draft) || other.draft == draft));
}


@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'ReportReadingState.rateLimited(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $ReportReadingRateLimitedCopyWith<$Res> implements $ReportReadingStateCopyWith<$Res> {
  factory $ReportReadingRateLimitedCopyWith(ReportReadingRateLimited value, $Res Function(ReportReadingRateLimited) _then) = _$ReportReadingRateLimitedCopyWithImpl;
@useResult
$Res call({
 ReportDraft draft
});


$ReportDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$ReportReadingRateLimitedCopyWithImpl<$Res>
    implements $ReportReadingRateLimitedCopyWith<$Res> {
  _$ReportReadingRateLimitedCopyWithImpl(this._self, this._then);

  final ReportReadingRateLimited _self;
  final $Res Function(ReportReadingRateLimited) _then;

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draft = null,}) {
  return _then(ReportReadingRateLimited(
null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as ReportDraft,
  ));
}

/// Create a copy of ReportReadingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportDraftCopyWith<$Res> get draft {
  
  return $ReportDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc


class ReportReadingAlreadyReported implements ReportReadingState {
  const ReportReadingAlreadyReported();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportReadingAlreadyReported);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportReadingState.alreadyReported()';
}


}




// dart format on
