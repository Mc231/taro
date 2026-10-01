// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StorePack {

/// A consumable of `TaroProducts`.
 ProductId get productId;/// Display order, 0–9.
 int get sortOrder;/// Whether the pack is shown.
 bool get enabled;/// Readings in the pack, injected read-only by the Worker from
/// `PRODUCT_CATALOG` (RC3); `null` in the compiled defaults.
 int? get credits;
/// Create a copy of StorePack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorePackCopyWith<StorePack> get copyWith => _$StorePackCopyWithImpl<StorePack>(this as StorePack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorePack&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.credits, credits) || other.credits == credits));
}


@override
int get hashCode => Object.hash(runtimeType,productId,sortOrder,enabled,credits);

@override
String toString() {
  return 'StorePack(productId: $productId, sortOrder: $sortOrder, enabled: $enabled, credits: $credits)';
}


}

/// @nodoc
abstract mixin class $StorePackCopyWith<$Res>  {
  factory $StorePackCopyWith(StorePack value, $Res Function(StorePack) _then) = _$StorePackCopyWithImpl;
@useResult
$Res call({
 ProductId productId, int sortOrder, bool enabled, int? credits
});




}
/// @nodoc
class _$StorePackCopyWithImpl<$Res>
    implements $StorePackCopyWith<$Res> {
  _$StorePackCopyWithImpl(this._self, this._then);

  final StorePack _self;
  final $Res Function(StorePack) _then;

/// Create a copy of StorePack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? sortOrder = null,Object? enabled = null,Object? credits = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,credits: freezed == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StorePack].
extension StorePackPatterns on StorePack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorePack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorePack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorePack value)  $default,){
final _that = this;
switch (_that) {
case _StorePack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorePack value)?  $default,){
final _that = this;
switch (_that) {
case _StorePack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProductId productId,  int sortOrder,  bool enabled,  int? credits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorePack() when $default != null:
return $default(_that.productId,_that.sortOrder,_that.enabled,_that.credits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProductId productId,  int sortOrder,  bool enabled,  int? credits)  $default,) {final _that = this;
switch (_that) {
case _StorePack():
return $default(_that.productId,_that.sortOrder,_that.enabled,_that.credits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProductId productId,  int sortOrder,  bool enabled,  int? credits)?  $default,) {final _that = this;
switch (_that) {
case _StorePack() when $default != null:
return $default(_that.productId,_that.sortOrder,_that.enabled,_that.credits);case _:
  return null;

}
}

}

/// @nodoc


class _StorePack implements StorePack {
  const _StorePack({required this.productId, required this.sortOrder, this.enabled = true, this.credits});
  

/// A consumable of `TaroProducts`.
@override final  ProductId productId;
/// Display order, 0–9.
@override final  int sortOrder;
/// Whether the pack is shown.
@override@JsonKey() final  bool enabled;
/// Readings in the pack, injected read-only by the Worker from
/// `PRODUCT_CATALOG` (RC3); `null` in the compiled defaults.
@override final  int? credits;

/// Create a copy of StorePack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorePackCopyWith<_StorePack> get copyWith => __$StorePackCopyWithImpl<_StorePack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorePack&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.credits, credits) || other.credits == credits));
}


@override
int get hashCode => Object.hash(runtimeType,productId,sortOrder,enabled,credits);

@override
String toString() {
  return 'StorePack(productId: $productId, sortOrder: $sortOrder, enabled: $enabled, credits: $credits)';
}


}

