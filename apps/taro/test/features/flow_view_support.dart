import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/bootstrap/bootstrap.dart' show noProviderRetry;
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import '../../../../packages/taro_ui/test/helpers/golden/load_taro_test_fonts.dart';
import 'skeleton_support.dart';

export 'feature_test_support.dart';
export 'skeleton_support.dart';

/// Every location the onboarding / Today / reading screens navigate to
/// (each renders `route:<uri>`).
const List<String> kFlowRoutes = [
  '/home',
  '/store',
  '/daily',
  '/update',
  '/journal',
  '/journal/:id',
  '/learn',
  '/learn/spreads',
  '/help/crisis',
  '/legal/:doc',
  '/onboarding/disclaimer',
  '/consent/ai',
  '/reading/spreads',
  '/reading/question',
  '/reading/draw',
  '/reading/:id',
];

/// Pumps a [GoRouter] whose [path] route builds [builder]; every other
/// [kFlowRoutes] location renders `route:<uri>`. With [pushed] the screen
/// is pushed over `/` (a `route:/` stub), so `pop` can be tested. Returns
/// the router.
Future<GoRouter> pumpFlow(
  WidgetTester tester, {
  required String path,
  required Widget Function(GoRouterState state) builder,
  required TaroFakes fakes,
  String? location,
  bool pushed = false,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  Size size = kPhoneSmall,
}) async {
  fakes.locale = locale.languageCode;
  applyTestViewSize(tester, size);
  Widget stub(GoRouterState state) =>
      Scaffold(body: Text('route:${state.uri}'));
  final router = GoRouter(
    initialLocation: pushed ? '/' : location ?? path,
    routes: [
      GoRoute(path: '/', builder: (context, state) => stub(state)),
      GoRoute(path: path, builder: (context, state) => builder(state)),
      for (final other in kFlowRoutes)
        if (other != path)
          GoRoute(path: other, builder: (context, state) => stub(state)),
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
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: app!,
        ),
      ),
    ),
  );
  if (pushed) {
    await tester.pumpAndSettle();
    router.push(location ?? path).ignore();
  }
  await tester.pumpAndSettle();
  return router;
}

/// Taps the widget with [text] without settling (for screens with an
/// endless animation); pumps [frames] frames.
Future<void> tapTextOnce(
  WidgetTester tester,
  String text, {
  int frames = 3,
}) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  for (var i = 0; i < frames; i++) {
    await tester.pump();
  }
}

/// Scrolls the first scrollable until [finder] is built, then taps it and
/// settles.
Future<void> tapFound(WidgetTester tester, Finder finder) async {
  await revealFound(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Scrolls the first scrollable until [finder] is built and visible.
Future<void> revealFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(_mainScrollable(tester), const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// The tallest vertical scrollable on screen (the page body, not a text
/// field's own scrollable).
Finder _mainScrollable(WidgetTester tester) {
  final all = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  var best = all.first;
  var height = -1.0;
  for (var i = 0; i < all.evaluate().length; i++) {
    final candidate = all.at(i);
    final size = tester.getSize(candidate).height;
    if (size > height) {
      height = size;
      best = candidate;
    }
  }
  return best;
}
