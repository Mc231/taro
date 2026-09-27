import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import 'pump_taro_widget.dart';

void main() {
  testWidgets('pumps the child with Taro localizations', (tester) async {
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
  });

  testWidgets('honours locale and theme overrides', (tester) async {
    await pumpTaroWidget(
      tester,
      const SizedBox.shrink(),
      locale: const Locale('ar'),
      theme: TaroTheme.dark(),
    );
    final context = tester.element(find.byType(SizedBox));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