/// @nodoc
abstract mixin class _$StorePackCopyWith<$Res> implements $StorePackCopyWith<$Res> {
  factory _$StorePackCopyWith(_StorePack value, $Res Function(_StorePack) _then) = __$StorePackCopyWithImpl;
@override @useResult
$Res call({
 ProductId productId, int sortOrder, bool enabled, int? credits
});




}
/// @nodoc
class __$StorePackCopyWithImpl<$Res>
    implements _$StorePackCopyWith<$Res> {
  __$StorePackCopyWithImpl(this._self, this._then);

  final _StorePack _self;
  final $Res Function(_StorePack) _then;

/// Create a copy of StorePack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? sortOrder = null,Object? enabled = null,Object? credits = freezed,}) {
  return _then(_StorePack(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as ProductId,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,credits: freezed == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$RemoteConfig {

/// Config document `version` (0 = compiled defaults).
 int get version;/// When the document was fetched; `null` for the defaults.
 DateTime? get fetchedAt;/// `readings.enabled`: the only reading kill switch.
 bool get readingsEnabled;/// `readings.freeDaily`, 1–5.
 int get readingsFreeDaily;/// `readings.maxPerInstallPerDay`, 5–100.
 int get readingsMaxPerInstallPerDay;/// `readings.tzCooldownHours`, 12–168.
 int get readingsTzCooldownHours;/// `spreads.enabled`, a subset of the six spread IDs.
 List<SpreadId> get spreadsEnabled;/// `rewarded.enabled`.
 bool get rewardedEnabled;/// `rewarded.amount`, 1–2.
 int get rewardedAmount;/// `rewarded.dailyCap`, 0–10 (0 = disabled).
 int get rewardedDailyCap;/// `rewarded.cooldownSec`, 0–3600.
 int get rewardedCooldownSec;/// `rewarded.intentTtlSec`, 300–3600.
 int get rewardedIntentTtlSec;/// `rewarded.loadTimeoutSec`, 5–30.
 int get rewardedLoadTimeoutSec;/// `rewarded.grantPollTimeoutSec`, 5–60.
 int get rewardedGrantPollTimeoutSec;/// `ads.enabled`: global ads kill switch (also hides rewarded).
 bool get adsEnabled;/// `ads.bannerEnabled`.
 bool get adsBannerEnabled;/// `ads.bannerScreens`, a subset of `kBannerAllowList`.
 List<String> get adsBannerScreens;/// `ads.bannerMinCompletedReadings`, 0–10.
 int get adsBannerMinCompletedReadings;/// `ads.attPrepromptEnabled`.
 bool get adsAttPrepromptEnabled;/// `store.enabled`.
 bool get storeEnabled;/// `store.packs`, 1–4 consumables.
 List<StorePack> get storePacks;/// `store.verifyRetryWindowHours`, 24–168.
 int get storeVerifyRetryWindowHours;/// `store.pendingHoldMinutes`, 5–240.
 int get storePendingHoldMinutes;/// `store.removeAdsEnabled`.
 bool get storeRemoveAdsEnabled;/// `store.showBestValueBadge`.
 bool get storeShowBestValueBadge;/// `store.showPerReadingPrice`.
 bool get storeShowPerReadingPrice;/// `ai.consentVersion` (2 since the OpenAI-only consent copy, RC97).
 int get aiConsentVersion;/// `ai.questionMaxChars` (grapheme clusters, RC45).
 int get aiQuestionMaxChars;/// `app.minVersion.ios`.
 String get appMinVersionIos;/// `app.minVersion.android`.
 String get appMinVersionAndroid;/// `app.recommendedVersion.ios`.
 String get appRecommendedVersionIos;/// `app.recommendedVersion.android`.
 String get appRecommendedVersionAndroid;/// `balance.staleAfterSec`, 30–3600.
 int get balanceStaleAfterSec;/// `balance.resumeSyncThrottleSec`, 0–600.
 int get balanceResumeSyncThrottleSec;/// `review.promptAfterPositiveReadings`, 1–20.
 int get reviewPromptAfterPositiveReadings;/// `legal.termsUrl`.
 String get legalTermsUrl;/// `legal.privacyUrl`.
 String get legalPrivacyUrl;/// `support.email`.
 String get supportEmail;
/// Create a copy of RemoteConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoteConfigCopyWith<RemoteConfig> get copyWith => _$RemoteConfigCopyWithImpl<RemoteConfig>(this as RemoteConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteConfig&&(identical(other.version, version) || other.version == version)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.readingsEnabled, readingsEnabled) || other.readingsEnabled == readingsEnabled)&&(identical(other.readingsFreeDaily, readingsFreeDaily) || other.readingsFreeDaily == readingsFreeDaily)&&(identical(other.readingsMaxPerInstallPerDay, readingsMaxPerInstallPerDay) || other.readingsMaxPerInstallPerDay == readingsMaxPerInstallPerDay)&&(identical(other.readingsTzCooldownHours, readingsTzCooldownHours) || other.readingsTzCooldownHours == readingsTzCooldownHours)&&const DeepCollectionEquality().equals(other.spreadsEnabled, spreadsEnabled)&&(identical(other.rewardedEnabled, rewardedEnabled) || other.rewardedEnabled == rewardedEnabled)&&(identical(other.rewardedAmount, rewardedAmount) || other.rewardedAmount == rewardedAmount)&&(identical(other.rewardedDailyCap, rewardedDailyCap) || other.rewardedDailyCap == rewardedDailyCap)&&(identical(other.rewardedCooldownSec, rewardedCooldownSec) || other.rewardedCooldownSec == rewardedCooldownSec)&&(identical(other.rewardedIntentTtlSec, rewardedIntentTtlSec) || other.rewardedIntentTtlSec == rewardedIntentTtlSec)&&(identical(other.rewardedLoadTimeoutSec, rewardedLoadTimeoutSec) || other.rewardedLoadTimeoutSec == rewardedLoadTimeoutSec)&&(identical(other.rewardedGrantPollTimeoutSec, rewardedGrantPollTimeoutSec) || other.rewardedGrantPollTimeoutSec == rewardedGrantPollTimeoutSec)&&(identical(other.adsEnabled, adsEnabled) || other.adsEnabled == adsEnabled)&&(identical(other.adsBannerEnabled, adsBannerEnabled) || other.adsBannerEnabled == adsBannerEnabled)&&const DeepCollectionEquality().equals(other.adsBannerScreens, adsBannerScreens)&&(identical(other.adsBannerMinCompletedReadings, adsBannerMinCompletedReadings) || other.adsBannerMinCompletedReadings == adsBannerMinCompletedReadings)&&(identical(other.adsAttPrepromptEnabled, adsAttPrepromptEnabled) || other.adsAttPrepromptEnabled == adsAttPrepromptEnabled)&&(identical(other.storeEnabled, storeEnabled) || other.storeEnabled == storeEnabled)&&const DeepCollectionEquality().equals(other.storePacks, storePacks)&&(identical(other.storeVerifyRetryWindowHours, storeVerifyRetryWindowHours) || other.storeVerifyRetryWindowHours == storeVerifyRetryWindowHours)&&(identical(other.storePendingHoldMinutes, storePendingHoldMinutes) || other.storePendingHoldMinutes == storePendingHoldMinutes)&&(identical(other.storeRemoveAdsEnabled, storeRemoveAdsEnabled) || other.storeRemoveAdsEnabled == storeRemoveAdsEnabled)&&(identical(other.storeShowBestValueBadge, storeShowBestValueBadge) || other.storeShowBestValueBadge == storeShowBestValueBadge)&&(identical(other.storeShowPerReadingPrice, storeShowPerReadingPrice) || other.storeShowPerReadingPrice == storeShowPerReadingPrice)&&(identical(other.aiConsentVersion, aiConsentVersion) || other.aiConsentVersion == aiConsentVersion)&&(identical(other.aiQuestionMaxChars, aiQuestionMaxChars) || other.aiQuestionMaxChars == aiQuestionMaxChars)&&(identical(other.appMinVersionIos, appMinVersionIos) || other.appMinVersionIos == appMinVersionIos)&&(identical(other.appMinVersionAndroid, appMinVersionAndroid) || other.appMinVersionAndroid == appMinVersionAndroid)&&(identical(other.appRecommendedVersionIos, appRecommendedVersionIos) || other.appRecommendedVersionIos == appRecommendedVersionIos)&&(identical(other.appRecommendedVersionAndroid, appRecommendedVersionAndroid) || other.appRecommendedVersionAndroid == appRecommendedVersionAndroid)&&(identical(other.balanceStaleAfterSec, balanceStaleAfterSec) || other.balanceStaleAfterSec == balanceStaleAfterSec)&&(identical(other.balanceResumeSyncThrottleSec, balanceResumeSyncThrottleSec) || other.balanceResumeSyncThrottleSec == balanceResumeSyncThrottleSec)&&(identical(other.reviewPromptAfterPositiveReadings, reviewPromptAfterPositiveReadings) || other.reviewPromptAfterPositiveReadings == reviewPromptAfterPositiveReadings)&&(identical(other.legalTermsUrl, legalTermsUrl) || other.legalTermsUrl == legalTermsUrl)&&(identical(other.legalPrivacyUrl, legalPrivacyUrl) || other.legalPrivacyUrl == legalPrivacyUrl)&&(identical(other.supportEmail, supportEmail) || other.supportEmail == supportEmail));
}


@override
int get hashCode => Object.hashAll([runtimeType,version,fetchedAt,readingsEnabled,readingsFreeDaily,readingsMaxPerInstallPerDay,readingsTzCooldownHours,const DeepCollectionEquality().hash(spreadsEnabled),rewardedEnabled,rewardedAmount,rewardedDailyCap,rewardedCooldownSec,rewardedIntentTtlSec,rewardedLoadTimeoutSec,rewardedGrantPollTimeoutSec,adsEnabled,adsBannerEnabled,const DeepCollectionEquality().hash(adsBannerScreens),adsBannerMinCompletedReadings,adsAttPrepromptEnabled,storeEnabled,const DeepCollectionEquality().hash(storePacks),storeVerifyRetryWindowHours,storePendingHoldMinutes,storeRemoveAdsEnabled,storeShowBestValueBadge,storeShowPerReadingPrice,aiConsentVersion,aiQuestionMaxChars,appMinVersionIos,appMinVersionAndroid,appRecommendedVersionIos,appRecommendedVersionAndroid,balanceStaleAfterSec,balanceResumeSyncThrottleSec,reviewPromptAfterPositiveReadings,legalTermsUrl,legalPrivacyUrl,supportEmail]);

@override
String toString() {
  return 'RemoteConfig(version: $version, fetchedAt: $fetchedAt, readingsEnabled: $readingsEnabled, readingsFreeDaily: $readingsFreeDaily, readingsMaxPerInstallPerDay: $readingsMaxPerInstallPerDay, readingsTzCooldownHours: $readingsTzCooldownHours, spreadsEnabled: $spreadsEnabled, rewardedEnabled: $rewardedEnabled, rewardedAmount: $rewardedAmount, rewardedDailyCap: $rewardedDailyCap, rewardedCooldownSec: $rewardedCooldownSec, rewardedIntentTtlSec: $rewardedIntentTtlSec, rewardedLoadTimeoutSec: $rewardedLoadTimeoutSec, rewardedGrantPollTimeoutSec: $rewardedGrantPollTimeoutSec, adsEnabled: $adsEnabled, adsBannerEnabled: $adsBannerEnabled, adsBannerScreens: $adsBannerScreens, adsBannerMinCompletedReadings: $adsBannerMinCompletedReadings, adsAttPrepromptEnabled: $adsAttPrepromptEnabled, storeEnabled: $storeEnabled, storePacks: $storePacks, storeVerifyRetryWindowHours: $storeVerifyRetryWindowHours, storePendingHoldMinutes: $storePendingHoldMinutes, storeRemoveAdsEnabled: $storeRemoveAdsEnabled, storeShowBestValueBadge: $storeShowBestValueBadge, storeShowPerReadingPrice: $storeShowPerReadingPrice, aiConsentVersion: $aiConsentVersion, aiQuestionMaxChars: $aiQuestionMaxChars, appMinVersionIos: $appMinVersionIos, appMinVersionAndroid: $appMinVersionAndroid, appRecommendedVersionIos: $appRecommendedVersionIos, appRecommendedVersionAndroid: $appRecommendedVersionAndroid, balanceStaleAfterSec: $balanceStaleAfterSec, balanceResumeSyncThrottleSec: $balanceResumeSyncThrottleSec, reviewPromptAfterPositiveReadings: $reviewPromptAfterPositiveReadings, legalTermsUrl: $legalTermsUrl, legalPrivacyUrl: $legalPrivacyUrl, supportEmail: $supportEmail)';
}


}

/// @nodoc
abstract mixin class $RemoteConfigCopyWith<$Res>  {
  factory $RemoteConfigCopyWith(RemoteConfig value, $Res Function(RemoteConfig) _then) = _$RemoteConfigCopyWithImpl;
@useResult
$Res call({
 int version, DateTime? fetchedAt, bool readingsEnabled, int readingsFreeDaily, int readingsMaxPerInstallPerDay, int readingsTzCooldownHours, List<SpreadId> spreadsEnabled, bool rewardedEnabled, int rewardedAmount, int rewardedDailyCap, int rewardedCooldownSec, int rewardedIntentTtlSec, int rewardedLoadTimeoutSec, int rewardedGrantPollTimeoutSec, bool adsEnabled, bool adsBannerEnabled, List<String> adsBannerScreens, int adsBannerMinCompletedReadings, bool adsAttPrepromptEnabled, bool storeEnabled, List<StorePack> storePacks, int storeVerifyRetryWindowHours, int storePendingHoldMinutes, bool storeRemoveAdsEnabled, bool storeShowBestValueBadge, bool storeShowPerReadingPrice, int aiConsentVersion, int aiQuestionMaxChars, String appMinVersionIos, String appMinVersionAndroid, String appRecommendedVersionIos, String appRecommendedVersionAndroid, int balanceStaleAfterSec, int balanceResumeSyncThrottleSec, int reviewPromptAfterPositiveReadings, String legalTermsUrl, String legalPrivacyUrl, String supportEmail
});




}
/// @nodoc
class _$RemoteConfigCopyWithImpl<$Res>
    implements $RemoteConfigCopyWith<$Res> {
  _$RemoteConfigCopyWithImpl(this._self, this._then);

  final RemoteConfig _self;
  final $Res Function(RemoteConfig) _then;

/// Create a copy of RemoteConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? fetchedAt = freezed,Object? readingsEnabled = null,Object? readingsFreeDaily = null,Object? readingsMaxPerInstallPerDay = null,Object? readingsTzCooldownHours = null,Object? spreadsEnabled = null,Object? rewardedEnabled = null,Object? rewardedAmount = null,Object? rewardedDailyCap = null,Object? rewardedCooldownSec = null,Object? rewardedIntentTtlSec = null,Object? rewardedLoadTimeoutSec = null,Object? rewardedGrantPollTimeoutSec = null,Object? adsEnabled = null,Object? adsBannerEnabled = null,Object? adsBannerScreens = null,Object? adsBannerMinCompletedReadings = null,Object? adsAttPrepromptEnabled = null,Object? storeEnabled = null,Object? storePacks = null,Object? storeVerifyRetryWindowHours = null,Object? storePendingHoldMinutes = null,Object? storeRemoveAdsEnabled = null,Object? storeShowBestValueBadge = null,Object? storeShowPerReadingPrice = null,Object? aiConsentVersion = null,Object? aiQuestionMaxChars = null,Object? appMinVersionIos = null,Object? appMinVersionAndroid = null,Object? appRecommendedVersionIos = null,Object? appRecommendedVersionAndroid = null,Object? balanceStaleAfterSec = null,Object? balanceResumeSyncThrottleSec = null,Object? reviewPromptAfterPositiveReadings = null,Object? legalTermsUrl = null,Object? legalPrivacyUrl = null,Object? supportEmail = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readingsEnabled: null == readingsEnabled ? _self.readingsEnabled : readingsEnabled // ignore: cast_nullable_to_non_nullable
as bool,readingsFreeDaily: null == readingsFreeDaily ? _self.readingsFreeDaily : readingsFreeDaily // ignore: cast_nullable_to_non_nullable
as int,readingsMaxPerInstallPerDay: null == readingsMaxPerInstallPerDay ? _self.readingsMaxPerInstallPerDay : readingsMaxPerInstallPerDay // ignore: cast_nullable_to_non_nullable
as int,readingsTzCooldownHours: null == readingsTzCooldownHours ? _self.readingsTzCooldownHours : readingsTzCooldownHours // ignore: cast_nullable_to_non_nullable
as int,spreadsEnabled: null == spreadsEnabled ? _self.spreadsEnabled : spreadsEnabled // ignore: cast_nullable_to_non_nullable
as List<SpreadId>,rewardedEnabled: null == rewardedEnabled ? _self.rewardedEnabled : rewardedEnabled // ignore: cast_nullable_to_non_nullable
as bool,rewardedAmount: null == rewardedAmount ? _self.rewardedAmount : rewardedAmount // ignore: cast_nullable_to_non_nullable
as int,rewardedDailyCap: null == rewardedDailyCap ? _self.rewardedDailyCap : rewardedDailyCap // ignore: cast_nullable_to_non_nullable
as int,rewardedCooldownSec: null == rewardedCooldownSec ? _self.rewardedCooldownSec : rewardedCooldownSec // ignore: cast_nullable_to_non_nullable
as int,rewardedIntentTtlSec: null == rewardedIntentTtlSec ? _self.rewardedIntentTtlSec : rewardedIntentTtlSec // ignore: cast_nullable_to_non_nullable
as int,rewardedLoadTimeoutSec: null == rewardedLoadTimeoutSec ? _self.rewardedLoadTimeoutSec : rewardedLoadTimeoutSec // ignore: cast_nullable_to_non_nullable
as int,rewardedGrantPollTimeoutSec: null == rewardedGrantPollTimeoutSec ? _self.rewardedGrantPollTimeoutSec : rewardedGrantPollTimeoutSec // ignore: cast_nullable_to_non_nullable
as int,adsEnabled: null == adsEnabled ? _self.adsEnabled : adsEnabled // ignore: cast_nullable_to_non_nullable
as bool,adsBannerEnabled: null == adsBannerEnabled ? _self.adsBannerEnabled : adsBannerEnabled // ignore: cast_nullable_to_non_nullable
as bool,adsBannerScreens: null == adsBannerScreens ? _self.adsBannerScreens : adsBannerScreens // ignore: cast_nullable_to_non_nullable
as List<String>,adsBannerMinCompletedReadings: null == adsBannerMinCompletedReadings ? _self.adsBannerMinCompletedReadings : adsBannerMinCompletedReadings // ignore: cast_nullable_to_non_nullable
as int,adsAttPrepromptEnabled: null == adsAttPrepromptEnabled ? _self.adsAttPrepromptEnabled : adsAttPrepromptEnabled // ignore: cast_nullable_to_non_nullable
as bool,storeEnabled: null == storeEnabled ? _self.storeEnabled : storeEnabled // ignore: cast_nullable_to_non_nullable
as bool,storePacks: null == storePacks ? _self.storePacks : storePacks // ignore: cast_nullable_to_non_nullable
as List<StorePack>,storeVerifyRetryWindowHours: null == storeVerifyRetryWindowHours ? _self.storeVerifyRetryWindowHours : storeVerifyRetryWindowHours // ignore: cast_nullable_to_non_nullable
as int,storePendingHoldMinutes: null == storePendingHoldMinutes ? _self.storePendingHoldMinutes : storePendingHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,storeRemoveAdsEnabled: null == storeRemoveAdsEnabled ? _self.storeRemoveAdsEnabled : storeRemoveAdsEnabled // ignore: cast_nullable_to_non_nullable
as bool,storeShowBestValueBadge: null == storeShowBestValueBadge ? _self.storeShowBestValueBadge : storeShowBestValueBadge // ignore: cast_nullable_to_non_nullable
as bool,storeShowPerReadingPrice: null == storeShowPerReadingPrice ? _self.storeShowPerReadingPrice : storeShowPerReadingPrice // ignore: cast_nullable_to_non_nullable
as bool,aiConsentVersion: null == aiConsentVersion ? _self.aiConsentVersion : aiConsentVersion // ignore: cast_nullable_to_non_nullable
as int,aiQuestionMaxChars: null == aiQuestionMaxChars ? _self.aiQuestionMaxChars : aiQuestionMaxChars // ignore: cast_nullable_to_non_nullable
as int,appMinVersionIos: null == appMinVersionIos ? _self.appMinVersionIos : appMinVersionIos // ignore: cast_nullable_to_non_nullable
as String,appMinVersionAndroid: null == appMinVersionAndroid ? _self.appMinVersionAndroid : appMinVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,appRecommendedVersionIos: null == appRecommendedVersionIos ? _self.appRecommendedVersionIos : appRecommendedVersionIos // ignore: cast_nullable_to_non_nullable
as String,appRecommendedVersionAndroid: null == appRecommendedVersionAndroid ? _self.appRecommendedVersionAndroid : appRecommendedVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,balanceStaleAfterSec: null == balanceStaleAfterSec ? _self.balanceStaleAfterSec : balanceStaleAfterSec // ignore: cast_nullable_to_non_nullable
as int,balanceResumeSyncThrottleSec: null == balanceResumeSyncThrottleSec ? _self.balanceResumeSyncThrottleSec : balanceResumeSyncThrottleSec // ignore: cast_nullable_to_non_nullable
as int,reviewPromptAfterPositiveReadings: null == reviewPromptAfterPositiveReadings ? _self.reviewPromptAfterPositiveReadings : reviewPromptAfterPositiveReadings // ignore: cast_nullable_to_non_nullable
as int,legalTermsUrl: null == legalTermsUrl ? _self.legalTermsUrl : legalTermsUrl // ignore: cast_nullable_to_non_nullable
as String,legalPrivacyUrl: null == legalPrivacyUrl ? _self.legalPrivacyUrl : legalPrivacyUrl // ignore: cast_nullable_to_non_nullable
as String,supportEmail: null == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoteConfig].
extension RemoteConfigPatterns on RemoteConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoteConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoteConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoteConfig value)  $default,){
final _that = this;
switch (_that) {
case _RemoteConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoteConfig value)?  $default,){
final _that = this;
switch (_that) {
case _RemoteConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  DateTime? fetchedAt,  bool readingsEnabled,  int readingsFreeDaily,  int readingsMaxPerInstallPerDay,  int readingsTzCooldownHours,  List<SpreadId> spreadsEnabled,  bool rewardedEnabled,  int rewardedAmount,  int rewardedDailyCap,  int rewardedCooldownSec,  int rewardedIntentTtlSec,  int rewardedLoadTimeoutSec,  int rewardedGrantPollTimeoutSec,  bool adsEnabled,  bool adsBannerEnabled,  List<String> adsBannerScreens,  int adsBannerMinCompletedReadings,  bool adsAttPrepromptEnabled,  bool storeEnabled,  List<StorePack> storePacks,  int storeVerifyRetryWindowHours,  int storePendingHoldMinutes,  bool storeRemoveAdsEnabled,  bool storeShowBestValueBadge,  bool storeShowPerReadingPrice,  int aiConsentVersion,  int aiQuestionMaxChars,  String appMinVersionIos,  String appMinVersionAndroid,  String appRecommendedVersionIos,  String appRecommendedVersionAndroid,  int balanceStaleAfterSec,  int balanceResumeSyncThrottleSec,  int reviewPromptAfterPositiveReadings,  String legalTermsUrl,  String legalPrivacyUrl,  String supportEmail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoteConfig() when $default != null:
return $default(_that.version,_that.fetchedAt,_that.readingsEnabled,_that.readingsFreeDaily,_that.readingsMaxPerInstallPerDay,_that.readingsTzCooldownHours,_that.spreadsEnabled,_that.rewardedEnabled,_that.rewardedAmount,_that.rewardedDailyCap,_that.rewardedCooldownSec,_that.rewardedIntentTtlSec,_that.rewardedLoadTimeoutSec,_that.rewardedGrantPollTimeoutSec,_that.adsEnabled,_that.adsBannerEnabled,_that.adsBannerScreens,_that.adsBannerMinCompletedReadings,_that.adsAttPrepromptEnabled,_that.storeEnabled,_that.storePacks,_that.storeVerifyRetryWindowHours,_that.storePendingHoldMinutes,_that.storeRemoveAdsEnabled,_that.storeShowBestValueBadge,_that.storeShowPerReadingPrice,_that.aiConsentVersion,_that.aiQuestionMaxChars,_that.appMinVersionIos,_that.appMinVersionAndroid,_that.appRecommendedVersionIos,_that.appRecommendedVersionAndroid,_that.balanceStaleAfterSec,_that.balanceResumeSyncThrottleSec,_that.reviewPromptAfterPositiveReadings,_that.legalTermsUrl,_that.legalPrivacyUrl,_that.supportEmail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  DateTime? fetchedAt,  bool readingsEnabled,  int readingsFreeDaily,  int readingsMaxPerInstallPerDay,  int readingsTzCooldownHours,  List<SpreadId> spreadsEnabled,  bool rewardedEnabled,  int rewardedAmount,  int rewardedDailyCap,  int rewardedCooldownSec,  int rewardedIntentTtlSec,  int rewardedLoadTimeoutSec,  int rewardedGrantPollTimeoutSec,  bool adsEnabled,  bool adsBannerEnabled,  List<String> adsBannerScreens,  int adsBannerMinCompletedReadings,  bool adsAttPrepromptEnabled,  bool storeEnabled,  List<StorePack> storePacks,  int storeVerifyRetryWindowHours,  int storePendingHoldMinutes,  bool storeRemoveAdsEnabled,  bool storeShowBestValueBadge,  bool storeShowPerReadingPrice,  int aiConsentVersion,  int aiQuestionMaxChars,  String appMinVersionIos,  String appMinVersionAndroid,  String appRecommendedVersionIos,  String appRecommendedVersionAndroid,  int balanceStaleAfterSec,  int balanceResumeSyncThrottleSec,  int reviewPromptAfterPositiveReadings,  String legalTermsUrl,  String legalPrivacyUrl,  String supportEmail)  $default,) {final _that = this;
switch (_that) {
case _RemoteConfig():
return $default(_that.version,_that.fetchedAt,_that.readingsEnabled,_that.readingsFreeDaily,_that.readingsMaxPerInstallPerDay,_that.readingsTzCooldownHours,_that.spreadsEnabled,_that.rewardedEnabled,_that.rewardedAmount,_that.rewardedDailyCap,_that.rewardedCooldownSec,_that.rewardedIntentTtlSec,_that.rewardedLoadTimeoutSec,_that.rewardedGrantPollTimeoutSec,_that.adsEnabled,_that.adsBannerEnabled,_that.adsBannerScreens,_that.adsBannerMinCompletedReadings,_that.adsAttPrepromptEnabled,_that.storeEnabled,_that.storePacks,_that.storeVerifyRetryWindowHours,_that.storePendingHoldMinutes,_that.storeRemoveAdsEnabled,_that.storeShowBestValueBadge,_that.storeShowPerReadingPrice,_that.aiConsentVersion,_that.aiQuestionMaxChars,_that.appMinVersionIos,_that.appMinVersionAndroid,_that.appRecommendedVersionIos,_that.appRecommendedVersionAndroid,_that.balanceStaleAfterSec,_that.balanceResumeSyncThrottleSec,_that.reviewPromptAfterPositiveReadings,_that.legalTermsUrl,_that.legalPrivacyUrl,_that.supportEmail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  DateTime? fetchedAt,  bool readingsEnabled,  int readingsFreeDaily,  int readingsMaxPerInstallPerDay,  int readingsTzCooldownHours,  List<SpreadId> spreadsEnabled,  bool rewardedEnabled,  int rewardedAmount,  int rewardedDailyCap,  int rewardedCooldownSec,  int rewardedIntentTtlSec,  int rewardedLoadTimeoutSec,  int rewardedGrantPollTimeoutSec,  bool adsEnabled,  bool adsBannerEnabled,  List<String> adsBannerScreens,  int adsBannerMinCompletedReadings,  bool adsAttPrepromptEnabled,  bool storeEnabled,  List<StorePack> storePacks,  int storeVerifyRetryWindowHours,  int storePendingHoldMinutes,  bool storeRemoveAdsEnabled,  bool storeShowBestValueBadge,  bool storeShowPerReadingPrice,  int aiConsentVersion,  int aiQuestionMaxChars,  String appMinVersionIos,  String appMinVersionAndroid,  String appRecommendedVersionIos,  String appRecommendedVersionAndroid,  int balanceStaleAfterSec,  int balanceResumeSyncThrottleSec,  int reviewPromptAfterPositiveReadings,  String legalTermsUrl,  String legalPrivacyUrl,  String supportEmail)?  $default,) {final _that = this;
switch (_that) {
case _RemoteConfig() when $default != null:
return $default(_that.version,_that.fetchedAt,_that.readingsEnabled,_that.readingsFreeDaily,_that.readingsMaxPerInstallPerDay,_that.readingsTzCooldownHours,_that.spreadsEnabled,_that.rewardedEnabled,_that.rewardedAmount,_that.rewardedDailyCap,_that.rewardedCooldownSec,_that.rewardedIntentTtlSec,_that.rewardedLoadTimeoutSec,_that.rewardedGrantPollTimeoutSec,_that.adsEnabled,_that.adsBannerEnabled,_that.adsBannerScreens,_that.adsBannerMinCompletedReadings,_that.adsAttPrepromptEnabled,_that.storeEnabled,_that.storePacks,_that.storeVerifyRetryWindowHours,_that.storePendingHoldMinutes,_that.storeRemoveAdsEnabled,_that.storeShowBestValueBadge,_that.storeShowPerReadingPrice,_that.aiConsentVersion,_that.aiQuestionMaxChars,_that.appMinVersionIos,_that.appMinVersionAndroid,_that.appRecommendedVersionIos,_that.appRecommendedVersionAndroid,_that.balanceStaleAfterSec,_that.balanceResumeSyncThrottleSec,_that.reviewPromptAfterPositiveReadings,_that.legalTermsUrl,_that.legalPrivacyUrl,_that.supportEmail);case _:
  return null;

}
}

}

/// @nodoc


class _RemoteConfig extends RemoteConfig {
  const _RemoteConfig({this.version = 0, this.fetchedAt, this.readingsEnabled = true, this.readingsFreeDaily = 1, this.readingsMaxPerInstallPerDay = 30, this.readingsTzCooldownHours = 24, final  List<SpreadId> spreadsEnabled = kSpreadIds, this.rewardedEnabled = true, this.rewardedAmount = 1, this.rewardedDailyCap = 3, this.rewardedCooldownSec = 300, this.rewardedIntentTtlSec = 900, this.rewardedLoadTimeoutSec = 10, this.rewardedGrantPollTimeoutSec = 20, this.adsEnabled = true, this.adsBannerEnabled = true, final  List<String> adsBannerScreens = _bannerAllowList, this.adsBannerMinCompletedReadings = 1, this.adsAttPrepromptEnabled = true, this.storeEnabled = true, final  List<StorePack> storePacks = _defaultPacks, this.storeVerifyRetryWindowHours = 72, this.storePendingHoldMinutes = 30, this.storeRemoveAdsEnabled = true, this.storeShowBestValueBadge = true, this.storeShowPerReadingPrice = true, this.aiConsentVersion = 2, this.aiQuestionMaxChars = 300, this.appMinVersionIos = '1.0.0', this.appMinVersionAndroid = '1.0.0', this.appRecommendedVersionIos = '1.0.0', this.appRecommendedVersionAndroid = '1.0.0', this.balanceStaleAfterSec = 300, this.balanceResumeSyncThrottleSec = 30, this.reviewPromptAfterPositiveReadings = 3, this.legalTermsUrl = 'https://taro.vshyrochuk.com/terms', this.legalPrivacyUrl = 'https://taro.vshyrochuk.com/privacy', this.supportEmail = 'volodymyr.shyrochuk@gmail.com'}): _spreadsEnabled = spreadsEnabled,_adsBannerScreens = adsBannerScreens,_storePacks = storePacks,super._();
  

/// Config document `version` (0 = compiled defaults).
@override@JsonKey() final  int version;
/// When the document was fetched; `null` for the defaults.
@override final  DateTime? fetchedAt;
/// `readings.enabled`: the only reading kill switch.
@override@JsonKey() final  bool readingsEnabled;
/// `readings.freeDaily`, 1–5.
@override@JsonKey() final  int readingsFreeDaily;
/// `readings.maxPerInstallPerDay`, 5–100.
@override@JsonKey() final  int readingsMaxPerInstallPerDay;
/// `readings.tzCooldownHours`, 12–168.
@override@JsonKey() final  int readingsTzCooldownHours;
/// `spreads.enabled`, a subset of the six spread IDs.
 final  List<SpreadId> _spreadsEnabled;
/// `spreads.enabled`, a subset of the six spread IDs.
@override@JsonKey() List<SpreadId> get spreadsEnabled {
  if (_spreadsEnabled is EqualUnmodifiableListView) return _spreadsEnabled;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spreadsEnabled);
}

/// `rewarded.enabled`.
@override@JsonKey() final  bool rewardedEnabled;
/// `rewarded.amount`, 1–2.
@override@JsonKey() final  int rewardedAmount;
/// `rewarded.dailyCap`, 0–10 (0 = disabled).
@override@JsonKey() final  int rewardedDailyCap;
/// `rewarded.cooldownSec`, 0–3600.
@override@JsonKey() final  int rewardedCooldownSec;
/// `rewarded.intentTtlSec`, 300–3600.
@override@JsonKey() final  int rewardedIntentTtlSec;
/// `rewarded.loadTimeoutSec`, 5–30.
@override@JsonKey() final  int rewardedLoadTimeoutSec;
/// `rewarded.grantPollTimeoutSec`, 5–60.
@override@JsonKey() final  int rewardedGrantPollTimeoutSec;
/// `ads.enabled`: global ads kill switch (also hides rewarded).
@override@JsonKey() final  bool adsEnabled;
/// `ads.bannerEnabled`.
@override@JsonKey() final  bool adsBannerEnabled;
/// `ads.bannerScreens`, a subset of `kBannerAllowList`.
 final  List<String> _adsBannerScreens;
/// `ads.bannerScreens`, a subset of `kBannerAllowList`.
@override@JsonKey() List<String> get adsBannerScreens {
  if (_adsBannerScreens is EqualUnmodifiableListView) return _adsBannerScreens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_adsBannerScreens);
}

