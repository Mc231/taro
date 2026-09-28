// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crisis_resource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CrisisResource {

/// Display name, e.g. "Telefonseelsorge".
 String get name;/// When a person last verified this entry.
 DateTime get verifiedAt;/// Languages served (BCP 47); empty = not stated.
 List<String> get languages;/// Phone number as dialled.
 String? get phone;/// SMS number or short code.
 String? get sms;/// Web or chat URL.
 String? get url;/// Opening hours, e.g. "24/7".
 String? get hours;
/// Create a copy of CrisisResource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrisisResourceCopyWith<CrisisResource> get copyWith => _$CrisisResourceCopyWithImpl<CrisisResource>(this as CrisisResource, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisResource&&(identical(other.name, name) || other.name == name)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&const DeepCollectionEquality().equals(other.languages, languages)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.sms, sms) || other.sms == sms)&&(identical(other.url, url) || other.url == url)&&(identical(other.hours, hours) || other.hours == hours));
}


@override
int get hashCode => Object.hash(runtimeType,name,verifiedAt,const DeepCollectionEquality().hash(languages),phone,sms,url,hours);

@override
String toString() {
  return 'CrisisResource(name: $name, verifiedAt: $verifiedAt, languages: $languages, phone: $phone, sms: $sms, url: $url, hours: $hours)';
}


}

/// @nodoc
abstract mixin class $CrisisResourceCopyWith<$Res>  {
  factory $CrisisResourceCopyWith(CrisisResource value, $Res Function(CrisisResource) _then) = _$CrisisResourceCopyWithImpl;
@useResult
$Res call({
 String name, DateTime verifiedAt, List<String> languages, String? phone, String? sms, String? url, String? hours
});




}
/// @nodoc
class _$CrisisResourceCopyWithImpl<$Res>
    implements $CrisisResourceCopyWith<$Res> {
  _$CrisisResourceCopyWithImpl(this._self, this._then);

  final CrisisResource _self;
  final $Res Function(CrisisResource) _then;

/// Create a copy of CrisisResource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? verifiedAt = null,Object? languages = null,Object? phone = freezed,Object? sms = freezed,Object? url = freezed,Object? hours = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verifiedAt: null == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,sms: freezed == sms ? _self.sms : sms // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CrisisResource].
extension CrisisResourcePatterns on CrisisResource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrisisResource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrisisResource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrisisResource value)  $default,){
final _that = this;
switch (_that) {
case _CrisisResource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrisisResource value)?  $default,){
final _that = this;
switch (_that) {
case _CrisisResource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  DateTime verifiedAt,  List<String> languages,  String? phone,  String? sms,  String? url,  String? hours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrisisResource() when $default != null:
return $default(_that.name,_that.verifiedAt,_that.languages,_that.phone,_that.sms,_that.url,_that.hours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  DateTime verifiedAt,  List<String> languages,  String? phone,  String? sms,  String? url,  String? hours)  $default,) {final _that = this;
switch (_that) {
case _CrisisResource():
return $default(_that.name,_that.verifiedAt,_that.languages,_that.phone,_that.sms,_that.url,_that.hours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  DateTime verifiedAt,  List<String> languages,  String? phone,  String? sms,  String? url,  String? hours)?  $default,) {final _that = this;
switch (_that) {
case _CrisisResource() when $default != null:
return $default(_that.name,_that.verifiedAt,_that.languages,_that.phone,_that.sms,_that.url,_that.hours);case _:
  return null;

}
}

}

/// @nodoc


class _CrisisResource extends CrisisResource {
  const _CrisisResource({required this.name, required this.verifiedAt, final  List<String> languages = const <String>[], this.phone, this.sms, this.url, this.hours}): _languages = languages,super._();
  

/// Display name, e.g. "Telefonseelsorge".
@override final  String name;
/// When a person last verified this entry.
@override final  DateTime verifiedAt;
/// Languages served (BCP 47); empty = not stated.
 final  List<String> _languages;
/// Languages served (BCP 47); empty = not stated.
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

/// Phone number as dialled.
@override final  String? phone;
/// SMS number or short code.
@override final  String? sms;
/// Web or chat URL.
@override final  String? url;
/// Opening hours, e.g. "24/7".
@override final  String? hours;

/// Create a copy of CrisisResource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrisisResourceCopyWith<_CrisisResource> get copyWith => __$CrisisResourceCopyWithImpl<_CrisisResource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrisisResource&&(identical(other.name, name) || other.name == name)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&const DeepCollectionEquality().equals(other._languages, _languages)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.sms, sms) || other.sms == sms)&&(identical(other.url, url) || other.url == url)&&(identical(other.hours, hours) || other.hours == hours));
}


@override
int get hashCode => Object.hash(runtimeType,name,verifiedAt,const DeepCollectionEquality().hash(_languages),phone,sms,url,hours);

@override
String toString() {
  return 'CrisisResource(name: $name, verifiedAt: $verifiedAt, languages: $languages, phone: $phone, sms: $sms, url: $url, hours: $hours)';
}


}

