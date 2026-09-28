// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SafetyInfo {

/// The refusal category.
 RefusalCategory get category;/// ARB key of the message.
 String get messageKey;/// Whether the user may rephrase and try again.
 bool get canRephrase;/// Helplines to show (S27) for crisis categories.
 List<CrisisResource> get crisisResources;
/// Create a copy of SafetyInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<SafetyInfo> get copyWith => _$SafetyInfoCopyWithImpl<SafetyInfo>(this as SafetyInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SafetyInfo&&(identical(other.category, category) || other.category == category)&&(identical(other.messageKey, messageKey) || other.messageKey == messageKey)&&(identical(other.canRephrase, canRephrase) || other.canRephrase == canRephrase)&&const DeepCollectionEquality().equals(other.crisisResources, crisisResources));
}


@override
int get hashCode => Object.hash(runtimeType,category,messageKey,canRephrase,const DeepCollectionEquality().hash(crisisResources));

@override
String toString() {
  return 'SafetyInfo(category: $category, messageKey: $messageKey, canRephrase: $canRephrase, crisisResources: $crisisResources)';
}


}

/// @nodoc
abstract mixin class $SafetyInfoCopyWith<$Res>  {
  factory $SafetyInfoCopyWith(SafetyInfo value, $Res Function(SafetyInfo) _then) = _$SafetyInfoCopyWithImpl;
@useResult
$Res call({
 RefusalCategory category, String messageKey, bool canRephrase, List<CrisisResource> crisisResources
});




}
/// @nodoc
class _$SafetyInfoCopyWithImpl<$Res>
    implements $SafetyInfoCopyWith<$Res> {
  _$SafetyInfoCopyWithImpl(this._self, this._then);

  final SafetyInfo _self;
  final $Res Function(SafetyInfo) _then;

/// Create a copy of SafetyInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? messageKey = null,Object? canRephrase = null,Object? crisisResources = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RefusalCategory,messageKey: null == messageKey ? _self.messageKey : messageKey // ignore: cast_nullable_to_non_nullable
as String,canRephrase: null == canRephrase ? _self.canRephrase : canRephrase // ignore: cast_nullable_to_non_nullable
as bool,crisisResources: null == crisisResources ? _self.crisisResources : crisisResources // ignore: cast_nullable_to_non_nullable
as List<CrisisResource>,
  ));
}

}


/// Adds pattern-matching-related methods to [SafetyInfo].
extension SafetyInfoPatterns on SafetyInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SafetyInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SafetyInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SafetyInfo value)  $default,){
final _that = this;
switch (_that) {
case _SafetyInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SafetyInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SafetyInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RefusalCategory category,  String messageKey,  bool canRephrase,  List<CrisisResource> crisisResources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SafetyInfo() when $default != null:
return $default(_that.category,_that.messageKey,_that.canRephrase,_that.crisisResources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RefusalCategory category,  String messageKey,  bool canRephrase,  List<CrisisResource> crisisResources)  $default,) {final _that = this;
switch (_that) {
case _SafetyInfo():
return $default(_that.category,_that.messageKey,_that.canRephrase,_that.crisisResources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RefusalCategory category,  String messageKey,  bool canRephrase,  List<CrisisResource> crisisResources)?  $default,) {final _that = this;
switch (_that) {
case _SafetyInfo() when $default != null:
return $default(_that.category,_that.messageKey,_that.canRephrase,_that.crisisResources);case _:
  return null;

}
}

}

/// @nodoc


class _SafetyInfo extends SafetyInfo {
  const _SafetyInfo({required this.category, required this.messageKey, required this.canRephrase, final  List<CrisisResource> crisisResources = const <CrisisResource>[]}): _crisisResources = crisisResources,super._();
  

/// The refusal category.
@override final  RefusalCategory category;
/// ARB key of the message.
@override final  String messageKey;
/// Whether the user may rephrase and try again.
@override final  bool canRephrase;
/// Helplines to show (S27) for crisis categories.
 final  List<CrisisResource> _crisisResources;
/// Helplines to show (S27) for crisis categories.
@override@JsonKey() List<CrisisResource> get crisisResources {
  if (_crisisResources is EqualUnmodifiableListView) return _crisisResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_crisisResources);
}


/// Create a copy of SafetyInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SafetyInfoCopyWith<_SafetyInfo> get copyWith => __$SafetyInfoCopyWithImpl<_SafetyInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SafetyInfo&&(identical(other.category, category) || other.category == category)&&(identical(other.messageKey, messageKey) || other.messageKey == messageKey)&&(identical(other.canRephrase, canRephrase) || other.canRephrase == canRephrase)&&const DeepCollectionEquality().equals(other._crisisResources, _crisisResources));
}


