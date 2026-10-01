import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/monetization/taro_products.dart';
import 'package:taro_core/src/result/ids.dart';

part 'remote_config.freezed.dart';

/// Called with the config key (e.g. `rewarded.dailyCap`) whenever a present
/// value was out of range, of the wrong type or partly unknown and was
/// clamped or replaced; the caller logs `config_value_clamped` (03 §8.1).
typedef ConfigClampedHook = void Function(String key);

/// The only screens that may show a banner (RC18, MO11, GLOSSARY §10).
/// Not remote-configurable: `ads.bannerScreens` can only narrow it.
const Set<String> kBannerAllowList = {'home', 'journal_list', 'learn_library'};

/// [kBannerAllowList] as the `ads.bannerScreens` default.
const List<String> _bannerAllowList = [...kBannerAllowList];

/// `config_value_clamped.key`: the remote-config keys the client reads
/// (03 §8.2), the single list `RemoteConfig.fromJson` reads them from.
/// Unknown keys map to [other].
enum ConfigKey {
  /// `readings.enabled`.
  readingsEnabled('readings.enabled'),

  /// `readings.freeDaily`.
  readingsFreeDaily('readings.freeDaily'),

  /// `readings.maxPerInstallPerDay`.
  readingsMaxPerInstallPerDay('readings.maxPerInstallPerDay'),

  /// `readings.tzCooldownHours`.
  readingsTzCooldownHours('readings.tzCooldownHours'),

  /// `spreads.enabled`.
  spreadsEnabled('spreads.enabled'),

  /// `rewarded.enabled`.
  rewardedEnabled('rewarded.enabled'),

  /// `rewarded.amount`.
  rewardedAmount('rewarded.amount'),

  /// `rewarded.dailyCap`.
  rewardedDailyCap('rewarded.dailyCap'),

  /// `rewarded.cooldownSec`.
  rewardedCooldownSec('rewarded.cooldownSec'),

  /// `rewarded.intentTtlSec`.
  rewardedIntentTtlSec('rewarded.intentTtlSec'),

  /// `rewarded.loadTimeoutSec`.
  rewardedLoadTimeoutSec('rewarded.loadTimeoutSec'),

  /// `rewarded.grantPollTimeoutSec`.
  rewardedGrantPollTimeoutSec('rewarded.grantPollTimeoutSec'),

  /// `ads.enabled`.
  adsEnabled('ads.enabled'),

  /// `ads.bannerEnabled`.
  adsBannerEnabled('ads.bannerEnabled'),

  /// `ads.bannerScreens`.
  adsBannerScreens('ads.bannerScreens'),

  /// `ads.bannerMinCompletedReadings`.
  adsBannerMinCompletedReadings('ads.bannerMinCompletedReadings'),

  /// `ads.attPrepromptEnabled`.
  adsAttPrepromptEnabled('ads.attPrepromptEnabled'),

  /// `store.enabled`.
  storeEnabled('store.enabled'),

  /// `store.packs`.
  storePacks('store.packs'),

  /// `store.verifyRetryWindowHours`.
  storeVerifyRetryWindowHours('store.verifyRetryWindowHours'),

  /// `store.pendingHoldMinutes`.
  storePendingHoldMinutes('store.pendingHoldMinutes'),

  /// `store.removeAdsEnabled`.
  storeRemoveAdsEnabled('store.removeAdsEnabled'),

  /// `store.showBestValueBadge`.
  storeShowBestValueBadge('store.showBestValueBadge'),

  /// `store.showPerReadingPrice`.
  storeShowPerReadingPrice('store.showPerReadingPrice'),

  /// `ai.consentVersion`.
  aiConsentVersion('ai.consentVersion'),

  /// `ai.questionMaxChars`.
  aiQuestionMaxChars('ai.questionMaxChars'),

  /// `balance.resumeSyncThrottleSec`.
  balanceResumeSyncThrottleSec('balance.resumeSyncThrottleSec'),

  /// `balance.staleAfterSec`.
  balanceStaleAfterSec('balance.staleAfterSec'),

  /// `review.promptAfterPositiveReadings`.
  reviewPromptAfterPositiveReadings('review.promptAfterPositiveReadings'),

  /// `legal.privacyUrl`.
  legalPrivacyUrl('legal.privacyUrl'),

  /// `legal.termsUrl`.
  legalTermsUrl('legal.termsUrl'),

  /// `support.email`.
  supportEmail('support.email'),

  /// Any other key.
  other('other');