/// @nodoc
abstract mixin class _$CrisisResourceCopyWith<$Res> implements $CrisisResourceCopyWith<$Res> {
  factory _$CrisisResourceCopyWith(_CrisisResource value, $Res Function(_CrisisResource) _then) = __$CrisisResourceCopyWithImpl;
@override @useResult
$Res call({
 String name, DateTime verifiedAt, List<String> languages, String? phone, String? sms, String? url, String? hours
});




}
/// @nodoc
class __$CrisisResourceCopyWithImpl<$Res>
    implements _$CrisisResourceCopyWith<$Res> {
  __$CrisisResourceCopyWithImpl(this._self, this._then);

  final _CrisisResource _self;
  final $Res Function(_CrisisResource) _then;

/// Create a copy of CrisisResource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? verifiedAt = null,Object? languages = null,Object? phone = freezed,Object? sms = freezed,Object? url = freezed,Object? hours = freezed,}) {
  return _then(_CrisisResource(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verifiedAt: null == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,sms: freezed == sms ? _self.sms : sms // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CrisisDirectory {

/// Resources by ISO 3166-1 alpha-2 country code.
 Map<String, List<CrisisResource>> get countries;/// Country to use for a locale when the country is unknown; `null`
/// values mean "international only".
 Map<String, String?> get localeFallback;/// Always-included international entries (e.g. Find A Helpline).
 List<CrisisResource> get international;
/// Create a copy of CrisisDirectory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrisisDirectoryCopyWith<CrisisDirectory> get copyWith => _$CrisisDirectoryCopyWithImpl<CrisisDirectory>(this as CrisisDirectory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrisisDirectory&&const DeepCollectionEquality().equals(other.countries, countries)&&const DeepCollectionEquality().equals(other.localeFallback, localeFallback)&&const DeepCollectionEquality().equals(other.international, international));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(countries),const DeepCollectionEquality().hash(localeFallback),const DeepCollectionEquality().hash(international));

@override
String toString() {
  return 'CrisisDirectory(countries: $countries, localeFallback: $localeFallback, international: $international)';
}


}

/// @nodoc
abstract mixin class $CrisisDirectoryCopyWith<$Res>  {
  factory $CrisisDirectoryCopyWith(CrisisDirectory value, $Res Function(CrisisDirectory) _then) = _$CrisisDirectoryCopyWithImpl;
@useResult
$Res call({
 Map<String, List<CrisisResource>> countries, Map<String, String?> localeFallback, List<CrisisResource> international
});




}
/// @nodoc
class _$CrisisDirectoryCopyWithImpl<$Res>
    implements $CrisisDirectoryCopyWith<$Res> {
  _$CrisisDirectoryCopyWithImpl(this._self, this._then);

  final CrisisDirectory _self;
  final $Res Function(CrisisDirectory) _then;

/// Create a copy of CrisisDirectory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? countries = null,Object? localeFallback = null,Object? international = null,}) {
  return _then(_self.copyWith(
countries: null == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as Map<String, List<CrisisResource>>,localeFallback: null == localeFallback ? _self.localeFallback : localeFallback // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,international: null == international ? _self.international : international // ignore: cast_nullable_to_non_nullable
as List<CrisisResource>,
  ));
}

}


/// Adds pattern-matching-related methods to [CrisisDirectory].
extension CrisisDirectoryPatterns on CrisisDirectory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrisisDirectory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrisisDirectory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrisisDirectory value)  $default,){
final _that = this;
switch (_that) {
case _CrisisDirectory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrisisDirectory value)?  $default,){
final _that = this;
switch (_that) {
case _CrisisDirectory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, List<CrisisResource>> countries,  Map<String, String?> localeFallback,  List<CrisisResource> international)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrisisDirectory() when $default != null:
return $default(_that.countries,_that.localeFallback,_that.international);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, List<CrisisResource>> countries,  Map<String, String?> localeFallback,  List<CrisisResource> international)  $default,) {final _that = this;
switch (_that) {
case _CrisisDirectory():
return $default(_that.countries,_that.localeFallback,_that.international);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, List<CrisisResource>> countries,  Map<String, String?> localeFallback,  List<CrisisResource> international)?  $default,) {final _that = this;
switch (_that) {
case _CrisisDirectory() when $default != null:
return $default(_that.countries,_that.localeFallback,_that.international);case _:
  return null;

}
}

}

