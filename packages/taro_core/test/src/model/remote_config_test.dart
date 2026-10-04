import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// Every clamped int key with its 03 §8.2 range and field accessor.
final Map<String, (int, int, int Function(RemoteConfig))> ranges = {
  'readings.freeDaily': (1, 5, (c) => c.readingsFreeDaily),
  'readings.maxPerInstallPerDay': (
    5,
    100,
    (c) => c.readingsMaxPerInstallPerDay,
  ),
  'readings.tzCooldownHours': (12, 168, (c) => c.readingsTzCooldownHours),
  'rewarded.amount': (1, 2, (c) => c.rewardedAmount),
  'rewarded.dailyCap': (0, 10, (c) => c.rewardedDailyCap),
  'rewarded.cooldownSec': (0, 3600, (c) => c.rewardedCooldownSec),
  'rewarded.intentTtlSec': (300, 3600, (c) => c.rewardedIntentTtlSec),
  'rewarded.loadTimeoutSec': (5, 30, (c) => c.rewardedLoadTimeoutSec),
  'rewarded.grantPollTimeoutSec': (5, 60, (c) => c.rewardedGrantPollTimeoutSec),
  'ads.bannerMinCompletedReadings': (
    0,
    10,
    (c) => c.adsBannerMinCompletedReadings,
  ),
  'store.verifyRetryWindowHours': (
    24,
    168,
    (c) => c.storeVerifyRetryWindowHours,
  ),
  'store.pendingHoldMinutes': (5, 240, (c) => c.storePendingHoldMinutes),
  'balance.staleAfterSec': (30, 3600, (c) => c.balanceStaleAfterSec),
  'balance.resumeSyncThrottleSec': (
    0,
    600,
    (c) => c.balanceResumeSyncThrottleSec,
  ),
  'review.promptAfterPositiveReadings': (
    1,
    20,
    (c) => c.reviewPromptAfterPositiveReadings,
  ),
};

(RemoteConfig, List<String>) parse(Map<String, Object?> json) {
  final clamped = <String>[];
  final config = RemoteConfig.fromJson(json, onClamped: clamped.add);
  return (config, clamped);
}

