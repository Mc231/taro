// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ImportState()';
}


}

/// @nodoc
class $ImportStateCopyWith<$Res>  {
$ImportStateCopyWith(ImportState _, $Res Function(ImportState) __);
}


/// Adds pattern-matching-related methods to [ImportState].
extension ImportStatePatterns on ImportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ImportPicking value)?  picking,TResult Function( ImportValidating value)?  validating,TResult Function( ImportInvalid value)?  invalid,TResult Function( ImportPreviewing value)?  preview,TResult Function( ImportConfirmReplace value)?  confirmReplace,TResult Function( ImportImporting value)?  importing,TResult Function( ImportDone value)?  done,TResult Function( ImportFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ImportPicking() when picking != null:
return picking(_that);case ImportValidating() when validating != null:
return validating(_that);case ImportInvalid() when invalid != null:
return invalid(_that);case ImportPreviewing() when preview != null:
return preview(_that);case ImportConfirmReplace() when confirmReplace != null:
return confirmReplace(_that);case ImportImporting() when importing != null:
return importing(_that);case ImportDone() when done != null:
return done(_that);case ImportFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ImportPicking value)  picking,required TResult Function( ImportValidating value)  validating,required TResult Function( ImportInvalid value)  invalid,required TResult Function( ImportPreviewing value)  preview,required TResult Function( ImportConfirmReplace value)  confirmReplace,required TResult Function( ImportImporting value)  importing,required TResult Function( ImportDone value)  done,required TResult Function( ImportFailed value)  failed,}){
final _that = this;
switch (_that) {
case ImportPicking():
return picking(_that);case ImportValidating():
return validating(_that);case ImportInvalid():
return invalid(_that);case ImportPreviewing():
return preview(_that);case ImportConfirmReplace():
return confirmReplace(_that);case ImportImporting():
return importing(_that);case ImportDone():
return done(_that);case ImportFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ImportPicking value)?  picking,TResult? Function( ImportValidating value)?  validating,TResult? Function( ImportInvalid value)?  invalid,TResult? Function( ImportPreviewing value)?  preview,TResult? Function( ImportConfirmReplace value)?  confirmReplace,TResult? Function( ImportImporting value)?  importing,TResult? Function( ImportDone value)?  done,TResult? Function( ImportFailed value)?  failed,}){
final _that = this;
switch (_that) {
case ImportPicking() when picking != null:
return picking(_that);case ImportValidating() when validating != null:
return validating(_that);case ImportInvalid() when invalid != null:
return invalid(_that);case ImportPreviewing() when preview != null:
return preview(_that);case ImportConfirmReplace() when confirmReplace != null:
return confirmReplace(_that);case ImportImporting() when importing != null:
return importing(_that);case ImportDone() when done != null:
return done(_that);case ImportFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  picking,TResult Function()?  validating,TResult Function( ImportInvalidReason reason)?  invalid,TResult Function( ImportPreview preview,  MergeMode mode)?  preview,TResult Function( ImportPreview preview,  int localEntries)?  confirmReplace,TResult Function( double progress)?  importing,TResult Function( MergeReport summary,  int readings,  int dailyCards)?  done,TResult Function( ErrorKind kind)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ImportPicking() when picking != null:
return picking();case ImportValidating() when validating != null:
return validating();case ImportInvalid() when invalid != null:
return invalid(_that.reason);case ImportPreviewing() when preview != null:
return preview(_that.preview,_that.mode);case ImportConfirmReplace() when confirmReplace != null:
return confirmReplace(_that.preview,_that.localEntries);case ImportImporting() when importing != null:
return importing(_that.progress);case ImportDone() when done != null:
return done(_that.summary,_that.readings,_that.dailyCards);case ImportFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  picking,required TResult Function()  validating,required TResult Function( ImportInvalidReason reason)  invalid,required TResult Function( ImportPreview preview,  MergeMode mode)  preview,required TResult Function( ImportPreview preview,  int localEntries)  confirmReplace,required TResult Function( double progress)  importing,required TResult Function( MergeReport summary,  int readings,  int dailyCards)  done,required TResult Function( ErrorKind kind)  failed,}) {final _that = this;
switch (_that) {
case ImportPicking():
return picking();case ImportValidating():
return validating();case ImportInvalid():
return invalid(_that.reason);case ImportPreviewing():
return preview(_that.preview,_that.mode);case ImportConfirmReplace():
return confirmReplace(_that.preview,_that.localEntries);case ImportImporting():
return importing(_that.progress);case ImportDone():
return done(_that.summary,_that.readings,_that.dailyCards);case ImportFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  picking,TResult? Function()?  validating,TResult? Function( ImportInvalidReason reason)?  invalid,TResult? Function( ImportPreview preview,  MergeMode mode)?  preview,TResult? Function( ImportPreview preview,  int localEntries)?  confirmReplace,TResult? Function( double progress)?  importing,TResult? Function( MergeReport summary,  int readings,  int dailyCards)?  done,TResult? Function( ErrorKind kind)?  failed,}) {final _that = this;
switch (_that) {
case ImportPicking() when picking != null:
return picking();case ImportValidating() when validating != null:
return validating();case ImportInvalid() when invalid != null:
return invalid(_that.reason);case ImportPreviewing() when preview != null:
return preview(_that.preview,_that.mode);case ImportConfirmReplace() when confirmReplace != null:
return confirmReplace(_that.preview,_that.localEntries);case ImportImporting() when importing != null:
return importing(_that.progress);case ImportDone() when done != null:
return done(_that.summary,_that.readings,_that.dailyCards);case ImportFailed() when failed != null:
return failed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class ImportPicking implements ImportState {
  const ImportPicking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportPicking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ImportState.picking()';
}


}




/// @nodoc


class ImportValidating implements ImportState {
  const ImportValidating();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportValidating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ImportState.validating()';
}


}




