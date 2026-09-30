// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsRestore {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRestore);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsRestore()';
}


}

/// @nodoc
class $SettingsRestoreCopyWith<$Res>  {
$SettingsRestoreCopyWith(SettingsRestore _, $Res Function(SettingsRestore) __);
}


/// Adds pattern-matching-related methods to [SettingsRestore].
extension SettingsRestorePatterns on SettingsRestore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsRestoreIdle value)?  idle,TResult Function( SettingsRestoreInProgress value)?  inProgress,TResult Function( SettingsRestoreSuccess value)?  success,TResult Function( SettingsRestoreFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsRestoreIdle() when idle != null:
return idle(_that);case SettingsRestoreInProgress() when inProgress != null:
return inProgress(_that);case SettingsRestoreSuccess() when success != null:
return success(_that);case SettingsRestoreFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsRestoreIdle value)  idle,required TResult Function( SettingsRestoreInProgress value)  inProgress,required TResult Function( SettingsRestoreSuccess value)  success,required TResult Function( SettingsRestoreFailed value)  failed,}){
final _that = this;
switch (_that) {
case SettingsRestoreIdle():
return idle(_that);case SettingsRestoreInProgress():
return inProgress(_that);case SettingsRestoreSuccess():
return success(_that);case SettingsRestoreFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsRestoreIdle value)?  idle,TResult? Function( SettingsRestoreInProgress value)?  inProgress,TResult? Function( SettingsRestoreSuccess value)?  success,TResult? Function( SettingsRestoreFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SettingsRestoreIdle() when idle != null:
return idle(_that);case SettingsRestoreInProgress() when inProgress != null:
return inProgress(_that);case SettingsRestoreSuccess() when success != null:
return success(_that);case SettingsRestoreFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  inProgress,TResult Function( RestoreFinding finding)?  success,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsRestoreIdle() when idle != null:
return idle();case SettingsRestoreInProgress() when inProgress != null:
return inProgress();case SettingsRestoreSuccess() when success != null:
return success(_that.finding);case SettingsRestoreFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  inProgress,required TResult Function( RestoreFinding finding)  success,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SettingsRestoreIdle():
return idle();case SettingsRestoreInProgress():
return inProgress();case SettingsRestoreSuccess():
return success(_that.finding);case SettingsRestoreFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  inProgress,TResult? Function( RestoreFinding finding)?  success,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SettingsRestoreIdle() when idle != null:
return idle();case SettingsRestoreInProgress() when inProgress != null:
return inProgress();case SettingsRestoreSuccess() when success != null:
return success(_that.finding);case SettingsRestoreFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SettingsRestoreIdle implements SettingsRestore {
  const SettingsRestoreIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRestoreIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsRestore.idle()';
}


}




/// @nodoc


class SettingsRestoreInProgress implements SettingsRestore {
  const SettingsRestoreInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRestoreInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsRestore.inProgress()';
}


}




/// @nodoc


class SettingsRestoreSuccess implements SettingsRestore {
  const SettingsRestoreSuccess(this.finding);
  

 final  RestoreFinding finding;

/// Create a copy of SettingsRestore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsRestoreSuccessCopyWith<SettingsRestoreSuccess> get copyWith => _$SettingsRestoreSuccessCopyWithImpl<SettingsRestoreSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRestoreSuccess&&(identical(other.finding, finding) || other.finding == finding));
}


@override
int get hashCode => Object.hash(runtimeType,finding);

@override
String toString() {
  return 'SettingsRestore.success(finding: $finding)';
}


}

/// @nodoc
abstract mixin class $SettingsRestoreSuccessCopyWith<$Res> implements $SettingsRestoreCopyWith<$Res> {
  factory $SettingsRestoreSuccessCopyWith(SettingsRestoreSuccess value, $Res Function(SettingsRestoreSuccess) _then) = _$SettingsRestoreSuccessCopyWithImpl;
@useResult
$Res call({
 RestoreFinding finding
});




}
/// @nodoc
class _$SettingsRestoreSuccessCopyWithImpl<$Res>
    implements $SettingsRestoreSuccessCopyWith<$Res> {
  _$SettingsRestoreSuccessCopyWithImpl(this._self, this._then);

  final SettingsRestoreSuccess _self;
  final $Res Function(SettingsRestoreSuccess) _then;

/// Create a copy of SettingsRestore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? finding = null,}) {
  return _then(SettingsRestoreSuccess(
null == finding ? _self.finding : finding // ignore: cast_nullable_to_non_nullable
as RestoreFinding,
  ));
}


}

