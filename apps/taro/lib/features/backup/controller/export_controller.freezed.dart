// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportState()';
}


}

/// @nodoc
class $ExportStateCopyWith<$Res>  {
$ExportStateCopyWith(ExportState _, $Res Function(ExportState) __);
}


/// Adds pattern-matching-related methods to [ExportState].
extension ExportStatePatterns on ExportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExportIdle value)?  idle,TResult Function( ExportPreparing value)?  preparing,TResult Function( ExportShareSheetOpen value)?  shareSheetOpen,TResult Function( ExportDone value)?  done,TResult Function( ExportFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExportIdle() when idle != null:
return idle(_that);case ExportPreparing() when preparing != null:
return preparing(_that);case ExportShareSheetOpen() when shareSheetOpen != null:
return shareSheetOpen(_that);case ExportDone() when done != null:
return done(_that);case ExportFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExportIdle value)  idle,required TResult Function( ExportPreparing value)  preparing,required TResult Function( ExportShareSheetOpen value)  shareSheetOpen,required TResult Function( ExportDone value)  done,required TResult Function( ExportFailed value)  failed,}){
final _that = this;
switch (_that) {
case ExportIdle():
return idle(_that);case ExportPreparing():
return preparing(_that);case ExportShareSheetOpen():
return shareSheetOpen(_that);case ExportDone():
return done(_that);case ExportFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExportIdle value)?  idle,TResult? Function( ExportPreparing value)?  preparing,TResult? Function( ExportShareSheetOpen value)?  shareSheetOpen,TResult? Function( ExportDone value)?  done,TResult? Function( ExportFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ExportIdle() when idle != null:
return idle(_that);case ExportPreparing() when preparing != null:
return preparing(_that);case ExportShareSheetOpen() when shareSheetOpen != null:
return shareSheetOpen(_that);case ExportDone() when done != null:
return done(_that);case ExportFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  preparing,TResult Function()?  shareSheetOpen,TResult Function( int entries)?  done,TResult Function( ErrorKind kind)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExportIdle() when idle != null:
return idle();case ExportPreparing() when preparing != null:
return preparing();case ExportShareSheetOpen() when shareSheetOpen != null:
return shareSheetOpen();case ExportDone() when done != null:
return done(_that.entries);case ExportFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  preparing,required TResult Function()  shareSheetOpen,required TResult Function( int entries)  done,required TResult Function( ErrorKind kind)  failed,}) {final _that = this;
switch (_that) {
case ExportIdle():
return idle();case ExportPreparing():
return preparing();case ExportShareSheetOpen():
return shareSheetOpen();case ExportDone():
return done(_that.entries);case ExportFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  preparing,TResult? Function()?  shareSheetOpen,TResult? Function( int entries)?  done,TResult? Function( ErrorKind kind)?  failed,}) {final _that = this;
switch (_that) {
case ExportIdle() when idle != null:
return idle();case ExportPreparing() when preparing != null:
return preparing();case ExportShareSheetOpen() when shareSheetOpen != null:
return shareSheetOpen();case ExportDone() when done != null:
return done(_that.entries);case ExportFailed() when failed != null:
return failed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class ExportIdle implements ExportState {
  const ExportIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportState.idle()';
}


}




/// @nodoc


class ExportPreparing implements ExportState {
  const ExportPreparing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportPreparing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportState.preparing()';
}


}




/// @nodoc


class ExportShareSheetOpen implements ExportState {
  const ExportShareSheetOpen();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportShareSheetOpen);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportState.shareSheetOpen()';
}


}




/// @nodoc


class ExportDone implements ExportState {
  const ExportDone({required this.entries});
  

 final  int entries;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportDoneCopyWith<ExportDone> get copyWith => _$ExportDoneCopyWithImpl<ExportDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDone&&(identical(other.entries, entries) || other.entries == entries));
}


@override
int get hashCode => Object.hash(runtimeType,entries);

@override
String toString() {
  return 'ExportState.done(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ExportDoneCopyWith<$Res> implements $ExportStateCopyWith<$Res> {
  factory $ExportDoneCopyWith(ExportDone value, $Res Function(ExportDone) _then) = _$ExportDoneCopyWithImpl;
@useResult
$Res call({
 int entries
});




}
/// @nodoc
class _$ExportDoneCopyWithImpl<$Res>
    implements $ExportDoneCopyWith<$Res> {
  _$ExportDoneCopyWithImpl(this._self, this._then);

  final ExportDone _self;
  final $Res Function(ExportDone) _then;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(ExportDone(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ExportFailed implements ExportState {
  const ExportFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportFailedCopyWith<ExportFailed> get copyWith => _$ExportFailedCopyWithImpl<ExportFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'ExportState.failed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $ExportFailedCopyWith<$Res> implements $ExportStateCopyWith<$Res> {
  factory $ExportFailedCopyWith(ExportFailed value, $Res Function(ExportFailed) _then) = _$ExportFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$ExportFailedCopyWithImpl<$Res>
    implements $ExportFailedCopyWith<$Res> {
  _$ExportFailedCopyWithImpl(this._self, this._then);

  final ExportFailed _self;
  final $Res Function(ExportFailed) _then;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(ExportFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

// dart format on
