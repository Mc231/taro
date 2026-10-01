import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/storage_error_app.dart';
import 'package:taro/common/onboarding_page.dart';
import 'package:taro/features/consent/view/att_preprompt_view.dart';
import 'package:taro/features/onboarding/controller/ai_consent_controller.dart';
import 'package:taro/features/onboarding/view/ai_consent_screen.dart';
import 'package:taro/features/onboarding/view/disclaimer_screen.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../../helpers/pump_taro_widget.dart';

/// Phase 16 Sprint 16.1: the designed S02–S04 and ATT pre-prompt layouts
/// (docs/design/screens/S02–S04): hero, notices, icon tiles, the re-entry
/// footnote, text scale 200 %, RTL and tap targets.
void noop() {}

void main() {
  late TaroLocalizations l10n;

  setUpAll(
    () async =>
        l10n = await TaroLocalizations.delegate.load(const Locale('en')),
  );

  const undecided = AiConsentState.undecided(
    origin: AiConsentOrigin.onboarding,
    version: 2,
  );

  Widget consent(AiConsentState state) => AiConsentLayout(
    state: state,
    onAllow: noop,
    onNotNow: noop,
    onBack: noop,
    onPrivacy: noop,
  );

  final layouts = <String, Widget Function()>{
    'S02': () => const WelcomeLayout(onGetStarted: noop, heroCardName: 'Star'),
    'S03': () => const DisclaimerLayout(
      acknowledged: false,
      onAcknowledge: noop,
      onReadFull: noop,
    ),
    'S04': () => consent(undecided),
    'ATT': () => const AttPrePromptLayout(onContinue: noop),
  };

  test('romanNumeral prints Major Arcana numbers', () {
    expect(romanNumeral(kWelcomeHeroNumber), 'XVII');
    expect(romanNumeral(4), 'IV');
    expect(romanNumeral(9), 'IX');
    expect(romanNumeral(21), 'XXI');
  });

  group('S02 hero', () {
    testWidgets('two backs fanned behind the face, excluded from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroWidget(tester, layouts['S02']!());
      expect(find.byType(TaroCardBack), findsNWidgets(2));
      expect(find.text('XVII'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);
      expect(find.bySemanticsLabel('XVII'), findsNothing);
      handle.dispose();
    });

    testWidgets('the fan mirrors in RTL', (tester) async {
      Future<double> firstBackX(Locale locale) async {
        await pumpTaroWidget(tester, layouts['S02']!(), locale: locale);
        return tester.getCenter(find.byType(TaroCardBack).first).dx;
      }

      final ltr = await firstBackX(const Locale('en'));
      final rtl = await firstBackX(const Locale('ar'));
      expect(ltr, lessThan(rtl));
    });

    testWidgets('above text scale 1.5 only the face is shown', (tester) async {
      await pumpTaroWidget(tester, layouts['S02']!(), textScale: 2);
      expect(find.byType(TaroCardBack), findsNothing);
      expect(find.text('XVII'), findsOneWidget);
    });

    testWidgets('without reduced motion the cards deal in', (tester) async {
      await pumpTaroWidget(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: const WelcomeHero(),
          ),
        ),
      );
      final fades = find.descendant(
        of: find.byType(WelcomeHero),
        matching: find.byType(FadeTransition),
      );
      expect(tester.widget<FadeTransition>(fades.last).opacity.value, 0);
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(fades.last).opacity.value, 1);
    });
  });

  group('S03 notices', () {
    testWidgets('three notice cards with the 05 §3 title and body', (
      tester,
    ) async {
      await pumpTaroWidget(tester, layouts['S03']!());
      expect(find.byType(DisclaimerNotice), findsNWidgets(3));
      expect(find.text(l10n.disclaimerNoticeYouDecide), findsOneWidget);
      expect(find.text(l10n.disclaimerNoticeSupport), findsOneWidget);
    });
  });

  group('S04', () {
    testWidgets('onboarding: icon tile, the full body and the footnote', (
      tester,
    ) async {
      await pumpTaroWidget(tester, consent(undecided));
      expect(find.byType(OnboardingIconTile), findsOneWidget);
      expect(find.text(l10n.aiConsentFootnote), findsOneWidget);
      expect(find.text(l10n.aiConsentReentryFootnote), findsNothing);
      expect(l10n.aiConsentBody, contains('OpenAI'));
      expect(l10n.aiConsentBody, isNot(contains('Anthropic')));
    });

    testWidgets('re-entry: the Classic reading footnote and the app bar', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        consent(
          const AiConsentState.declined(origin: AiConsentOrigin.readingGate),
        ),
      );
      expect(find.text(l10n.aiConsentReentryFootnote), findsOneWidget);
      expect(find.text(l10n.aiConsentFootnote), findsNothing);
      expect(find.byType(TaroAppBar), findsOneWidget);
      expect(find.byType(StepIndicator), findsNothing);
    });
  });

  group('ATT pre-prompt', () {
    testWidgets('one Continue, the three sections and the footnote', (
      tester,
    ) async {
      await pumpTaroWidget(tester, layouts['ATT']!());
      expect(find.byType(OnboardingIconTile), findsOneWidget);
      expect(find.byType(TaroButton), findsOneWidget);
      expect(find.text(l10n.attPrepromptFootnote), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  for (final MapEntry(key: name, value: build) in layouts.entries) {
    group(name, () {
      testWidgets('text scale 2.0 scrolls without overflow', (tester) async {
        await pumpTaroWidget(tester, build(), textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('Arabic renders right to left without overflow', (
        tester,
      ) async {
        await pumpTaroWidget(tester, build(), locale: const Locale('ar'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('tablet: the column is capped at layout.maxContentWidth', (
        tester,
      ) async {
        await pumpTaroWidget(tester, build(), size: const Size(1032, 1376));
        final width = tester.getSize(find.byType(SingleChildScrollView)).width;
        final context = tester.element(find.byType(OnboardingPage));
        expect(width, lessThanOrEqualTo(context.tokens.layout.maxContentWidth));
      });

      testWidgets('meets the tap-target and labelled-tap guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpTaroWidget(tester, build());
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    });
  }

  group('S01 storageError', () {
    testWidgets('TaroErrorView(storage) with Try again and the address', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        StorageErrorApp(
          onRetry: () => retries++,
          supportEmail: 'support@example.com',
        ),
      );
      final view = tester.widget<TaroErrorView>(find.byType(TaroErrorView));
      expect(view.kind, TaroErrorKind.storage);
      expect(find.text(l10n.bootstrapContactSupport), findsOneWidget);
      expect(find.text('support@example.com'), findsOneWidget);
      await tester.tap(find.text(l10n.bootstrapRetry));
      expect(retries, 1);
    });
  });

  test('the hero card is The Star', () {
    expect(kWelcomeHeroCard, const CardId('major_17'));
  });
}