  const ConfigKey(this.wire);

  /// The config key, also the analytics wire value.
  final String wire;

  /// The value for a config [key]; [other] if it is not listed.
  static ConfigKey fromKey(String key) {
    for (final k in values) {
      if (k.wire == key) return k;
    }
    return other;
  }
}

/// One `store.packs[]` entry (03 §8.2, 04 §13).
@freezed
abstract class StorePack with _$StorePack {
  /// Creates a pack entry.
  const factory StorePack({
    /// A consumable of `TaroProducts`.
    required ProductId productId,

    /// Display order, 0–9.
    required int sortOrder,

    /// Whether the pack is shown.
    @Default(true) bool enabled,

    /// Readings in the pack, injected read-only by the Worker from
    /// `PRODUCT_CATALOG` (RC3); `null` in the compiled defaults.
    int? credits,
  }) = _StorePack;
}

/// The default `store.packs` (04 §13).
const List<StorePack> _defaultPacks = [
  StorePack(
    productId: ProductId('com.vshyrochuk.taro.readings_3'),
    sortOrder: 0,
  ),
  StorePack(
    productId: ProductId('com.vshyrochuk.taro.readings_10'),
    sortOrder: 1,
  ),
  StorePack(
    productId: ProductId('com.vshyrochuk.taro.readings_30'),
    sortOrder: 2,
  ),
];

/// Typed view of the public remote config (`PublicConfigDto`, 03 §8.2,
/// 02 §9.4; RC8). Every field defaults to the compiled default, so
/// `RemoteConfig()` is [RemoteConfig.defaults].
///
/// Values the Worker enforces are only mirrored here for UI.
@Freezed(fromJson: false, toJson: false)
abstract class RemoteConfig with _$RemoteConfig {
  /// Creates a config; omitted fields take their defaults.
  const factory RemoteConfig({
    /// Config document `version` (0 = compiled defaults).
    @Default(0) int version,

    /// When the document was fetched; `null` for the defaults.
    DateTime? fetchedAt,

    /// `readings.enabled`: the only reading kill switch.
    @Default(true) bool readingsEnabled,

    /// `readings.freeDaily`, 1–5.
    @Default(1) int readingsFreeDaily,

    /// `readings.maxPerInstallPerDay`, 5–100.
    @Default(30) int readingsMaxPerInstallPerDay,

    /// `readings.tzCooldownHours`, 12–168.
    @Default(24) int readingsTzCooldownHours,

    /// `spreads.enabled`, a subset of the six spread IDs.
    @Default(kSpreadIds) List<SpreadId> spreadsEnabled,

    /// `rewarded.enabled`.
    @Default(true) bool rewardedEnabled,

    /// `rewarded.amount`, 1–2.
    @Default(1) int rewardedAmount,

    /// `rewarded.dailyCap`, 0–10 (0 = disabled).
    @Default(3) int rewardedDailyCap,

    /// `rewarded.cooldownSec`, 0–3600.
    @Default(300) int rewardedCooldownSec,

    /// `rewarded.intentTtlSec`, 300–3600.
    @Default(900) int rewardedIntentTtlSec,

    /// `rewarded.loadTimeoutSec`, 5–30.
    @Default(10) int rewardedLoadTimeoutSec,

    /// `rewarded.grantPollTimeoutSec`, 5–60.
    @Default(20) int rewardedGrantPollTimeoutSec,

    /// `ads.enabled`: global ads kill switch (also hides rewarded).
    @Default(true) bool adsEnabled,

    /// `ads.bannerEnabled`.
    @Default(true) bool adsBannerEnabled,

    /// `ads.bannerScreens`, a subset of `kBannerAllowList`.
    @Default(_bannerAllowList) List<String> adsBannerScreens,

    /// `ads.bannerMinCompletedReadings`, 0–10.
    @Default(1) int adsBannerMinCompletedReadings,

    /// `ads.attPrepromptEnabled`.
    @Default(true) bool adsAttPrepromptEnabled,

    /// `store.enabled`.
    @Default(true) bool storeEnabled,

    /// `store.packs`, 1–4 consumables.
    @Default(_defaultPacks) List<StorePack> storePacks,

    /// `store.verifyRetryWindowHours`, 24–168.
    @Default(72) int storeVerifyRetryWindowHours,

    /// `store.pendingHoldMinutes`, 5–240.
    @Default(30) int storePendingHoldMinutes,

    /// `store.removeAdsEnabled`.
    @Default(true) bool storeRemoveAdsEnabled,

    /// `store.showBestValueBadge`.
    @Default(true) bool storeShowBestValueBadge,

    /// `store.showPerReadingPrice`.
    @Default(true) bool storeShowPerReadingPrice,

    /// `ai.consentVersion` (2 since the OpenAI-only consent copy, RC97).
    @Default(2) int aiConsentVersion,

    /// `ai.questionMaxChars` (grapheme clusters, RC45).
    @Default(300) int aiQuestionMaxChars,

    /// `app.minVersion.ios`.
    @Default('1.0.0') String appMinVersionIos,

    /// `app.minVersion.android`.
    @Default('1.0.0') String appMinVersionAndroid,

    /// `app.recommendedVersion.ios`.
    @Default('1.0.0') String appRecommendedVersionIos,

    /// `app.recommendedVersion.android`.
    @Default('1.0.0') String appRecommendedVersionAndroid,

    /// `balance.staleAfterSec`, 30–3600.
    @Default(300) int balanceStaleAfterSec,

    /// `balance.resumeSyncThrottleSec`, 0–600.
    @Default(30) int balanceResumeSyncThrottleSec,

    /// `review.promptAfterPositiveReadings`, 1–20.
    @Default(3) int reviewPromptAfterPositiveReadings,

    /// `legal.termsUrl`.
    @Default('https://taro.vshyrochuk.com/terms') String legalTermsUrl,

    /// `legal.privacyUrl`.
    @Default('https://taro.vshyrochuk.com/privacy') String legalPrivacyUrl,

    /// `support.email`.
    @Default('volodymyr.shyrochuk@gmail.com') String supportEmail,
  }) = _RemoteConfig;

