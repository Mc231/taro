import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('copyWith replaces only the given groups', () {
    final light = TaroTokens.light();
    final copy = light.copyWith();
    expect(copy.color, same(light.color));
    expect(copy.typography, same(light.typography));
    final dark = TaroTokens.dark();
    final all = light.copyWith(
      brightness: Brightness.dark,
      color: dark.color,
      typography: dark.typography,
      space: dark.space,
      radius: dark.radius,
      size: dark.size,
      layout: dark.layout,
      opacity: dark.opacity,
      elevation: dark.elevation,
      motion: dark.reducedMotion,
      reducedMotion: dark.motion,
      font: dark.font,
      haptic: dark.haptic,
    );
    expect(all.brightness, Brightness.dark);
    expect(all.color, same(dark.color));
    expect(all.elevation, same(dark.elevation));
    expect(all.motion, same(TaroMotionTokens.reduced));
    expect(all.reducedMotion, same(TaroMotionTokens.light));
  });

  test('lerp interpolates colours and switches discrete values', () {
    final light = TaroTokens.light();
    final dark = TaroTokens.dark();
    expect(light.lerp(null, 0.5), same(light));
    final mid = light.lerp(dark, 0.5);
    expect(
      mid.color.text.primary,
      Color.lerp(light.color.text.primary, dark.color.text.primary, 0.5),
    );
    expect(mid.brightness, Brightness.dark);
    expect(light.lerp(dark, 0.2).brightness, Brightness.light);
    expect(mid.space.s4, light.space.s4);
    expect(mid.haptic.pick, light.haptic.pick);
    expect(mid.font.family.body.latin, light.font.family.body.latin);
    expect(mid.reducedMotion.ritual.flip, dark.reducedMotion.ritual.flip);
  });

  testWidgets('context.tokens reads the theme, with a fallback', (
    tester,
  ) async {
    late TaroTokens fromTaro;
    late TaroTokens fallbackLight;
    late TaroTokens fallbackDark;
    await tester.pumpWidget(
      Column(
        children: [
          Theme(
            data: TaroTheme.dark(),
            child: Builder(
              builder: (context) {
                fromTaro = context.tokens;
                return const SizedBox();
              },
            ),
          ),
          Theme(
            data: ThemeData(),
            child: Builder(
              builder: (context) {
                fallbackLight = context.tokens;
                return const SizedBox();
              },
            ),
          ),
          Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: Builder(
              builder: (context) {
                fallbackDark = context.tokens;
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(fromTaro.brightness, Brightness.dark);
    expect(fallbackLight.brightness, Brightness.light);
    expect(fallbackDark.brightness, Brightness.dark);
  });
}
