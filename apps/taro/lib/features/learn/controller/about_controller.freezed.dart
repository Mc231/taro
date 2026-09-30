// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutState()';
}


}

/// @nodoc
class $AboutStateCopyWith<$Res>  {
$AboutStateCopyWith(AboutState _, $Res Function(AboutState) __);
}


/// Adds pattern-matching-related methods to [AboutState].
extension AboutStatePatterns on AboutState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AboutLoading value)?  loading,TResult Function( AboutContent value)?  content,TResult Function( AboutStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AboutLoading() when loading != null:
return loading(_that);case AboutContent() when content != null:
return content(_that);case AboutStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AboutLoading value)  loading,required TResult Function( AboutContent value)  content,required TResult Function( AboutStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case AboutLoading():
return loading(_that);case AboutContent():
return content(_that);case AboutStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AboutLoading value)?  loading,TResult? Function( AboutContent value)?  content,TResult? Function( AboutStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case AboutLoading() when loading != null:
return loading(_that);case AboutContent() when content != null:
return content(_that);case AboutStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Article article)?  content,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AboutLoading() when loading != null:
return loading();case AboutContent() when content != null:
return content(_that.article);case AboutStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Article article)  content,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case AboutLoading():
return loading();case AboutContent():
return content(_that.article);case AboutStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Article article)?  content,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case AboutLoading() when loading != null:
return loading();case AboutContent() when content != null:
return content(_that.article);case AboutStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class AboutLoading implements AboutState {
  const AboutLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutState.loading()';
}


}




/// @nodoc


class AboutContent implements AboutState {
  const AboutContent(this.article);
  

 final  Article article;

/// Create a copy of AboutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutContentCopyWith<AboutContent> get copyWith => _$AboutContentCopyWithImpl<AboutContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutContent&&(identical(other.article, article) || other.article == article));
}


@override
int get hashCode => Object.hash(runtimeType,article);

@override
String toString() {
  return 'AboutState.content(article: $article)';
}


}

/// @nodoc
abstract mixin class $AboutContentCopyWith<$Res> implements $AboutStateCopyWith<$Res> {
  factory $AboutContentCopyWith(AboutContent value, $Res Function(AboutContent) _then) = _$AboutContentCopyWithImpl;
@useResult
$Res call({
 Article article
});




}
/// @nodoc
class _$AboutContentCopyWithImpl<$Res>
    implements $AboutContentCopyWith<$Res> {
  _$AboutContentCopyWithImpl(this._self, this._then);

  final AboutContent _self;
  final $Res Function(AboutContent) _then;

/// Create a copy of AboutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? article = null,}) {
  return _then(AboutContent(
null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as Article,
  ));
}


}

/// @nodoc


class AboutStorageError implements AboutState {
  const AboutStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutState.storageError()';
}


}




// dart format on