void main() {
  group('defaults (03 §8.2)', () {
    test('RemoteConfig() equals defaults and matches the spec', () {
      const d = RemoteConfig.defaults;
      expect(RemoteConfig.fromJson(const {}), d);
      expect(d.version, 0);
      expect(d.fetchedAt, isNull);
      expect(d.readingsEnabled, isTrue);
      expect(d.readingsFreeDaily, 1);
      expect(d.readingsMaxPerInstallPerDay, 30);
      expect(d.readingsTzCooldownHours, 24);
      expect(d.spreadsEnabled, kSpreadIds);
      expect(d.rewardedEnabled, isTrue);
      expect(d.rewardedAmount, 1);
      expect(d.rewardedDailyCap, 3);
      expect(d.rewardedCooldownSec, 300);
      expect(d.rewardedIntentTtlSec, 900);
      expect(d.rewardedLoadTimeoutSec, 10);
      expect(d.rewardedGrantPollTimeoutSec, 20);
      expect(d.adsEnabled, isTrue);
      expect(d.adsBannerEnabled, isTrue);
      expect(d.adsBannerScreens, ['home', 'journal_list', 'learn_library']);
      expect(d.adsBannerMinCompletedReadings, 1);
      expect(d.adsAttPrepromptEnabled, isTrue);
      expect(d.storeEnabled, isTrue);
      expect(d.storePacks.map((p) => (p.productId.value, p.sortOrder)), [
        ('com.vshyrochuk.taro.readings_3', 0),
        ('com.vshyrochuk.taro.readings_10', 1),
        ('com.vshyrochuk.taro.readings_30', 2),
      ]);
      expect(d.storePacks.every((p) => p.enabled && p.credits == null), isTrue);
      expect(d.storeVerifyRetryWindowHours, 72);
      expect(d.storePendingHoldMinutes, 30);
      expect(d.storeRemoveAdsEnabled, isTrue);
      expect(d.storeShowBestValueBadge, isTrue);
      expect(d.storeShowPerReadingPrice, isTrue);
      expect(d.aiConsentVersion, 2);
      expect(d.aiQuestionMaxChars, 300);
      expect(d.appMinVersionIos, '0.0.0');
      expect(d.appMinVersionAndroid, '0.0.0');
      expect(d.appRecommendedVersionIos, '0.0.0');
      expect(d.appRecommendedVersionAndroid, '0.0.0');
      expect(d.balanceStaleAfterSec, 300);
      expect(d.balanceResumeSyncThrottleSec, 30);
      expect(d.reviewPromptAfterPositiveReadings, 3);
      expect(d.legalTermsUrl, 'https://taro.vshyrochuk.com/terms');
      expect(d.legalPrivacyUrl, 'https://taro.vshyrochuk.com/privacy');
      expect(d.supportEmail, 'volodymyr.shyrochuk@gmail.com');
    });

    test('an empty document is the defaults, nothing clamped', () {
      final (config, clamped) = parse({});
      expect(config, RemoteConfig.defaults);
      expect(clamped, isEmpty);
    });

    test('durations and helpers', () {
      const d = RemoteConfig.defaults;
      expect(d.balanceStaleAfter, const Duration(minutes: 5));
      expect(d.balanceResumeSyncThrottle, const Duration(seconds: 30));
      expect(d.rewardedLoadTimeout, const Duration(seconds: 10));
      expect(d.rewardedGrantPollTimeout, const Duration(seconds: 20));
      expect(d.isSpreadEnabled(const SpreadId('celtic_cross')), isTrue);
      expect(d.isSpreadEnabled(const SpreadId('daily')), isFalse);
      expect(d.enabledPacks, hasLength(3));
    });
  });

  group('parsing', () {
    test('reads flat and nested keys', () {
      final fetchedAt = DateTime.utc(2026, 9, 26);
      final flat = RemoteConfig.fromJson({
        'version': 7,
        'readings.enabled': false,
        'app.minVersion.ios': '1.2.0',
        'support.email': 'help@example.com',
      }, fetchedAt: fetchedAt);
      final nested = RemoteConfig.fromJson({
        'version': 7,
        'readings': {'enabled': false},
        'app': {
          'minVersion': {'ios': '1.2.0'},
        },
        'support': {'email': 'help@example.com'},
      }, fetchedAt: fetchedAt);
      expect(flat, nested);
      expect(flat.version, 7);
      expect(flat.fetchedAt, fetchedAt);
      expect(flat.readingsEnabled, isFalse);
      expect(flat.appMinVersionIos, '1.2.0');
      expect(flat.supportEmail, 'help@example.com');
    });

    test('ignores unknown keys and partial nested paths', () {
      final (config, clamped) = parse({
        'unknown.key': 1,
        'ai.model.paid': 'server-only',
        'app': {'minVersion': 'not-a-map'},
      });
      expect(config, RemoteConfig.defaults);
      expect(clamped, isEmpty);
    });

    test('in-range values pass through unclamped', () {
      final (config, clamped) = parse({
        for (final e in ranges.entries) e.key: e.value.$2,
        'ai.consentVersion': 4,
        'ai.questionMaxChars': 250,
      });
      for (final e in ranges.entries) {
        expect(e.value.$3(config), e.value.$2, reason: e.key);
      }
      expect(config.aiConsentVersion, 4);
      expect(config.aiQuestionMaxChars, 250);
      expect(clamped, isEmpty);
    });

    for (final e in ranges.entries) {
      test('clamps ${e.key} to ${e.value.$1}–${e.value.$2}', () {
        final (low, lowClamped) = parse({e.key: e.value.$1 - 1});
        expect(e.value.$3(low), e.value.$1);
        expect(lowClamped, [e.key]);
        final (high, highClamped) = parse({e.key: e.value.$2 + 1000});
        expect(e.value.$3(high), e.value.$2);
        expect(highClamped, [e.key]);
      });
    }

    test('accepts integral doubles, rejects fractions and wrong types', () {
      final (config, clamped) = parse({
        'rewarded.dailyCap': 5.0,
        'rewarded.amount': 1.5,
        'readings.freeDaily': 'two',
        'readings.enabled': 'false',
        'legal.termsUrl': 42,
      });
      expect(config.rewardedDailyCap, 5);
      expect(config.rewardedAmount, 1);
      expect(config.readingsFreeDaily, 1);
      expect(config.readingsEnabled, isTrue);
      expect(config.legalTermsUrl, 'https://taro.vshyrochuk.com/terms');
      expect(clamped, [
        'readings.enabled',
        'readings.freeDaily',
        'rewarded.amount',
        'legal.termsUrl',
      ]);
    });

    test('never throws on a hostile document', () {
      expect(
        () => RemoteConfig.fromJson({
          'version': double.nan,
          'spreads.enabled': null,
          'store.packs': 'all',
        }),
        returnsNormally,
      );
    });
  });

  group('list keys', () {
    test('spreads.enabled keeps known IDs only', () {
      final (config, clamped) = parse({
        'spreads.enabled': ['single', 'daily', 'celtic_cross', 'single', 3],
      });
      expect(config.spreadsEnabled, const [
        SpreadId('single'),
        SpreadId('celtic_cross'),
      ]);
      expect(clamped, ['spreads.enabled']);
      final (valid, none) = parse({
        'spreads.enabled': ['three_ppf'],
      });
      expect(valid.spreadsEnabled, const [SpreadId('three_ppf')]);
      expect(none, isEmpty);
      final (empty, _) = parse({'spreads.enabled': <String>[]});
      expect(empty.spreadsEnabled, isEmpty);
    });

    test('ads.bannerScreens is clamped to kBannerAllowList (RC18)', () {
      final (config, clamped) = parse({
        'ads.bannerScreens': ['home', 'reading_result', 'journal_list'],
      });
      expect(config.adsBannerScreens, ['home', 'journal_list']);
      expect(clamped, ['ads.bannerScreens']);
      final (wrong, wrongClamped) = parse({'ads.bannerScreens': 'home'});
      expect(wrong.adsBannerScreens, RemoteConfig.defaults.adsBannerScreens);
      expect(wrongClamped, ['ads.bannerScreens']);
    });

    test('store.packs parses credits and sort order', () {
      final (config, clamped) = parse({
        'store': {
          'packs': [
            {
              'productId': 'com.vshyrochuk.taro.readings_30',
              'enabled': true,
              'sortOrder': 0,
              'credits': 30,
            },
            {
              'productId': 'com.vshyrochuk.taro.readings_3',
              'enabled': false,
              'sortOrder': 1,
              'credits': 3,
            },
            {'productId': 'com.vshyrochuk.taro.readings_10', 'credits': 10},
          ],
        },
      });
      expect(clamped, isEmpty);
      expect(config.storePacks, hasLength(3));
      expect(config.storePacks.first.credits, 30);
      expect(config.storePacks.last.sortOrder, 0);
      expect(config.storePacks.last.enabled, isTrue);
      expect(config.enabledPacks.map((p) => p.productId.value), [
        'com.vshyrochuk.taro.readings_30',
        'com.vshyrochuk.taro.readings_10',
      ]);
    });

    test('store.packs drops non-consumables, unknown, duplicate and bad '
        'entries and clamps sortOrder', () {
      final (config, clamped) = parse({
        'store.packs': [
          {'productId': 'com.vshyrochuk.taro.remove_ads', 'sortOrder': 0},
          {'productId': 'com.example.other', 'sortOrder': 0},
          {'productId': 'com.vshyrochuk.taro.readings_3', 'sortOrder': 42},
          {'productId': 'com.vshyrochuk.taro.readings_3', 'sortOrder': 1},
          {'productId': 'com.vshyrochuk.taro.readings_10', 'enabled': 'yes'},
          {'productId': 'com.vshyrochuk.taro.readings_10', 'credits': '10'},
          {'productId': 'com.vshyrochuk.taro.readings_10', 'sortOrder': 1.5},
          'not a pack',
        ],
      });
      expect(config.storePacks, const [
        StorePack(
          productId: ProductId('com.vshyrochuk.taro.readings_3'),
          sortOrder: 9,
        ),
      ]);
      expect(clamped, ['store.packs']);
    });

    test('store.packs clamps a sortOrder alone', () {
      final (config, clamped) = parse({
        'store.packs': [
          {'productId': 'com.vshyrochuk.taro.readings_3', 'sortOrder': -1},
        ],
      });
      expect(config.storePacks.single.sortOrder, 0);
      expect(clamped, ['store.packs']);
    });

    test('store.packs falls back to defaults when empty or not a list', () {
      for (final value in [<Object?>[], 'packs']) {
        final (config, clamped) = parse({'store.packs': value});
        expect(config.storePacks, RemoteConfig.defaults.storePacks);
        expect(clamped, ['store.packs']);
      }
    });

    test('store.packs accepts every consumable once', () {
      final (config, clamped) = parse({
        'store.packs': [
          for (final p in TaroProducts.consumables)
            {'productId': p.id.value, 'sortOrder': 0},
        ],
      });
      expect(config.storePacks, hasLength(3));
      expect(clamped, isEmpty);
    });
  });

  test('copyWith and StorePack equality', () {
    final changed = RemoteConfig.defaults.copyWith(rewardedEnabled: false);
    expect(changed.rewardedEnabled, isFalse);
    expect(changed, isNot(RemoteConfig.defaults));
    const pack = StorePack(productId: ProductId('p'), sortOrder: 1);
    expect(pack.copyWith(credits: 3), isNot(pack));
  });
}
