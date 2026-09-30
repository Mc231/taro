// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LegalState {

 LegalDoc get doc; String? get url;
/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalStateCopyWith<LegalState> get copyWith => _$LegalStateCopyWithImpl<LegalState>(this as LegalState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalState&&(identical(other.doc, doc) || other.doc == doc)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,doc,url);

@override
String toString() {
  return 'LegalState(doc: $doc, url: $url)';
}


}

/// @nodoc
abstract mixin class $LegalStateCopyWith<$Res>  {
  factory $LegalStateCopyWith(LegalState value, $Res Function(LegalState) _then) = _$LegalStateCopyWithImpl;
@useResult
$Res call({
 LegalDoc doc, String url
});




}
/// @nodoc
class _$LegalStateCopyWithImpl<$Res>
    implements $LegalStateCopyWith<$Res> {
  _$LegalStateCopyWithImpl(this._self, this._then);

  final LegalState _self;
  final $Res Function(LegalState) _then;

/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? doc = null,Object? url = null,}) {
  return _then(_self.copyWith(
doc: null == doc ? _self.doc : doc // ignore: cast_nullable_to_non_nullable
as LegalDoc,url: null == url ? _self.url! : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalState].
extension LegalStatePatterns on LegalState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LegalContent value)?  content,TResult Function( LegalOffline value)?  offline,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LegalContent() when content != null:
return content(_that);case LegalOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LegalContent value)  content,required TResult Function( LegalOffline value)  offline,}){
final _that = this;
switch (_that) {
case LegalContent():
return content(_that);case LegalOffline():
return offline(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LegalContent value)?  content,TResult? Function( LegalOffline value)?  offline,}){
final _that = this;
switch (_that) {
case LegalContent() when content != null:
return content(_that);case LegalOffline() when offline != null:
return offline(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LegalDoc doc,  String? url)?  content,TResult Function( LegalDoc doc,  String url)?  offline,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LegalContent() when content != null:
return content(_that.doc,_that.url);case LegalOffline() when offline != null:
return offline(_that.doc,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LegalDoc doc,  String? url)  content,required TResult Function( LegalDoc doc,  String url)  offline,}) {final _that = this;
switch (_that) {
case LegalContent():
return content(_that.doc,_that.url);case LegalOffline():
return offline(_that.doc,_that.url);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LegalDoc doc,  String? url)?  content,TResult? Function( LegalDoc doc,  String url)?  offline,}) {final _that = this;
switch (_that) {
case LegalContent() when content != null:
return content(_that.doc,_that.url);case LegalOffline() when offline != null:
return offline(_that.doc,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class LegalContent implements LegalState {
  const LegalContent({required this.doc, this.url});
  

@override final  LegalDoc doc;
@override final  String? url;

/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalContentCopyWith<LegalContent> get copyWith => _$LegalContentCopyWithImpl<LegalContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalContent&&(identical(other.doc, doc) || other.doc == doc)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,doc,url);

@override
String toString() {
  return 'LegalState.content(doc: $doc, url: $url)';
}


}

/// @nodoc
abstract mixin class $LegalContentCopyWith<$Res> implements $LegalStateCopyWith<$Res> {
  factory $LegalContentCopyWith(LegalContent value, $Res Function(LegalContent) _then) = _$LegalContentCopyWithImpl;
@override @useResult
$Res call({
 LegalDoc doc, String? url
});




}
/// @nodoc
class _$LegalContentCopyWithImpl<$Res>
    implements $LegalContentCopyWith<$Res> {
  _$LegalContentCopyWithImpl(this._self, this._then);

  final LegalContent _self;
  final $Res Function(LegalContent) _then;

/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? doc = null,Object? url = freezed,}) {
  return _then(LegalContent(
doc: null == doc ? _self.doc : doc // ignore: cast_nullable_to_non_nullable
as LegalDoc,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LegalOffline implements LegalState {
  const LegalOffline({required this.doc, required this.url});
  

@override final  LegalDoc doc;
@override final  String url;

/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalOfflineCopyWith<LegalOffline> get copyWith => _$LegalOfflineCopyWithImpl<LegalOffline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalOffline&&(identical(other.doc, doc) || other.doc == doc)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,doc,url);

@override
String toString() {
  return 'LegalState.offline(doc: $doc, url: $url)';
}


}

/// @nodoc
abstract mixin class $LegalOfflineCopyWith<$Res> implements $LegalStateCopyWith<$Res> {
  factory $LegalOfflineCopyWith(LegalOffline value, $Res Function(LegalOffline) _then) = _$LegalOfflineCopyWithImpl;
@override @useResult
$Res call({
 LegalDoc doc, String url
});




}
/// @nodoc
class _$LegalOfflineCopyWithImpl<$Res>
    implements $LegalOfflineCopyWith<$Res> {
  _$LegalOfflineCopyWithImpl(this._self, this._then);

  final LegalOffline _self;
  final $Res Function(LegalOffline) _then;

/// Create a copy of LegalState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? doc = null,Object? url = null,}) {
  return _then(LegalOffline(
doc: null == doc ? _self.doc : doc // ignore: cast_nullable_to_non_nullable
as LegalDoc,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
