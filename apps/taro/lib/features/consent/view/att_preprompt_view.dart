import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/onboarding_page.dart';
import 'package:taro/features/consent/controller/att_preprompt_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// Puts the neutral ATT pre-prompt (05 CS14, RC19; onboarding step 5, iOS)
/// over [child] while `attPrePromptProvider` is `visible`. Mount it once
/// above the router (`MaterialApp.router(builder: …)`), so the
/// `ConsentOrchestrator` can show it from outside the widget tree.
class AttPrePromptHost extends ConsumerWidget {
  /// Wraps [child].
  const AttPrePromptHost({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attPrePromptProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (state is AttPrePromptVisible)
          Positioned.fill(
            child: AttPrePromptLayout(
              onContinue: () =>
                  ref.read(attPrePromptProvider.notifier).proceed(),
            ),
          ),
      ],
    );
  }
}

/// The pre-prompt page: an icon tile, a title, neutral copy and **one**
/// "Continue" that leads to the system prompt (no incentive, no fake
/// "Allow", no Skip; docs/design/screens/S04).
class AttPrePromptLayout extends StatelessWidget {
  /// Creates the view.
  const AttPrePromptLayout({required this.onContinue, super.key});

  /// "Continue".
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    Widget section(String title, String body) => MergeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: tokens.space.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.space.s2,
          children: [
            Text(
              title,
              style: tokens.typography.titleSmall.copyWith(
                color: c.text.primary,
              ),
            ),
            Text(
              body,
              style: tokens.typography.body.copyWith(color: c.text.secondary),
            ),
          ],
        ),
      ),
    );
    final divider = Divider(
      height: TaroStrokes.hairline,
      thickness: TaroStrokes.hairline,
      color: c.border.subtle,
    );
    return OnboardingPage(
      gap: tokens.space.s7,
      content: [
        const OnboardingIconTile(icon: Icons.ad_units_outlined),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.space.s4,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.attPrepromptTitle,
                style: tokens.typography.headline,
              ),
            ),
            Text(
              l10n.attPrepromptBody,
              style: tokens.typography.body.copyWith(color: c.text.secondary),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.bg.surface,
            borderRadius: BorderRadius.circular(tokens.radius.lg),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.space.s5,
              vertical: tokens.space.s1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                section(
                  l10n.attPrepromptAllowTitle,
                  l10n.attPrepromptAllowBody,
                ),
                divider,
                section(l10n.attPrepromptDenyTitle, l10n.attPrepromptDenyBody),
                divider,
                section(
                  l10n.attPrepromptEitherTitle,
                  l10n.attPrepromptEitherBody,
                ),
              ],
            ),
          ),
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s4,
        children: [
          TaroButton.primary(
            label: l10n.attPrepromptContinue,
            expand: true,
            onPressed: onContinue,
          ),
          Text(
            l10n.attPrepromptFootnote,
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(color: c.text.tertiary),
          ),
        ],
      ),
    );
  }
}
