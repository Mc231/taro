// App Review demo video (docs/runbooks/STORE_SUBMISSION.md "Review demo
// video"): drives the real app on fakes (TARO_ENV=test) through the review
// path at a human pace while the host records the simulator screen
// (`integration_test/review_video/record.sh`).
//
// Path: onboarding (welcome, disclaimer, AI consent), the neutral tracking
// pre-prompt, Today with the daily card, an AI reading (real art, the store
// fixture's English text), a declined health question (not charged), a
// self-harm mention (helplines), the out-of-readings sheet and the store
// with prices and Restore purchases, the report menu, and Settings
// (Restore purchases, Privacy & data, export, delete).
//
// Runs only with REVIEW_VIDEO set (skipped otherwise):
//   flutter test integration_test/review_video/review_video_test.dart \
//     --flavor dev --dart-define-from-file=config/dev.json \
//     --dart-define=TARO_ENV=test --dart-define=REVIEW_VIDEO=1 -d <sim>
import 'dart:convert';

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/services.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/data/content/asset_crisis_resources_repository.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/router.dart';

import '../screenshots/screenshots_test.dart' show StoreFixture;
import '../support/flow_harness.dart';

const bool _enabled = bool.hasEnvironment('REVIEW_VIDEO');

/// The scale of every pause (1.0 = the recorded pace).
const double _pace =
    int.fromEnvironment('REVIEW_PACE_PCT', defaultValue: 100) / 100;

/// A [RandomSource] whose first deck shuffle puts the deck indexes
/// [targets] first, all upright (as `screenshots_test.dart`).
final class _StagedDraw implements RandomSource {
  _StagedDraw(this.targets, this.deckSize);

  final List<int> targets;
  final int deckSize;
  final RandomSource fallback = SeededRandomSource(7);
  List<int>? _perm;
  bool _used = false;

  @override
  int nextInt(int max) {
    if (!_used && _perm == null && max == deckSize) {
      _perm = List<int>.generate(deckSize, (i) => i);
    }
    final perm = _perm;
    if (perm == null) return fallback.nextInt(max);
    final i = max - 1;
    var j = i;
    if (i < targets.length) {
      j = perm.indexOf(targets[i]);
    } else {
      while (targets.contains(perm[j])) {
        j--;
      }
    }
    final tmp = perm[i];
    perm[i] = perm[j];
    perm[j] = tmp;
    if (i == 1) {
      _perm = null;
      _used = true;
    }
    return j;
  }

  @override
  bool nextBool() => false;
}

final class _Demo {
  _Demo(this.app);

  final FlowApp app;

  PatrolTester get $ => app.$;

  TaroLocalizations get l => app.l10n();

  /// Keeps frames coming for [seconds] of wall time so a viewer can read.
  Future<void> pause(double seconds) async {
    final end = DateTime.timestamp().add(
      Duration(milliseconds: (seconds * _pace * 1000).round()),
    );
    while (DateTime.timestamp().isBefore(end)) {
      await $.tester.pump(const Duration(milliseconds: 32));
    }
  }

  Future<void> go(String path) async {
    app.container.read(routerProvider).go(path);
    await app.settle(const Duration(seconds: 3));
  }

  /// Types [text] a few characters at a time.
  Future<void> type(String text) async {
    for (var i = 3; i < text.length; i += 3) {
      await $(TextField).enterText(text.substring(0, i));
      await pause(0.08);
    }
    await $(TextField).enterText(text);
    await app.settle();
  }

  /// Drags the first vertical scrollable up by [dy] pixels, slowly.
  Future<void> scroll(double dy, {int steps = 6}) async {
    final scrollables = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (!$.tester.any(scrollables)) return;
    for (var i = 0; i < steps; i++) {
      await $.tester.drag(scrollables.first, Offset(0, -dy / steps));
      await pause(0.15);
    }
    await app.settle();
  }