/// @nodoc


class SettingsRestoreFailed implements SettingsRestore {
  const SettingsRestoreFailed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsRestoreFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsRestore.failed()';
}


}




/// @nodoc
mixin _$SettingsTransfer {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransfer);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsTransfer()';
}


}

/// @nodoc
class $SettingsTransferCopyWith<$Res>  {
$SettingsTransferCopyWith(SettingsTransfer _, $Res Function(SettingsTransfer) __);
}


/// Adds pattern-matching-related methods to [SettingsTransfer].
extension SettingsTransferPatterns on SettingsTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsTransferIdle value)?  idle,TResult Function( SettingsTransferChecking value)?  checking,TResult Function( SettingsTransferCode value)?  code,TResult Function( SettingsTransferNotEligible value)?  notEligible,TResult Function( SettingsTransferNothing value)?  nothingFound,TResult Function( SettingsTransferFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsTransferIdle() when idle != null:
return idle(_that);case SettingsTransferChecking() when checking != null:
return checking(_that);case SettingsTransferCode() when code != null:
return code(_that);case SettingsTransferNotEligible() when notEligible != null:
return notEligible(_that);case SettingsTransferNothing() when nothingFound != null:
return nothingFound(_that);case SettingsTransferFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsTransferIdle value)  idle,required TResult Function( SettingsTransferChecking value)  checking,required TResult Function( SettingsTransferCode value)  code,required TResult Function( SettingsTransferNotEligible value)  notEligible,required TResult Function( SettingsTransferNothing value)  nothingFound,required TResult Function( SettingsTransferFailed value)  failed,}){
final _that = this;
switch (_that) {
case SettingsTransferIdle():
return idle(_that);case SettingsTransferChecking():
return checking(_that);case SettingsTransferCode():
return code(_that);case SettingsTransferNotEligible():
return notEligible(_that);case SettingsTransferNothing():
return nothingFound(_that);case SettingsTransferFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsTransferIdle value)?  idle,TResult? Function( SettingsTransferChecking value)?  checking,TResult? Function( SettingsTransferCode value)?  code,TResult? Function( SettingsTransferNotEligible value)?  notEligible,TResult? Function( SettingsTransferNothing value)?  nothingFound,TResult? Function( SettingsTransferFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SettingsTransferIdle() when idle != null:
return idle(_that);case SettingsTransferChecking() when checking != null:
return checking(_that);case SettingsTransferCode() when code != null:
return code(_that);case SettingsTransferNotEligible() when notEligible != null:
return notEligible(_that);case SettingsTransferNothing() when nothingFound != null:
return nothingFound(_that);case SettingsTransferFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  checking,TResult Function( String transferCode)?  code,TResult Function()?  notEligible,TResult Function()?  nothingFound,TResult Function( ErrorKind kind)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsTransferIdle() when idle != null:
return idle();case SettingsTransferChecking() when checking != null:
return checking();case SettingsTransferCode() when code != null:
return code(_that.transferCode);case SettingsTransferNotEligible() when notEligible != null:
return notEligible();case SettingsTransferNothing() when nothingFound != null:
return nothingFound();case SettingsTransferFailed() when failed != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  checking,required TResult Function( String transferCode)  code,required TResult Function()  notEligible,required TResult Function()  nothingFound,required TResult Function( ErrorKind kind)  failed,}) {final _that = this;
switch (_that) {
case SettingsTransferIdle():
return idle();case SettingsTransferChecking():
return checking();case SettingsTransferCode():
return code(_that.transferCode);case SettingsTransferNotEligible():
return notEligible();case SettingsTransferNothing():
return nothingFound();case SettingsTransferFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  checking,TResult? Function( String transferCode)?  code,TResult? Function()?  notEligible,TResult? Function()?  nothingFound,TResult? Function( ErrorKind kind)?  failed,}) {final _that = this;
switch (_that) {
case SettingsTransferIdle() when idle != null:
return idle();case SettingsTransferChecking() when checking != null:
return checking();case SettingsTransferCode() when code != null:
return code(_that.transferCode);case SettingsTransferNotEligible() when notEligible != null:
return notEligible();case SettingsTransferNothing() when nothingFound != null:
return nothingFound();case SettingsTransferFailed() when failed != null:
return failed(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class SettingsTransferIdle implements SettingsTransfer {
  const SettingsTransferIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsTransfer.idle()';
}


}




/// @nodoc


class SettingsTransferChecking implements SettingsTransfer {
  const SettingsTransferChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsTransfer.checking()';
}


}




/// @nodoc


class SettingsTransferCode implements SettingsTransfer {
  const SettingsTransferCode(this.transferCode);
  

 final  String transferCode;

/// Create a copy of SettingsTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsTransferCodeCopyWith<SettingsTransferCode> get copyWith => _$SettingsTransferCodeCopyWithImpl<SettingsTransferCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferCode&&(identical(other.transferCode, transferCode) || other.transferCode == transferCode));
}


@override
int get hashCode => Object.hash(runtimeType,transferCode);

@override
String toString() {
  return 'SettingsTransfer.code(transferCode: $transferCode)';
}


}

