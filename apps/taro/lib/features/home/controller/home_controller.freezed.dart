// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeView {

 CreditBalance? get balance; HomeBalanceVariant get variant; bool get firstRun; bool get balanceStale; bool get deviceUnverified; bool get adsRemoved; bool get updateAvailable; DailyCard? get dailyCard; List<Reading> get recentReadings;
/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeViewCopyWith<HomeView> get copyWith => _$HomeViewCopyWithImpl<HomeView>(this as HomeView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeView&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.firstRun, firstRun) || other.firstRun == firstRun)&&(identical(other.balanceStale, balanceStale) || other.balanceStale == balanceStale)&&(identical(other.deviceUnverified, deviceUnverified) || other.deviceUnverified == deviceUnverified)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&(identical(other.updateAvailable, updateAvailable) || other.updateAvailable == updateAvailable)&&(identical(other.dailyCard, dailyCard) || other.dailyCard == dailyCard)&&const DeepCollectionEquality().equals(other.recentReadings, recentReadings));
}


@override
int get hashCode => Object.hash(runtimeType,balance,variant,firstRun,balanceStale,deviceUnverified,adsRemoved,updateAvailable,dailyCard,const DeepCollectionEquality().hash(recentReadings));

@override
String toString() {
  return 'HomeView(balance: $balance, variant: $variant, firstRun: $firstRun, balanceStale: $balanceStale, deviceUnverified: $deviceUnverified, adsRemoved: $adsRemoved, updateAvailable: $updateAvailable, dailyCard: $dailyCard, recentReadings: $recentReadings)';
}


}

