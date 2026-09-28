import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_matrix.dart';
import 'golden_sizes.dart';

void main() {
  group('goldenVariants', () {
    test('a plain golden gets both phones x light/dark x en/ar', () {
      final variants = goldenVariants();
      expect(variants, hasLength(8));
      expect(variants.where((v) => v.isTablet), isEmpty);
      expect(variants.map((v) => v.name), [
        'phone_small_light_en',
        'phone_small_light_ar',
        'phone_small_dark_en',
        'phone_small_dark_ar',
        'phone_large_light_en',
        'phone_large_light_ar',
        'phone_large_dark_en',
        'phone_large_dark_ar',
      ]);
    });

    test('a key screen adds en light and ar dark on every tablet', () {
      final tablets = goldenVariants(
        keyScreen: true,
      ).where((v) => v.isTablet).map((v) => v.name);
      expect(tablets, [
        'tablet_ipad13_light_en',
        'tablet_ipad13_dark_ar',
        'tablet_android_light_en',
        'tablet_android_dark_ar',
      ]);
    });

    test('extra locales and large text are light, per phone size', () {
      final names = goldenVariants(
        extraLocales: const [Locale('ja'), Locale('de')],
        largeText: true,
        phoneSizes: const [kPhoneSmall],
      ).map((v) => v.name);
      expect(
        names,
        containsAll(<String>[
          'phone_small_light_ja',
          'phone_small_light_de',
          'phone_small_light_en_x2',
        ]),
      );
      expect(names, hasLength(7));
    });

    test('size lists can be narrowed (the sample golden)', () {
      final variants = goldenVariants(
        keyScreen: true,
        phoneSizes: const [kPhoneSmall],
        tabletSizes: const [kTabletIpad13],
      );
      expect(variants, hasLength(6));
    });
  });

  group('GoldenVariant', () {
    const ar = GoldenVariant(
      size: kPhoneLarge,
      themeMode: ThemeMode.dark,
      locale: Locale('ar'),
    );

    test('derives direction from the locale', () {
      expect(ar.textDirection, TextDirection.rtl);
      expect(
        const GoldenVariant(
          size: kPhoneSmall,
          themeMode: ThemeMode.light,
          locale: Locale('ja'),
        ).textDirection,
        TextDirection.ltr,
      );
    });

    test('names fractional scales and unknown sizes', () {
      const odd = GoldenVariant(
        size: Size(320, 480),
        themeMode: ThemeMode.light,
        locale: Locale('pt', 'BR'),
        textScale: 1.3,
      );
      expect(odd.name, '320x480_light_pt-BR_x1.3');
      expect(
        goldenPath('s09', odd),
        'goldens/s09/320x480_light_pt-BR_x1.3.png',
      );
    });

    test('has value equality', () {
      const same = GoldenVariant(
        size: kPhoneLarge,
        themeMode: ThemeMode.dark,
        locale: Locale('ar'),
      );
      expect(same, ar);
      expect(same.hashCode, ar.hashCode);
      expect(ar.toString(), 'GoldenVariant(phone_large_dark_ar)');
    });
  });

  group('golden sizes', () {
    test('match 06 §3', () {
      expect(kPhoneSmall, const Size(375, 667));
      expect(kPhoneLarge, const Size(430, 932));
      expect(kTabletIpad13, const Size(1032, 1376));
      expect(kTabletAndroid, const Size(800, 1280));
      expect(kPhoneSizes.every(isTabletSize), isFalse);
      expect(kTabletSizes.every(isTabletSize), isTrue);
    });

    testWidgets('applyTestViewSize sets logical size at dpr 1', (
      tester,
    ) async {
      applyTestViewSize(tester, kTabletAndroid);
      expect(tester.view.physicalSize, kTabletAndroid);
      expect(tester.view.devicePixelRatio, 1);
    });
  });
}
