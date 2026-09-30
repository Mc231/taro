// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delete_data_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeleteDataSummary {

/// Journal entries (readings + daily cards) that will be erased.
 int get journalEntries;/// Readings kept (purchased + earned; "Your readings balance: 3").
 int get readingsKept;/// Remove Banner Ads is owned and kept.
 bool get removeAdsKept;
/// Create a copy of DeleteDataSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteDataSummaryCopyWith<DeleteDataSummary> get copyWith => _$DeleteDataSummaryCopyWithImpl<DeleteDataSummary>(this as DeleteDataSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataSummary&&(identical(other.journalEntries, journalEntries) || other.journalEntries == journalEntries)&&(identical(other.readingsKept, readingsKept) || other.readingsKept == readingsKept)&&(identical(other.removeAdsKept, removeAdsKept) || other.removeAdsKept == removeAdsKept));
}


@override
int get hashCode => Object.hash(runtimeType,journalEntries,readingsKept,removeAdsKept);

@override
String toString() {
  return 'DeleteDataSummary(journalEntries: $journalEntries, readingsKept: $readingsKept, removeAdsKept: $removeAdsKept)';
}


}

/// @nodoc
abstract mixin class $DeleteDataSummaryCopyWith<$Res>  {
  factory $DeleteDataSummaryCopyWith(DeleteDataSummary value, $Res Function(DeleteDataSummary) _then) = _$DeleteDataSummaryCopyWithImpl;
@useResult
$Res call({
 int journalEntries, int readingsKept, bool removeAdsKept
});




}
/// @nodoc
class _$DeleteDataSummaryCopyWithImpl<$Res>
    implements $DeleteDataSummaryCopyWith<$Res> {
  _$DeleteDataSummaryCopyWithImpl(this._self, this._then);

  final DeleteDataSummary _self;
  final $Res Function(DeleteDataSummary) _then;

/// Create a copy of DeleteDataSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? journalEntries = null,Object? readingsKept = null,Object? removeAdsKept = null,}) {
  return _then(_self.copyWith(
journalEntries: null == journalEntries ? _self.journalEntries : journalEntries // ignore: cast_nullable_to_non_nullable
as int,readingsKept: null == readingsKept ? _self.readingsKept : readingsKept // ignore: cast_nullable_to_non_nullable
as int,removeAdsKept: null == removeAdsKept ? _self.removeAdsKept : removeAdsKept // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeleteDataSummary].
extension DeleteDataSummaryPatterns on DeleteDataSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeleteDataSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeleteDataSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeleteDataSummary value)  $default,){
final _that = this;
switch (_that) {
case _DeleteDataSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeleteDataSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DeleteDataSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int journalEntries,  int readingsKept,  bool removeAdsKept)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeleteDataSummary() when $default != null:
return $default(_that.journalEntries,_that.readingsKept,_that.removeAdsKept);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int journalEntries,  int readingsKept,  bool removeAdsKept)  $default,) {final _that = this;
switch (_that) {
case _DeleteDataSummary():
return $default(_that.journalEntries,_that.readingsKept,_that.removeAdsKept);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int journalEntries,  int readingsKept,  bool removeAdsKept)?  $default,) {final _that = this;
switch (_that) {
case _DeleteDataSummary() when $default != null:
return $default(_that.journalEntries,_that.readingsKept,_that.removeAdsKept);case _:
  return null;

}
}

}

/// @nodoc


class _DeleteDataSummary implements DeleteDataSummary {
  const _DeleteDataSummary({required this.journalEntries, required this.readingsKept, required this.removeAdsKept});
  

/// Journal entries (readings + daily cards) that will be erased.
@override final  int journalEntries;
/// Readings kept (purchased + earned; "Your readings balance: 3").
@override final  int readingsKept;
/// Remove Banner Ads is owned and kept.
@override final  bool removeAdsKept;

/// Create a copy of DeleteDataSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteDataSummaryCopyWith<_DeleteDataSummary> get copyWith => __$DeleteDataSummaryCopyWithImpl<_DeleteDataSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteDataSummary&&(identical(other.journalEntries, journalEntries) || other.journalEntries == journalEntries)&&(identical(other.readingsKept, readingsKept) || other.readingsKept == readingsKept)&&(identical(other.removeAdsKept, removeAdsKept) || other.removeAdsKept == removeAdsKept));
}


@override
int get hashCode => Object.hash(runtimeType,journalEntries,readingsKept,removeAdsKept);

@override
String toString() {
  return 'DeleteDataSummary(journalEntries: $journalEntries, readingsKept: $readingsKept, removeAdsKept: $removeAdsKept)';
}


}