@override
int get hashCode => Object.hash(runtimeType,category,messageKey,canRephrase,const DeepCollectionEquality().hash(_crisisResources));

@override
String toString() {
  return 'SafetyInfo(category: $category, messageKey: $messageKey, canRephrase: $canRephrase, crisisResources: $crisisResources)';
}


}

/// @nodoc
abstract mixin class _$SafetyInfoCopyWith<$Res> implements $SafetyInfoCopyWith<$Res> {
  factory _$SafetyInfoCopyWith(_SafetyInfo value, $Res Function(_SafetyInfo) _then) = __$SafetyInfoCopyWithImpl;
@override @useResult
$Res call({
 RefusalCategory category, String messageKey, bool canRephrase, List<CrisisResource> crisisResources
});




}
/// @nodoc
class __$SafetyInfoCopyWithImpl<$Res>
    implements _$SafetyInfoCopyWith<$Res> {
  __$SafetyInfoCopyWithImpl(this._self, this._then);

  final _SafetyInfo _self;
  final $Res Function(_SafetyInfo) _then;

/// Create a copy of SafetyInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? messageKey = null,Object? canRephrase = null,Object? crisisResources = null,}) {
  return _then(_SafetyInfo(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as RefusalCategory,messageKey: null == messageKey ? _self.messageKey : messageKey // ignore: cast_nullable_to_non_nullable
as String,canRephrase: null == canRephrase ? _self.canRephrase : canRephrase // ignore: cast_nullable_to_non_nullable
as bool,crisisResources: null == crisisResources ? _self._crisisResources : crisisResources // ignore: cast_nullable_to_non_nullable
as List<CrisisResource>,
  ));
}


}

/// @nodoc
mixin _$ReadingStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingStatus()';
}


}

/// @nodoc
class $ReadingStatusCopyWith<$Res>  {
$ReadingStatusCopyWith(ReadingStatus _, $Res Function(ReadingStatus) __);
}