/// @nodoc
abstract mixin class $HomeViewCopyWith<$Res>  {
  factory $HomeViewCopyWith(HomeView value, $Res Function(HomeView) _then) = _$HomeViewCopyWithImpl;
@useResult
$Res call({
 CreditBalance? balance, HomeBalanceVariant variant, bool firstRun, bool balanceStale, bool deviceUnverified, bool adsRemoved, bool updateAvailable, DailyCard? dailyCard, List<Reading> recentReadings
});


$CreditBalanceCopyWith<$Res>? get balance;$DailyCardCopyWith<$Res>? get dailyCard;

}
/// @nodoc
class _$HomeViewCopyWithImpl<$Res>
    implements $HomeViewCopyWith<$Res> {
  _$HomeViewCopyWithImpl(this._self, this._then);

  final HomeView _self;
  final $Res Function(HomeView) _then;

/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = freezed,Object? variant = null,Object? firstRun = null,Object? balanceStale = null,Object? deviceUnverified = null,Object? adsRemoved = null,Object? updateAvailable = null,Object? dailyCard = freezed,Object? recentReadings = null,}) {
  return _then(_self.copyWith(
balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as HomeBalanceVariant,firstRun: null == firstRun ? _self.firstRun : firstRun // ignore: cast_nullable_to_non_nullable
as bool,balanceStale: null == balanceStale ? _self.balanceStale : balanceStale // ignore: cast_nullable_to_non_nullable
as bool,deviceUnverified: null == deviceUnverified ? _self.deviceUnverified : deviceUnverified // ignore: cast_nullable_to_non_nullable
as bool,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,dailyCard: freezed == dailyCard ? _self.dailyCard : dailyCard // ignore: cast_nullable_to_non_nullable
as DailyCard?,recentReadings: null == recentReadings ? _self.recentReadings : recentReadings // ignore: cast_nullable_to_non_nullable
as List<Reading>,
  ));
}
/// Create a copy of HomeView
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
}/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res>? get dailyCard {
    if (_self.dailyCard == null) {
    return null;
  }

  return $DailyCardCopyWith<$Res>(_self.dailyCard!, (value) {
    return _then(_self.copyWith(dailyCard: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeView].
extension HomeViewPatterns on HomeView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeView value)  $default,){
final _that = this;
switch (_that) {
case _HomeView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeView value)?  $default,){
final _that = this;
switch (_that) {
case _HomeView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CreditBalance? balance,  HomeBalanceVariant variant,  bool firstRun,  bool balanceStale,  bool deviceUnverified,  bool adsRemoved,  bool updateAvailable,  DailyCard? dailyCard,  List<Reading> recentReadings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeView() when $default != null:
return $default(_that.balance,_that.variant,_that.firstRun,_that.balanceStale,_that.deviceUnverified,_that.adsRemoved,_that.updateAvailable,_that.dailyCard,_that.recentReadings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CreditBalance? balance,  HomeBalanceVariant variant,  bool firstRun,  bool balanceStale,  bool deviceUnverified,  bool adsRemoved,  bool updateAvailable,  DailyCard? dailyCard,  List<Reading> recentReadings)  $default,) {final _that = this;
switch (_that) {
case _HomeView():
return $default(_that.balance,_that.variant,_that.firstRun,_that.balanceStale,_that.deviceUnverified,_that.adsRemoved,_that.updateAvailable,_that.dailyCard,_that.recentReadings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CreditBalance? balance,  HomeBalanceVariant variant,  bool firstRun,  bool balanceStale,  bool deviceUnverified,  bool adsRemoved,  bool updateAvailable,  DailyCard? dailyCard,  List<Reading> recentReadings)?  $default,) {final _that = this;
switch (_that) {
case _HomeView() when $default != null:
return $default(_that.balance,_that.variant,_that.firstRun,_that.balanceStale,_that.deviceUnverified,_that.adsRemoved,_that.updateAvailable,_that.dailyCard,_that.recentReadings);case _:
  return null;

}
}

}

/// @nodoc


class _HomeView extends HomeView {
  const _HomeView({required this.balance, required this.variant, required this.firstRun, required this.balanceStale, required this.deviceUnverified, required this.adsRemoved, required this.updateAvailable, this.dailyCard, final  List<Reading> recentReadings = const <Reading>[]}): _recentReadings = recentReadings,super._();
  

@override final  CreditBalance? balance;
@override final  HomeBalanceVariant variant;
@override final  bool firstRun;
@override final  bool balanceStale;
@override final  bool deviceUnverified;
@override final  bool adsRemoved;
@override final  bool updateAvailable;
@override final  DailyCard? dailyCard;
 final  List<Reading> _recentReadings;
@override@JsonKey() List<Reading> get recentReadings {
  if (_recentReadings is EqualUnmodifiableListView) return _recentReadings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentReadings);
}


/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeViewCopyWith<_HomeView> get copyWith => __$HomeViewCopyWithImpl<_HomeView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeView&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.firstRun, firstRun) || other.firstRun == firstRun)&&(identical(other.balanceStale, balanceStale) || other.balanceStale == balanceStale)&&(identical(other.deviceUnverified, deviceUnverified) || other.deviceUnverified == deviceUnverified)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&(identical(other.updateAvailable, updateAvailable) || other.updateAvailable == updateAvailable)&&(identical(other.dailyCard, dailyCard) || other.dailyCard == dailyCard)&&const DeepCollectionEquality().equals(other._recentReadings, _recentReadings));
}


@override
int get hashCode => Object.hash(runtimeType,balance,variant,firstRun,balanceStale,deviceUnverified,adsRemoved,updateAvailable,dailyCard,const DeepCollectionEquality().hash(_recentReadings));

@override
String toString() {
  return 'HomeView(balance: $balance, variant: $variant, firstRun: $firstRun, balanceStale: $balanceStale, deviceUnverified: $deviceUnverified, adsRemoved: $adsRemoved, updateAvailable: $updateAvailable, dailyCard: $dailyCard, recentReadings: $recentReadings)';
}


}