/// @nodoc


class ImportInvalid implements ImportState {
  const ImportInvalid(this.reason);
  

 final  ImportInvalidReason reason;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportInvalidCopyWith<ImportInvalid> get copyWith => _$ImportInvalidCopyWithImpl<ImportInvalid>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportInvalid&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'ImportState.invalid(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ImportInvalidCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportInvalidCopyWith(ImportInvalid value, $Res Function(ImportInvalid) _then) = _$ImportInvalidCopyWithImpl;
@useResult
$Res call({
 ImportInvalidReason reason
});




}
/// @nodoc
class _$ImportInvalidCopyWithImpl<$Res>
    implements $ImportInvalidCopyWith<$Res> {
  _$ImportInvalidCopyWithImpl(this._self, this._then);

  final ImportInvalid _self;
  final $Res Function(ImportInvalid) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(ImportInvalid(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as ImportInvalidReason,
  ));
}


}

/// @nodoc


class ImportPreviewing implements ImportState {
  const ImportPreviewing(this.preview, {this.mode = MergeMode.merge});
  

 final  ImportPreview preview;
@JsonKey() final  MergeMode mode;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportPreviewingCopyWith<ImportPreviewing> get copyWith => _$ImportPreviewingCopyWithImpl<ImportPreviewing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportPreviewing&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,preview,mode);

@override
String toString() {
  return 'ImportState.preview(preview: $preview, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $ImportPreviewingCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportPreviewingCopyWith(ImportPreviewing value, $Res Function(ImportPreviewing) _then) = _$ImportPreviewingCopyWithImpl;
@useResult
$Res call({
 ImportPreview preview, MergeMode mode
});


$ImportPreviewCopyWith<$Res> get preview;

}
/// @nodoc
class _$ImportPreviewingCopyWithImpl<$Res>
    implements $ImportPreviewingCopyWith<$Res> {
  _$ImportPreviewingCopyWithImpl(this._self, this._then);

  final ImportPreviewing _self;
  final $Res Function(ImportPreviewing) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preview = null,Object? mode = null,}) {
  return _then(ImportPreviewing(
null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as ImportPreview,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MergeMode,
  ));
}

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImportPreviewCopyWith<$Res> get preview {
  
  return $ImportPreviewCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}
}

/// @nodoc


class ImportConfirmReplace implements ImportState {
  const ImportConfirmReplace(this.preview, {required this.localEntries});
  

 final  ImportPreview preview;
 final  int localEntries;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportConfirmReplaceCopyWith<ImportConfirmReplace> get copyWith => _$ImportConfirmReplaceCopyWithImpl<ImportConfirmReplace>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportConfirmReplace&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.localEntries, localEntries) || other.localEntries == localEntries));
}


@override
int get hashCode => Object.hash(runtimeType,preview,localEntries);

