// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncStatus()';
}


}

/// @nodoc
class $SyncStatusCopyWith<$Res>  {
$SyncStatusCopyWith(SyncStatus _, $Res Function(SyncStatus) __);
}


/// Adds pattern-matching-related methods to [SyncStatus].
extension SyncStatusPatterns on SyncStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SyncStatusSyncing value)?  syncing,TResult Function( SyncStatusSynced value)?  synced,TResult Function( SyncStatusStale value)?  stale,TResult Function( SyncStatusUnavailable value)?  unavailable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SyncStatusSyncing() when syncing != null:
return syncing(_that);case SyncStatusSynced() when synced != null:
return synced(_that);case SyncStatusStale() when stale != null:
return stale(_that);case SyncStatusUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SyncStatusSyncing value)  syncing,required TResult Function( SyncStatusSynced value)  synced,required TResult Function( SyncStatusStale value)  stale,required TResult Function( SyncStatusUnavailable value)  unavailable,}){
final _that = this;
switch (_that) {
case SyncStatusSyncing():
return syncing(_that);case SyncStatusSynced():
return synced(_that);case SyncStatusStale():
return stale(_that);case SyncStatusUnavailable():
return unavailable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SyncStatusSyncing value)?  syncing,TResult? Function( SyncStatusSynced value)?  synced,TResult? Function( SyncStatusStale value)?  stale,TResult? Function( SyncStatusUnavailable value)?  unavailable,}){
final _that = this;
switch (_that) {
case SyncStatusSyncing() when syncing != null:
return syncing(_that);case SyncStatusSynced() when synced != null:
return synced(_that);case SyncStatusStale() when stale != null:
return stale(_that);case SyncStatusUnavailable() when unavailable != null:
return unavailable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  syncing,TResult Function( DateTime at)?  synced,TResult Function( DateTime? lastSyncedAt)?  stale,TResult Function( Failure failure)?  unavailable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SyncStatusSyncing() when syncing != null:
return syncing();case SyncStatusSynced() when synced != null:
return synced(_that.at);case SyncStatusStale() when stale != null:
return stale(_that.lastSyncedAt);case SyncStatusUnavailable() when unavailable != null:
return unavailable(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  syncing,required TResult Function( DateTime at)  synced,required TResult Function( DateTime? lastSyncedAt)  stale,required TResult Function( Failure failure)  unavailable,}) {final _that = this;
switch (_that) {
case SyncStatusSyncing():
return syncing();case SyncStatusSynced():
return synced(_that.at);case SyncStatusStale():
return stale(_that.lastSyncedAt);case SyncStatusUnavailable():
return unavailable(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  syncing,TResult? Function( DateTime at)?  synced,TResult? Function( DateTime? lastSyncedAt)?  stale,TResult? Function( Failure failure)?  unavailable,}) {final _that = this;
switch (_that) {
case SyncStatusSyncing() when syncing != null:
return syncing();case SyncStatusSynced() when synced != null:
return synced(_that.at);case SyncStatusStale() when stale != null:
return stale(_that.lastSyncedAt);case SyncStatusUnavailable() when unavailable != null:
return unavailable(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SyncStatusSyncing implements SyncStatus {
  const SyncStatusSyncing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatusSyncing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncStatus.syncing()';
}


}




/// @nodoc


class SyncStatusSynced implements SyncStatus {
  const SyncStatusSynced({required this.at});
  

 final  DateTime at;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncStatusSyncedCopyWith<SyncStatusSynced> get copyWith => _$SyncStatusSyncedCopyWithImpl<SyncStatusSynced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatusSynced&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode => Object.hash(runtimeType,at);

@override
String toString() {
  return 'SyncStatus.synced(at: $at)';
}


}

/// @nodoc
abstract mixin class $SyncStatusSyncedCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncStatusSyncedCopyWith(SyncStatusSynced value, $Res Function(SyncStatusSynced) _then) = _$SyncStatusSyncedCopyWithImpl;
@useResult
$Res call({
 DateTime at
});




}
/// @nodoc
class _$SyncStatusSyncedCopyWithImpl<$Res>
    implements $SyncStatusSyncedCopyWith<$Res> {
  _$SyncStatusSyncedCopyWithImpl(this._self, this._then);

  final SyncStatusSynced _self;
  final $Res Function(SyncStatusSynced) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? at = null,}) {
  return _then(SyncStatusSynced(
at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class SyncStatusStale implements SyncStatus {
  const SyncStatusStale({this.lastSyncedAt});
  

 final  DateTime? lastSyncedAt;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncStatusStaleCopyWith<SyncStatusStale> get copyWith => _$SyncStatusStaleCopyWithImpl<SyncStatusStale>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatusStale&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt));
}


@override
int get hashCode => Object.hash(runtimeType,lastSyncedAt);

@override
String toString() {
  return 'SyncStatus.stale(lastSyncedAt: $lastSyncedAt)';
}


}

/// @nodoc
abstract mixin class $SyncStatusStaleCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncStatusStaleCopyWith(SyncStatusStale value, $Res Function(SyncStatusStale) _then) = _$SyncStatusStaleCopyWithImpl;
@useResult
$Res call({
 DateTime? lastSyncedAt
});




}
/// @nodoc
class _$SyncStatusStaleCopyWithImpl<$Res>
    implements $SyncStatusStaleCopyWith<$Res> {
  _$SyncStatusStaleCopyWithImpl(this._self, this._then);

  final SyncStatusStale _self;
  final $Res Function(SyncStatusStale) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lastSyncedAt = freezed,}) {
  return _then(SyncStatusStale(
lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class SyncStatusUnavailable implements SyncStatus {
  const SyncStatusUnavailable({required this.failure});
  

 final  Failure failure;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncStatusUnavailableCopyWith<SyncStatusUnavailable> get copyWith => _$SyncStatusUnavailableCopyWithImpl<SyncStatusUnavailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStatusUnavailable&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SyncStatus.unavailable(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SyncStatusUnavailableCopyWith<$Res> implements $SyncStatusCopyWith<$Res> {
  factory $SyncStatusUnavailableCopyWith(SyncStatusUnavailable value, $Res Function(SyncStatusUnavailable) _then) = _$SyncStatusUnavailableCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SyncStatusUnavailableCopyWithImpl<$Res>
    implements $SyncStatusUnavailableCopyWith<$Res> {
  _$SyncStatusUnavailableCopyWithImpl(this._self, this._then);

  final SyncStatusUnavailable _self;
  final $Res Function(SyncStatusUnavailable) _then;

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SyncStatusUnavailable(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SyncStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
