// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'iap_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoreBuyResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreBuyResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreBuyResult()';
}


}

/// @nodoc
class $StoreBuyResultCopyWith<$Res>  {
$StoreBuyResultCopyWith(StoreBuyResult _, $Res Function(StoreBuyResult) __);
}


/// Adds pattern-matching-related methods to [StoreBuyResult].
extension StoreBuyResultPatterns on StoreBuyResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoreBuyPurchased value)?  purchased,TResult Function( StoreBuyPending value)?  pending,TResult Function( StoreBuyCancelled value)?  cancelled,TResult Function( StoreBuyAlreadyOwned value)?  alreadyOwned,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoreBuyPurchased() when purchased != null:
return purchased(_that);case StoreBuyPending() when pending != null:
return pending(_that);case StoreBuyCancelled() when cancelled != null:
return cancelled(_that);case StoreBuyAlreadyOwned() when alreadyOwned != null:
return alreadyOwned(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoreBuyPurchased value)  purchased,required TResult Function( StoreBuyPending value)  pending,required TResult Function( StoreBuyCancelled value)  cancelled,required TResult Function( StoreBuyAlreadyOwned value)  alreadyOwned,}){
final _that = this;
switch (_that) {
case StoreBuyPurchased():
return purchased(_that);case StoreBuyPending():
return pending(_that);case StoreBuyCancelled():
return cancelled(_that);case StoreBuyAlreadyOwned():
return alreadyOwned(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoreBuyPurchased value)?  purchased,TResult? Function( StoreBuyPending value)?  pending,TResult? Function( StoreBuyCancelled value)?  cancelled,TResult? Function( StoreBuyAlreadyOwned value)?  alreadyOwned,}){
final _that = this;
switch (_that) {
case StoreBuyPurchased() when purchased != null:
return purchased(_that);case StoreBuyPending() when pending != null:
return pending(_that);case StoreBuyCancelled() when cancelled != null:
return cancelled(_that);case StoreBuyAlreadyOwned() when alreadyOwned != null:
return alreadyOwned(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( StorePurchase purchase)?  purchased,TResult Function()?  pending,TResult Function()?  cancelled,TResult Function()?  alreadyOwned,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoreBuyPurchased() when purchased != null:
return purchased(_that.purchase);case StoreBuyPending() when pending != null:
return pending();case StoreBuyCancelled() when cancelled != null:
return cancelled();case StoreBuyAlreadyOwned() when alreadyOwned != null:
return alreadyOwned();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( StorePurchase purchase)  purchased,required TResult Function()  pending,required TResult Function()  cancelled,required TResult Function()  alreadyOwned,}) {final _that = this;
switch (_that) {
case StoreBuyPurchased():
return purchased(_that.purchase);case StoreBuyPending():
return pending();case StoreBuyCancelled():
return cancelled();case StoreBuyAlreadyOwned():
return alreadyOwned();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( StorePurchase purchase)?  purchased,TResult? Function()?  pending,TResult? Function()?  cancelled,TResult? Function()?  alreadyOwned,}) {final _that = this;
switch (_that) {
case StoreBuyPurchased() when purchased != null:
return purchased(_that.purchase);case StoreBuyPending() when pending != null:
return pending();case StoreBuyCancelled() when cancelled != null:
return cancelled();case StoreBuyAlreadyOwned() when alreadyOwned != null:
return alreadyOwned();case _:
  return null;

}
}

}

/// @nodoc


class StoreBuyPurchased implements StoreBuyResult {
  const StoreBuyPurchased(this.purchase);
  

 final  StorePurchase purchase;

/// Create a copy of StoreBuyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreBuyPurchasedCopyWith<StoreBuyPurchased> get copyWith => _$StoreBuyPurchasedCopyWithImpl<StoreBuyPurchased>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreBuyPurchased&&(identical(other.purchase, purchase) || other.purchase == purchase));
}


@override
int get hashCode => Object.hash(runtimeType,purchase);

@override
String toString() {
  return 'StoreBuyResult.purchased(purchase: $purchase)';
}


}

/// @nodoc
abstract mixin class $StoreBuyPurchasedCopyWith<$Res> implements $StoreBuyResultCopyWith<$Res> {
  factory $StoreBuyPurchasedCopyWith(StoreBuyPurchased value, $Res Function(StoreBuyPurchased) _then) = _$StoreBuyPurchasedCopyWithImpl;
@useResult
$Res call({
 StorePurchase purchase
});


$StorePurchaseCopyWith<$Res> get purchase;

}
/// @nodoc
class _$StoreBuyPurchasedCopyWithImpl<$Res>
    implements $StoreBuyPurchasedCopyWith<$Res> {
  _$StoreBuyPurchasedCopyWithImpl(this._self, this._then);

  final StoreBuyPurchased _self;
  final $Res Function(StoreBuyPurchased) _then;

/// Create a copy of StoreBuyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? purchase = null,}) {
  return _then(StoreBuyPurchased(
null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as StorePurchase,
  ));
}

/// Create a copy of StoreBuyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StorePurchaseCopyWith<$Res> get purchase {
  
  return $StorePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}
}

/// @nodoc


class StoreBuyPending implements StoreBuyResult {
  const StoreBuyPending();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreBuyPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreBuyResult.pending()';
}


}




/// @nodoc


class StoreBuyCancelled implements StoreBuyResult {
  const StoreBuyCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreBuyCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreBuyResult.cancelled()';
}


}




/// @nodoc


class StoreBuyAlreadyOwned implements StoreBuyResult {
  const StoreBuyAlreadyOwned();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreBuyAlreadyOwned);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StoreBuyResult.alreadyOwned()';
}


}




// dart format on