@override
String toString() {
  return 'ImportState.confirmReplace(preview: $preview, localEntries: $localEntries)';
}


}

/// @nodoc
abstract mixin class $ImportConfirmReplaceCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportConfirmReplaceCopyWith(ImportConfirmReplace value, $Res Function(ImportConfirmReplace) _then) = _$ImportConfirmReplaceCopyWithImpl;
@useResult
$Res call({
 ImportPreview preview, int localEntries
});


$ImportPreviewCopyWith<$Res> get preview;

}
/// @nodoc
class _$ImportConfirmReplaceCopyWithImpl<$Res>
    implements $ImportConfirmReplaceCopyWith<$Res> {
  _$ImportConfirmReplaceCopyWithImpl(this._self, this._then);

  final ImportConfirmReplace _self;
  final $Res Function(ImportConfirmReplace) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preview = null,Object? localEntries = null,}) {
  return _then(ImportConfirmReplace(
null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as ImportPreview,localEntries: null == localEntries ? _self.localEntries : localEntries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImportPreviewCopyWith<$Res> get preview {
  
  return $ImportPreviewCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}
}

/// @nodoc


class ImportImporting implements ImportState {
  const ImportImporting({required this.progress});
  

 final  double progress;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportImportingCopyWith<ImportImporting> get copyWith => _$ImportImportingCopyWithImpl<ImportImporting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportImporting&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,progress);

@override
String toString() {
  return 'ImportState.importing(progress: $progress)';
}


}

/// @nodoc
abstract mixin class $ImportImportingCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportImportingCopyWith(ImportImporting value, $Res Function(ImportImporting) _then) = _$ImportImportingCopyWithImpl;
@useResult
$Res call({
 double progress
});




}
/// @nodoc
class _$ImportImportingCopyWithImpl<$Res>
    implements $ImportImportingCopyWith<$Res> {
  _$ImportImportingCopyWithImpl(this._self, this._then);

  final ImportImporting _self;
  final $Res Function(ImportImporting) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,}) {
  return _then(ImportImporting(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class ImportDone implements ImportState {
  const ImportDone({required this.summary, required this.readings, required this.dailyCards});
  

 final  MergeReport summary;
 final  int readings;
 final  int dailyCards;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportDoneCopyWith<ImportDone> get copyWith => _$ImportDoneCopyWithImpl<ImportDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportDone&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.readings, readings) || other.readings == readings)&&(identical(other.dailyCards, dailyCards) || other.dailyCards == dailyCards));
}


@override
int get hashCode => Object.hash(runtimeType,summary,readings,dailyCards);

@override
String toString() {
  return 'ImportState.done(summary: $summary, readings: $readings, dailyCards: $dailyCards)';
}


}

/// @nodoc
abstract mixin class $ImportDoneCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportDoneCopyWith(ImportDone value, $Res Function(ImportDone) _then) = _$ImportDoneCopyWithImpl;
@useResult
$Res call({
 MergeReport summary, int readings, int dailyCards
});


$MergeReportCopyWith<$Res> get summary;

}
/// @nodoc
class _$ImportDoneCopyWithImpl<$Res>
    implements $ImportDoneCopyWith<$Res> {
  _$ImportDoneCopyWithImpl(this._self, this._then);

  final ImportDone _self;
  final $Res Function(ImportDone) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? readings = null,Object? dailyCards = null,}) {
  return _then(ImportDone(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as MergeReport,readings: null == readings ? _self.readings : readings // ignore: cast_nullable_to_non_nullable
as int,dailyCards: null == dailyCards ? _self.dailyCards : dailyCards // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MergeReportCopyWith<$Res> get summary {
  
  return $MergeReportCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class ImportFailed implements ImportState {
  const ImportFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportFailedCopyWith<ImportFailed> get copyWith => _$ImportFailedCopyWithImpl<ImportFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'ImportState.failed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $ImportFailedCopyWith<$Res> implements $ImportStateCopyWith<$Res> {
  factory $ImportFailedCopyWith(ImportFailed value, $Res Function(ImportFailed) _then) = _$ImportFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$ImportFailedCopyWithImpl<$Res>
    implements $ImportFailedCopyWith<$Res> {
  _$ImportFailedCopyWithImpl(this._self, this._then);

  final ImportFailed _self;
  final $Res Function(ImportFailed) _then;

/// Create a copy of ImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(ImportFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

// dart format on
