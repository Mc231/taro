import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart' show StoreLinks;
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
    expect(
      find.textContaining(l10n.updateSafeTitle, findRichText: true),
      findsOneWidget,
    );
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

  testWidgets('default: the Play listing opens through UrlLauncher', (
    tester,
  ) async {
    final fakes = TaroFakes()
      ..appInfo = const FakeAppInfo(platform: AppPlatform.android);
    await pumpTaro(tester, const UpdateRequiredScreen(), fakes: fakes);
    await tapText(tester, l10n.updateButton);
    expect(fakes.links.opened.single.host, 'play.google.com');
  });

  testWidgets('default on iOS without an App Store ID: disabled', (
    tester,
  ) async {
    await pumpTaro(tester, const UpdateRequiredScreen());
    final button = tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.updateButton),
    );
    expect(button.onPressed, isNull);
  });

  test('store links', () {
    final ios = StoreLinks.of(AppPlatform.ios, appStoreId: '123');
    expect(ios.listing.toString(), 'https://apps.apple.com/app/id123');
    expect(ios.review!.queryParameters['action'], 'write-review');
    expect(StoreLinks.of(AppPlatform.ios).listing, isNull);
    final android = StoreLinks.of(AppPlatform.android);
    expect(android.listing!.queryParameters['id'], 'com.vshyrochuk.taro');
    expect(android.review, android.listing);
  });
}
