import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden/golden_sizes.dart';
import 'pump_taro_ui_widget.dart';

void main() {
  testWidgets('defaults: en, light, 1.0 text scale, small phone', (
    tester,
  ) async {
    await pumpTaroUiWidget(tester, const Text('x'));
    final context = tester.element(find.text('x'));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Theme.of(context).brightness, Brightness.light);
    expect(MediaQuery.textScalerOf(context), TextScaler.noScaling);
    expect(MediaQuery.sizeOf(context), kPhoneSmall);
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
  });

  testWidgets('honours locale direction, theme, scale and size', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      const Text('x'),
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 2,
      size: kTabletIpad13,
    );
    final context = tester.element(find.text('x'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(context), const TextScaler.linear(2));
    expect(MediaQuery.sizeOf(context), kTabletIpad13);
  });

  test('textDirectionOf covers the RTL languages', () {
    for (final code in kRtlLanguages) {
      expect(textDirectionOf(Locale(code)), TextDirection.rtl);
    }
    expect(textDirectionOf(const Locale('uk')), TextDirection.ltr);
  });
}
