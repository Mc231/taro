import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/duration_text.dart';
import 'package:taro/common/offline_banner.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/pump_app.dart';
import '../helpers/pump_taro_widget.dart';

const _disclaimer =
    'For entertainment and self-reflection. Not professional advice.';

void main() {
  group('DisclaimerFooter (05 §3)', () {
    testWidgets('shows disclaimerShort without a link', (tester) async {
      await pumpTaroWidget(tester, const DisclaimerFooter());
      expect(find.text(_disclaimer), findsOneWidget);
      expect(find.byType(TaroButton), findsNothing);
      final text = tester.widget<Text>(find.text(_disclaimer));
      expect(text.textAlign, TextAlign.start);
    });

    testWidgets('link opens the full disclaimer; centred variant', (
      tester,
    ) async {
      var opened = 0;
      await pumpTaroWidget(
        tester,
        DisclaimerFooter(onOpenDisclaimer: () => opened++, centered: true),
      );
      expect(
        tester.widget<Text>(find.text(_disclaimer)).textAlign,
        TextAlign.center,
      );
      await tester.tap(find.text('Full disclaimer'));
      expect(opened, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('localised and RTL in ar', (tester) async {
      await pumpTaroWidget(
        tester,
        const DisclaimerFooter(),
        locale: const Locale('ar'),
      );
      expect(
        Directionality.of(tester.element(find.byType(DisclaimerFooter))),
        TextDirection.rtl,
      );
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('OfflineBanner', () {
    testWidgets('hidden while online', (tester) async {
      await pumpTaro(tester, const OfflineBanner());
      await tester.pump();
      expect(find.byType(TaroOfflineBanner), findsNothing);
    });

    testWidgets('shown offline with the default message', (tester) async {
      final fakes = TaroFakes()
        ..connectivity = FakeConnectivityMonitor(online: false);
      await pumpTaro(tester, const OfflineBanner(), fakes: fakes);
      await tester.pump();
      expect(
        find.text('You’re offline. Your journal still works.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('custom message and Retry; hides when back online', (
      tester,
    ) async {
      final fakes = TaroFakes()
        ..connectivity = FakeConnectivityMonitor(online: false);
      var retries = 0;
      await pumpTaro(
        tester,
        OfflineBanner(message: 'custom', onRetry: () => retries++),
        fakes: fakes,
      );
      await tester.pump();
      expect(find.text('custom'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      fakes.connectivity.setOnline(online: true);
      await tester.pump();
      expect(find.byType(TaroOfflineBanner), findsNothing);
    });
  });

  group('formatCountdown (real server-time countdowns, 04 §11)', () {
    late TaroLocalizations l10n;
    setUpAll(() async {
      l10n = await TaroLocalizations.delegate.load(const Locale('en'));
    });

    test('hours and minutes', () {
      expect(
        formatCountdown(l10n, const Duration(hours: 5, minutes: 12)),
        '5 h 12 min',
      );
      expect(formatCountdown(l10n, const Duration(hours: 1)), '1 h 0 min');
    });

    test('minutes', () {
      expect(formatCountdown(l10n, const Duration(minutes: 4)), '4 min');
      expect(formatCountdown(l10n, const Duration(minutes: 1)), '1 min');
    });

    test('below a minute and negative', () {
      expect(
        formatCountdown(l10n, const Duration(seconds: 30)),
        'less than a minute',
      );
      expect(
        formatCountdown(l10n, const Duration(minutes: -3)),
        'less than a minute',
      );
    });
  });
}