/// `ads.bannerMinCompletedReadings`, 0–10.
@override@JsonKey() final  int adsBannerMinCompletedReadings;
/// `ads.attPrepromptEnabled`.
@override@JsonKey() final  bool adsAttPrepromptEnabled;
/// `store.enabled`.
@override@JsonKey() final  bool storeEnabled;
/// `store.packs`, 1–4 consumables.
 final  List<StorePack> _storePacks;
/// `store.packs`, 1–4 consumables.
@override@JsonKey() List<StorePack> get storePacks {
  if (_storePacks is EqualUnmodifiableListView) return _storePacks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storePacks);
}

/// `store.verifyRetryWindowHours`, 24–168.
@override@JsonKey() final  int storeVerifyRetryWindowHours;
/// `store.pendingHoldMinutes`, 5–240.
@override@JsonKey() final  int storePendingHoldMinutes;
/// `store.removeAdsEnabled`.
@override@JsonKey() final  bool storeRemoveAdsEnabled;
/// `store.showBestValueBadge`.
@override@JsonKey() final  bool storeShowBestValueBadge;
/// `store.showPerReadingPrice`.
@override@JsonKey() final  bool storeShowPerReadingPrice;
/// `ai.consentVersion` (2 since the OpenAI-only consent copy, RC97).
@override@JsonKey() final  int aiConsentVersion;
/// `ai.questionMaxChars` (grapheme clusters, RC45).
@override@JsonKey() final  int aiQuestionMaxChars;
/// `app.minVersion.ios`.
@override@JsonKey() final  String appMinVersionIos;
/// `app.minVersion.android`.
@override@JsonKey() final  String appMinVersionAndroid;
/// `app.recommendedVersion.ios`.
@override@JsonKey() final  String appRecommendedVersionIos;
/// `app.recommendedVersion.android`.
@override@JsonKey() final  String appRecommendedVersionAndroid;
/// `balance.staleAfterSec`, 30–3600.
@override@JsonKey() final  int balanceStaleAfterSec;
/// `balance.resumeSyncThrottleSec`, 0–600.
@override@JsonKey() final  int balanceResumeSyncThrottleSec;
/// `review.promptAfterPositiveReadings`, 1–20.
@override@JsonKey() final  int reviewPromptAfterPositiveReadings;
/// `legal.termsUrl`.
@override@JsonKey() final  String legalTermsUrl;
/// `legal.privacyUrl`.
@override@JsonKey() final  String legalPrivacyUrl;
/// `support.email`.
@override@JsonKey() final  String supportEmail;