/// Adds pattern-matching-related methods to [ReadingStatus].
extension ReadingStatusPatterns on ReadingStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReadingStatusPending value)?  pending,TResult Function( ReadingStatusComplete value)?  complete,TResult Function( ReadingStatusRefused value)?  refused,TResult Function( ReadingStatusFailed value)?  failed,TResult Function( ReadingStatusClassic value)?  classic,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReadingStatusPending() when pending != null:
return pending(_that);case ReadingStatusComplete() when complete != null:
return complete(_that);case ReadingStatusRefused() when refused != null:
return refused(_that);case ReadingStatusFailed() when failed != null:
return failed(_that);case ReadingStatusClassic() when classic != null:
return classic(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReadingStatusPending value)  pending,required TResult Function( ReadingStatusComplete value)  complete,required TResult Function( ReadingStatusRefused value)  refused,required TResult Function( ReadingStatusFailed value)  failed,required TResult Function( ReadingStatusClassic value)  classic,}){
final _that = this;
switch (_that) {
case ReadingStatusPending():
return pending(_that);case ReadingStatusComplete():
return complete(_that);case ReadingStatusRefused():
return refused(_that);case ReadingStatusFailed():
return failed(_that);case ReadingStatusClassic():
return classic(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReadingStatusPending value)?  pending,TResult? Function( ReadingStatusComplete value)?  complete,TResult? Function( ReadingStatusRefused value)?  refused,TResult? Function( ReadingStatusFailed value)?  failed,TResult? Function( ReadingStatusClassic value)?  classic,}){
final _that = this;
switch (_that) {
case ReadingStatusPending() when pending != null:
return pending(_that);case ReadingStatusComplete() when complete != null:
return complete(_that);case ReadingStatusRefused() when refused != null:
return refused(_that);case ReadingStatusFailed() when failed != null:
return failed(_that);case ReadingStatusClassic() when classic != null:
return classic(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function()?  complete,TResult Function( SafetyInfo? safety)?  refused,TResult Function( Failure failure,  bool refunded)?  failed,TResult Function()?  classic,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReadingStatusPending() when pending != null:
return pending();case ReadingStatusComplete() when complete != null:
return complete();case ReadingStatusRefused() when refused != null:
return refused(_that.safety);case ReadingStatusFailed() when failed != null:
return failed(_that.failure,_that.refunded);case ReadingStatusClassic() when classic != null:
return classic();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function()  complete,required TResult Function( SafetyInfo? safety)  refused,required TResult Function( Failure failure,  bool refunded)  failed,required TResult Function()  classic,}) {final _that = this;
switch (_that) {
case ReadingStatusPending():
return pending();case ReadingStatusComplete():
return complete();case ReadingStatusRefused():
return refused(_that.safety);case ReadingStatusFailed():
return failed(_that.failure,_that.refunded);case ReadingStatusClassic():
return classic();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function()?  complete,TResult? Function( SafetyInfo? safety)?  refused,TResult? Function( Failure failure,  bool refunded)?  failed,TResult? Function()?  classic,}) {final _that = this;
switch (_that) {
case ReadingStatusPending() when pending != null:
return pending();case ReadingStatusComplete() when complete != null:
return complete();case ReadingStatusRefused() when refused != null:
return refused(_that.safety);case ReadingStatusFailed() when failed != null:
return failed(_that.failure,_that.refunded);case ReadingStatusClassic() when classic != null:
return classic();case _:
  return null;

}
}

}

/// @nodoc


class ReadingStatusPending extends ReadingStatus {
  const ReadingStatusPending(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatusPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingStatus.pending()';
}


}




/// @nodoc


class ReadingStatusComplete extends ReadingStatus {
  const ReadingStatusComplete(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatusComplete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingStatus.complete()';
}


}




/// @nodoc


class ReadingStatusRefused extends ReadingStatus {
  const ReadingStatusRefused({this.safety}): super._();
  

 final  SafetyInfo? safety;

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingStatusRefusedCopyWith<ReadingStatusRefused> get copyWith => _$ReadingStatusRefusedCopyWithImpl<ReadingStatusRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatusRefused&&(identical(other.safety, safety) || other.safety == safety));
}


@override
int get hashCode => Object.hash(runtimeType,safety);

@override
String toString() {
  return 'ReadingStatus.refused(safety: $safety)';
}


}

/// @nodoc
abstract mixin class $ReadingStatusRefusedCopyWith<$Res> implements $ReadingStatusCopyWith<$Res> {
  factory $ReadingStatusRefusedCopyWith(ReadingStatusRefused value, $Res Function(ReadingStatusRefused) _then) = _$ReadingStatusRefusedCopyWithImpl;
@useResult
$Res call({
 SafetyInfo? safety
});


$SafetyInfoCopyWith<$Res>? get safety;

}
/// @nodoc
class _$ReadingStatusRefusedCopyWithImpl<$Res>
    implements $ReadingStatusRefusedCopyWith<$Res> {
  _$ReadingStatusRefusedCopyWithImpl(this._self, this._then);

  final ReadingStatusRefused _self;
  final $Res Function(ReadingStatusRefused) _then;

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? safety = freezed,}) {
  return _then(ReadingStatusRefused(
safety: freezed == safety ? _self.safety : safety // ignore: cast_nullable_to_non_nullable
as SafetyInfo?,
  ));
}

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SafetyInfoCopyWith<$Res>? get safety {
    if (_self.safety == null) {
    return null;
  }

  return $SafetyInfoCopyWith<$Res>(_self.safety!, (value) {
    return _then(_self.copyWith(safety: value));
  });
}
}

