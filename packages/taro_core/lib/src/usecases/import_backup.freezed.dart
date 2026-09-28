// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportPreview {

 BackupV1 get backup;
/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportPreviewCopyWith<ImportPreview> get copyWith => _$ImportPreviewCopyWithImpl<ImportPreview>(this as ImportPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportPreview&&(identical(other.backup, backup) || other.backup == backup));
}


@override
int get hashCode => Object.hash(runtimeType,backup);

@override
String toString() {
  return 'ImportPreview(backup: $backup)';
}


}

/// @nodoc
abstract mixin class $ImportPreviewCopyWith<$Res>  {
  factory $ImportPreviewCopyWith(ImportPreview value, $Res Function(ImportPreview) _then) = _$ImportPreviewCopyWithImpl;
@useResult
$Res call({
 BackupV1 backup
});


$BackupV1CopyWith<$Res> get backup;

}
/// @nodoc
class _$ImportPreviewCopyWithImpl<$Res>
    implements $ImportPreviewCopyWith<$Res> {
  _$ImportPreviewCopyWithImpl(this._self, this._then);

  final ImportPreview _self;
  final $Res Function(ImportPreview) _then;

/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backup = null,}) {
  return _then(_self.copyWith(
backup: null == backup ? _self.backup : backup // ignore: cast_nullable_to_non_nullable
as BackupV1,
  ));
}
/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackupV1CopyWith<$Res> get backup {
  
  return $BackupV1CopyWith<$Res>(_self.backup, (value) {
    return _then(_self.copyWith(backup: value));
  });
}
}


/// Adds pattern-matching-related methods to [ImportPreview].
extension ImportPreviewPatterns on ImportPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportPreview value)  $default,){
final _that = this;
switch (_that) {
case _ImportPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportPreview value)?  $default,){
final _that = this;
switch (_that) {
case _ImportPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BackupV1 backup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportPreview() when $default != null:
return $default(_that.backup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BackupV1 backup)  $default,) {final _that = this;
switch (_that) {
case _ImportPreview():
return $default(_that.backup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BackupV1 backup)?  $default,) {final _that = this;
switch (_that) {
case _ImportPreview() when $default != null:
return $default(_that.backup);case _:
  return null;

}
}

}

/// @nodoc


class _ImportPreview extends ImportPreview {
  const _ImportPreview(this.backup): super._();
  

@override final  BackupV1 backup;

/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportPreviewCopyWith<_ImportPreview> get copyWith => __$ImportPreviewCopyWithImpl<_ImportPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportPreview&&(identical(other.backup, backup) || other.backup == backup));
}


@override
int get hashCode => Object.hash(runtimeType,backup);

@override
String toString() {
  return 'ImportPreview(backup: $backup)';
}


}

/// @nodoc
abstract mixin class _$ImportPreviewCopyWith<$Res> implements $ImportPreviewCopyWith<$Res> {
  factory _$ImportPreviewCopyWith(_ImportPreview value, $Res Function(_ImportPreview) _then) = __$ImportPreviewCopyWithImpl;
@override @useResult
$Res call({
 BackupV1 backup
});


@override $BackupV1CopyWith<$Res> get backup;

}
/// @nodoc
class __$ImportPreviewCopyWithImpl<$Res>
    implements _$ImportPreviewCopyWith<$Res> {
  __$ImportPreviewCopyWithImpl(this._self, this._then);

  final _ImportPreview _self;
  final $Res Function(_ImportPreview) _then;

/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backup = null,}) {
  return _then(_ImportPreview(
null == backup ? _self.backup : backup // ignore: cast_nullable_to_non_nullable
as BackupV1,
  ));
}

/// Create a copy of ImportPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackupV1CopyWith<$Res> get backup {
  
  return $BackupV1CopyWith<$Res>(_self.backup, (value) {
    return _then(_self.copyWith(backup: value));
  });
}
}

// dart format on
