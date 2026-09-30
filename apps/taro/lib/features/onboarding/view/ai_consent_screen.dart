import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/onboarding/controller/ai_consent_controller.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S04 AI consent (01 §7.12 step 3, §8.3; 05 CS6; RC21): onboarding and
/// the reading-gate / Settings re-entry, selected by the `origin` query
/// (`/consent/ai?origin=reading_gate`).
///
/// **Allow AI readings** and **Not now** are the same `TaroButton` variant
/// and size (equal weight, nothing pre-selected). From onboarding either
/// decision continues Home (UMP → ATT run there, RC19); from the reading
/// gate **Allow** returns to S07 (the gate re-runs) and "Not now" shows the
/// "AI readings need your permission" variant with **Allow** / **Back**.
class AiConsentScreen extends ConsumerWidget {
  /// Creates the screen for [origin].
  const AiConsentScreen({required this.origin, super.key});

  /// The screen for the route's `origin` query (default: onboarding).
  factory AiConsentScreen.fromQuery(Map<String, String> query, {Key? key}) {
    final wire = query[originQuery];
    return AiConsentScreen(
      origin: AiConsentOrigin.values.firstWhere(
        (o) => o.wire == wire,
        orElse: () => AiConsentOrigin.onboarding,
      ),
      key: key,
    );
  }

  /// The route query naming the origin.
  static const String originQuery = 'origin';

  /// The S04 location for [origin].
  static String location(AiConsentOrigin origin) =>
      origin == AiConsentOrigin.onboarding
      ? RoutePaths.consentAi
      : RoutePaths.consentAiFrom(origin.wire);

  /// Where S04 was opened from.
  final AiConsentOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = aiConsentControllerProvider(origin);
    ref.listen(provider, (previous, next) {
      final leave = switch ((origin, next)) {
        (
          AiConsentOrigin.onboarding,
          AiConsentGranted() || AiConsentDeclined(),
        ) =>
          () => context.go(RoutePaths.home),
        (_, AiConsentGranted()) ||
        (AiConsentOrigin.settings, AiConsentDeclined()) => () => _back(context),
        _ => null,
      };
      leave?.call();
    });
    final state = ref.watch(provider);
    void decide({required bool granted}) =>
        unawaited(ref.read(provider.notifier).decide(granted: granted));
    return AiConsentLayout(
      state: state,
      onAllow: () => decide(granted: true),
      onNotNow: () => decide(granted: false),
      onBack: () => _back(context),
      onPrivacy: () => context.push(RoutePaths.legal('privacy')),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }
}

/// The S04 layout for [state].
class AiConsentLayout extends StatelessWidget {
  /// Creates the view.
  const AiConsentLayout({
    required this.state,
    required this.onAllow,
    required this.onNotNow,
    required this.onBack,
    required this.onPrivacy,
    super.key,
  });

  /// The controller state.
  final AiConsentState state;

  /// **Allow AI readings** / **Allow**.
  final VoidCallback onAllow;

  /// **Not now**.
  final VoidCallback onNotNow;

  /// **Back** (the re-entry variant and the app bar).
  final VoidCallback onBack;

  /// "Privacy policy" (S29).
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final origin = switch (state) {
      AiConsentUndecided(:final origin) ||
      AiConsentGranted(:final origin) ||
      AiConsentDeclined(:final origin) => origin,
    };
    final onboarding = origin == AiConsentOrigin.onboarding;
    // The re-entry variant: the reading flow after "Not now", or a
    // re-prompt after an earlier decline (F7).
    final reentry =
        !onboarding &&
        switch (state) {
          AiConsentDeclined() => true,
          AiConsentUndecided(:final previouslyDeclined) => previouslyDeclined,
          AiConsentGranted() => false,
        };
    final busy = state is AiConsentGranted;
    // Equal weight (05 CS6): the same variant and size, in the same order.
    final allow = TaroButton.secondary(
      label: reentry ? l10n.aiConsentReentryAllow : l10n.aiConsentAccept,
      expand: true,
      onPressed: busy ? null : onAllow,
    );
    final decline = TaroButton.secondary(
      label: reentry ? l10n.aiConsentReentryBack : l10n.aiConsentDecline,
      expand: true,
      onPressed: busy ? null : (reentry ? onBack : onNotNow),
    );
    return TaroScaffold(
      appBar: onboarding
          ? null
          : TaroAppBar(onLeading: onBack, leadingLabel: l10n.commonBack),
      body: ListView(
        padding: EdgeInsetsDirectional.only(
          top: onboarding ? tokens.space.s9 : tokens.space.s5,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              reentry ? l10n.aiConsentReentryTitle : l10n.aiConsentTitle,
              style: tokens.typography.headline,
            ),
          ),
          SizedBox(height: tokens.space.s4),
          Text(
            l10n.aiConsentBody,
            style: tokens.typography.label.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
          SizedBox(height: tokens.space.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TaroButton.tertiary(
              label: l10n.commonPrivacyPolicy,
              onPressed: onPrivacy,
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s3,
        children: [
          allow,
          decline,
          Text(
            l10n.aiConsentFootnote,
            textAlign: TextAlign.start,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.tertiary,
            ),
          ),
          if (onboarding)
            StepIndicator(
              current: 3,
              total: kOnboardingSteps,
              semanticsLabel: l10n.commonStepOf(3, kOnboardingSteps),
            ),
        ],
      ),
    );
  }
}