/// @nodoc


class ReadingStatusFailed extends ReadingStatus {
  const ReadingStatusFailed(this.failure, {this.refunded = false}): super._();
  

 final  Failure failure;
@JsonKey() final  bool refunded;

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingStatusFailedCopyWith<ReadingStatusFailed> get copyWith => _$ReadingStatusFailedCopyWithImpl<ReadingStatusFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatusFailed&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.refunded, refunded) || other.refunded == refunded));
}


@override
int get hashCode => Object.hash(runtimeType,failure,refunded);

@override
String toString() {
  return 'ReadingStatus.failed(failure: $failure, refunded: $refunded)';
}


}

/// @nodoc
abstract mixin class $ReadingStatusFailedCopyWith<$Res> implements $ReadingStatusCopyWith<$Res> {
  factory $ReadingStatusFailedCopyWith(ReadingStatusFailed value, $Res Function(ReadingStatusFailed) _then) = _$ReadingStatusFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure, bool refunded
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ReadingStatusFailedCopyWithImpl<$Res>
    implements $ReadingStatusFailedCopyWith<$Res> {
  _$ReadingStatusFailedCopyWithImpl(this._self, this._then);

  final ReadingStatusFailed _self;
  final $Res Function(ReadingStatusFailed) _then;

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? refunded = null,}) {
  return _then(ReadingStatusFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ReadingStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class ReadingStatusClassic extends ReadingStatus {
  const ReadingStatusClassic(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingStatusClassic);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReadingStatus.classic()';
}


}




/// @nodoc
mixin _$Reading {

/// UUIDv4 = `clientReadingId` = `Idempotency-Key` (RC42).
 ReadingId get id;/// Creation time (UTC).
 DateTime get createdAt;/// Last change (UTC); the newer one wins a backup merge.
 DateTime get updatedAt;/// Local calendar date `YYYY-MM-DD` of creation.
 String get localDate;/// The drawn cards.
 Draw get draw;/// Local status.
 ReadingStatus get status;/// Locale the content was generated in.
 String get contentLocale;/// The user's question.
 String? get question;/// The AI text; `null` until delivered and for Classic readings.
 ReadingContent? get content;/// Worker prompt version; `null` for Classic readings.
 String? get promptVersion;/// Model ID (device-local, never exported).
 String? get modelId;/// Which bucket paid (device-local, never exported).
 ChargeSource? get chargeSource;/// The user's note.
 String? get note;/// Favourite flag.
 bool get favourite;/// Thumbs rating.
 Rating? get rating;/// Reason for a thumbs-down.
 RatingReason? get ratingReason;/// Whether the delivery ack reached the Worker (device-local).
 bool get deliveryAcked;/// Whether the user reported this reading.
 bool get reported;
/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingCopyWith<Reading> get copyWith => _$ReadingCopyWithImpl<Reading>(this as Reading, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reading&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.status, status) || other.status == status)&&(identical(other.contentLocale, contentLocale) || other.contentLocale == contentLocale)&&(identical(other.question, question) || other.question == question)&&(identical(other.content, content) || other.content == content)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.chargeSource, chargeSource) || other.chargeSource == chargeSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.favourite, favourite) || other.favourite == favourite)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingReason, ratingReason) || other.ratingReason == ratingReason)&&(identical(other.deliveryAcked, deliveryAcked) || other.deliveryAcked == deliveryAcked)&&(identical(other.reported, reported) || other.reported == reported));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,updatedAt,localDate,draw,status,contentLocale,question,content,promptVersion,modelId,chargeSource,note,favourite,rating,ratingReason,deliveryAcked,reported);