/// @nodoc
abstract mixin class _$HomeViewCopyWith<$Res> implements $HomeViewCopyWith<$Res> {
  factory _$HomeViewCopyWith(_HomeView value, $Res Function(_HomeView) _then) = __$HomeViewCopyWithImpl;
@override @useResult
$Res call({
 CreditBalance? balance, HomeBalanceVariant variant, bool firstRun, bool balanceStale, bool deviceUnverified, bool adsRemoved, bool updateAvailable, DailyCard? dailyCard, List<Reading> recentReadings
});


@override $CreditBalanceCopyWith<$Res>? get balance;@override $DailyCardCopyWith<$Res>? get dailyCard;

}
/// @nodoc
class __$HomeViewCopyWithImpl<$Res>
    implements _$HomeViewCopyWith<$Res> {
  __$HomeViewCopyWithImpl(this._self, this._then);

  final _HomeView _self;
  final $Res Function(_HomeView) _then;

/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = freezed,Object? variant = null,Object? firstRun = null,Object? balanceStale = null,Object? deviceUnverified = null,Object? adsRemoved = null,Object? updateAvailable = null,Object? dailyCard = freezed,Object? recentReadings = null,}) {
  return _then(_HomeView(
balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as CreditBalance?,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as HomeBalanceVariant,firstRun: null == firstRun ? _self.firstRun : firstRun // ignore: cast_nullable_to_non_nullable
as bool,balanceStale: null == balanceStale ? _self.balanceStale : balanceStale // ignore: cast_nullable_to_non_nullable
as bool,deviceUnverified: null == deviceUnverified ? _self.deviceUnverified : deviceUnverified // ignore: cast_nullable_to_non_nullable
as bool,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,dailyCard: freezed == dailyCard ? _self.dailyCard : dailyCard // ignore: cast_nullable_to_non_nullable
as DailyCard?,recentReadings: null == recentReadings ? _self._recentReadings : recentReadings // ignore: cast_nullable_to_non_nullable
as List<Reading>,
  ));
}

/// Create a copy of HomeView
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
}/// Create a copy of HomeView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyCardCopyWith<$Res>? get dailyCard {
    if (_self.dailyCard == null) {
    return null;
  }

  return $DailyCardCopyWith<$Res>(_self.dailyCard!, (value) {
    return _then(_self.copyWith(dailyCard: value));
  });
}
}

/// @nodoc
mixin _$HomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState()';
}


}

/// @nodoc
class $HomeStateCopyWith<$Res>  {
$HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HomeLoading value)?  loading,TResult Function( HomeContent value)?  content,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeContent() when content != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HomeLoading value)  loading,required TResult Function( HomeContent value)  content,}){
final _that = this;
switch (_that) {
case HomeLoading():
return loading(_that);case HomeContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HomeLoading value)?  loading,TResult? Function( HomeContent value)?  content,}){
final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading(_that);case HomeContent() when content != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( HomeView view)?  content,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeContent() when content != null:
return content(_that.view);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( HomeView view)  content,}) {final _that = this;
switch (_that) {
case HomeLoading():
return loading();case HomeContent():
return content(_that.view);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( HomeView view)?  content,}) {final _that = this;
switch (_that) {
case HomeLoading() when loading != null:
return loading();case HomeContent() when content != null:
return content(_that.view);case _:
  return null;

}
}

}

/// @nodoc


class HomeLoading implements HomeState {
  const HomeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.loading()';
}


}




/// @nodoc


class HomeContent implements HomeState {
  const HomeContent(this.view);
  

 final  HomeView view;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeContentCopyWith<HomeContent> get copyWith => _$HomeContentCopyWithImpl<HomeContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeContent&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'HomeState.content(view: $view)';
}


}

/// @nodoc
abstract mixin class $HomeContentCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory $HomeContentCopyWith(HomeContent value, $Res Function(HomeContent) _then) = _$HomeContentCopyWithImpl;
@useResult
$Res call({
 HomeView view
});


$HomeViewCopyWith<$Res> get view;

}
/// @nodoc
class _$HomeContentCopyWithImpl<$Res>
    implements $HomeContentCopyWith<$Res> {
  _$HomeContentCopyWithImpl(this._self, this._then);

  final HomeContent _self;
  final $Res Function(HomeContent) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(HomeContent(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as HomeView,
  ));
}

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeViewCopyWith<$Res> get view {
  
  return $HomeViewCopyWith<$Res>(_self.view, (value) {
    return _then(_self.copyWith(view: value));
  });
}
}

/// @nodoc
mixin _$HomeFlags {

 bool get firstRunDone; String? get updateNoticeVersion;
/// Create a copy of HomeFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeFlagsCopyWith<HomeFlags> get copyWith => _$HomeFlagsCopyWithImpl<HomeFlags>(this as HomeFlags, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeFlags&&(identical(other.firstRunDone, firstRunDone) || other.firstRunDone == firstRunDone)&&(identical(other.updateNoticeVersion, updateNoticeVersion) || other.updateNoticeVersion == updateNoticeVersion));
}


