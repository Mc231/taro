import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/router.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart' as core;
import 'package:taro_ui/taro_ui.dart';

import '../helpers/pump_app.dart';

Future<(TaroFakes, ProviderContainer)> _boot(
  WidgetTester tester, {
  TaroFakes? fakes,
}) async {
  final used = fakes ?? TaroFakes();
  final container = used.container();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TaroApp()),
  );
  await tester.pumpAndSettle();
  return (used, container);
}

Future<void> _go(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

/// The screen with the S-ID [wire] (`buildScreen` keys every screen).
Finder _screen(String wire) => find.byKey(
  ValueKey(core.ScreenId.values.firstWhere((s) => s.wire == wire)),
);

void main() {
  testWidgets('boots Home in the Today tab and switches tabs', (tester) async {
    await _boot(tester);
    expect(_screen('S05'), findsOneWidget);
    for (final (label, screen) in [
      ('Journal', 'S14'),
      ('Learn', 'S16'),
      ('Settings', 'S20'),
      ('Today', 'S05'),
      ('Today', 'S05'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(_screen(screen), findsOneWidget, reason: label);
    }
  });

  testWidgets('every route renders its screen (S01–S32)', (tester) async {
    final (_, container) = await _boot(tester);
    final table = {
      '/consent/ai': 'S04',
      '/reading/spreads': 'S06',
      '/reading/question?spread=single': 'S07',
      // S08 without a reading session (a stale link) closes to Home.
      '/reading/draw': 'S05',
      '/reading/abc': 'S09',
      '/reading/abc?mode=classic': 'S32',
      '/store': 'S11',
      '/daily': 'S13',
      '/journal/2026-09-26': 'S15',
      '/learn/card/major_00': 'S17',
      '/learn/spreads': 'S18',
      '/learn/spreads/single': 'S18',
      '/learn/about': 'S19',
      '/settings/language': 'S21',
      '/settings/reminder': 'S22',
      '/settings/privacy': 'S23',
      '/settings/export': 'S24',
      '/settings/import': 'S25',
      '/settings/delete': 'S26',
      '/help/crisis': 'S27',
      '/help': 'S28',
      '/legal/terms': 'S29',
      '/onboarding/welcome': 'S05',
      '/does/not/exist': 'S05',
    };
    for (final MapEntry(key: location, value: screen) in table.entries) {
      await _go(tester, container, location);
      expect(_screen(screen), findsOneWidget, reason: location);
    }
    expect(
      RoutePaths.reading('abc', classic: true),
      '/reading/abc?mode=classic',
    );
    expect(RoutePaths.learnSpread('single'), '/learn/spreads/single');
    expect(RoutePaths.legal('terms'), '/legal/terms');
  });

  testWidgets('S09 back goes Home', (tester) async {
    final (_, container) = await _boot(tester);
    unawaited(container.read(routerProvider).push(RoutePaths.reading('abc')));
    await tester.pumpAndSettle();
    expect(_screen('S09'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_screen('S05'), findsOneWidget);
  });

  testWidgets('onboarding resumes at the persisted step', (tester) async {
    final fakes = TaroFakes(
      consent: const core.ConsentState(
        onboardingStep: core.OnboardingStep.disclaimer,
      ),
    );
    final (_, container) = await _boot(tester, fakes: fakes);
    expect(_screen('S03'), findsOneWidget);

    await _go(tester, container, 'taro://daily');
    expect(_screen('S03'), findsOneWidget);

    await fakes.consentStore.update(
      (s) => s.copyWith(onboardingStep: core.OnboardingStep.done),
    );
    await tester.pumpAndSettle();
    expect(_screen('S13'), findsOneWidget);
  });

  testWidgets('an outdated app is held on S30', (tester) async {
    final fakes = TaroFakes();
    fakes.config.current = core.RemoteConfig.defaults.copyWith(
      appMinVersionIos: '9.0.0',
    );
    final (_, container) = await _boot(tester, fakes: fakes);
    expect(_screen('S30'), findsOneWidget);
    await _go(tester, container, '/journal');
    expect(_screen('S30'), findsOneWidget);
    fakes.config.current = core.RemoteConfig.defaults;
    await tester.pumpAndSettle();
    expect(_screen('S05'), findsOneWidget);
  });

  testWidgets('deep links and notification taps are sanitized', (tester) async {
    final (fakes, container) = await _boot(tester);
    await _go(tester, container, 'taro://learn/card/major_01');
    expect(_screen('S17'), findsOneWidget);
    await _go(tester, container, 'https://taro.vshyrochuk.com/app/store');
    expect(_screen('S11'), findsOneWidget);

    fakes.reminders.tap('taro://daily');
    await tester.pumpAndSettle();
    expect(_screen('S13'), findsOneWidget);
    expect(fakes.analytics.events, contains(isA<core.ReminderOpenedEvent>()));

    fakes.reminders.tap('taro://reading/draw');
    await tester.pumpAndSettle();
    expect(_screen('S05'), findsOneWidget);
  });

  testWidgets('modals open S10, S12 and S33', (tester) async {
    final (_, container) = await _boot(tester);
    final context = container
        .read(routerProvider)
        .routerDelegate
        .navigatorKey
        .currentContext!;

    Future<void> check(
      Future<void> Function() open,
      String screen,
    ) async {
      final done = open();
      await tester.pumpAndSettle();
      expect(_screen(screen), findsOneWidget);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      await done;
    }

    await check(() => TaroModals.outOfReadings<void>(context), 'S10');
    await check(() => TaroModals.rewarded<void>(context), 'S12');
    await check(
      () => TaroModals.reportReading<void>(context, readingId: 'r1'),
      'S33',
    );
  });

  testWidgets('the Settings theme and locale reach MaterialApp', (
    tester,
  ) async {
    final fakes = TaroFakes();
    await fakes.settings.update(
      (s) => s.copyWith(
        localeOverride: 'uk',
        themeMode: core.ThemeMode.dark,
      ),
    );
    await _boot(tester, fakes: fakes);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('uk'));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Сьогодні'), findsOneWidget);
  });

  testWidgets('script fonts, reduce motion and haptics reach taro_ui', (
    tester,
  ) async {
    final fakes = TaroFakes();
    await fakes.settings.update(
      (s) => s.copyWith(
        localeOverride: 'ja',
        reduceMotion: true,
        hapticsEnabled: false,
      ),
    );
    await _boot(tester, fakes: fakes);
    final context = tester.element(find.byType(Navigator).first);
    final scope = TaroA11yScope.maybeOf(context)!;
    expect(scope.reduceMotion, isTrue);
    expect(scope.hapticsEnabled, isFalse);
    expect(
      Theme.of(context).textTheme.bodyMedium?.fontFamily,
      TaroTheme.light(script: TaroScript.cjk).textTheme.bodyMedium?.fontFamily,
    );
  });

  test('themeForScript follows the brightness', () {
    expect(
      themeForScript(Brightness.dark, TaroScript.arabic).brightness,
      Brightness.dark,
    );
    expect(
      themeForScript(Brightness.light, TaroScript.latin).brightness,
      Brightness.light,
    );
  });

  test('themeModeOf', () {
    expect(themeModeOf(core.ThemeMode.system), ThemeMode.system);
    expect(themeModeOf(core.ThemeMode.light), ThemeMode.light);
    expect(themeModeOf(core.ThemeMode.dark), ThemeMode.dark);
  });

  group('DrawBackScope (01 §9.1)', () {
    Future<GoRouter> pumpDraw(
      WidgetTester tester, {
      required bool confirm,
    }) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Text('home'),
            routes: [
              GoRoute(
                path: 'draw',
                builder: (_, _) =>
                    DrawBackScope(confirm: confirm, child: const Text('draw')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: TaroLocalizations.localizationsDelegates,
          supportedLocales: TaroLocalizations.supportedLocales,
        ),
      );
      unawaited(router.push('/home/draw'));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('before a pick, back leaves at once', (tester) async {
      await pumpDraw(tester, confirm: false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('after a pick, back asks first', (tester) async {
      await pumpDraw(tester, confirm: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave this reading?'), findsOneWidget);
      await tester.tap(find.text('Keep drawing'));
      await tester.pumpAndSettle();
      expect(find.text('draw'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });
}