@override
String toString() {
  return 'Reading(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, localDate: $localDate, draw: $draw, status: $status, contentLocale: $contentLocale, question: $question, content: $content, promptVersion: $promptVersion, modelId: $modelId, chargeSource: $chargeSource, note: $note, favourite: $favourite, rating: $rating, ratingReason: $ratingReason, deliveryAcked: $deliveryAcked, reported: $reported)';
}


}

/// @nodoc
abstract mixin class $ReadingCopyWith<$Res>  {
  factory $ReadingCopyWith(Reading value, $Res Function(Reading) _then) = _$ReadingCopyWithImpl;
@useResult
$Res call({
 ReadingId id, DateTime createdAt, DateTime updatedAt, String localDate, Draw draw, ReadingStatus status, String contentLocale, String? question, ReadingContent? content, String? promptVersion, String? modelId, ChargeSource? chargeSource, String? note, bool favourite, Rating? rating, RatingReason? ratingReason, bool deliveryAcked, bool reported
});


$DrawCopyWith<$Res> get draw;$ReadingStatusCopyWith<$Res> get status;$ReadingContentCopyWith<$Res>? get content;

}
/// @nodoc
class _$ReadingCopyWithImpl<$Res>
    implements $ReadingCopyWith<$Res> {
  _$ReadingCopyWithImpl(this._self, this._then);

  final Reading _self;
  final $Res Function(Reading) _then;

/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? updatedAt = null,Object? localDate = null,Object? draw = null,Object? status = null,Object? contentLocale = null,Object? question = freezed,Object? content = freezed,Object? promptVersion = freezed,Object? modelId = freezed,Object? chargeSource = freezed,Object? note = freezed,Object? favourite = null,Object? rating = freezed,Object? ratingReason = freezed,Object? deliveryAcked = null,Object? reported = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ReadingId,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReadingStatus,contentLocale: null == contentLocale ? _self.contentLocale : contentLocale // ignore: cast_nullable_to_non_nullable
as String,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as ReadingContent?,promptVersion: freezed == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,chargeSource: freezed == chargeSource ? _self.chargeSource : chargeSource // ignore: cast_nullable_to_non_nullable
as ChargeSource?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,favourite: null == favourite ? _self.favourite : favourite // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as Rating?,ratingReason: freezed == ratingReason ? _self.ratingReason : ratingReason // ignore: cast_nullable_to_non_nullable
as RatingReason?,deliveryAcked: null == deliveryAcked ? _self.deliveryAcked : deliveryAcked // ignore: cast_nullable_to_non_nullable
as bool,reported: null == reported ? _self.reported : reported // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawCopyWith<$Res> get draw {
  
  return $DrawCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingStatusCopyWith<$Res> get status {
  
  return $ReadingStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingContentCopyWith<$Res>? get content {
    if (_self.content == null) {
    return null;
  }

  return $ReadingContentCopyWith<$Res>(_self.content!, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}


/// Adds pattern-matching-related methods to [Reading].
extension ReadingPatterns on Reading {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reading value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reading() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reading value)  $default,){
final _that = this;
switch (_that) {
case _Reading():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reading value)?  $default,){
final _that = this;
switch (_that) {
case _Reading() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReadingId id,  DateTime createdAt,  DateTime updatedAt,  String localDate,  Draw draw,  ReadingStatus status,  String contentLocale,  String? question,  ReadingContent? content,  String? promptVersion,  String? modelId,  ChargeSource? chargeSource,  String? note,  bool favourite,  Rating? rating,  RatingReason? ratingReason,  bool deliveryAcked,  bool reported)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reading() when $default != null:
return $default(_that.id,_that.createdAt,_that.updatedAt,_that.localDate,_that.draw,_that.status,_that.contentLocale,_that.question,_that.content,_that.promptVersion,_that.modelId,_that.chargeSource,_that.note,_that.favourite,_that.rating,_that.ratingReason,_that.deliveryAcked,_that.reported);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReadingId id,  DateTime createdAt,  DateTime updatedAt,  String localDate,  Draw draw,  ReadingStatus status,  String contentLocale,  String? question,  ReadingContent? content,  String? promptVersion,  String? modelId,  ChargeSource? chargeSource,  String? note,  bool favourite,  Rating? rating,  RatingReason? ratingReason,  bool deliveryAcked,  bool reported)  $default,) {final _that = this;
switch (_that) {
case _Reading():
return $default(_that.id,_that.createdAt,_that.updatedAt,_that.localDate,_that.draw,_that.status,_that.contentLocale,_that.question,_that.content,_that.promptVersion,_that.modelId,_that.chargeSource,_that.note,_that.favourite,_that.rating,_that.ratingReason,_that.deliveryAcked,_that.reported);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReadingId id,  DateTime createdAt,  DateTime updatedAt,  String localDate,  Draw draw,  ReadingStatus status,  String contentLocale,  String? question,  ReadingContent? content,  String? promptVersion,  String? modelId,  ChargeSource? chargeSource,  String? note,  bool favourite,  Rating? rating,  RatingReason? ratingReason,  bool deliveryAcked,  bool reported)?  $default,) {final _that = this;
switch (_that) {
case _Reading() when $default != null:
return $default(_that.id,_that.createdAt,_that.updatedAt,_that.localDate,_that.draw,_that.status,_that.contentLocale,_that.question,_that.content,_that.promptVersion,_that.modelId,_that.chargeSource,_that.note,_that.favourite,_that.rating,_that.ratingReason,_that.deliveryAcked,_that.reported);case _:
  return null;

}
}

}

