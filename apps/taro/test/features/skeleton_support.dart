import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/bootstrap/bootstrap.dart' show noProviderRetry;
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import '../../../../packages/taro_ui/test/helpers/golden/load_taro_test_fonts.dart';
import '../helpers/pump_app.dart';

export '../helpers/pump_app.dart';
export '../helpers/pump_taro_widget.dart';

/// A no-op callback for views under test.
void noop() {}

/// A no-op value callback for views under test.
void noop1<T>(T _) {}

/// The English strings.
Future<TaroLocalizations> enL10n() =>
    TaroLocalizations.delegate.load(const Locale('en'));

/// The locations a routed screen test can land on (each shows
/// `route:<location>`).
const List<String> kLandingRoutes = [
  '/home',
  '/store',
  '/help',
  '/help/crisis',
  '/legal/:doc',
  '/journal',
  '/journal/:id',
  '/reading/draw',
  '/reading/spreads',
  '/reading/question',
  '/reading/:id',
  '/learn/card/:cardId',
  '/learn/spreads',
  '/learn/about',
  '/settings/:sub',
  '/consent/ai',
];

/// Pumps [screen] at `/` of a [GoRouter] with providers from [fakes], so
/// `context.push`/`go` work; every [kLandingRoutes] location renders
/// `route:<uri>`. With [pushed], `/` is a blank page and [screen] is pushed
/// on top of it at `/under-test` (so close / back can pop it). Returns the
/// router.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget screen, {
  required TaroFakes fakes,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  Size size = kPhoneSmall,
  double textScale = 1.0,
  bool pushed = false,
}) async {
  fakes.locale = locale.languageCode;
  applyTestViewSize(tester, size);
  // Clipboard and other platform calls answer at once (Copy actions).
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            pushed ? const Scaffold(body: Text('route:/')) : screen,
      ),
      GoRoute(path: '/under-test', builder: (context, state) => screen),
      for (final path in kLandingRoutes)
        GoRoute(
          path: path,
          builder: (context, state) =>
              Scaffold(body: Text('route:${state.uri}')),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...fakes.toOverrides(), ...overrides],
      retry: noProviderRetry,
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: withTaroTestFonts(TaroTheme.light()),
        localizationsDelegates: TaroLocalizations.localizationsDelegates,
        supportedLocales: TaroLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: app!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (pushed) {
    router.push<void>('/under-test').ignore();
    await tester.pumpAndSettle();
  }
  return router;
}

/// Taps the widget with [text], scrolling the first scrollable until it is
/// built and visible.
Future<void> tapText(WidgetTester tester, String text) async {
  await revealText(tester, text);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

/// Scrolls the first scrollable until [text] is built and visible.
Future<void> revealText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  final scrollable = _pageScrollable();
  if (finder.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
    // Walk the page list from its top until the text is built.
    final position = tester.state<ScrollableState>(scrollable).position
      ..jumpTo(0);
    await tester.pump();
    while (finder.evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        (position.pixels + 200).clamp(0, position.maxScrollExtent),
      );
      await tester.pump();
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// The page's list (not a text field's inner scrollable).
Finder _pageScrollable() {
  final lists = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );
  return lists.evaluate().isEmpty ? find.byType(Scrollable).first : lists.first;
}

/// Expects the router landed on [location].
void expectRoute(String location) =>
    expect(find.text('route:$location'), findsOneWidget);
