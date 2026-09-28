// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this, avoid_positional_boolean_parameters

import 'package:taro_core/taro_core.dart';

/// `aRemoteConfig().withRewardedEnabled(false).build()`: the compiled
/// defaults with overrides.
RemoteConfigBuilder aRemoteConfig() => RemoteConfigBuilder();

/// Builds a [RemoteConfig].
final class RemoteConfigBuilder {
  RemoteConfig _config = RemoteConfig.defaults;

  RemoteConfigBuilder _with(RemoteConfig config) {
    _config = config;
    return this;
  }

  /// Document `version`.
  RemoteConfigBuilder withVersion(int version) =>
      _with(_config.copyWith(version: version));

  /// `readings.enabled` (kill switch).
  RemoteConfigBuilder withReadingsEnabled(bool enabled) =>
      _with(_config.copyWith(readingsEnabled: enabled));

  /// `spreads.enabled`.
  RemoteConfigBuilder withSpreadsEnabled(List<String> ids) => _with(
    _config.copyWith(spreadsEnabled: [for (final i in ids) SpreadId(i)]),
  );

  /// `rewarded.enabled`.
  RemoteConfigBuilder withRewardedEnabled(bool enabled) =>
      _with(_config.copyWith(rewardedEnabled: enabled));

  /// `rewarded.grantPollTimeoutSec`.
  RemoteConfigBuilder withGrantPollTimeoutSec(int seconds) =>
      _with(_config.copyWith(rewardedGrantPollTimeoutSec: seconds));

  /// `ads.enabled`.
  RemoteConfigBuilder withAdsEnabled(bool enabled) =>
      _with(_config.copyWith(adsEnabled: enabled));

  /// `ads.bannerEnabled`.
  RemoteConfigBuilder withBannerEnabled(bool enabled) =>
      _with(_config.copyWith(adsBannerEnabled: enabled));

  /// `store.enabled`.
  RemoteConfigBuilder withStoreEnabled(bool enabled) =>
      _with(_config.copyWith(storeEnabled: enabled));

  /// `store.removeAdsEnabled`.
  RemoteConfigBuilder withRemoveAdsEnabled(bool enabled) =>
      _with(_config.copyWith(storeRemoveAdsEnabled: enabled));

  /// `store.packs`.
  RemoteConfigBuilder withPacks(List<StorePack> packs) =>
      _with(_config.copyWith(storePacks: packs));

  /// `store.verifyRetryWindowHours`.
  RemoteConfigBuilder withVerifyRetryWindowHours(int hours) =>
      _with(_config.copyWith(storeVerifyRetryWindowHours: hours));

  /// `ai.consentVersion`.
  RemoteConfigBuilder withAiConsentVersion(int version) =>
      _with(_config.copyWith(aiConsentVersion: version));

  /// `ai.questionMaxChars`.
  RemoteConfigBuilder withQuestionMaxChars(int max) =>
      _with(_config.copyWith(aiQuestionMaxChars: max));

  /// `balance.staleAfterSec`.
  RemoteConfigBuilder withStaleAfterSec(int seconds) =>
      _with(_config.copyWith(balanceStaleAfterSec: seconds));

  /// `balance.resumeSyncThrottleSec`.
  RemoteConfigBuilder withResumeSyncThrottleSec(int seconds) =>
      _with(_config.copyWith(balanceResumeSyncThrottleSec: seconds));

  /// The config.
  RemoteConfig build() => _config;
}
