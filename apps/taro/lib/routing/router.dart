import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/routing/deep_link_policy.dart';
import 'package:taro/routing/guards.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';

/// The deep-link allowlist for this flavor's Universal Link host.
final deepLinkPolicyProvider = Provider<DeepLinkPolicy>(
  (ref) => DeepLinkPolicy(
    universalLinkHost: ref.watch(flavorConfigProvider).universalLinkHost,
  ),
);

/// The app router (02 §8): the route table, the guards (`updateGuard` →
/// `onboardingGuard` → `deepLinkPolicy`) re-evaluated whenever the update
/// requirement or the onboarding step changes, and the reminder
/// notification taps (`taro://daily`, sanitized like any link).
final routerProvider = Provider<GoRouter>((ref) {
  final keys = TaroNavigatorKeys();
  final policy = ref.watch(deepLinkPolicyProvider);
  final pending = PendingDeepLink();
  final refresh = ValueNotifier<int>(0);

  GuardState guardState() => GuardState(
    updateRequired: ref.read(updateRequiredProvider),
    onboardingStep: ref.read(consentProvider).onboardingStep,
  );

  final router = GoRouter(
    navigatorKey: keys.root,
    initialLocation: RoutePaths.launch,
    refreshListenable: refresh,
    routes: taroRoutes(keys),
    redirect: (context, state) => redirectFor(
      state: guardState(),
      uri: state.uri,
      policy: policy,
      pending: pending,
    ),
    // An unknown in-app location (a stale link, a removed screen) goes Home.
    onException: (context, state, router) => router.go(RoutePaths.home),
  );

  void bump() => refresh.value++;
  ref
    ..listen(updateRequiredProvider, (_, _) => bump())
    ..listen(
      consentProvider.select((consent) => consent.onboardingStep),
      (_, _) => bump(),
    );

  final analytics = ref.watch(analyticsServiceProvider);
  final taps = ref.watch(reminderSchedulerProvider).taps.listen((link) {
    unawaited(analytics.log(const ReminderOpenedEvent()));
    router.go(link);
  });

  ref.onDispose(() async {
    await taps.cancel();
    refresh.dispose();
    router.dispose();
  });
  return router;
});