/// @nodoc


class _CrisisDirectory extends CrisisDirectory {
  const _CrisisDirectory({required final  Map<String, List<CrisisResource>> countries, required final  Map<String, String?> localeFallback, required final  List<CrisisResource> international}): _countries = countries,_localeFallback = localeFallback,_international = international,super._();
  

/// Resources by ISO 3166-1 alpha-2 country code.
 final  Map<String, List<CrisisResource>> _countries;
/// Resources by ISO 3166-1 alpha-2 country code.
@override Map<String, List<CrisisResource>> get countries {
  if (_countries is EqualUnmodifiableMapView) return _countries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_countries);
}

/// Country to use for a locale when the country is unknown; `null`
/// values mean "international only".
 final  Map<String, String?> _localeFallback;
/// Country to use for a locale when the country is unknown; `null`
/// values mean "international only".
@override Map<String, String?> get localeFallback {
  if (_localeFallback is EqualUnmodifiableMapView) return _localeFallback;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localeFallback);
}

/// Always-included international entries (e.g. Find A Helpline).
 final  List<CrisisResource> _international;
/// Always-included international entries (e.g. Find A Helpline).
@override List<CrisisResource> get international {
  if (_international is EqualUnmodifiableListView) return _international;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_international);
}


/// Create a copy of CrisisDirectory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrisisDirectoryCopyWith<_CrisisDirectory> get copyWith => __$CrisisDirectoryCopyWithImpl<_CrisisDirectory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrisisDirectory&&const DeepCollectionEquality().equals(other._countries, _countries)&&const DeepCollectionEquality().equals(other._localeFallback, _localeFallback)&&const DeepCollectionEquality().equals(other._international, _international));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_countries),const DeepCollectionEquality().hash(_localeFallback),const DeepCollectionEquality().hash(_international));

@override
String toString() {
  return 'CrisisDirectory(countries: $countries, localeFallback: $localeFallback, international: $international)';
}


}

/// @nodoc
abstract mixin class _$CrisisDirectoryCopyWith<$Res> implements $CrisisDirectoryCopyWith<$Res> {
  factory _$CrisisDirectoryCopyWith(_CrisisDirectory value, $Res Function(_CrisisDirectory) _then) = __$CrisisDirectoryCopyWithImpl;
@override @useResult
$Res call({
 Map<String, List<CrisisResource>> countries, Map<String, String?> localeFallback, List<CrisisResource> international
});




}
/// @nodoc
class __$CrisisDirectoryCopyWithImpl<$Res>
    implements _$CrisisDirectoryCopyWith<$Res> {
  __$CrisisDirectoryCopyWithImpl(this._self, this._then);

  final _CrisisDirectory _self;
  final $Res Function(_CrisisDirectory) _then;

/// Create a copy of CrisisDirectory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? countries = null,Object? localeFallback = null,Object? international = null,}) {
  return _then(_CrisisDirectory(
countries: null == countries ? _self._countries : countries // ignore: cast_nullable_to_non_nullable
as Map<String, List<CrisisResource>>,localeFallback: null == localeFallback ? _self._localeFallback : localeFallback // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,international: null == international ? _self._international : international // ignore: cast_nullable_to_non_nullable
as List<CrisisResource>,
  ));
}


}

// dart format on