/// Create a copy of RemoteConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoteConfigCopyWith<_RemoteConfig> get copyWith => __$RemoteConfigCopyWithImpl<_RemoteConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoteConfig&&(identical(other.version, version) || other.version == version)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.readingsEnabled, readingsEnabled) || other.readingsEnabled == readingsEnabled)&&(identical(other.readingsFreeDaily, readingsFreeDaily) || other.readingsFreeDaily == readingsFreeDaily)&&(identical(other.readingsMaxPerInstallPerDay, readingsMaxPerInstallPerDay) || other.readingsMaxPerInstallPerDay == readingsMaxPerInstallPerDay)&&(identical(other.readingsTzCooldownHours, readingsTzCooldownHours) || other.readingsTzCooldownHours == readingsTzCooldownHours)&&const DeepCollectionEquality().equals(other._spreadsEnabled, _spreadsEnabled)&&(identical(other.rewardedEnabled, rewardedEnabled) || other.rewardedEnabled == rewardedEnabled)&&(identical(other.rewardedAmount, rewardedAmount) || other.rewardedAmount == rewardedAmount)&&(identical(other.rewardedDailyCap, rewardedDailyCap) || other.rewardedDailyCap == rewardedDailyCap)&&(identical(other.rewardedCooldownSec, rewardedCooldownSec) || other.rewardedCooldownSec == rewardedCooldownSec)&&(identical(other.rewardedIntentTtlSec, rewardedIntentTtlSec) || other.rewardedIntentTtlSec == rewardedIntentTtlSec)&&(identical(other.rewardedLoadTimeoutSec, rewardedLoadTimeoutSec) || other.rewardedLoadTimeoutSec == rewardedLoadTimeoutSec)&&(identical(other.rewardedGrantPollTimeoutSec, rewardedGrantPollTimeoutSec) || other.rewardedGrantPollTimeoutSec == rewardedGrantPollTimeoutSec)&&(identical(other.adsEnabled, adsEnabled) || other.adsEnabled == adsEnabled)&&(identical(other.adsBannerEnabled, adsBannerEnabled) || other.adsBannerEnabled == adsBannerEnabled)&&const DeepCollectionEquality().equals(other._adsBannerScreens, _adsBannerScreens)&&(identical(other.adsBannerMinCompletedReadings, adsBannerMinCompletedReadings) || other.adsBannerMinCompletedReadings == adsBannerMinCompletedReadings)&&(identical(other.adsAttPrepromptEnabled, adsAttPrepromptEnabled) || other.adsAttPrepromptEnabled == adsAttPrepromptEnabled)&&(identical(other.storeEnabled, storeEnabled) || other.storeEnabled == storeEnabled)&&const DeepCollectionEquality().equals(other._storePacks, _storePacks)&&(identical(other.storeVerifyRetryWindowHours, storeVerifyRetryWindowHours) || other.storeVerifyRetryWindowHours == storeVerifyRetryWindowHours)&&(identical(other.storePendingHoldMinutes, storePendingHoldMinutes) || other.storePendingHoldMinutes == storePendingHoldMinutes)&&(identical(other.storeRemoveAdsEnabled, storeRemoveAdsEnabled) || other.storeRemoveAdsEnabled == storeRemoveAdsEnabled)&&(identical(other.storeShowBestValueBadge, storeShowBestValueBadge) || other.storeShowBestValueBadge == storeShowBestValueBadge)&&(identical(other.storeShowPerReadingPrice, storeShowPerReadingPrice) || other.storeShowPerReadingPrice == storeShowPerReadingPrice)&&(identical(other.aiConsentVersion, aiConsentVersion) || other.aiConsentVersion == aiConsentVersion)&&(identical(other.aiQuestionMaxChars, aiQuestionMaxChars) || other.aiQuestionMaxChars == aiQuestionMaxChars)&&(identical(other.appMinVersionIos, appMinVersionIos) || other.appMinVersionIos == appMinVersionIos)&&(identical(other.appMinVersionAndroid, appMinVersionAndroid) || other.appMinVersionAndroid == appMinVersionAndroid)&&(identical(other.appRecommendedVersionIos, appRecommendedVersionIos) || other.appRecommendedVersionIos == appRecommendedVersionIos)&&(identical(other.appRecommendedVersionAndroid, appRecommendedVersionAndroid) || other.appRecommendedVersionAndroid == appRecommendedVersionAndroid)&&(identical(other.balanceStaleAfterSec, balanceStaleAfterSec) || other.balanceStaleAfterSec == balanceStaleAfterSec)&&(identical(other.balanceResumeSyncThrottleSec, balanceResumeSyncThrottleSec) || other.balanceResumeSyncThrottleSec == balanceResumeSyncThrottleSec)&&(identical(other.reviewPromptAfterPositiveReadings, reviewPromptAfterPositiveReadings) || other.reviewPromptAfterPositiveReadings == reviewPromptAfterPositiveReadings)&&(identical(other.legalTermsUrl, legalTermsUrl) || other.legalTermsUrl == legalTermsUrl)&&(identical(other.legalPrivacyUrl, legalPrivacyUrl) || other.legalPrivacyUrl == legalPrivacyUrl)&&(identical(other.supportEmail, supportEmail) || other.supportEmail == supportEmail));
}


