import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_matrix.dart';
import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import 'pump_taro_widget.dart';

void main() {
  testWidgets('pumps the child with Taro localizations and defaults', (
    tester,
  ) async {
    late String title;
    await pumpTaroWidget(
      tester,
      Builder(
        builder: (context) {
          title = TaroLocalizations.of(context).appTitle;
          return const Text('child');
        },
      ),
    );
    expect(find.text('child'), findsOneWidget);
    expect(title, 'Taro');
    final context = tester.element(find.text('child'));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(Theme.of(context).brightness, Brightness.light);
    expect(MediaQuery.textScalerOf(context), TextScaler.noScaling);
    expect(MediaQuery.sizeOf(context), kPhoneSmall);
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
  });

  testWidgets('honours locale, theme mode, text scale and size', (
    tester,
  ) async {
    await pumpTaroWidget(
      tester,
      const SizedBox.shrink(),
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
      textScale: 2,
      size: kTabletIpad13,
    );
    final context = tester.element(find.byType(SizedBox));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(context), const TextScaler.linear(2));
    expect(MediaQuery.sizeOf(context), kTabletIpad13);
  });

  testWidgets('pumpTaroGolden forwards the variant', (tester) async {
    await pumpTaroGolden(
      tester,
      const SizedBox.shrink(),
      const GoldenVariant(
        size: kTabletAndroid,
        themeMode: ThemeMode.dark,
        locale: Locale('ja'),
      ),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(Localizations.localeOf(context), const Locale('ja'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(MediaQuery.sizeOf(context), kTabletAndroid);
  });
}
