import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/onboarding_page.dart';
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

  /// "Read the full disclaimer": S29 on the disclaimer tab, which the
  /// onboarding guard lets open over S03.
  final VoidCallback onReadFull;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return OnboardingPage(
      content: [
        Semantics(
          header: true,
          child: Text(
            l10n.disclaimerOnboardingTitle,
            style: tokens.typography.headline,
          ),
        ),
        Text(
          l10n.disclaimerOnboardingBody,
          style: tokens.typography.bodyReading.copyWith(
            color: tokens.color.text.primary,
          ),
        ),
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s4,
            children: [
              DisclaimerNotice(
                icon: Icons.error_outline,
                text: l10n.disclaimerNoticeAi,
              ),
              DisclaimerNotice(
                icon: Icons.arrow_forward,
                text: l10n.disclaimerNoticeYouDecide,
              ),
              DisclaimerNotice(
                icon: Icons.favorite_border,
                text: l10n.disclaimerNoticeSupport,
              ),
            ],
          ),
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s3,
        children: [
          TaroButton.primary(
            label: l10n.disclaimerAcknowledge,
            expand: true,
            loading: acknowledged,
            loadingSemanticsHint: l10n.commonLoading,
            onPressed: acknowledged ? null : onAcknowledge,
          ),
          Center(
            child: TaroButton.link(
              label: l10n.disclaimerReadFull,
              onPressed: onReadFull,
            ),
          ),
          Center(
            child: StepIndicator(
              current: 2,
              total: kOnboardingSteps,
              semanticsLabel: l10n.commonStepOf(2, kOnboardingSteps),
            ),
          ),
        ],
      ),
    );
  }
}

/// One S03 notice card: `color.bg.surface`, `radius.md`, padding
/// `space.5`, a `size.icon.md` icon at the start and `type.body` text.
class DisclaimerNotice extends StatelessWidget {
  /// Creates the notice.
  const DisclaimerNotice({required this.icon, required this.text, super.key});

  /// The decorative icon.
  final IconData icon;

  /// The notice text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.space.s5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.space.s5,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: tokens.size.icon.md,
                color: c.accent.secondary,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: tokens.typography.body.copyWith(
                  color: c.text.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