/// @nodoc
abstract mixin class $SettingsTransferCodeCopyWith<$Res> implements $SettingsTransferCopyWith<$Res> {
  factory $SettingsTransferCodeCopyWith(SettingsTransferCode value, $Res Function(SettingsTransferCode) _then) = _$SettingsTransferCodeCopyWithImpl;
@useResult
$Res call({
 String transferCode
});




}
/// @nodoc
class _$SettingsTransferCodeCopyWithImpl<$Res>
    implements $SettingsTransferCodeCopyWith<$Res> {
  _$SettingsTransferCodeCopyWithImpl(this._self, this._then);

  final SettingsTransferCode _self;
  final $Res Function(SettingsTransferCode) _then;

/// Create a copy of SettingsTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transferCode = null,}) {
  return _then(SettingsTransferCode(
null == transferCode ? _self.transferCode : transferCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SettingsTransferNotEligible implements SettingsTransfer {
  const SettingsTransferNotEligible();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferNotEligible);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsTransfer.notEligible()';
}


}




/// @nodoc


class SettingsTransferNothing implements SettingsTransfer {
  const SettingsTransferNothing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferNothing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsTransfer.nothingFound()';
}


}




/// @nodoc


class SettingsTransferFailed implements SettingsTransfer {
  const SettingsTransferFailed(this.kind);
  

 final  ErrorKind kind;

/// Create a copy of SettingsTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsTransferFailedCopyWith<SettingsTransferFailed> get copyWith => _$SettingsTransferFailedCopyWithImpl<SettingsTransferFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsTransferFailed&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'SettingsTransfer.failed(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $SettingsTransferFailedCopyWith<$Res> implements $SettingsTransferCopyWith<$Res> {
  factory $SettingsTransferFailedCopyWith(SettingsTransferFailed value, $Res Function(SettingsTransferFailed) _then) = _$SettingsTransferFailedCopyWithImpl;
@useResult
$Res call({
 ErrorKind kind
});




}
/// @nodoc
class _$SettingsTransferFailedCopyWithImpl<$Res>
    implements $SettingsTransferFailedCopyWith<$Res> {
  _$SettingsTransferFailedCopyWithImpl(this._self, this._then);

  final SettingsTransferFailed _self;
  final $Res Function(SettingsTransferFailed) _then;

/// Create a copy of SettingsTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(SettingsTransferFailed(
null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ErrorKind,
  ));
}


}

