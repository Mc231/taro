import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/features/paywall/view/out_of_readings_screen.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';

import '../skeleton_support.dart';

/// Regression (found by `integration_test/flows/hold_lost_test.dart`): a
/// rewarded grant resolves S10 while S12 is still on top. S10 used to pop
/// the top route, closing S12 before "Reading added" was seen and leaving
/// an empty S10 sheet behind. Now S12 stays until Continue, then S10
/// closes with `true`.
void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  testWidgets('S10 resolved under S12: S12 stays, then S10 closes', (
    tester,
  ) async {
    final fakes = TaroFakes(
      consent: const ConsentState(
        onboardingStep: OnboardingStep.done,
        ads: AdsConsent(
          status: AdsConsentStatus.notRequired,
          canRequestAds: true,
        ),
      ),
    );
    fakes.balance.seed(
      aCreditBalance()
          .withFreeRemaining(0)
          .withRewarded(available: true)
          .build(),
    );
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards
      ..autoGrant = true
      ..grantBalance = aCreditBalance()
          .withFreeRemaining(0)
          .withBonus(1)
          .withLedgerVersion(2)
          .build();
    Object? result = 'unset';
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(
              TaroModals.outOfReadings<bool>(
                context,
              ).then((value) => result = value),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      fakes: fakes,
      overrides: [rewardedPollDelayProvider.overrideWithValue((_) async {})],
    );

    await tapText(tester, 'open');
    await tapText(tester, l10n.rewardedOfferTitle(1));
    await tester.pumpAndSettle();
    // Granted: the balance can read, S10 is resolved, S12 is still up.
    expect(fakes.balance.cached?.bonus, 1);
    expect(find.byType(RewardedScreen), findsOneWidget);
    expect(find.text(l10n.rewardedGrantedTitle), findsOneWidget);
    expect(find.byType(OutOfReadingsScreen), findsOneWidget);
    expect(result, 'unset');

    await tapText(tester, l10n.commonContinue);
    await tester.pumpAndSettle();
    expect(find.byType(RewardedScreen), findsNothing);
    expect(find.byType(OutOfReadingsScreen), findsNothing);
    expect(result, isTrue);
  });
}