@override
int get hashCode => Object.hashAll([runtimeType,version,fetchedAt,readingsEnabled,readingsFreeDaily,readingsMaxPerInstallPerDay,readingsTzCooldownHours,const DeepCollectionEquality().hash(_spreadsEnabled),rewardedEnabled,rewardedAmount,rewardedDailyCap,rewardedCooldownSec,rewardedIntentTtlSec,rewardedLoadTimeoutSec,rewardedGrantPollTimeoutSec,adsEnabled,adsBannerEnabled,const DeepCollectionEquality().hash(_adsBannerScreens),adsBannerMinCompletedReadings,adsAttPrepromptEnabled,storeEnabled,const DeepCollectionEquality().hash(_storePacks),storeVerifyRetryWindowHours,storePendingHoldMinutes,storeRemoveAdsEnabled,storeShowBestValueBadge,storeShowPerReadingPrice,aiConsentVersion,aiQuestionMaxChars,appMinVersionIos,appMinVersionAndroid,appRecommendedVersionIos,appRecommendedVersionAndroid,balanceStaleAfterSec,balanceResumeSyncThrottleSec,reviewPromptAfterPositiveReadings,legalTermsUrl,legalPrivacyUrl,supportEmail]);

@override
String toString() {
  return 'RemoteConfig(version: $version, fetchedAt: $fetchedAt, readingsEnabled: $readingsEnabled, readingsFreeDaily: $readingsFreeDaily, readingsMaxPerInstallPerDay: $readingsMaxPerInstallPerDay, readingsTzCooldownHours: $readingsTzCooldownHours, spreadsEnabled: $spreadsEnabled, rewardedEnabled: $rewardedEnabled, rewardedAmount: $rewardedAmount, rewardedDailyCap: $rewardedDailyCap, rewardedCooldownSec: $rewardedCooldownSec, rewardedIntentTtlSec: $rewardedIntentTtlSec, rewardedLoadTimeoutSec: $rewardedLoadTimeoutSec, rewardedGrantPollTimeoutSec: $rewardedGrantPollTimeoutSec, adsEnabled: $adsEnabled, adsBannerEnabled: $adsBannerEnabled, adsBannerScreens: $adsBannerScreens, adsBannerMinCompletedReadings: $adsBannerMinCompletedReadings, adsAttPrepromptEnabled: $adsAttPrepromptEnabled, storeEnabled: $storeEnabled, storePacks: $storePacks, storeVerifyRetryWindowHours: $storeVerifyRetryWindowHours, storePendingHoldMinutes: $storePendingHoldMinutes, storeRemoveAdsEnabled: $storeRemoveAdsEnabled, storeShowBestValueBadge: $storeShowBestValueBadge, storeShowPerReadingPrice: $storeShowPerReadingPrice, aiConsentVersion: $aiConsentVersion, aiQuestionMaxChars: $aiQuestionMaxChars, appMinVersionIos: $appMinVersionIos, appMinVersionAndroid: $appMinVersionAndroid, appRecommendedVersionIos: $appRecommendedVersionIos, appRecommendedVersionAndroid: $appRecommendedVersionAndroid, balanceStaleAfterSec: $balanceStaleAfterSec, balanceResumeSyncThrottleSec: $balanceResumeSyncThrottleSec, reviewPromptAfterPositiveReadings: $reviewPromptAfterPositiveReadings, legalTermsUrl: $legalTermsUrl, legalPrivacyUrl: $legalPrivacyUrl, supportEmail: $supportEmail)';
}


}