/// @nodoc
mixin _$SettingsView {

 UserSettings get settings;/// The balance row ("3 readings · 1 free today").
 CreditBalance? get balance;/// `adsRemoved`: "Banner ads removed ✓", no price.
 bool get adsRemoved;/// Whether Remove Banner Ads is offered (`store.removeAdsEnabled`).
 bool get removeAdsOffered;/// The AI readings row (Allowed / Not allowed).
 bool get aiConsentGranted;/// About: version, build and the Support ID (RC43); `null` until the
/// install is known.
 SupportInfo? get support;
/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsViewCopyWith<SettingsView> get copyWith => _$SettingsViewCopyWithImpl<SettingsView>(this as SettingsView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsView&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&(identical(other.removeAdsOffered, removeAdsOffered) || other.removeAdsOffered == removeAdsOffered)&&(identical(other.aiConsentGranted, aiConsentGranted) || other.aiConsentGranted == aiConsentGranted)&&(identical(other.support, support) || other.support == support));
}


@override
int get hashCode => Object.hash(runtimeType,settings,balance,adsRemoved,removeAdsOffered,aiConsentGranted,support);

@override
String toString() {
  return 'SettingsView(settings: $settings, balance: $balance, adsRemoved: $adsRemoved, removeAdsOffered: $removeAdsOffered, aiConsentGranted: $aiConsentGranted, support: $support)';
}


}

/// @nodoc
abstract mixin class $SettingsViewCopyWith<$Res>  {
  factory $SettingsViewCopyWith(SettingsView value, $Res Function(SettingsView) _then) = _$SettingsViewCopyWithImpl;
@useResult
$Res call({
 UserSettings settings, CreditBalance? balance, bool adsRemoved, bool removeAdsOffered, bool aiConsentGranted, SupportInfo? support
});


$UserSettingsCopyWith<$Res> get settings;$CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class _$SettingsViewCopyWithImpl<$Res>
    implements $SettingsViewCopyWith<$Res> {
  _$SettingsViewCopyWithImpl(this._self, this._then);

  final SettingsView _self;
  final $Res Function(SettingsView) _then;

/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? balance = freezed,Object? adsRemoved = null,Object? removeAdsOffered = null,Object? aiConsentGranted = null,Object? support = freezed,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,removeAdsOffered: null == removeAdsOffered ? _self.removeAdsOffered : removeAdsOffered // ignore: cast_nullable_to_non_nullable
as bool,aiConsentGranted: null == aiConsentGranted ? _self.aiConsentGranted : aiConsentGranted // ignore: cast_nullable_to_non_nullable
as bool,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as SupportInfo?,
  ));
}
/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $CreditBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsView].
extension SettingsViewPatterns on SettingsView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsView value)  $default,){
final _that = this;
switch (_that) {
case _SettingsView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsView value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserSettings settings,  CreditBalance? balance,  bool adsRemoved,  bool removeAdsOffered,  bool aiConsentGranted,  SupportInfo? support)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsView() when $default != null:
return $default(_that.settings,_that.balance,_that.adsRemoved,_that.removeAdsOffered,_that.aiConsentGranted,_that.support);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserSettings settings,  CreditBalance? balance,  bool adsRemoved,  bool removeAdsOffered,  bool aiConsentGranted,  SupportInfo? support)  $default,) {final _that = this;
switch (_that) {
case _SettingsView():
return $default(_that.settings,_that.balance,_that.adsRemoved,_that.removeAdsOffered,_that.aiConsentGranted,_that.support);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserSettings settings,  CreditBalance? balance,  bool adsRemoved,  bool removeAdsOffered,  bool aiConsentGranted,  SupportInfo? support)?  $default,) {final _that = this;
switch (_that) {
case _SettingsView() when $default != null:
return $default(_that.settings,_that.balance,_that.adsRemoved,_that.removeAdsOffered,_that.aiConsentGranted,_that.support);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsView implements SettingsView {
  const _SettingsView({required this.settings, required this.balance, required this.adsRemoved, required this.removeAdsOffered, required this.aiConsentGranted, this.support});
  

@override final  UserSettings settings;
/// The balance row ("3 readings · 1 free today").
@override final  CreditBalance? balance;
/// `adsRemoved`: "Banner ads removed ✓", no price.
@override final  bool adsRemoved;
/// Whether Remove Banner Ads is offered (`store.removeAdsEnabled`).
@override final  bool removeAdsOffered;
/// The AI readings row (Allowed / Not allowed).
@override final  bool aiConsentGranted;
/// About: version, build and the Support ID (RC43); `null` until the
/// install is known.
@override final  SupportInfo? support;

/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsViewCopyWith<_SettingsView> get copyWith => __$SettingsViewCopyWithImpl<_SettingsView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsView&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&(identical(other.removeAdsOffered, removeAdsOffered) || other.removeAdsOffered == removeAdsOffered)&&(identical(other.aiConsentGranted, aiConsentGranted) || other.aiConsentGranted == aiConsentGranted)&&(identical(other.support, support) || other.support == support));
}


@override
int get hashCode => Object.hash(runtimeType,settings,balance,adsRemoved,removeAdsOffered,aiConsentGranted,support);

@override
String toString() {
  return 'SettingsView(settings: $settings, balance: $balance, adsRemoved: $adsRemoved, removeAdsOffered: $removeAdsOffered, aiConsentGranted: $aiConsentGranted, support: $support)';
}


}

