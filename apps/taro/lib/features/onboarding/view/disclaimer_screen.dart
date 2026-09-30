import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/onboarding/controller/onboarding_controller.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// S03 Onboarding: Disclaimer (01 §7.12, §8.3 `content`, `acknowledged`;
/// 05 §3 `disclaimerOnboarding*`). "I understand" is required; it persists
/// the next step, then S04 opens.
class DisclaimerScreen extends ConsumerWidget {
  /// Creates the screen.
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    return DisclaimerLayout(
      acknowledged: state is OnboardingAcknowledged,
      onAcknowledge: () async {
        await ref
            .read(onboardingControllerProvider.notifier)
            .acknowledgeDisclaimer();
        if (context.mounted) context.go(RoutePaths.consentAi);
      },
      onReadFull: () => context.push(RoutePaths.legal('disclaimer')),
    );
  }
}

/// The S03 layout; [acknowledged] shows the button busy while S04 opens.
class DisclaimerLayout extends StatelessWidget {
  /// Creates the view.
  const DisclaimerLayout({
    required this.acknowledged,
    required this.onAcknowledge,
    required this.onReadFull,
    super.key,
  });

  /// S03 `acknowledged`.
  final bool acknowledged;

  /// "I understand".
  final FutureOr<void> Function() onAcknowledge;

  /// "Read the full disclaimer" (S29).
  final VoidCallback onReadFull;

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
            child: Text(
              l10n.disclaimerOnboardingTitle,
              style: tokens.typography.headline,
            ),
          ),
          SizedBox(height: tokens.space.s4),
          Text(l10n.disclaimerOnboardingBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s7),
          IconBulletList(
            items: [
              IconBulletItem(
                title: l10n.disclaimerNoticeAi,
                icon: Icons.auto_awesome_outlined,
              ),
              IconBulletItem(
                title: l10n.disclaimerNoticeYouDecide,
                icon: Icons.self_improvement_outlined,
              ),
              IconBulletItem(
                title: l10n.disclaimerNoticeSupport,
                icon: Icons.favorite_border,
              ),
            ],
          ),
          SizedBox(height: tokens.space.s5),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TaroButton.tertiary(
              label: l10n.disclaimerReadFull,
              onPressed: onReadFull,
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s5,
        children: [
          TaroButton.primary(
            label: l10n.disclaimerAcknowledge,
            expand: true,
            loading: acknowledged,
            loadingSemanticsHint: l10n.commonLoading,
            onPressed: acknowledged ? null : onAcknowledge,
          ),
          StepIndicator(
            current: 2,
            total: kOnboardingSteps,
            semanticsLabel: l10n.commonStepOf(2, kOnboardingSteps),
          ),
        ],
      ),
    );
  }
}