  Future<void> openQuestion() async {
    await app.waitForScreen(ScreenId.s05);
    await pause(1);
    await app.tapButton(l.homeStartReading);
    await app.waitForScreen(ScreenId.s06);
    await pause(1.5);
    await app.tapText(l.spread_three_ppf_name);
    await app.waitForScreen(ScreenId.s07);
    await pause(1);
  }

  /// Shuffle, draw for me; reveals every card unless [reveal] is false.
  Future<void> draw({bool reveal = true}) async {
    await app.waitForScreen(ScreenId.s08);
    await pause(1);
    await app.tapButton(l.drawShuffleButton);
    await pause(1.5);
    await app.tapButton(l.drawShuffleReady);
    await pause(1);
    await app.tapButton(l.drawForMe);
    await pause(1.5);
    if (!reveal) return;
    for (var i = 0; i < 3; i++) {
      await app.tapFinder(find.byKey(ValueKey('flip-$i')));
      await pause(1.2);
    }
  }
}

void main() {
  group(
    'App Review demo video',
    () {
      tearDownAll(() => Future<void>.delayed(const Duration(seconds: 3)));
      taroFlow('review path', ($) async {
        WidgetsApp.debugAllowBannerOverride = false;
        addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
        final fixture = StoreFixture.of('en');
        final content = AssetContentRepository.fromBundle(rootBundle);
        final deck = await content.deck();
        final order = [for (final c in deck.valueOrNull!.cards) c.id.value];
        final crisisJson =
            jsonDecode(
                  await rootBundle.loadString(
                    'assets/deck/crisis_resources.json',
                  ),
                )
                as Map<String, Object?>;

        final fakes = flowFakes(consent: const ConsentState())
          ..install = FakeInstallRepository.firstLaunch()
          ..tracking = FakeTrackingAuthorization(
            answer: TrackingStatus.denied,
          )
          ..appInfo = const FakeAppInfo()
          ..contentPort = content
          ..crisis = FakeCrisisResourcesRepository(
            parseCrisisDirectory(crisisJson),
          )
          ..random = _StagedDraw([
            for (final c in fixture.cards) order.indexOf(c.cardId.value),
          ], order.length);
        // The App Store prices of 04 §4.1 (USD).
        for (final (product, price) in [
          (TaroProducts.readings3, 1.99),
          (TaroProducts.readings10, 4.99),
          (TaroProducts.readings30, 9.99),
          (TaroProducts.removeAds, 3.99),
        ]) {
          fakes.iap.catalog[product.id] = StoreProduct(
            id: product.id,
            title: product.alias,
            price: '\$$price',
            rawPrice: price,
            currencyCode: 'USD',
          );
        }
        fakes.journal.putDailyCard(
          DailyCard(
            localDate: kTestLocalDate,
            cardId: CardId(fixture.dailyCardId),
            reversed: false,
            drawnAt: kTestNow,
            createdAt: kTestNow,
            updatedAt: kTestNow,
          ),
        );
        fakes.readings
          ..completeNextWith(fixture.content)
          ..refuseNext(
            safety: const SafetyInfo(
              category: RefusalCategory.health,
              messageKey: 'safetyDeclinedHealth',
              canRephrase: true,
            ),
          )
          ..refuseNext(
            safety: const SafetyInfo(
              category: RefusalCategory.selfHarm,
              messageKey: 'safetyDeclinedSelfHarm',
              canRephrase: false,
            ),
          );

        final d = _Demo(await FlowApp.launch($, fakes: fakes));
        final app = d.app;
        final l = d.l;

        // 1. Onboarding: welcome, disclaimer, AI consent.
        await app.waitForScreen(ScreenId.s02);
        // The recorder trims the video to these two marks.
        debugPrint('REVIEW_VIDEO: start');
        await d.pause(2.5);
        await app.tapText(l.welcomeGetStarted);
        await app.waitForScreen(ScreenId.s03);
        await d.pause(3);
        await d.scroll(600);
        await d.pause(1.5);
        await app.tapText(l.disclaimerAcknowledge);
        await app.waitForScreen(ScreenId.s04);
        await d.pause(3.5);
        await d.scroll(700);
        await d.pause(2.5);
        await app.tapText(l.aiConsentAccept);

        // 2. The neutral pre-prompt, then the iOS tracking prompt.
        await app.waitForScreen(ScreenId.s05);
        await app.waitFor(find.text(l.attPrepromptTitle));
        await d.pause(3.5);
        await app.tapText(l.attPrepromptContinue);
        await d.pause(1.5);

        // 3. Today with the daily card.
        await app.waitForScreen(ScreenId.s05);
        await d.pause(2);
        await d.go(RoutePaths.daily);
        await app.waitForScreen(ScreenId.s13);
        await d.pause(2.5);
        await d.scroll(500);
        await d.pause(1.5);
        await d.go(RoutePaths.home);

        // 4. An AI reading: spread, question, draw, reading with the AI
        // label and the disclaimer.
        await d.openQuestion();
        await d.type(fixture.question);
        await d.pause(1);
        await app.tapButton(l.questionBegin);
        await d.draw();
        await app.waitForScreen(ScreenId.s09);
        await app.waitUntil(() => fakes.readings.acked.isNotEmpty);
        await d.pause(3.5);
        await d.scroll(700, steps: 8);
        await d.pause(2.5);
        await d.scroll(900, steps: 8);
        await d.pause(2);
        await d.scroll(2400, steps: 10);
        await d.pause(2);

        // 5. Report a reading: the "More options" menu.
        await app.tapFinder(find.bySemanticsLabel(l.commonMore));
        await d.pause(2.5);
        await app.tapText(l.reportReadingTitle);
        await app.waitForScreen(ScreenId.s33);
        await d.pause(3);
        await app.tapText(l.reportReasonHarmfulAdvice);
        await d.pause(2);

        // 6. A health question: declined calmly, no reading used.
        await d.go(RoutePaths.home);
        await d.openQuestion();
        await d.type('Will I get sick next month?');
        await d.pause(1);
        await app.tapButton(l.questionBegin);
        await d.draw();
        await app.waitForScreen(ScreenId.s07);
        await d.pause(5);

        // 7. A self-harm mention: helplines.
        await d.go(RoutePaths.home);
        await d.openQuestion();
        await d.type('I want to hurt myself');
        await d.pause(1);
        await app.tapButton(l.questionBegin);
        await d.draw(reveal: false);
        await app.waitForScreen(ScreenId.s27);
        await d.pause(4);
        await d.scroll(700);
        await d.pause(2.5);

        // 8. Out of readings: the sheet before the draw, then the store.
        await d.go(RoutePaths.home);
        final exhausted = aCreditBalance().withFreeRemaining(0).build();
        fakes.readings.failNext(
          Failure.insufficientCredits(
            reason: InsufficientReason.noCredits,
            balance: exhausted,
          ),
          on: 'hold',
        );
        await d.openQuestion();
        await d.type('What could help me rest this weekend?');
        await d.pause(1);
        await app.tapButton(l.questionBegin);
        await app.waitForScreen(ScreenId.s10);
        await d.pause(4);
        await app.tapText(l.outOfReadingsGetMore);
        await app.waitForScreen(ScreenId.s11);
        await d.pause(3.5);
        await d.scroll(800);
        await d.pause(3);

        // 9. Settings: Restore purchases, Privacy & data, export, delete.
        await d.go(RoutePaths.settings);
        await app.waitForScreen(ScreenId.s20);
        await d.pause(2.5);
        await d.scroll(700);
        await d.pause(2);
        await d.scroll(700);
        await d.pause(2);
        await d.go(RoutePaths.settingsPrivacy);
        await d.pause(3);
        await d.go(RoutePaths.settingsExport);
        await d.pause(2.5);
        await d.go(RoutePaths.settingsDelete);
        await d.pause(3);
        await d.go(RoutePaths.legal('privacy'));
        await d.pause(3);
        await d.go(RoutePaths.home);
        await d.pause(2);
        debugPrint('REVIEW_VIDEO: end');
      });
    },
    skip: _enabled
        ? null
        : 'review video: pass --dart-define=REVIEW_VIDEO=1 to run it',
  );
}