/// @nodoc
abstract mixin class _$SettingsViewCopyWith<$Res> implements $SettingsViewCopyWith<$Res> {
  factory _$SettingsViewCopyWith(_SettingsView value, $Res Function(_SettingsView) _then) = __$SettingsViewCopyWithImpl;
@override @useResult
$Res call({
 UserSettings settings, CreditBalance? balance, bool adsRemoved, bool removeAdsOffered, bool aiConsentGranted, SupportInfo? support
});


@override $UserSettingsCopyWith<$Res> get settings;@override $CreditBalanceCopyWith<$Res>? get balance;

}
/// @nodoc
class __$SettingsViewCopyWithImpl<$Res>
    implements _$SettingsViewCopyWith<$Res> {
  __$SettingsViewCopyWithImpl(this._self, this._then);

  final _SettingsView _self;
  final $Res Function(_SettingsView) _then;

/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? balance = freezed,Object? adsRemoved = null,Object? removeAdsOffered = null,Object? aiConsentGranted = null,Object? support = freezed,}) {
  return _then(_SettingsView(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,removeAdsOffered: null == removeAdsOffered ? _self.removeAdsOffered : removeAdsOffered // ignore: cast_nullable_to_non_nullable
as bool,aiConsentGranted: null == aiConsentGranted ? _self.aiConsentGranted : aiConsentGranted // ignore: cast_nullable_to_non_nullable
as bool,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as SupportInfo?,
  ));
}

/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of SettingsView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreditBalanceCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $CreditBalanceCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}

/// @nodoc
mixin _$SettingsScreenState {

 SettingsView get view; SettingsRestore get restore; SettingsTransfer get transfer;
/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsScreenStateCopyWith<SettingsScreenState> get copyWith => _$SettingsScreenStateCopyWithImpl<SettingsScreenState>(this as SettingsScreenState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsScreenState&&(identical(other.view, view) || other.view == view)&&(identical(other.restore, restore) || other.restore == restore)&&(identical(other.transfer, transfer) || other.transfer == transfer));
}


@override
int get hashCode => Object.hash(runtimeType,view,restore,transfer);

@override
String toString() {
  return 'SettingsScreenState(view: $view, restore: $restore, transfer: $transfer)';
}


}

