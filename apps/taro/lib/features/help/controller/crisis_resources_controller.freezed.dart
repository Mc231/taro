// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crisis_resources_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CrisisResourcesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisResourcesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CrisisResourcesState()';
}


}

/// @nodoc
class $CrisisResourcesStateCopyWith<$Res>  {
$CrisisResourcesStateCopyWith(CrisisResourcesState _, $Res Function(CrisisResourcesState) __);
}


/// Adds pattern-matching-related methods to [CrisisResourcesState].
extension CrisisResourcesStatePatterns on CrisisResourcesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CrisisResourcesLoading value)?  loading,TResult Function( CrisisResourcesContent value)?  content,TResult Function( CrisisResourcesStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CrisisResourcesLoading() when loading != null:
return loading(_that);case CrisisResourcesContent() when content != null:
return content(_that);case CrisisResourcesStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CrisisResourcesLoading value)  loading,required TResult Function( CrisisResourcesContent value)  content,required TResult Function( CrisisResourcesStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case CrisisResourcesLoading():
return loading(_that);case CrisisResourcesContent():
return content(_that);case CrisisResourcesStorageError():
return storageError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CrisisResourcesLoading value)?  loading,TResult? Function( CrisisResourcesContent value)?  content,TResult? Function( CrisisResourcesStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case CrisisResourcesLoading() when loading != null:
return loading(_that);case CrisisResourcesContent() when content != null:
return content(_that);case CrisisResourcesStorageError() when storageError != null:
return storageError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( String? country,  List<CrisisResource> resources,  bool hasLocalLines,  List<String> countries)?  content,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CrisisResourcesLoading() when loading != null:
return loading();case CrisisResourcesContent() when content != null:
return content(_that.country,_that.resources,_that.hasLocalLines,_that.countries);case CrisisResourcesStorageError() when storageError != null:
return storageError();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( String? country,  List<CrisisResource> resources,  bool hasLocalLines,  List<String> countries)  content,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case CrisisResourcesLoading():
return loading();case CrisisResourcesContent():
return content(_that.country,_that.resources,_that.hasLocalLines,_that.countries);case CrisisResourcesStorageError():
return storageError();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( String? country,  List<CrisisResource> resources,  bool hasLocalLines,  List<String> countries)?  content,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case CrisisResourcesLoading() when loading != null:
return loading();case CrisisResourcesContent() when content != null:
return content(_that.country,_that.resources,_that.hasLocalLines,_that.countries);case CrisisResourcesStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class CrisisResourcesLoading implements CrisisResourcesState {
  const CrisisResourcesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisResourcesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CrisisResourcesState.loading()';
}


}




/// @nodoc


class CrisisResourcesContent implements CrisisResourcesState {
  const CrisisResourcesContent({required this.country, required final  List<CrisisResource> resources, required this.hasLocalLines, required final  List<String> countries}): _resources = resources,_countries = countries;
  

/// The selected country, if known.
 final  String? country;
/// The lines to show (≤ 3).
 final  List<CrisisResource> _resources;
/// The lines to show (≤ 3).
 List<CrisisResource> get resources {
  if (_resources is EqualUnmodifiableListView) return _resources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resources);
}

/// Whether `country` has its own lines (else only the international
/// entry: "no entry for the region").
 final  bool hasLocalLines;
/// Countries of the "Show resources for another country" picker.
 final  List<String> _countries;
/// Countries of the "Show resources for another country" picker.
 List<String> get countries {
  if (_countries is EqualUnmodifiableListView) return _countries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_countries);
}


/// Create a copy of CrisisResourcesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrisisResourcesContentCopyWith<CrisisResourcesContent> get copyWith => _$CrisisResourcesContentCopyWithImpl<CrisisResourcesContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisResourcesContent&&(identical(other.country, country) || other.country == country)&&const DeepCollectionEquality().equals(other._resources, _resources)&&(identical(other.hasLocalLines, hasLocalLines) || other.hasLocalLines == hasLocalLines)&&const DeepCollectionEquality().equals(other._countries, _countries));
}


@override
int get hashCode => Object.hash(runtimeType,country,const DeepCollectionEquality().hash(_resources),hasLocalLines,const DeepCollectionEquality().hash(_countries));

@override
String toString() {
  return 'CrisisResourcesState.content(country: $country, resources: $resources, hasLocalLines: $hasLocalLines, countries: $countries)';
}


}

/// @nodoc
abstract mixin class $CrisisResourcesContentCopyWith<$Res> implements $CrisisResourcesStateCopyWith<$Res> {
  factory $CrisisResourcesContentCopyWith(CrisisResourcesContent value, $Res Function(CrisisResourcesContent) _then) = _$CrisisResourcesContentCopyWithImpl;
@useResult
$Res call({
 String? country, List<CrisisResource> resources, bool hasLocalLines, List<String> countries
});




}
/// @nodoc
class _$CrisisResourcesContentCopyWithImpl<$Res>
    implements $CrisisResourcesContentCopyWith<$Res> {
  _$CrisisResourcesContentCopyWithImpl(this._self, this._then);

  final CrisisResourcesContent _self;
  final $Res Function(CrisisResourcesContent) _then;

/// Create a copy of CrisisResourcesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? country = freezed,Object? resources = null,Object? hasLocalLines = null,Object? countries = null,}) {
  return _then(CrisisResourcesContent(
country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,resources: null == resources ? _self._resources : resources // ignore: cast_nullable_to_non_nullable
as List<CrisisResource>,hasLocalLines: null == hasLocalLines ? _self.hasLocalLines : hasLocalLines // ignore: cast_nullable_to_non_nullable
as bool,countries: null == countries ? _self._countries : countries // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class CrisisResourcesStorageError implements CrisisResourcesState {
  const CrisisResourcesStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisResourcesStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CrisisResourcesState.storageError()';
}


}




// dart format on