/// @nodoc


class _Reading extends Reading {
  const _Reading({required this.id, required this.createdAt, required this.updatedAt, required this.localDate, required this.draw, required this.status, required this.contentLocale, this.question, this.content, this.promptVersion, this.modelId, this.chargeSource, this.note, this.favourite = false, this.rating, this.ratingReason, this.deliveryAcked = false, this.reported = false}): super._();
  

/// UUIDv4 = `clientReadingId` = `Idempotency-Key` (RC42).
@override final  ReadingId id;
/// Creation time (UTC).
@override final  DateTime createdAt;
/// Last change (UTC); the newer one wins a backup merge.
@override final  DateTime updatedAt;
/// Local calendar date `YYYY-MM-DD` of creation.
@override final  String localDate;
/// The drawn cards.
@override final  Draw draw;
/// Local status.
@override final  ReadingStatus status;
/// Locale the content was generated in.
@override final  String contentLocale;
/// The user's question.
@override final  String? question;
/// The AI text; `null` until delivered and for Classic readings.
@override final  ReadingContent? content;
/// Worker prompt version; `null` for Classic readings.
@override final  String? promptVersion;
/// Model ID (device-local, never exported).
@override final  String? modelId;
/// Which bucket paid (device-local, never exported).
@override final  ChargeSource? chargeSource;
/// The user's note.
@override final  String? note;
/// Favourite flag.
@override@JsonKey() final  bool favourite;
/// Thumbs rating.
@override final  Rating? rating;
/// Reason for a thumbs-down.
@override final  RatingReason? ratingReason;
/// Whether the delivery ack reached the Worker (device-local).
@override@JsonKey() final  bool deliveryAcked;
/// Whether the user reported this reading.
@override@JsonKey() final  bool reported;

/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingCopyWith<_Reading> get copyWith => __$ReadingCopyWithImpl<_Reading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reading&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.localDate, localDate) || other.localDate == localDate)&&(identical(other.draw, draw) || other.draw == draw)&&(identical(other.status, status) || other.status == status)&&(identical(other.contentLocale, contentLocale) || other.contentLocale == contentLocale)&&(identical(other.question, question) || other.question == question)&&(identical(other.content, content) || other.content == content)&&(identical(other.promptVersion, promptVersion) || other.promptVersion == promptVersion)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.chargeSource, chargeSource) || other.chargeSource == chargeSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.favourite, favourite) || other.favourite == favourite)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingReason, ratingReason) || other.ratingReason == ratingReason)&&(identical(other.deliveryAcked, deliveryAcked) || other.deliveryAcked == deliveryAcked)&&(identical(other.reported, reported) || other.reported == reported));
}


