import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/onboarding/controller/onboarding_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// The onboarding step count shown by the step indicator (S02–S04).
const int kOnboardingSteps = 3;

/// S02 Onboarding: Welcome (01 §7.12, §8.3 `content`). v1 ships one page
/// (docs/design/screens/S02); "Get started" persists the next step, then
/// S03 opens.
class WelcomeScreen extends ConsumerWidget {
  /// Creates the screen.
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(onboardingControllerProvider);
    return WelcomeLayout(
      onGetStarted: () async {
        await ref.read(onboardingControllerProvider.notifier).skipWelcome();
        if (context.mounted) context.go(RoutePaths.onboardingDisclaimer);
      },
    );
  }
}

/// The S02 layout.
class WelcomeLayout extends StatelessWidget {
  /// Creates the view.
  const WelcomeLayout({required this.onGetStarted, super.key});

  /// "Get started".
  final FutureOr<void> Function() onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return TaroScaffold(
      body: ListView(
        padding: EdgeInsetsDirectional.only(top: tokens.space.s9),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.welcomeTitle, style: tokens.typography.display),
          ),
          SizedBox(height: tokens.space.s5),
          Text(
            l10n.welcomeLead,
            style: tokens.typography.body.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
          SizedBox(height: tokens.space.s8),
          IconBulletList(
            items: [
              IconBulletItem(
                title: l10n.welcomeFeatureFreeReading,
                icon: Icons.auto_awesome_outlined,
                intent: IconBulletIntent.accent,
              ),
              IconBulletItem(
                title: l10n.welcomeFeatureDailyCard,
                icon: Icons.style_outlined,
                intent: IconBulletIntent.accent,
              ),
              IconBulletItem(
                title: l10n.welcomeFeatureJournal,
                icon: Icons.lock_outline,
                intent: IconBulletIntent.accent,
              ),
            ],
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s5,
        children: [
          TaroButton.primary(
            label: l10n.welcomeGetStarted,
            expand: true,
            onPressed: onGetStarted,
          ),
          StepIndicator(
            current: 1,
            total: kOnboardingSteps,
            semanticsLabel: l10n.commonStepOf(1, kOnboardingSteps),
          ),
        ],
      ),
    );
  }
}