/// @nodoc
abstract mixin class $SettingsScreenStateCopyWith<$Res>  {
  factory $SettingsScreenStateCopyWith(SettingsScreenState value, $Res Function(SettingsScreenState) _then) = _$SettingsScreenStateCopyWithImpl;
@useResult
$Res call({
 SettingsView view, SettingsRestore restore, SettingsTransfer transfer
});


$SettingsViewCopyWith<$Res> get view;$SettingsRestoreCopyWith<$Res> get restore;$SettingsTransferCopyWith<$Res> get transfer;

}
/// @nodoc
class _$SettingsScreenStateCopyWithImpl<$Res>
    implements $SettingsScreenStateCopyWith<$Res> {
  _$SettingsScreenStateCopyWithImpl(this._self, this._then);

  final SettingsScreenState _self;
  final $Res Function(SettingsScreenState) _then;

/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? view = null,Object? restore = null,Object? transfer = null,}) {
  return _then(_self.copyWith(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as SettingsView,restore: null == restore ? _self.restore : restore // ignore: cast_nullable_to_non_nullable
as SettingsRestore,transfer: null == transfer ? _self.transfer : transfer // ignore: cast_nullable_to_non_nullable
as SettingsTransfer,
  ));
}
/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsViewCopyWith<$Res> get view {
  
  return $SettingsViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsRestoreCopyWith<$Res> get restore {
  
  return $SettingsRestoreCopyWith<$Res>(_self.restore, (value) {
    return _then(_self.copyWith(restore: value));
  });
}/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsTransferCopyWith<$Res> get transfer {
  
  return $SettingsTransferCopyWith<$Res>(_self.transfer, (value) {
    return _then(_self.copyWith(transfer: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsScreenState].
extension SettingsScreenStatePatterns on SettingsScreenState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsContent value)?  content,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsContent() when content != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsContent value)  content,}){
final _that = this;
switch (_that) {
case SettingsContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsContent value)?  content,}){
final _that = this;
switch (_that) {
case SettingsContent() when content != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SettingsView view,  SettingsRestore restore,  SettingsTransfer transfer)?  content,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsContent() when content != null:
return content(_that.view,_that.restore,_that.transfer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SettingsView view,  SettingsRestore restore,  SettingsTransfer transfer)  content,}) {final _that = this;
switch (_that) {
case SettingsContent():
return content(_that.view,_that.restore,_that.transfer);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SettingsView view,  SettingsRestore restore,  SettingsTransfer transfer)?  content,}) {final _that = this;
switch (_that) {
case SettingsContent() when content != null:
return content(_that.view,_that.restore,_that.transfer);case _:
  return null;

}
}

}

/// @nodoc


class SettingsContent implements SettingsScreenState {
  const SettingsContent({required this.view, required this.restore, required this.transfer});
  

@override final  SettingsView view;
@override final  SettingsRestore restore;
@override final  SettingsTransfer transfer;

/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsContentCopyWith<SettingsContent> get copyWith => _$SettingsContentCopyWithImpl<SettingsContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsContent&&(identical(other.view, view) || other.view == view)&&(identical(other.restore, restore) || other.restore == restore)&&(identical(other.transfer, transfer) || other.transfer == transfer));
}


@override
int get hashCode => Object.hash(runtimeType,view,restore,transfer);

@override
String toString() {
  return 'SettingsScreenState.content(view: $view, restore: $restore, transfer: $transfer)';
}


}

/// @nodoc
abstract mixin class $SettingsContentCopyWith<$Res> implements $SettingsScreenStateCopyWith<$Res> {
  factory $SettingsContentCopyWith(SettingsContent value, $Res Function(SettingsContent) _then) = _$SettingsContentCopyWithImpl;
@override @useResult
$Res call({
 SettingsView view, SettingsRestore restore, SettingsTransfer transfer
});


@override $SettingsViewCopyWith<$Res> get view;@override $SettingsRestoreCopyWith<$Res> get restore;@override $SettingsTransferCopyWith<$Res> get transfer;

}
/// @nodoc
class _$SettingsContentCopyWithImpl<$Res>
    implements $SettingsContentCopyWith<$Res> {
  _$SettingsContentCopyWithImpl(this._self, this._then);

  final SettingsContent _self;
  final $Res Function(SettingsContent) _then;

/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? view = null,Object? restore = null,Object? transfer = null,}) {
  return _then(SettingsContent(
view: null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as SettingsView,restore: null == restore ? _self.restore : restore // ignore: cast_nullable_to_non_nullable
as SettingsRestore,transfer: null == transfer ? _self.transfer : transfer // ignore: cast_nullable_to_non_nullable
as SettingsTransfer,
  ));
}

/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsViewCopyWith<$Res> get view {
  
  return $SettingsViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsRestoreCopyWith<$Res> get restore {
  
  return $SettingsRestoreCopyWith<$Res>(_self.restore, (value) {
    return _then(_self.copyWith(restore: value));
  });
}/// Create a copy of SettingsScreenState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SettingsTransferCopyWith<$Res> get transfer {
  
  return $SettingsTransferCopyWith<$Res>(_self.transfer, (value) {
    return _then(_self.copyWith(transfer: value));
  });
}
}

// dart format on