  const RemoteConfig._();

  /// Parses a `PublicConfigDto` document. Keys may be flat
  /// (`"rewarded.dailyCap": 3`) or nested (`{"rewarded": {"dailyCap": 3}}`).
  ///
  /// Never throws: unknown keys are ignored, missing keys take the default,
  /// out-of-range values are clamped to the 03 §8.2 ranges, and wrongly
  /// typed values take the default. [onClamped] is called once per key that
  /// was clamped or replaced.
  factory RemoteConfig.fromJson(
    Map<String, Object?> json, {
    DateTime? fetchedAt,
    ConfigClampedHook? onClamped,
  }) {
    final r = _Reader(json, onClamped ?? (_) {});
    const d = defaults;
    return RemoteConfig(
      version: r.integer('version', d.version),
      fetchedAt: fetchedAt,
      readingsEnabled: r.boolean(
        ConfigKey.readingsEnabled.wire,
        fallback: d.readingsEnabled,
      ),
      readingsFreeDaily: r.integer(
        ConfigKey.readingsFreeDaily.wire,
        d.readingsFreeDaily,
        1,
        5,
      ),
      readingsMaxPerInstallPerDay: r.integer(
        ConfigKey.readingsMaxPerInstallPerDay.wire,
        d.readingsMaxPerInstallPerDay,
        5,
        100,
      ),
      readingsTzCooldownHours: r.integer(
        ConfigKey.readingsTzCooldownHours.wire,
        d.readingsTzCooldownHours,
        12,
        168,
      ),
      spreadsEnabled: r
          .subset(
            ConfigKey.spreadsEnabled.wire,
            [
              for (final s in kSpreadIds) s.value,
            ],
            d.spreadsEnabled.map((s) => s.value).toList(),
          )
          .map(SpreadId.new)
          .toList(growable: false),
      rewardedEnabled: r.boolean(
        ConfigKey.rewardedEnabled.wire,
        fallback: d.rewardedEnabled,
      ),
      rewardedAmount: r.integer(
        ConfigKey.rewardedAmount.wire,
        d.rewardedAmount,
        1,
        2,
      ),
      rewardedDailyCap: r.integer(
        ConfigKey.rewardedDailyCap.wire,
        d.rewardedDailyCap,
        0,
        10,
      ),
      rewardedCooldownSec: r.integer(
        ConfigKey.rewardedCooldownSec.wire,
        d.rewardedCooldownSec,
        0,
        3600,
      ),
      rewardedIntentTtlSec: r.integer(
        ConfigKey.rewardedIntentTtlSec.wire,
        d.rewardedIntentTtlSec,
        300,
        3600,
      ),
      rewardedLoadTimeoutSec: r.integer(
        ConfigKey.rewardedLoadTimeoutSec.wire,
        d.rewardedLoadTimeoutSec,
        5,
        30,
      ),
      rewardedGrantPollTimeoutSec: r.integer(
        ConfigKey.rewardedGrantPollTimeoutSec.wire,
        d.rewardedGrantPollTimeoutSec,
        5,
        60,
      ),
      adsEnabled: r.boolean(ConfigKey.adsEnabled.wire, fallback: d.adsEnabled),
      adsBannerEnabled: r.boolean(
        ConfigKey.adsBannerEnabled.wire,
        fallback: d.adsBannerEnabled,
      ),
      adsBannerScreens: r.subset(
        ConfigKey.adsBannerScreens.wire,
        _bannerAllowList,
        d.adsBannerScreens,
      ),
      adsBannerMinCompletedReadings: r.integer(
        ConfigKey.adsBannerMinCompletedReadings.wire,
        d.adsBannerMinCompletedReadings,
        0,
        10,
      ),
      adsAttPrepromptEnabled: r.boolean(
        ConfigKey.adsAttPrepromptEnabled.wire,
        fallback: d.adsAttPrepromptEnabled,
      ),
      storeEnabled: r.boolean(
        ConfigKey.storeEnabled.wire,
        fallback: d.storeEnabled,
      ),
      storePacks: r.packs(ConfigKey.storePacks.wire, d.storePacks),
      storeVerifyRetryWindowHours: r.integer(
        ConfigKey.storeVerifyRetryWindowHours.wire,
        d.storeVerifyRetryWindowHours,
        24,
        168,
      ),
      storePendingHoldMinutes: r.integer(
        ConfigKey.storePendingHoldMinutes.wire,
        d.storePendingHoldMinutes,
        5,
        240,
      ),
      storeRemoveAdsEnabled: r.boolean(
        ConfigKey.storeRemoveAdsEnabled.wire,
        fallback: d.storeRemoveAdsEnabled,
      ),
      storeShowBestValueBadge: r.boolean(
        ConfigKey.storeShowBestValueBadge.wire,
        fallback: d.storeShowBestValueBadge,
      ),
      storeShowPerReadingPrice: r.boolean(
        ConfigKey.storeShowPerReadingPrice.wire,
        fallback: d.storeShowPerReadingPrice,
      ),
      aiConsentVersion: r.integer(
        ConfigKey.aiConsentVersion.wire,
        d.aiConsentVersion,
      ),
      aiQuestionMaxChars: r.integer(
        ConfigKey.aiQuestionMaxChars.wire,
        d.aiQuestionMaxChars,
      ),
      appMinVersionIos: r.string('app.minVersion.ios', d.appMinVersionIos),
      appMinVersionAndroid: r.string(
        'app.minVersion.android',
        d.appMinVersionAndroid,
      ),
      appRecommendedVersionIos: r.string(
        'app.recommendedVersion.ios',
        d.appRecommendedVersionIos,
      ),
      appRecommendedVersionAndroid: r.string(
        'app.recommendedVersion.android',
        d.appRecommendedVersionAndroid,
      ),
      balanceStaleAfterSec: r.integer(
        ConfigKey.balanceStaleAfterSec.wire,
        d.balanceStaleAfterSec,
        30,
        3600,
      ),
      balanceResumeSyncThrottleSec: r.integer(
        ConfigKey.balanceResumeSyncThrottleSec.wire,
        d.balanceResumeSyncThrottleSec,
        0,
        600,
      ),
      reviewPromptAfterPositiveReadings: r.integer(
        ConfigKey.reviewPromptAfterPositiveReadings.wire,
        d.reviewPromptAfterPositiveReadings,
        1,
        20,
      ),
      legalTermsUrl: r.string(ConfigKey.legalTermsUrl.wire, d.legalTermsUrl),
      legalPrivacyUrl: r.string(
        ConfigKey.legalPrivacyUrl.wire,
        d.legalPrivacyUrl,
      ),
      supportEmail: r.string(ConfigKey.supportEmail.wire, d.supportEmail),
    );
  }

