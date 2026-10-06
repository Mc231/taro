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

/// A consent store whose stream trails its writes by [_latency] (drift).
final class _LaggingConsentStore implements core.ConsentStore {
  _LaggingConsentStore(this._inner);

  static const Duration _latency = Duration(milliseconds: 50);

  final core.ConsentStore _inner;

  @override
  core.ConsentState get current => _inner.current;

  @override
  Stream<core.ConsentState> watch() => _inner.watch().asyncMap(
    (s) => Future<core.ConsentState>.delayed(_latency, () => s),
  );

  @override
  Future<core.Result<core.ConsentState>> update(
    core.ConsentState Function(core.ConsentState current) change,
  ) => _inner.update(change);
}

/// Analytics whose calls complete after [_latency] (Firebase on a device).
final class _SlowAnalytics implements core.AnalyticsService {
  _SlowAnalytics(this._inner);

  static const Duration _latency = Duration(milliseconds: 50);

  final core.AnalyticsService _inner;

  Future<void> _later(Future<void> Function() call) =>
      Future<void>.delayed(_latency).then((_) => call());

  @override
  Future<void> log(core.TaroAnalyticsEvent event) =>
      _later(() => _inner.log(event));

  @override
  Future<void> screen(String screenId) => _later(() => _inner.screen(screenId));

  @override
  Future<void> setCollectionEnabled({required bool enabled}) =>
      _later(() => _inner.setCollectionEnabled(enabled: enabled));

  @override
  Future<void> setConsent(core.AnalyticsConsent consent) =>
      _later(() => _inner.setConsent(consent));
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

  final iOSOnly = TargetPlatformVariant.only(TargetPlatform.iOS);
  // TestFlight 0.1.0 (5): back on S09 did nothing on an iPhone. Pages were
  // go_router's `NoTransitionPage` (no iOS edge swipe), S08 replaced the
  // flow with `go` (nothing below S09) and S09 opened from S15 went Home.
  for (final classic in [false, true]) {
    final id = classic ? 'S32' : 'S09';
    Future<GoRouter> afterDraw(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      final router = container.read(routerProvider);
      unawaited(router.push(RoutePaths.readingSpreads));
      await tester.pumpAndSettle();
      unawaited(router.push(RoutePaths.readingQuestion('three_card')));
      await tester.pumpAndSettle();
      unawaited(router.push(RoutePaths.readingDraw));
      await tester.pump();
      // What S08 does on `DrawCompleted`.
      ReadingResultBackScope.openFromDraw(
        tester.element(
          find.byKey(const ValueKey(core.ScreenId.s08), skipOffstage: false),
        ),
        RoutePaths.reading('abc', classic: classic),
      );
      await tester.pumpAndSettle();
      expect(_screen(id), findsOneWidget);
      return router;
    }

    testWidgets('$id after a draw: Done goes Home', (tester) async {
      final (_, container) = await _boot(tester);
      await afterDraw(tester, container);
      await tester.tap(find.bySemanticsLabel('Done').last);
      await tester.pumpAndSettle();
      expect(_screen('S05'), findsOneWidget);
      expect(_screen(id), findsNothing);
    }, variant: iOSOnly);

    testWidgets('$id after a draw: system back goes Home', (tester) async {
      final (_, container) = await _boot(tester);
      await afterDraw(tester, container);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_screen('S05'), findsOneWidget);
      expect(_screen(id), findsNothing);
    });

