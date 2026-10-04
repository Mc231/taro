import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/routing/back_behaviour.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/screen_builders.dart';
import 'package:taro/routing/tab_shell.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

export 'package:taro/routing/back_behaviour.dart';
export 'package:taro/routing/route_paths.dart';

/// The navigator keys of the root stack and of the four tab branches.
final class TaroNavigatorKeys {
  /// Fresh keys (one set per router).
  TaroNavigatorKeys();

  /// The root navigator: full-screen routes and modals cover the tabs.
  final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
}

/// A platform page for [child]: the Cupertino transition and the iOS edge
/// swipe back on iOS, the Material one on Android.
///
/// go_router 18 detects the app type through `material_ui`'s `MaterialApp`,
/// not Flutter's, so its own `builder:` pages fall back to
/// `NoTransitionPage` (no transition, no iOS back swipe on any screen).
Page<void> _page(GoRouterState state, Widget child) => MaterialPage<void>(
  key: state.pageKey,
  name: state.name ?? state.path,
  arguments: <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  },
  restorationId: state.pageKey.value,
  child: child,
);

GoRoute _screen(
  String path,
  ScreenId screen, {
  GlobalKey<NavigatorState>? parent,
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  parentNavigatorKey: parent,
  routes: routes,
  pageBuilder: (context, state) =>
      _page(state, buildScreen(context, screen, _args(state))),
);

ScreenArgs _args(GoRouterState state) =>
    ScreenArgs(path: state.pathParameters, query: state.uri.queryParameters);

/// The route table of 01 §8.1 / 02 §8.1 (S01–S33, RC17, RC20, RC71–RC73).
///
/// A `StatefulShellRoute` holds the four tabs (Today `/home`, Journal,
/// Learn, Settings); their detail screens keep the tab bar. The reading
/// flow, the store, the daily card, help, legal and update cover the tabs
/// on the root navigator. S10, S12 and S33 are modals ([TaroModals]), not
/// routes, so no link can open them; S31 is an inline state of S07.
List<RouteBase> taroRoutes(TaroNavigatorKeys keys) => [
  _screen(RoutePaths.launch, ScreenId.s01),
  _screen(RoutePaths.onboardingWelcome, ScreenId.s02),
  _screen(RoutePaths.onboardingDisclaimer, ScreenId.s03),
  _screen(RoutePaths.consentAi, ScreenId.s04),
  StatefulShellRoute.indexedStack(
    pageBuilder: (context, state, shell) =>
        _page(state, TaroTabShell(navigationShell: shell)),
    branches: [
      StatefulShellBranch(routes: [_screen(RoutePaths.home, ScreenId.s05)]),
      StatefulShellBranch(
        routes: [
          _screen(
            RoutePaths.journal,
            ScreenId.s14,
            routes: [_screen(':id', ScreenId.s15)],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          _screen(
            RoutePaths.learn,
            ScreenId.s16,
            routes: [
              _screen('card/:cardId', ScreenId.s17),
              _screen(
                'spreads',
                ScreenId.s18,
                routes: [_screen(':spreadId', ScreenId.s18)],
              ),
              _screen('about', ScreenId.s19),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          _screen(
            RoutePaths.settings,
            ScreenId.s20,
            routes: [
              _screen('language', ScreenId.s21),
              _screen('reminder', ScreenId.s22),
              _screen('privacy', ScreenId.s23),
              _screen('export', ScreenId.s24),
              _screen('import', ScreenId.s25),
              _screen('delete', ScreenId.s26),
            ],
          ),
        ],
      ),
    ],
  ),
  _screen(RoutePaths.readingSpreads, ScreenId.s06, parent: keys.root),
  _screen(RoutePaths.readingQuestionPath, ScreenId.s07, parent: keys.root),
  _screen(RoutePaths.readingDraw, ScreenId.s08, parent: keys.root),
  GoRoute(
    path: RoutePaths.readingPattern,
    parentNavigatorKey: keys.root,
    pageBuilder: (context, state) {
      final classic =
          state.uri.queryParameters['mode'] == RoutePaths.classicMode;
      return _page(
        state,
        ReadingResultBackScope(
          child: buildScreen(
            context,
            classic ? ScreenId.s32 : ScreenId.s09,
            _args(state),
          ),
        ),
      );
    },
  ),
  _screen(RoutePaths.store, ScreenId.s11, parent: keys.root),
  _screen(RoutePaths.daily, ScreenId.s13, parent: keys.root),
  _screen(
    RoutePaths.help,
    ScreenId.s28,
    parent: keys.root,
    routes: [_screen('crisis', ScreenId.s27, parent: keys.root)],
  ),
  _screen('/legal/:doc', ScreenId.s29, parent: keys.root),
  _screen(RoutePaths.update, ScreenId.s30, parent: keys.root),
];

/// The modal screens (02 §8.1): pushed by controllers, never deep-linkable.
abstract final class TaroModals {
  /// S10 Out-of-readings sheet; [source] is the
  /// `out_of_readings_viewed.source` wire value (query `source`).
  /// It is a `TaroSheet`; swipe-down, a scrim tap and back close it.
  static Future<T?> outOfReadings<T>(BuildContext context, {String? source}) =>
      TaroSheet.show<T>(
        context,
        builder: (sheet) => buildScreen(
          sheet,
          ScreenId.s10,
          ScreenArgs(query: {'source': ?source}),
        ),
      );

  /// S12 Rewarded flow overlay: a `TaroDialog`-styled modal, not
  /// dismissible by a barrier tap (Cancel / Continue close it).
  static Future<T?> rewarded<T>(BuildContext context) => TaroDialog.show<T>(
    context,
    builder: (dialog) => buildScreen(dialog, ScreenId.s12),
  );

  /// S33 Report reading for the reading [readingId] (a `TaroSheet`: the
  /// `color.bg.surfaceRaised` sheet over `color.bg.scrim`).
  static Future<T?> reportReading<T>(
    BuildContext context, {
    required String readingId,
  }) => TaroSheet.show<T>(
    context,
    builder: (sheet) => buildScreen(
      sheet,
      ScreenId.s33,
      ScreenArgs(path: {'id': readingId}),
    ),
  );
}
