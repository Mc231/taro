import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/features/paywall/view/out_of_readings_screen.dart';
import 'package:taro/features/paywall/view/rewarded_screen.dart';
import 'package:taro/features/reading/view/question_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../flow_view_support.dart';

/// 01 §9.4, RC58, 05 3.1.1: after a grant opened from the gate, S07 shows
/// the same question with **Begin** enabled; nothing auto-starts.
void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  testWidgets('a rewarded grant from the gate returns to S07 with the same '
      'question; the user taps Begin again', (tester) async {
    final empty = aCreditBalance()
        .withFreeRemaining(0)
        .withRewarded(available: true)
        .build();
    final fakes = TaroFakes(
      consent: kAiGranted.copyWith(
        ads: const AdsConsent(
          status: AdsConsentStatus.notRequired,
          canRequestAds: true,
        ),
      ),
    )..balance = FakeBalanceRepository(cached: empty, server: empty);
    fakes.ads.autoResult = RewardedShowResult.earned;
    fakes.rewards.autoGrant = true;
    await pumpFlow(
      tester,
      path: RoutePaths.readingQuestionPath,
      location: RoutePaths.readingQuestion('three_ppf'),
      builder: (state) => QuestionScreen.fromQuery(state.uri.queryParameters),
      fakes: fakes,
      overrides: [rewardedPollDelayProvider.overrideWithValue((_) async {})],
    );
    const question = 'What helps me now?';
    await tester.enterText(find.byType(TextField), question);
    await tester.pump();
    await tapFound(tester, find.text(l10n.questionBegin));

    // The paywall opens before any hold or draw (MO13).
    expect(find.byType(OutOfReadingsScreen), findsOneWidget);
    expect(fakes.readings.holds, isEmpty);
    expect(fakes.ads.shown, isEmpty, reason: 'never auto-shown');

    await tapText(tester, l10n.rewardedOfferTitle(1));
    await tester.pumpAndSettle();
    expect(find.byType(RewardedScreen), findsOneWidget);
    expect(find.text(l10n.rewardedGrantedTitle), findsOneWidget);
    // The Worker's balance now has the earned reading.
    fakes.balance.seed(
      aCreditBalance().withFreeRemaining(0).withBonus(1).build(),
    );
    await tapText(tester, l10n.commonContinue);
    await tester.pumpAndSettle();

    expect(find.byType(RewardedScreen), findsNothing);
    expect(find.byType(OutOfReadingsScreen), findsNothing);
    expect(find.widgetWithText(TextField, question), findsOneWidget);
    expect(find.byType(QuestionScreen), findsOneWidget);
    expect(find.text('route:${RoutePaths.readingDraw}'), findsNothing);
    // Nothing auto-started: no hold, no draw; Begin is enabled.
    expect(fakes.readings.holds, isEmpty);
    final begin = tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.questionBegin),
    );
    expect(begin.onPressed, isNotNull);
    expect(begin.loading, isFalse);
  });
}