/// @nodoc
abstract mixin class _$RemoteConfigCopyWith<$Res> implements $RemoteConfigCopyWith<$Res> {
  factory _$RemoteConfigCopyWith(_RemoteConfig value, $Res Function(_RemoteConfig) _then) = __$RemoteConfigCopyWithImpl;
@override @useResult
$Res call({
 int version, DateTime? fetchedAt, bool readingsEnabled, int readingsFreeDaily, int readingsMaxPerInstallPerDay, int readingsTzCooldownHours, List<SpreadId> spreadsEnabled, bool rewardedEnabled, int rewardedAmount, int rewardedDailyCap, int rewardedCooldownSec, int rewardedIntentTtlSec, int rewardedLoadTimeoutSec, int rewardedGrantPollTimeoutSec, bool adsEnabled, bool adsBannerEnabled, List<String> adsBannerScreens, int adsBannerMinCompletedReadings, bool adsAttPrepromptEnabled, bool storeEnabled, List<StorePack> storePacks, int storeVerifyRetryWindowHours, int storePendingHoldMinutes, bool storeRemoveAdsEnabled, bool storeShowBestValueBadge, bool storeShowPerReadingPrice, int aiConsentVersion, int aiQuestionMaxChars, String appMinVersionIos, String appMinVersionAndroid, String appRecommendedVersionIos, String appRecommendedVersionAndroid, int balanceStaleAfterSec, int balanceResumeSyncThrottleSec, int reviewPromptAfterPositiveReadings, String legalTermsUrl, String legalPrivacyUrl, String supportEmail
});




}
/// @nodoc
class __$RemoteConfigCopyWithImpl<$Res>
    implements _$RemoteConfigCopyWith<$Res> {
  __$RemoteConfigCopyWithImpl(this._self, this._then);

  final _RemoteConfig _self;
  final $Res Function(_RemoteConfig) _then;

/// Create a copy of RemoteConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? fetchedAt = freezed,Object? readingsEnabled = null,Object? readingsFreeDaily = null,Object? readingsMaxPerInstallPerDay = null,Object? readingsTzCooldownHours = null,Object? spreadsEnabled = null,Object? rewardedEnabled = null,Object? rewardedAmount = null,Object? rewardedDailyCap = null,Object? rewardedCooldownSec = null,Object? rewardedIntentTtlSec = null,Object? rewardedLoadTimeoutSec = null,Object? rewardedGrantPollTimeoutSec = null,Object? adsEnabled = null,Object? adsBannerEnabled = null,Object? adsBannerScreens = null,Object? adsBannerMinCompletedReadings = null,Object? adsAttPrepromptEnabled = null,Object? storeEnabled = null,Object? storePacks = null,Object? storeVerifyRetryWindowHours = null,Object? storePendingHoldMinutes = null,Object? storeRemoveAdsEnabled = null,Object? storeShowBestValueBadge = null,Object? storeShowPerReadingPrice = null,Object? aiConsentVersion = null,Object? aiQuestionMaxChars = null,Object? appMinVersionIos = null,Object? appMinVersionAndroid = null,Object? appRecommendedVersionIos = null,Object? appRecommendedVersionAndroid = null,Object? balanceStaleAfterSec = null,Object? balanceResumeSyncThrottleSec = null,Object? reviewPromptAfterPositiveReadings = null,Object? legalTermsUrl = null,Object? legalPrivacyUrl = null,Object? supportEmail = null,}) {
  return _then(_RemoteConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,fetchedAt: freezed == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,readingsEnabled: null == readingsEnabled ? _self.readingsEnabled : readingsEnabled // ignore: cast_nullable_to_non_nullable
as bool,readingsFreeDaily: null == readingsFreeDaily ? _self.readingsFreeDaily : readingsFreeDaily // ignore: cast_nullable_to_non_nullable
as int,readingsMaxPerInstallPerDay: null == readingsMaxPerInstallPerDay ? _self.readingsMaxPerInstallPerDay : readingsMaxPerInstallPerDay // ignore: cast_nullable_to_non_nullable
as int,readingsTzCooldownHours: null == readingsTzCooldownHours ? _self.readingsTzCooldownHours : readingsTzCooldownHours // ignore: cast_nullable_to_non_nullable
as int,spreadsEnabled: null == spreadsEnabled ? _self._spreadsEnabled : spreadsEnabled // ignore: cast_nullable_to_non_nullable
as List<SpreadId>,rewardedEnabled: null == rewardedEnabled ? _self.rewardedEnabled : rewardedEnabled // ignore: cast_nullable_to_non_nullable
as bool,rewardedAmount: null == rewardedAmount ? _self.rewardedAmount : rewardedAmount // ignore: cast_nullable_to_non_nullable
as int,rewardedDailyCap: null == rewardedDailyCap ? _self.rewardedDailyCap : rewardedDailyCap // ignore: cast_nullable_to_non_nullable
as int,rewardedCooldownSec: null == rewardedCooldownSec ? _self.rewardedCooldownSec : rewardedCooldownSec // ignore: cast_nullable_to_non_nullable
as int,rewardedIntentTtlSec: null == rewardedIntentTtlSec ? _self.rewardedIntentTtlSec : rewardedIntentTtlSec // ignore: cast_nullable_to_non_nullable
as int,rewardedLoadTimeoutSec: null == rewardedLoadTimeoutSec ? _self.rewardedLoadTimeoutSec : rewardedLoadTimeoutSec // ignore: cast_nullable_to_non_nullable
as int,rewardedGrantPollTimeoutSec: null == rewardedGrantPollTimeoutSec ? _self.rewardedGrantPollTimeoutSec : rewardedGrantPollTimeoutSec // ignore: cast_nullable_to_non_nullable
as int,adsEnabled: null == adsEnabled ? _self.adsEnabled : adsEnabled // ignore: cast_nullable_to_non_nullable
as bool,adsBannerEnabled: null == adsBannerEnabled ? _self.adsBannerEnabled : adsBannerEnabled // ignore: cast_nullable_to_non_nullable
as bool,adsBannerScreens: null == adsBannerScreens ? _self._adsBannerScreens : adsBannerScreens // ignore: cast_nullable_to_non_nullable
as List<String>,adsBannerMinCompletedReadings: null == adsBannerMinCompletedReadings ? _self.adsBannerMinCompletedReadings : adsBannerMinCompletedReadings // ignore: cast_nullable_to_non_nullable
as int,adsAttPrepromptEnabled: null == adsAttPrepromptEnabled ? _self.adsAttPrepromptEnabled : adsAttPrepromptEnabled // ignore: cast_nullable_to_non_nullable
as bool,storeEnabled: null == storeEnabled ? _self.storeEnabled : storeEnabled // ignore: cast_nullable_to_non_nullable
as bool,storePacks: null == storePacks ? _self._storePacks : storePacks // ignore: cast_nullable_to_non_nullable
as List<StorePack>,storeVerifyRetryWindowHours: null == storeVerifyRetryWindowHours ? _self.storeVerifyRetryWindowHours : storeVerifyRetryWindowHours // ignore: cast_nullable_to_non_nullable
as int,storePendingHoldMinutes: null == storePendingHoldMinutes ? _self.storePendingHoldMinutes : storePendingHoldMinutes // ignore: cast_nullable_to_non_nullable
as int,storeRemoveAdsEnabled: null == storeRemoveAdsEnabled ? _self.storeRemoveAdsEnabled : storeRemoveAdsEnabled // ignore: cast_nullable_to_non_nullable
as bool,storeShowBestValueBadge: null == storeShowBestValueBadge ? _self.storeShowBestValueBadge : storeShowBestValueBadge // ignore: cast_nullable_to_non_nullable
as bool,storeShowPerReadingPrice: null == storeShowPerReadingPrice ? _self.storeShowPerReadingPrice : storeShowPerReadingPrice // ignore: cast_nullable_to_non_nullable
as bool,aiConsentVersion: null == aiConsentVersion ? _self.aiConsentVersion : aiConsentVersion // ignore: cast_nullable_to_non_nullable
as int,aiQuestionMaxChars: null == aiQuestionMaxChars ? _self.aiQuestionMaxChars : aiQuestionMaxChars // ignore: cast_nullable_to_non_nullable
as int,appMinVersionIos: null == appMinVersionIos ? _self.appMinVersionIos : appMinVersionIos // ignore: cast_nullable_to_non_nullable
as String,appMinVersionAndroid: null == appMinVersionAndroid ? _self.appMinVersionAndroid : appMinVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,appRecommendedVersionIos: null == appRecommendedVersionIos ? _self.appRecommendedVersionIos : appRecommendedVersionIos // ignore: cast_nullable_to_non_nullable
as String,appRecommendedVersionAndroid: null == appRecommendedVersionAndroid ? _self.appRecommendedVersionAndroid : appRecommendedVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,balanceStaleAfterSec: null == balanceStaleAfterSec ? _self.balanceStaleAfterSec : balanceStaleAfterSec // ignore: cast_nullable_to_non_nullable
as int,balanceResumeSyncThrottleSec: null == balanceResumeSyncThrottleSec ? _self.balanceResumeSyncThrottleSec : balanceResumeSyncThrottleSec // ignore: cast_nullable_to_non_nullable
as int,reviewPromptAfterPositiveReadings: null == reviewPromptAfterPositiveReadings ? _self.reviewPromptAfterPositiveReadings : reviewPromptAfterPositiveReadings // ignore: cast_nullable_to_non_nullable
as int,legalTermsUrl: null == legalTermsUrl ? _self.legalTermsUrl : legalTermsUrl // ignore: cast_nullable_to_non_nullable
as String,legalPrivacyUrl: null == legalPrivacyUrl ? _self.legalPrivacyUrl : legalPrivacyUrl // ignore: cast_nullable_to_non_nullable
as String,supportEmail: null == supportEmail ? _self.supportEmail : supportEmail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