@override
int get hashCode => Object.hash(runtimeType,id,createdAt,updatedAt,localDate,draw,status,contentLocale,question,content,promptVersion,modelId,chargeSource,note,favourite,rating,ratingReason,deliveryAcked,reported);

@override
String toString() {
  return 'Reading(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, localDate: $localDate, draw: $draw, status: $status, contentLocale: $contentLocale, question: $question, content: $content, promptVersion: $promptVersion, modelId: $modelId, chargeSource: $chargeSource, note: $note, favourite: $favourite, rating: $rating, ratingReason: $ratingReason, deliveryAcked: $deliveryAcked, reported: $reported)';
}


}

/// @nodoc
abstract mixin class _$ReadingCopyWith<$Res> implements $ReadingCopyWith<$Res> {
  factory _$ReadingCopyWith(_Reading value, $Res Function(_Reading) _then) = __$ReadingCopyWithImpl;
@override @useResult
$Res call({
 ReadingId id, DateTime createdAt, DateTime updatedAt, String localDate, Draw draw, ReadingStatus status, String contentLocale, String? question, ReadingContent? content, String? promptVersion, String? modelId, ChargeSource? chargeSource, String? note, bool favourite, Rating? rating, RatingReason? ratingReason, bool deliveryAcked, bool reported
});


@override $DrawCopyWith<$Res> get draw;@override $ReadingStatusCopyWith<$Res> get status;@override $ReadingContentCopyWith<$Res>? get content;

}
/// @nodoc
class __$ReadingCopyWithImpl<$Res>
    implements _$ReadingCopyWith<$Res> {
  __$ReadingCopyWithImpl(this._self, this._then);

  final _Reading _self;
  final $Res Function(_Reading) _then;

/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? updatedAt = null,Object? localDate = null,Object? draw = null,Object? status = null,Object? contentLocale = null,Object? question = freezed,Object? content = freezed,Object? promptVersion = freezed,Object? modelId = freezed,Object? chargeSource = freezed,Object? note = freezed,Object? favourite = null,Object? rating = freezed,Object? ratingReason = freezed,Object? deliveryAcked = null,Object? reported = null,}) {
  return _then(_Reading(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ReadingId,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as String,draw: null == draw ? _self.draw : draw // ignore: cast_nullable_to_non_nullable
as Draw,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReadingStatus,contentLocale: null == contentLocale ? _self.contentLocale : contentLocale // ignore: cast_nullable_to_non_nullable
as String,question: freezed == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as ReadingContent?,promptVersion: freezed == promptVersion ? _self.promptVersion : promptVersion // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,chargeSource: freezed == chargeSource ? _self.chargeSource : chargeSource // ignore: cast_nullable_to_non_nullable
as ChargeSource?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,favourite: null == favourite ? _self.favourite : favourite // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as Rating?,ratingReason: freezed == ratingReason ? _self.ratingReason : ratingReason // ignore: cast_nullable_to_non_nullable
as RatingReason?,deliveryAcked: null == deliveryAcked ? _self.deliveryAcked : deliveryAcked // ignore: cast_nullable_to_non_nullable
as bool,reported: null == reported ? _self.reported : reported // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawCopyWith<$Res> get draw {
  
  return $DrawCopyWith<$Res>(_self.draw, (value) {
    return _then(_self.copyWith(draw: value));
  });
}/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingStatusCopyWith<$Res> get status {
  
  return $ReadingStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of Reading
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadingContentCopyWith<$Res>? get content {
    if (_self.content == null) {
    return null;
  }

  return $ReadingContentCopyWith<$Res>(_self.content!, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}

// dart format on
