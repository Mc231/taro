// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faq_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FaqState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FaqState()';
}


}

/// @nodoc
class $FaqStateCopyWith<$Res>  {
$FaqStateCopyWith(FaqState _, $Res Function(FaqState) __);
}


/// Adds pattern-matching-related methods to [FaqState].
extension FaqStatePatterns on FaqState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FaqLoading value)?  loading,TResult Function( FaqContent value)?  content,TResult Function( FaqSearchEmpty value)?  searchEmpty,TResult Function( FaqStorageError value)?  storageError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FaqLoading() when loading != null:
return loading(_that);case FaqContent() when content != null:
return content(_that);case FaqSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case FaqStorageError() when storageError != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FaqLoading value)  loading,required TResult Function( FaqContent value)  content,required TResult Function( FaqSearchEmpty value)  searchEmpty,required TResult Function( FaqStorageError value)  storageError,}){
final _that = this;
switch (_that) {
case FaqLoading():
return loading(_that);case FaqContent():
return content(_that);case FaqSearchEmpty():
return searchEmpty(_that);case FaqStorageError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FaqLoading value)?  loading,TResult? Function( FaqContent value)?  content,TResult? Function( FaqSearchEmpty value)?  searchEmpty,TResult? Function( FaqStorageError value)?  storageError,}){
final _that = this;
switch (_that) {
case FaqLoading() when loading != null:
return loading(_that);case FaqContent() when content != null:
return content(_that);case FaqSearchEmpty() when searchEmpty != null:
return searchEmpty(_that);case FaqStorageError() when storageError != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<ArticleSection> sections,  String query,  Set<String> expanded,  SupportInfo? support)?  content,TResult Function( String query,  SupportInfo? support)?  searchEmpty,TResult Function()?  storageError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FaqLoading() when loading != null:
return loading();case FaqContent() when content != null:
return content(_that.sections,_that.query,_that.expanded,_that.support);case FaqSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query,_that.support);case FaqStorageError() when storageError != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<ArticleSection> sections,  String query,  Set<String> expanded,  SupportInfo? support)  content,required TResult Function( String query,  SupportInfo? support)  searchEmpty,required TResult Function()  storageError,}) {final _that = this;
switch (_that) {
case FaqLoading():
return loading();case FaqContent():
return content(_that.sections,_that.query,_that.expanded,_that.support);case FaqSearchEmpty():
return searchEmpty(_that.query,_that.support);case FaqStorageError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<ArticleSection> sections,  String query,  Set<String> expanded,  SupportInfo? support)?  content,TResult? Function( String query,  SupportInfo? support)?  searchEmpty,TResult? Function()?  storageError,}) {final _that = this;
switch (_that) {
case FaqLoading() when loading != null:
return loading();case FaqContent() when content != null:
return content(_that.sections,_that.query,_that.expanded,_that.support);case FaqSearchEmpty() when searchEmpty != null:
return searchEmpty(_that.query,_that.support);case FaqStorageError() when storageError != null:
return storageError();case _:
  return null;

}
}

}

/// @nodoc


class FaqLoading implements FaqState {
  const FaqLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FaqState.loading()';
}


}




/// @nodoc


class FaqContent implements FaqState {
  const FaqContent({required final  List<ArticleSection> sections, this.query = '', final  Set<String> expanded = const <String>{}, this.support}): _sections = sections,_expanded = expanded;
  

 final  List<ArticleSection> _sections;
 List<ArticleSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// The search text (empty when not searching).
@JsonKey() final  String query;
/// Titles of the expanded questions.
 final  Set<String> _expanded;
/// Titles of the expanded questions.
@JsonKey() Set<String> get expanded {
  if (_expanded is EqualUnmodifiableSetView) return _expanded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_expanded);
}

/// Email, Support ID and diagnostics for "Email support"; `null` until
/// the install is known.
 final  SupportInfo? support;

/// Create a copy of FaqState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaqContentCopyWith<FaqContent> get copyWith => _$FaqContentCopyWithImpl<FaqContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqContent&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._expanded, _expanded)&&(identical(other.support, support) || other.support == support));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sections),query,const DeepCollectionEquality().hash(_expanded),support);

@override
String toString() {
  return 'FaqState.content(sections: $sections, query: $query, expanded: $expanded, support: $support)';
}


}

/// @nodoc
abstract mixin class $FaqContentCopyWith<$Res> implements $FaqStateCopyWith<$Res> {
  factory $FaqContentCopyWith(FaqContent value, $Res Function(FaqContent) _then) = _$FaqContentCopyWithImpl;
@useResult
$Res call({
 List<ArticleSection> sections, String query, Set<String> expanded, SupportInfo? support
});




}
/// @nodoc
class _$FaqContentCopyWithImpl<$Res>
    implements $FaqContentCopyWith<$Res> {
  _$FaqContentCopyWithImpl(this._self, this._then);

  final FaqContent _self;
  final $Res Function(FaqContent) _then;

/// Create a copy of FaqState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sections = null,Object? query = null,Object? expanded = null,Object? support = freezed,}) {
  return _then(FaqContent(
sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<ArticleSection>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,expanded: null == expanded ? _self._expanded : expanded // ignore: cast_nullable_to_non_nullable
as Set<String>,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as SupportInfo?,
  ));
}


}

/// @nodoc


class FaqSearchEmpty implements FaqState {
  const FaqSearchEmpty({required this.query, this.support});
  

 final  String query;
 final  SupportInfo? support;

/// Create a copy of FaqState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaqSearchEmptyCopyWith<FaqSearchEmpty> get copyWith => _$FaqSearchEmptyCopyWithImpl<FaqSearchEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqSearchEmpty&&(identical(other.query, query) || other.query == query)&&(identical(other.support, support) || other.support == support));
}


@override
int get hashCode => Object.hash(runtimeType,query,support);

@override
String toString() {
  return 'FaqState.searchEmpty(query: $query, support: $support)';
}


}

/// @nodoc
abstract mixin class $FaqSearchEmptyCopyWith<$Res> implements $FaqStateCopyWith<$Res> {
  factory $FaqSearchEmptyCopyWith(FaqSearchEmpty value, $Res Function(FaqSearchEmpty) _then) = _$FaqSearchEmptyCopyWithImpl;
@useResult
$Res call({
 String query, SupportInfo? support
});




}
/// @nodoc
class _$FaqSearchEmptyCopyWithImpl<$Res>
    implements $FaqSearchEmptyCopyWith<$Res> {
  _$FaqSearchEmptyCopyWithImpl(this._self, this._then);

  final FaqSearchEmpty _self;
  final $Res Function(FaqSearchEmpty) _then;

/// Create a copy of FaqState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? support = freezed,}) {
  return _then(FaqSearchEmpty(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as SupportInfo?,
  ));
}


}

/// @nodoc


class FaqStorageError implements FaqState {
  const FaqStorageError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqStorageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FaqState.storageError()';
}


}




// dart format on