/// @nodoc
abstract mixin class _$DeleteDataSummaryCopyWith<$Res> implements $DeleteDataSummaryCopyWith<$Res> {
  factory _$DeleteDataSummaryCopyWith(_DeleteDataSummary value, $Res Function(_DeleteDataSummary) _then) = __$DeleteDataSummaryCopyWithImpl;
@override @useResult
$Res call({
 int journalEntries, int readingsKept, bool removeAdsKept
});




}
/// @nodoc
class __$DeleteDataSummaryCopyWithImpl<$Res>
    implements _$DeleteDataSummaryCopyWith<$Res> {
  __$DeleteDataSummaryCopyWithImpl(this._self, this._then);

  final _DeleteDataSummary _self;
  final $Res Function(_DeleteDataSummary) _then;

/// Create a copy of DeleteDataSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? journalEntries = null,Object? readingsKept = null,Object? removeAdsKept = null,}) {
  return _then(_DeleteDataSummary(
journalEntries: null == journalEntries ? _self.journalEntries : journalEntries // ignore: cast_nullable_to_non_nullable
as int,readingsKept: null == readingsKept ? _self.readingsKept : readingsKept // ignore: cast_nullable_to_non_nullable
as int,removeAdsKept: null == removeAdsKept ? _self.removeAdsKept : removeAdsKept // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$DeleteDataState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteDataState()';
}


}

/// @nodoc
class $DeleteDataStateCopyWith<$Res>  {
$DeleteDataStateCopyWith(DeleteDataState _, $Res Function(DeleteDataState) __);
}


/// Adds pattern-matching-related methods to [DeleteDataState].
extension DeleteDataStatePatterns on DeleteDataState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteDataConfirm1 value)?  confirm1,TResult Function( DeleteDataConfirm2 value)?  confirm2,TResult Function( DeleteDataDeleting value)?  deleting,TResult Function( DeleteDataDone value)?  done,TResult Function( DeleteDataPartial value)?  partial,TResult Function( DeleteDataFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteDataConfirm1() when confirm1 != null:
return confirm1(_that);case DeleteDataConfirm2() when confirm2 != null:
return confirm2(_that);case DeleteDataDeleting() when deleting != null:
return deleting(_that);case DeleteDataDone() when done != null:
return done(_that);case DeleteDataPartial() when partial != null:
return partial(_that);case DeleteDataFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteDataConfirm1 value)  confirm1,required TResult Function( DeleteDataConfirm2 value)  confirm2,required TResult Function( DeleteDataDeleting value)  deleting,required TResult Function( DeleteDataDone value)  done,required TResult Function( DeleteDataPartial value)  partial,required TResult Function( DeleteDataFailed value)  failed,}){
final _that = this;
switch (_that) {
case DeleteDataConfirm1():
return confirm1(_that);case DeleteDataConfirm2():
return confirm2(_that);case DeleteDataDeleting():
return deleting(_that);case DeleteDataDone():
return done(_that);case DeleteDataPartial():
return partial(_that);case DeleteDataFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteDataConfirm1 value)?  confirm1,TResult? Function( DeleteDataConfirm2 value)?  confirm2,TResult? Function( DeleteDataDeleting value)?  deleting,TResult? Function( DeleteDataDone value)?  done,TResult? Function( DeleteDataPartial value)?  partial,TResult? Function( DeleteDataFailed value)?  failed,}){
final _that = this;
switch (_that) {
case DeleteDataConfirm1() when confirm1 != null:
return confirm1(_that);case DeleteDataConfirm2() when confirm2 != null:
return confirm2(_that);case DeleteDataDeleting() when deleting != null:
return deleting(_that);case DeleteDataDone() when done != null:
return done(_that);case DeleteDataPartial() when partial != null:
return partial(_that);case DeleteDataFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DeleteDataSummary summary)?  confirm1,TResult Function( DeleteDataSummary summary)?  confirm2,TResult Function()?  deleting,TResult Function()?  done,TResult Function()?  partial,TResult Function( ErrorKind kind)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteDataConfirm1() when confirm1 != null:
return confirm1(_that.summary);case DeleteDataConfirm2() when confirm2 != null:
return confirm2(_that.summary);case DeleteDataDeleting() when deleting != null:
return deleting();case DeleteDataDone() when done != null:
return done();case DeleteDataPartial() when partial != null:
return partial();case DeleteDataFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DeleteDataSummary summary)  confirm1,required TResult Function( DeleteDataSummary summary)  confirm2,required TResult Function()  deleting,required TResult Function()  done,required TResult Function()  partial,required TResult Function( ErrorKind kind)  failed,}) {final _that = this;
switch (_that) {
case DeleteDataConfirm1():
return confirm1(_that.summary);case DeleteDataConfirm2():
return confirm2(_that.summary);case DeleteDataDeleting():
return deleting();case DeleteDataDone():
return done();case DeleteDataPartial():
return partial();case DeleteDataFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DeleteDataSummary summary)?  confirm1,TResult? Function( DeleteDataSummary summary)?  confirm2,TResult? Function()?  deleting,TResult? Function()?  done,TResult? Function()?  partial,TResult? Function( ErrorKind kind)?  failed,}) {final _that = this;
switch (_that) {
case DeleteDataConfirm1() when confirm1 != null:
return confirm1(_that.summary);case DeleteDataConfirm2() when confirm2 != null:
return confirm2(_that.summary);case DeleteDataDeleting() when deleting != null:
return deleting();case DeleteDataDone() when done != null:
return done();case DeleteDataPartial() when partial != null:
return partial();case DeleteDataFailed() when failed != null:
return failed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class DeleteDataConfirm1 implements DeleteDataState {
  const DeleteDataConfirm1(this.summary);
  

 final  DeleteDataSummary summary;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteDataConfirm1CopyWith<DeleteDataConfirm1> get copyWith => _$DeleteDataConfirm1CopyWithImpl<DeleteDataConfirm1>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataConfirm1&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,summary);

@override
String toString() {
  return 'DeleteDataState.confirm1(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $DeleteDataConfirm1CopyWith<$Res> implements $DeleteDataStateCopyWith<$Res> {
  factory $DeleteDataConfirm1CopyWith(DeleteDataConfirm1 value, $Res Function(DeleteDataConfirm1) _then) = _$DeleteDataConfirm1CopyWithImpl;
@useResult
$Res call({
 DeleteDataSummary summary
});


$DeleteDataSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$DeleteDataConfirm1CopyWithImpl<$Res>
    implements $DeleteDataConfirm1CopyWith<$Res> {
  _$DeleteDataConfirm1CopyWithImpl(this._self, this._then);

  final DeleteDataConfirm1 _self;
  final $Res Function(DeleteDataConfirm1) _then;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(DeleteDataConfirm1(
null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DeleteDataSummary,
  ));
}

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeleteDataSummaryCopyWith<$Res> get summary {
  
  return $DeleteDataSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class DeleteDataConfirm2 implements DeleteDataState {
  const DeleteDataConfirm2(this.summary);
  

 final  DeleteDataSummary summary;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteDataConfirm2CopyWith<DeleteDataConfirm2> get copyWith => _$DeleteDataConfirm2CopyWithImpl<DeleteDataConfirm2>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataConfirm2&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,summary);

@override
String toString() {
  return 'DeleteDataState.confirm2(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $DeleteDataConfirm2CopyWith<$Res> implements $DeleteDataStateCopyWith<$Res> {
  factory $DeleteDataConfirm2CopyWith(DeleteDataConfirm2 value, $Res Function(DeleteDataConfirm2) _then) = _$DeleteDataConfirm2CopyWithImpl;
@useResult
$Res call({
 DeleteDataSummary summary
});


$DeleteDataSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$DeleteDataConfirm2CopyWithImpl<$Res>
    implements $DeleteDataConfirm2CopyWith<$Res> {
  _$DeleteDataConfirm2CopyWithImpl(this._self, this._then);

  final DeleteDataConfirm2 _self;
  final $Res Function(DeleteDataConfirm2) _then;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(DeleteDataConfirm2(
null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DeleteDataSummary,
  ));
}

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeleteDataSummaryCopyWith<$Res> get summary {
  
  return $DeleteDataSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class DeleteDataDeleting implements DeleteDataState {
  const DeleteDataDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteDataState.deleting()';
}


}




/// @nodoc


class DeleteDataDone implements DeleteDataState {
  const DeleteDataDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteDataState.done()';
}


}




/// @nodoc


class DeleteDataPartial implements DeleteDataState {
  const DeleteDataPartial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataPartial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteDataState.partial()';
}


}




/// @nodoc


class DeleteDataFailed implements DeleteDataState {
  const DeleteDataFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteDataFailedCopyWith<DeleteDataFailed> get copyWith => _$DeleteDataFailedCopyWithImpl<DeleteDataFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteDataFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'DeleteDataState.failed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $DeleteDataFailedCopyWith<$Res> implements $DeleteDataStateCopyWith<$Res> {
  factory $DeleteDataFailedCopyWith(DeleteDataFailed value, $Res Function(DeleteDataFailed) _then) = _$DeleteDataFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$DeleteDataFailedCopyWithImpl<$Res>
    implements $DeleteDataFailedCopyWith<$Res> {
  _$DeleteDataFailedCopyWithImpl(this._self, this._then);

  final DeleteDataFailed _self;
  final $Res Function(DeleteDataFailed) _then;

/// Create a copy of DeleteDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(DeleteDataFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

// dart format on
