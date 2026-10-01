import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/onboarding_page.dart';
import 'package:taro/features/onboarding/controller/onboarding_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The onboarding step count shown by the step indicator (S02–S04).
const int kOnboardingSteps = 3;

/// The card on the S02 hero (The Star).
const CardId kWelcomeHeroCard = CardId('major_17');

/// The Major Arcana number of [kWelcomeHeroCard].
const int kWelcomeHeroNumber = 17;

/// [value] (1–39) in Roman numerals, as printed on Major Arcana cards.
String romanNumeral(int value) {
  const symbols = [(10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I')];
  final out = StringBuffer();
  var rest = value;
  for (final (amount, symbol) in symbols) {
    while (rest >= amount) {
      out.write(symbol);
      rest -= amount;
    }
  }
  return out.toString();
}

/// S02 Onboarding: Welcome (01 §7.12, §8.3 `content`). v1 ships one page
/// (docs/design/screens/S02); "Get started" persists the next step, then
/// S03 opens.
class WelcomeScreen extends ConsumerWidget {
  /// Creates the screen.
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(onboardingControllerProvider);
    final star = ref.watch(cardTextProvider(kWelcomeHeroCard)).value;
    return WelcomeLayout(
      heroCardName: star?.name,
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
  const WelcomeLayout({
    required this.onGetStarted,
    this.heroCardName,
    super.key,
  });

  /// "Get started".
  final FutureOr<void> Function() onGetStarted;

  /// The localised name of the hero card (The Star); none while loading.
  final String? heroCardName;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return OnboardingPage(
      content: [
        WelcomeHero(cardName: heroCardName),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.space.s4,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.welcomeTitle, style: tokens.typography.display),
            ),
            Text(
              l10n.welcomeLead,
              style: tokens.typography.body.copyWith(
                color: tokens.color.text.secondary,
              ),
            ),
          ],
        ),
        Semantics(
          container: true,
          explicitChildNodes: true,
          child: IconBulletList(
            items: [
              IconBulletItem(
                title: l10n.welcomeFeatureFreeReading,
                icon: Icons.schedule_outlined,
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
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s5,
        children: [
          TaroButton.primary(
            label: l10n.welcomeGetStarted,
            expand: true,
            onPressed: onGetStarted,
          ),
          Center(
            child: StepIndicator(
              current: 1,
              total: kOnboardingSteps,
              semanticsLabel: l10n.commonStepOf(1, kOnboardingSteps),
            ),
          ),
        ],
      ),
    );
  }
}

/// The decorative S02 hero: two card backs fanned behind The Star. The
/// cards deal in once on first paint (`motion.ritual.dealStagger`, each
/// `motion.duration.slow`, `motion.easing.emphasized`); with reduced motion
/// the hero is static. Above text scale 1.5 it shrinks to the single face
/// so "Get started" stays reachable (S02 *Text scale*). Excluded from
/// semantics; the fan mirrors in RTL, the face does not.
class WelcomeHero extends StatefulWidget {
  /// Creates the hero.
  const WelcomeHero({this.cardName, super.key});

  /// The localised name printed on the face.
  final String? cardName;

  /// The fan angle of each back card (radians).
  static const double fanAngle = math.pi / 14;

  /// The text scale above which only the face is shown.
  static const double singleCardTextScale = 1.5;

  @override
  State<WelcomeHero> createState() => _WelcomeHeroState();
}

class _WelcomeHeroState extends State<WelcomeHero>
    with SingleTickerProviderStateMixin {
  AnimationController? _deal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deal != null) return;
    final motion = context.tokens.motion;
    final controller = AnimationController(
      vsync: this,
      duration: motion.duration.slow + motion.ritual.dealStagger * 2,
    );
    _deal = controller;
    if (context.reduceMotion) {
      controller.value = 1;
    } else {
      unawaited(controller.forward());
    }
  }

  @override
  void dispose() {
    _deal?.dispose();
    super.dispose();
  }

  Widget _dealt(int index, Widget child) {
    final motion = context.tokens.motion;
    final total = _deal!.duration!.inMicroseconds;
    final start = (motion.ritual.dealStagger * index).inMicroseconds / total;
    final end = start + motion.duration.slow.inMicroseconds / total;
    final curve = CurvedAnimation(
      parent: _deal!,
      curve: Interval(start, math.min(end, 1), curve: motion.easing.emphasized),
    );
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = TaroCardSize.md.sizeOf(tokens);
    final single =
        MediaQuery.textScalerOf(context).scale(1) >
        WelcomeHero.singleCardTextScale;
    final face = _dealt(2, _HeroFace(name: widget.cardName));
    final offset = tokens.space.s11;
    Widget back(int index, double side) => _dealt(
      index,
      Transform.translate(
        offset: Offset(side * offset, tokens.space.s5),
        child: Transform.rotate(
          angle: side * WelcomeHero.fanAngle,
          child: const TaroCardBack(),
        ),
      ),
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final first = rtl ? 1.0 : -1.0;
    return ExcludeSemantics(
      child: SizedBox(
        height: card.height + tokens.space.s10,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!single) ...[back(0, first), back(1, -first)],
            face,
          ],
        ),
      ),
    );
  }
}

/// The Star as drawn on the S02 canvas: numeral, star and name inside an
/// ochre frame (the card art itself appears from S08 on).
class _HeroFace extends StatelessWidget {
  const _HeroFace({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final card = TaroCardSize.md.sizeOf(tokens);
    return Container(
      width: card.width,
      height: card.height,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.space.s2,
        vertical: tokens.space.s4,
      ),
      decoration: BoxDecoration(
        color: c.bg.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radius.card),
        border: Border.all(color: c.card.frame, width: TaroStrokes.focusRing),
        boxShadow: tokens.elevation.e2.shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            romanNumeral(kWelcomeHeroNumber),
            style: tokens.typography.numeral.copyWith(color: c.card.frame),
            textScaler: TextScaler.noScaling,
          ),
          TaroIcon(
            TaroIcons.majorStar,
            size: tokens.space.s10,
            color: c.card.frame,
          ),
          Text(
            name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: tokens.typography.caption.copyWith(color: c.text.primary),
          ),
        ],
      ),
    );
  }
}