  /// The compiled defaults (03 §8.2).
  static const RemoteConfig defaults = RemoteConfig();

  /// Whether [id] is in `spreads.enabled`.
  bool isSpreadEnabled(SpreadId id) => spreadsEnabled.contains(id);

  /// Enabled packs in `sortOrder`.
  List<StorePack> get enabledPacks => [
    for (final p in storePacks)
      if (p.enabled) p,
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// `balance.staleAfterSec` as a [Duration].
  Duration get balanceStaleAfter => Duration(seconds: balanceStaleAfterSec);

  /// `balance.resumeSyncThrottleSec` as a [Duration].
  Duration get balanceResumeSyncThrottle =>
      Duration(seconds: balanceResumeSyncThrottleSec);

  /// `rewarded.loadTimeoutSec` as a [Duration].
  Duration get rewardedLoadTimeout => Duration(seconds: rewardedLoadTimeoutSec);

  /// `rewarded.grantPollTimeoutSec` as a [Duration].
  Duration get rewardedGrantPollTimeout =>
      Duration(seconds: rewardedGrantPollTimeoutSec);
}

/// Reads typed, clamped values out of a config document.
final class _Reader {
  _Reader(this._json, this._onClamped);

  final Map<String, Object?> _json;
  final ConfigClampedHook _onClamped;

