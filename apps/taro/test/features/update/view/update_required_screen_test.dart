import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro/features/update/view/update_required_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  testWidgets('content (iOS): App Store caption, blocking back', (
    tester,
  ) async {
    var opened = 0;
    await pumpTaro(
      tester,
      UpdateRequiredScreen(onOpenStore: () => opened++),
    );
    expect(find.text(l10n.updateTitle), findsOneWidget);
    expect(find.text(l10n.updateSafeTitle), findsOneWidget);
    expect(find.text(l10n.updateCaptionIos(kTestAppVersion)), findsOneWidget);
    final scope = tester.widget<PopScope<Object?>>(
      find.byWidgetPredicate((w) => w is PopScope),
    );
    expect(scope.canPop, isFalse);
    await tapText(tester, l10n.updateButton);
    expect(opened, 1);
  });

  testWidgets('content (Android): Google Play caption; no link, disabled', (
    tester,
  ) async {
    await pumpTaroWidget(
      tester,
      const UpdateRequiredLayout(
        state: UpdateRequiredState.content(
          platform: AppPlatform.android,
          installedVersion: '1.0.0',
          minVersion: '1.2.0',
        ),
        onOpenStore: null,
      ),
    );
    expect(find.text(l10n.updateCaptionAndroid('1.0.0')), findsOneWidget);
    final button = tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.updateButton),
    );
    expect(button.onPressed, isNull);
  });
}
