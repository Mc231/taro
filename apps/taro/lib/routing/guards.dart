import 'package:taro/routing/deep_link_policy.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro_core/taro_core.dart';

/// What the guards read (02 §8.1): pure data, so the guards are tested
/// without widgets.
final class GuardState {
  /// A snapshot of the app state the router depends on.
  const GuardState({
    required this.updateRequired,
    required this.onboardingStep,
  });

  /// Whether the installed version is below `app.minVersion.*` (S30).
  final bool updateRequired;

  /// The persisted onboarding step (01 §7.12).
  final OnboardingStep onboardingStep;

  /// Whether onboarding reached the UMP step: from then on the app is
  /// usable (UMP / ATT have no route, 02 §8.1).
  bool get onboarded => onboardingStep.index >= OnboardingStep.ump.index;
}

/// Holds the deep link that arrived during onboarding until Home (02 §8.2).
final class PendingDeepLink {
  String? _location;

  /// The queued location, if any.
  String? get location => _location;

  /// Queues [location] (a later link replaces an earlier one).
  // A queue operation, not a property.
  // ignore: use_setters_to_change_properties
  void queue(String location) => _location = location;

  /// Returns and clears the queued location.
  String? take() {
    final location = _location;
    _location = null;
    return location;
  }
}

/// S30 first: an outdated app goes to `/update` and stays there.
String? updateGuard(GuardState state, String path) {
  if (!state.updateRequired) {
    return path == RoutePaths.update ? RoutePaths.home : null;
  }
  return path == RoutePaths.update ? null : RoutePaths.update;
}

/// The onboarding location that resumes [step] (01 §7.12).
String onboardingLocationFor(OnboardingStep step) => switch (step) {
  OnboardingStep.welcome => RoutePaths.onboardingWelcome,
  OnboardingStep.disclaimer => RoutePaths.onboardingDisclaimer,
  OnboardingStep.aiConsent => RoutePaths.consentAi,
  OnboardingStep.ump ||
  OnboardingStep.att ||
  OnboardingStep.done => RoutePaths.home,
};

/// Before onboarding is done every location resumes at the persisted step
/// (the onboarding screens themselves, S29 legal and S27 support lines stay
/// reachable, [RoutePaths.openDuringOnboarding]); after it, the
/// welcome and disclaimer screens and `/` lead Home. S04 stays reachable
/// as the gate re-entry (RC21).
String? onboardingGuard(GuardState state, String path) {
  if (!state.onboarded) {
    return RoutePaths.onboarding.contains(path) ||
            RoutePaths.openDuringOnboarding(path)
        ? null
        : onboardingLocationFor(state.onboardingStep);
  }
  if (path == RoutePaths.launch ||
      path == RoutePaths.onboardingWelcome ||
      path == RoutePaths.onboardingDisclaimer) {
    return RoutePaths.home;
  }
  return null;
}

/// The router's top-level redirect (02 §8.1): deep-link sanitising →
/// [updateGuard] → [onboardingGuard], plus the onboarding link queue.
///
/// Returns the location to go to instead of [uri], or `null` to stay.
String? redirectFor({
  required GuardState state,
  required Uri uri,
  required DeepLinkPolicy policy,
  required PendingDeepLink pending,
}) {
  final external = policy.isExternal(uri);
  final target = external ? Uri.parse(policy.sanitize(uri)) : uri;
  final path = target.path;

  final update = updateGuard(state, path);
  if (state.updateRequired) {
    final next = update ?? path;
    return next == uri.toString() ? null : next;
  }
  if (update != null) return update;

  final onboarding = onboardingGuard(state, path);
  if (!state.onboarded) {
    if (external && onboarding != null) pending.queue(target.toString());
    return onboarding ?? (external ? target.toString() : null);
  }
  if (onboarding == RoutePaths.home || path == RoutePaths.home) {
    final queued = pending.take();
    if (queued != null) return queued;
  }
  final next = onboarding ?? target.toString();
  return next == uri.toString() ? null : next;
}