  static const Object _absent = Object();

  /// The value at the flat key, else at the nested path; [_absent] if none.
  Object? _lookup(String key) {
    if (_json.containsKey(key)) return _json[key];
    Object? node = _json;
    for (final segment in key.split('.')) {
      if (node is! Map<String, Object?> || !node.containsKey(segment)) {
        return _absent;
      }
      node = node[segment];
    }
    return node;
  }

  T _replaced<T>(String key, T fallback) {
    _onClamped(key);
    return fallback;
  }

  bool boolean(String key, {required bool fallback}) {
    final value = _lookup(key);
    if (identical(value, _absent)) return fallback;
    return value is bool ? value : _replaced(key, fallback);
  }

  String string(String key, String fallback) {
    final value = _lookup(key);
    if (identical(value, _absent)) return fallback;
    return value is String ? value : _replaced(key, fallback);
  }

  int integer(String key, int fallback, [int? min, int? max]) {
    final value = _lookup(key);
    if (identical(value, _absent)) return fallback;
    if (value is! num || !value.isFinite || value != value.truncate()) {
      return _replaced(key, fallback);
    }
    final raw = value.toInt();
    final clamped = raw.clamp(min ?? raw, max ?? raw);
    return clamped == raw ? raw : _replaced(key, clamped);
  }

  /// A string list restricted to [allowed]; unknown entries are dropped.
  List<String> subset(String key, List<String> allowed, List<String> fallback) {
    final value = _lookup(key);
    if (identical(value, _absent)) return fallback;
    if (value is! List<Object?>) return _replaced(key, fallback);
    final kept = <String>[];
    for (final item in value) {
      if (item is String && allowed.contains(item) && !kept.contains(item)) {
        kept.add(item);
      }
    }
    if (kept.length != value.length) _onClamped(key);
    return List.unmodifiable(kept);
  }

  /// `store.packs`: distinct consumables only (so at most three, within the
  /// 1–4 range), sortOrder clamped to 0–9; an empty result falls back to the
  /// defaults.
  List<StorePack> packs(String key, List<StorePack> fallback) {
    final value = _lookup(key);
    if (identical(value, _absent)) return fallback;
    if (value is! List<Object?>) return _replaced(key, fallback);
    final consumables = {
      for (final p in TaroProducts.consumables) p.id.value,
    };
    final packs = <StorePack>[];
    var clamped = false;
    for (final item in value) {
      final pack = item is Map<String, Object?> ? _pack(item) : null;
      if (pack == null ||
          !consumables.contains(pack.$1.productId.value) ||
          packs.any((p) => p.productId == pack.$1.productId)) {
        clamped = true;
        continue;
      }
      clamped = clamped || pack.$2;
      packs.add(pack.$1);
    }
    if (packs.isEmpty) return _replaced(key, fallback);
    if (clamped) _onClamped(key);
    return List.unmodifiable(packs);
  }

  /// One pack and whether its `sortOrder` was clamped; `null` if malformed.
  (StorePack, bool)? _pack(Map<String, Object?> json) {
    final id = json['productId'];
    final enabled = json['enabled'] ?? true;
    final sortOrder = json['sortOrder'] ?? 0;
    final credits = json['credits'];
    if (id is! String ||
        enabled is! bool ||
        sortOrder is! int ||
        (credits != null && credits is! int)) {
      return null;
    }
    final order = sortOrder.clamp(0, 9);
    return (
      StorePack(
        productId: ProductId(id),
        sortOrder: order,
        enabled: enabled,
        credits: credits as int?,
      ),
      order != sortOrder,
    );
  }
}
