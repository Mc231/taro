import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  group('analyticsWire', () {
    test('uses AnalyticsEnum.wire', () {
      expect(analyticsWire(ReadingFlowSource.spreadsGuide), 'spreads_guide');
      expect(analyticsWire(OutOfReadingsSource.hold402), 'hold_402');
    });

    test('uses the wire of RefusalCategory and RatingReason', () {
      expect(
        analyticsWire(RefusalCategory.hateOrHarassment),
        'hate_or_harassment',
      );
      expect(analyticsWire(RatingReason.tooGeneric), 'too_generic');
    });

    test('snake_cases any other enum', () {
      expect(analyticsWire(ErrorKind.deviceUnverified), 'device_unverified');
      expect(analyticsWire(RewardUnavailableReason.noFill), 'no_fill');
      expect(analyticsWire(ChargeSource.bonus), 'bonus');
    });
  });

  test('ScreenId wire is the literal S-ID', () {
    expect(ScreenId.values, hasLength(33));
    expect(ScreenId.s01.wire, 'S01');
    expect(ScreenId.s33.wire, 'S33');
  });

  test('AnalyticsSpread matches kSpreadIds', () {
    for (final id in kSpreadIds) {
      expect(AnalyticsSpread.fromId(id).wire, id.value);
    }
    expect(
      AnalyticsSpread.fromId(const SpreadId('tarot_x')),
      AnalyticsSpread.unknown,
    );
    expect(AnalyticsSpread.values, hasLength(kSpreadIds.length + 1));
  });

  group('AnalyticsCardId', () {
    test('keeps valid IDs and maps others to unknown', () {
      expect(AnalyticsCardId.fromId(const CardId('wands_14')).wire, 'wands_14');
      expect(
        AnalyticsCardId.fromId(const CardId('wands_15')),
        AnalyticsCardId.unknown,
      );
    });

    test('value equality', () {
      final a = AnalyticsCardId.fromId(const CardId('major_00'));
      expect(a, AnalyticsCardId.fromId(const CardId('major_00')));
      expect(a.hashCode, 'major_00'.hashCode);
      expect(a, isNot(AnalyticsCardId.unknown));
      expect(a.toString(), 'AnalyticsCardId(major_00)');
    });
  });

  test('AnalyticsLocale covers kSupportedLocales', () {
    for (final tag in kSupportedLocales) {
      expect(AnalyticsLocale.fromTag(tag).wire, tag);
    }
    expect(AnalyticsLocale.fromTag('pt-BR'), AnalyticsLocale.pt);
    expect(AnalyticsLocale.fromTag('EN_us'), AnalyticsLocale.en);
    expect(AnalyticsLocale.fromTag('xx'), AnalyticsLocale.other);
    expect(AnalyticsLocale.fromTag('other'), AnalyticsLocale.other);
    expect(AnalyticsLocale.values, hasLength(kSupportedLocales.length + 1));
  });

  test('QuestionLengthBucket.fromLength', () {
    final cases = {
      0: '0',
      1: '1-50',
      50: '1-50',
      51: '51-150',
      150: '51-150',
      151: '151-300',
      400: '151-300',
    };
    for (final MapEntry(key: length, value: wire) in cases.entries) {
      expect(QuestionLengthBucket.fromLength(length).wire, wire);
    }
  });

  test('NoteLengthBucket.fromLength', () {
    final cases = {
      0: '0',
      100: '1-100',
      101: '101-500',
      500: '101-500',
      501: '501-2000',
      2000: '501-2000',
      2001: '2001+',
    };
    for (final MapEntry(key: length, value: wire) in cases.entries) {
      expect(NoteLengthBucket.fromLength(length).wire, wire);
    }
  });

  test('SearchResultsBucket.fromCount', () {
    expect(SearchResultsBucket.fromCount(0).wire, '0');
    expect(SearchResultsBucket.fromCount(5).wire, '1-5');
    expect(SearchResultsBucket.fromCount(6).wire, '6+');
  });

  test('EntriesBucket.fromCount', () {
    final cases = {
      -1: '0',
      1: '1-10',
      10: '1-10',
      11: '11-50',
      50: '11-50',
      51: '51-200',
      200: '51-200',
      201: '201+',
    };
    for (final MapEntry(key: count, value: wire) in cases.entries) {
      expect(EntriesBucket.fromCount(count).wire, wire);
    }
  });

  test('CreditType.fromChargeSource', () {
    expect(CreditType.fromChargeSource(ChargeSource.free), CreditType.free);
    expect(
      CreditType.fromChargeSource(ChargeSource.bonus),
      CreditType.rewarded,
    );
    expect(CreditType.fromChargeSource(ChargeSource.paid), CreditType.paid);
  });

  test('AnalyticsProduct.fromProduct uses the GLOSSARY §3 alias', () {
    expect(
      [for (final p in TaroProducts.all) AnalyticsProduct.fromProduct(p).wire],
      ['pack_s', 'pack_m', 'pack_l', 'remove_ads'],
    );
  });

  group('AnalyticsCurrency', () {
    test('wire is the upper-case ISO code', () {
      expect(AnalyticsCurrency.usd.wire, 'USD');
      expect(AnalyticsCurrency.tryLira.wire, 'TRY');
      expect(AnalyticsCurrency.other.wire, 'other');
      for (final c in AnalyticsCurrency.values) {
        if (c != AnalyticsCurrency.other) {
          expect(c.wire, matches(r'^[A-Z]{3}$'));
        }
      }
    });

    test('fromCode ignores case and maps unknown codes to other', () {
      expect(AnalyticsCurrency.fromCode('eur'), AnalyticsCurrency.eur);
      expect(AnalyticsCurrency.fromCode('TRY'), AnalyticsCurrency.tryLira);
      expect(AnalyticsCurrency.fromCode('XYZ'), AnalyticsCurrency.other);
    });
  });

  test('PurchaseErrorKind.fromFailure', () {
    final cases = {
      const Failure.purchase(wireCode: 'PURCHASE_INVALID'):
          PurchaseErrorKind.verifyRejected,
      const Failure.purchase(wireCode: 'PRODUCT_UNKNOWN'):
          PurchaseErrorKind.verifyRejected,
      const Failure.purchase(wireCode: 'storekit_error'):
          PurchaseErrorKind.storeError,
      const Failure.purchaseAlreadyClaimed(transferEligible: false):
          PurchaseErrorKind.alreadyClaimed,
      const Failure.purchasesBlocked(
        reason: PurchasesBlockedReason.refundDebt,
      ): PurchaseErrorKind.purchasesBlocked,
      const Failure.productUnavailable(): PurchaseErrorKind.productUnavailable,
      const Failure.network(): PurchaseErrorKind.network,
      const Failure.timeout(): PurchaseErrorKind.network,
      const Failure.storage(): PurchaseErrorKind.unknown,
    };
    for (final MapEntry(key: failure, value: kind) in cases.entries) {
      expect(PurchaseErrorKind.fromFailure(failure), kind, reason: '$failure');
    }
  });

  test('ConfigKey covers the keys RemoteConfig reads', () {
    expect(ConfigKey.fromKey('rewarded.dailyCap'), ConfigKey.rewardedDailyCap);
    expect(ConfigKey.fromKey('nope.key'), ConfigKey.other);
    expect(
      ConfigKey.values.map((k) => k.wire).toSet(),
      hasLength(ConfigKey.values.length),
    );

    final clamped = <String>[];
    RemoteConfig.fromJson(const {
      'rewarded.dailyCap': 999,
      'readings.freeDaily': -5,
      'ads.bannerScreens': ['nowhere'],
    }, onClamped: clamped.add);
    expect(clamped, isNotEmpty);
    for (final key in clamped) {
      expect(ConfigKey.fromKey(key), isNot(ConfigKey.other), reason: key);
    }
  });

  test('SettingValue wires', () {
    expect(
      [for (final v in SettingValue.values) v.wire],
      ['system', 'on', 'off'],
    );
  });
}
