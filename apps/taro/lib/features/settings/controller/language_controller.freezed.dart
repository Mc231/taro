// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LanguageState {

 String? get localeOverride; List<String> get locales;
/// Create a copy of LanguageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageStateCopyWith<LanguageState> get copyWith => _$LanguageStateCopyWithImpl<LanguageState>(this as LanguageState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LanguageState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageState&&(identical(other.localeOverride, _this.localeOverride) || other.localeOverride == _this.localeOverride)&&const DeepCollectionEquality().equals(other.locales, _this.locales));
}


@override
int get hashCode {
  final _this = this as LanguageState;
  return Object.hash(runtimeType,_this.localeOverride,const DeepCollectionEquality().hash(_this.locales));
}

@override
String toString() {
  final _this = this as LanguageState;
  return 'LanguageState(localeOverride: ${_this.localeOverride}, locales: ${_this.locales})';
}


}

/// @nodoc
abstract mixin class $LanguageStateCopyWith<$Res>  {
  factory $LanguageStateCopyWith(LanguageState value, $Res Function(LanguageState) _then) = _$LanguageStateCopyWithImpl;
@useResult
$Res call({
 String? localeOverride, List<String> locales
});




}
/// @nodoc
class _$LanguageStateCopyWithImpl<$Res>
    implements $LanguageStateCopyWith<$Res> {
  _$LanguageStateCopyWithImpl(this._self, this._then);

  final LanguageState _self;
  final $Res Function(LanguageState) _then;

/// Create a copy of LanguageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localeOverride = freezed,Object? locales = null,}) {
  return _then(LanguageState.content(
localeOverride: freezed == localeOverride ? _self.localeOverride : localeOverride // ignore: cast_nullable_to_non_nullable
as String?,locales: null == locales ? _self.locales : locales // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LanguageState].
extension LanguageStatePatterns on LanguageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LanguageContent value)?  content,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LanguageContent() when content != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LanguageContent value)  content,}){
final _that = this;
switch (_that) {
case LanguageContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LanguageContent value)?  content,}){
final _that = this;
switch (_that) {
case LanguageContent() when content != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? localeOverride,  List<String> locales)?  content,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LanguageContent() when content != null:
return content(_that.localeOverride,_that.locales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? localeOverride,  List<String> locales)  content,}) {final _that = this;
switch (_that) {
case LanguageContent():
return content(_that.localeOverride,_that.locales);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? localeOverride,  List<String> locales)?  content,}) {final _that = this;
switch (_that) {
case LanguageContent() when content != null:
return content(_that.localeOverride,_that.locales);case _:
  return null;

}
}

}

/// @nodoc


class LanguageContent implements LanguageState {
  const LanguageContent({required this.localeOverride, required  List<String> locales}): _locales = locales;
  

@override final  String? localeOverride;
 final  List<String> _locales;
@override List<String> get locales {
  if (_locales is EqualUnmodifiableListView) return _locales;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locales);
}


/// Create a copy of LanguageState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageContentCopyWith<LanguageContent> get copyWith => _$LanguageContentCopyWithImpl<LanguageContent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguageContent&&(identical(other.localeOverride, localeOverride) || other.localeOverride == localeOverride)&&const DeepCollectionEquality().equals(other.locales, _locales));
}


@override
int get hashCode {
    return Object.hash(runtimeType,localeOverride,const DeepCollectionEquality().hash(_locales));
}

@override
String toString() {
    return 'LanguageState.content(localeOverride: $localeOverride, locales: $locales)';
}


}

/// @nodoc
abstract mixin class $LanguageContentCopyWith<$Res> implements $LanguageStateCopyWith<$Res> {
  factory $LanguageContentCopyWith(LanguageContent value, $Res Function(LanguageContent) _then) = _$LanguageContentCopyWithImpl;
@override @useResult
$Res call({
 String? localeOverride, List<String> locales
});




}
/// @nodoc
class _$LanguageContentCopyWithImpl<$Res>
    implements $LanguageContentCopyWith<$Res> {
  _$LanguageContentCopyWithImpl(this._self, this._then);

  final LanguageContent _self;
  final $Res Function(LanguageContent) _then;

/// Create a copy of LanguageState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localeOverride = freezed,Object? locales = null,}) {
  return _then(LanguageContent(
localeOverride: freezed == localeOverride ? _self.localeOverride : localeOverride // ignore: cast_nullable_to_non_nullable
as String?,locales: null == locales ? _self._locales : locales // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