@override
int get hashCode => Object.hash(runtimeType,firstRunDone,updateNoticeVersion);

@override
String toString() {
  return 'HomeFlags(firstRunDone: $firstRunDone, updateNoticeVersion: $updateNoticeVersion)';
}


}

/// @nodoc
abstract mixin class $HomeFlagsCopyWith<$Res>  {
  factory $HomeFlagsCopyWith(HomeFlags value, $Res Function(HomeFlags) _then) = _$HomeFlagsCopyWithImpl;
@useResult
$Res call({
 bool firstRunDone, String? updateNoticeVersion
});




}
/// @nodoc
class _$HomeFlagsCopyWithImpl<$Res>
    implements $HomeFlagsCopyWith<$Res> {
  _$HomeFlagsCopyWithImpl(this._self, this._then);

  final HomeFlags _self;
  final $Res Function(HomeFlags) _then;

/// Create a copy of HomeFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstRunDone = null,Object? updateNoticeVersion = freezed,}) {
  return _then(_self.copyWith(
firstRunDone: null == firstRunDone ? _self.firstRunDone : firstRunDone // ignore: cast_nullable_to_non_nullable
as bool,updateNoticeVersion: freezed == updateNoticeVersion ? _self.updateNoticeVersion : updateNoticeVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeFlags].
extension HomeFlagsPatterns on HomeFlags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeFlags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeFlags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeFlags value)  $default,){
final _that = this;
switch (_that) {
case _HomeFlags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeFlags value)?  $default,){
final _that = this;
switch (_that) {
case _HomeFlags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool firstRunDone,  String? updateNoticeVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeFlags() when $default != null:
return $default(_that.firstRunDone,_that.updateNoticeVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool firstRunDone,  String? updateNoticeVersion)  $default,) {final _that = this;
switch (_that) {
case _HomeFlags():
return $default(_that.firstRunDone,_that.updateNoticeVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool firstRunDone,  String? updateNoticeVersion)?  $default,) {final _that = this;
switch (_that) {
case _HomeFlags() when $default != null:
return $default(_that.firstRunDone,_that.updateNoticeVersion);case _:
  return null;

}
}

}

/// @nodoc


class _HomeFlags implements HomeFlags {
  const _HomeFlags({required this.firstRunDone, required this.updateNoticeVersion});
  

@override final  bool firstRunDone;
@override final  String? updateNoticeVersion;

/// Create a copy of HomeFlags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeFlagsCopyWith<_HomeFlags> get copyWith => __$HomeFlagsCopyWithImpl<_HomeFlags>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeFlags&&(identical(other.firstRunDone, firstRunDone) || other.firstRunDone == firstRunDone)&&(identical(other.updateNoticeVersion, updateNoticeVersion) || other.updateNoticeVersion == updateNoticeVersion));
}


@override
int get hashCode => Object.hash(runtimeType,firstRunDone,updateNoticeVersion);

@override
String toString() {
  return 'HomeFlags(firstRunDone: $firstRunDone, updateNoticeVersion: $updateNoticeVersion)';
}


}

/// @nodoc
abstract mixin class _$HomeFlagsCopyWith<$Res> implements $HomeFlagsCopyWith<$Res> {
  factory _$HomeFlagsCopyWith(_HomeFlags value, $Res Function(_HomeFlags) _then) = __$HomeFlagsCopyWithImpl;
@override @useResult
$Res call({
 bool firstRunDone, String? updateNoticeVersion
});




}
/// @nodoc
class __$HomeFlagsCopyWithImpl<$Res>
    implements _$HomeFlagsCopyWith<$Res> {
  __$HomeFlagsCopyWithImpl(this._self, this._then);

  final _HomeFlags _self;
  final $Res Function(_HomeFlags) _then;

/// Create a copy of HomeFlags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstRunDone = null,Object? updateNoticeVersion = freezed,}) {
  return _then(_HomeFlags(
firstRunDone: null == firstRunDone ? _self.firstRunDone : firstRunDone // ignore: cast_nullable_to_non_nullable
as bool,updateNoticeVersion: freezed == updateNoticeVersion ? _self.updateNoticeVersion : updateNoticeVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