    testWidgets('$id after a draw: Home sits below it (edge swipe)', (
      tester,
    ) async {
      final (_, container) = await _boot(tester);
      final router = await afterDraw(tester, container);
      expect(router.canPop(), isTrue);
      await tester.dragFrom(const Offset(4, 300), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(_screen('S05'), findsOneWidget);
      expect(_screen(id), findsNothing);
    }, variant: iOSOnly);

    testWidgets('$id from S15: back and Done return to S15', (tester) async {
      final (_, container) = await _boot(tester);
      final router = container.read(routerProvider);
      await _go(tester, container, RoutePaths.journalEntry('abc'));
      expect(_screen('S15'), findsOneWidget);
      unawaited(router.push(RoutePaths.reading('abc', classic: classic)));
      await tester.pumpAndSettle();
      expect(_screen(id), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_screen('S15'), findsOneWidget);
      expect(_screen(id), findsNothing);

      unawaited(router.push(RoutePaths.reading('abc', classic: classic)));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Done').last);
      await tester.pumpAndSettle();
      expect(_screen('S15'), findsOneWidget);
      expect(_screen(id), findsNothing);
    });
  }

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

  // Release 1.0.0: the onboarding links did nothing on a device: the
  // onboarding guard sent `/legal/*` back to the current step.
  testWidgets('S03 "Read the full disclaimer" opens S29 over onboarding', (
    tester,
  ) async {
    final fakes = TaroFakes(
      consent: const core.ConsentState(
        onboardingStep: core.OnboardingStep.disclaimer,
      ),
    );
    final (_, container) = await _boot(tester, fakes: fakes);
    final l10n = TaroLocalizations.of(tester.element(_screen('S03')));
    await tester.tap(find.text(l10n.disclaimerReadFull));
    await tester.pumpAndSettle();
    expect(_screen('S29'), findsOneWidget);
    expect(find.text(l10n.legalDisclaimerBody), findsOneWidget);
    expect(
      container.read(routerProvider).state.uri.path,
      RoutePaths.legal('disclaimer'),
    );

    await tester.tap(find.text(l10n.legalSupportLine));
    await tester.pumpAndSettle();
    expect(_screen('S27'), findsOneWidget);
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(_screen('S03'), findsOneWidget);
  });

  testWidgets('S04 "Privacy policy" opens the hosted policy in onboarding', (
    tester,
  ) async {
    final fakes = TaroFakes(
      consent: const core.ConsentState(
        onboardingStep: core.OnboardingStep.aiConsent,
      ),
    );
    await _boot(tester, fakes: fakes);
    final l10n = TaroLocalizations.of(tester.element(_screen('S04')));
    await tester.tap(find.text(l10n.commonPrivacyPolicy));
    await tester.pumpAndSettle();
    expect(fakes.links.openedInApp, [
      Uri.parse('https://taro.vshyrochuk.com/privacy?hl=en'),
    ]);
    expect(_screen('S04'), findsOneWidget);
  });

  // BUG-01: "Allow AI readings" left the app on S04 when S04 navigated
  // Home before the onboarding step left `aiConsent` (the guard sent it
  // back to S04, which stays reachable once onboarded).
  for (final allow in [true, false]) {
    testWidgets('S04 from onboarding reaches Home (allow: $allow)', (
      tester,
    ) async {
      final fakes = TaroFakes(
        consent: const core.ConsentState(
          onboardingStep: core.OnboardingStep.aiConsent,
        ),
      );
      // On a device analytics and drift take real time: the step lands
      // after S04 has asked to leave, and drift's stream trails its write.
      fakes
        ..analyticsPort = _SlowAnalytics(fakes.analytics)
        ..consentStorePort = _LaggingConsentStore(fakes.consentStore);
      final (_, container) = await _boot(tester, fakes: fakes);
      expect(_screen('S04'), findsOneWidget);
      final l10n = TaroLocalizations.of(tester.element(_screen('S04')));

      await tester.tap(
        find.text(allow ? l10n.aiConsentAccept : l10n.aiConsentDecline),
      );
      await tester.pumpAndSettle();

      expect(_screen('S04'), findsNothing);
      expect(_screen('S05'), findsOneWidget);
      expect(
        container.read(routerProvider).state.uri.path,
        RoutePaths.home,
      );
      expect(
        fakes.consentStore.current.onboardingStep,
        core.OnboardingStep.done,
      );
    });
  }

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
