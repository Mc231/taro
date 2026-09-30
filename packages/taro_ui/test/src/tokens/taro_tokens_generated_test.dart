import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('the generated file carries all 166 01 §14 names and both modes', () {
    expect(kTaroTokenNames, hasLength(166));
    expect(kTaroTokenNames.toSet(), hasLength(166));
    expect(kTaroTokenModes, ['light', 'dark']);
    for (final group in [
      'color.',
      'type.',
      'font.family.',
      'space.',
      'radius.',
      'size.',
      'layout.',
      'opacity.',
      'elevation.',
      'motion.',
      'haptic.',
    ]) {
      expect(kTaroTokenNames.any((n) => n.startsWith(group)), isTrue);
    }
  });

  test('colours differ per mode; invariant groups are shared', () {
    expect(
      TaroColorTokens.light.bg.canvas,
      isNot(TaroColorTokens.dark.bg.canvas),
    );
    expect(TaroSpaceTokens.dark, same(TaroSpaceTokens.light));
    expect(TaroElevationTokens.light.e1.shadow, isNotEmpty);
    expect(TaroElevationTokens.dark.e0.shadow, isEmpty);
  });

  test('the 01 §14.3 constraints hold in the generated values', () {
    const s = TaroSpaceTokens.light;
    expect([s.s0, s.s1, s.s2, s.s3, s.s4, s.s5], [0, 2, 4, 8, 12, 16]);
    expect(s.adGap, greaterThanOrEqualTo(16));
    expect(TaroSizeTokens.light.touchTarget.min, 48);
    expect(TaroLayoutTokens.light.gutter, greaterThanOrEqualTo(16));
    expect(TaroTypeTokens.light.body.fontSize, greaterThanOrEqualTo(16));
    expect(TaroTypeTokens.light.caption.fontSize, greaterThanOrEqualTo(12));
    expect(TaroTypeTokens.light.bodyReading.height, greaterThanOrEqualTo(1.5));
  });

  test('reduced motion matches 01 §14.4', () {
    const r = TaroMotionTokens.reduced;
    expect(r.duration.instant, Duration.zero);
    expect(r.ritual.dealStagger, Duration.zero);
    expect(r.ritual.readingReveal, Duration.zero);
    for (final d in [r.ritual.shuffle, r.ritual.flip, r.duration.slow]) {
      expect(d.inMilliseconds, lessThanOrEqualTo(200));
    }
    expect(r.easing.standard.transform(0.5), closeTo(0.5, 1e-6));
    expect(TaroMotionTokens.light.ritual.shuffle.inMilliseconds, 1200);
  });

  test('every generated group lerps', () {
    const t = 0.5;
    expect(
      TaroColorTokens.lerp(
        TaroColorTokens.light,
        TaroColorTokens.dark,
        t,
      ).bg.canvas,
      Color.lerp(
        TaroColorTokens.light.bg.canvas,
        TaroColorTokens.dark.bg.canvas,
        t,
      ),
    );
    expect(
      TaroMotionTokens.lerp(
        TaroMotionTokens.light,
        TaroMotionTokens.reduced,
        0.25,
      ).ritual.flip,
      TaroMotionTokens.light.ritual.flip,
    );
    expect(
      TaroMotionTokens.lerp(
        TaroMotionTokens.light,
        TaroMotionTokens.reduced,
        0.75,
      ).ritual.flip,
      TaroMotionTokens.reduced.ritual.flip,
    );
    expect(
      TaroElevationTokens.lerp(
        TaroElevationTokens.light,
        TaroElevationTokens.dark,
        1,
      ).e1.overlay,
      TaroElevationTokens.dark.e1.overlay,
    );
  });

  test('type roles use the bundled package fonts', () {
    final display = TaroTypeTokens.light.display;
    expect(display.fontFamily, 'packages/taro_ui/Literata');
    expect(
      display.fontFamilyFallback,
      contains('packages/taro_ui/Noto Serif Arabic'),
    );
    expect(TaroTypeTokens.light.numeral.fontFamily, contains('IM Fell'));
  });
}
