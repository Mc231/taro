// QA screenshot tour (docs/qa/ANDROID_E2E_PLAN.md, method C): visits S01–S33
// and key states on fakes (TARO_ENV=test) and writes PNGs to the app cache
// dir (`<cache>/qa_shots/<mode>/<name>.png`), pulled with `adb run-as`.
//
// Runs only with QA_MODE set (skipped otherwise). Run one mode at a time:
//   flutter test integration_test/qa/screenshot_tour_test.dart --flavor dev \
//     --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test \
//     --dart-define=QA_MODE=en_light -d emulator-5554
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/rendering.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/router.dart';

import '../support/flow_harness.dart';

/// The tour runs only when a mode is given, so `melos run test:integration`
/// (every file under integration_test/) skips it.
const bool _tourEnabled = bool.hasEnvironment('QA_MODE');

const String _mode = String.fromEnvironment(
  'QA_MODE',
  defaultValue: 'en_light',
);

String get _locale => switch (_mode) {
  'ar' => 'ar',
  'de' => 'de',
  'ja' => 'ja',
  'uk' => 'uk',
  _ => 'en',
};

/// A question in the tour's locale (the UI language).
String get _question => switch (_locale) {
  'ar' => 'ما الذي يجب أن أنتبه إليه اليوم؟',
  'de' => 'Was soll ich heute beachten?',
  'ja' => '今日は何に気をつければいいですか？',
  'uk' => 'На що мені варто звернути увагу сьогодні?',
  _ => kTestQuestion,
};

ThemeMode get _theme => _mode == 'en_dark' ? ThemeMode.dark : ThemeMode.light;

double get _textScale => _mode == 'en_text200' ? 2.0 : 1.0;

/// Fakes for the tour in [_mode], on an Android device.
TaroFakes _fakes({ConsentState? consent}) {
  final f = flowFakes(consent: consent)
    ..appInfo = const FakeAppInfo(platform: AppPlatform.android)
    ..locale = _locale;
  f.journal.settings = UserSettings(
    themeMode: _theme,
    localeOverride: _locale == 'en' ? null : _locale,
  );
  return f;
}

/// The vertical scrollables on screen (page views and carousels excluded).
final Finder _vertical = find.byWidgetPredicate(
  (w) =>
      w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical,
);

final class _Tour {
  _Tour(this.app);

  final FlowApp app;

  PatrolTester get $ => app.$;

  TaroLocalizations get l => app.l10n(_locale);

  static Future<_Tour> launch(PatrolTester $, TaroFakes fakes) async {
    $.tester.platformDispatcher.localesTestValue = [Locale(_locale)];
    $.tester.platformDispatcher.textScaleFactorTestValue = _textScale;
    addTearDown($.tester.platformDispatcher.clearTextScaleFactorTestValue);
    return _Tour(await FlowApp.launch($, fakes: fakes));
  }

  Future<void> go(String path) async {
    app.container.read(routerProvider).go(path);
    await app.settle(const Duration(seconds: 3));
  }

  /// Captures the whole surface (overlays, sheets, dialogs included).
  Future<void> shot(String name, {bool settle = true}) async {
    if (settle) await app.settle();
    final binding = $.tester.binding;
    final view = binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final physical = view.flutterView.physicalSize;
    final image = await binding.runAsync(
      () => layer.toImage(Offset.zero & physical, pixelRatio: 0.5),
    );
    final bytes = await binding.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    final dir = Directory('${Directory.systemTemp.path}/qa_shots/$_mode')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(),
    );
    debugPrint('QA_SHOT: ${dir.path}/$name.png');
  }

  Future<void> tryShot(String name, Future<void> Function() steps) async {
    try {
      await steps();
      await shot(name);
    } on Object catch (e) {
      debugPrint('QA_SKIP: $_mode/$name: $e');
      await shot('${name}_FAILED');
    }
  }

  Future<void> scrollToEnd() async {
    final scrollables = _vertical;
    if (!$.tester.any(scrollables)) return;
    for (var i = 0; i < 6; i++) {
      await $.tester.drag(scrollables.first, const Offset(0, -600));
      await $.tester.pump(const Duration(milliseconds: 200));
    }
    await app.settle();
  }

  Future<void> draw({bool shots = true}) async {
    await app.waitForScreen(ScreenId.s08);
    if (shots) await shot('S08_shuffle');
    await app.tapButton(l.drawShuffleButton);
    if (shots) await shot('S08_shuffling');
    await app.tapButton(l.drawShuffleReady);
    if (shots) await shot('S08_pick');
    await app.tapButton(l.drawForMe);
    if (shots) await shot('S08_picked');
    await app.tapButton(l.drawRevealAll);
  }

  /// Taps [text]; at large text scales a wrapped label may not be
  /// hit-testable at its centre for the finder, so tap its centre directly.
  Future<void> tapLabel(String text) async {
    try {
      await app.tapText(text);
    } on Object {
      final f = find.text(text).first;
      await $.tester.ensureVisible(f);
      await app.settle();
      await $.tester.tapAt(
        $.tester.getCenter(f),
      );
      await app.settle();
    }
  }

  Future<void> openQuestion(String spreadName) async {
    await app.waitForScreen(ScreenId.s05);
    await app.tapButton(l.homeStartReading);
    await app.waitForScreen(ScreenId.s06);
    await tapLabel(spreadName);
    await app.waitForScreen(ScreenId.s07);
  }
}

void main() {
  group(
    'QA screenshot tour [$_mode]',
    () {
      // Leaves time for the host to pull the shots before the app is removed.
      tearDownAll(() => Future<void>.delayed(const Duration(seconds: 20)));
      taroFlow('[$_mode] onboarding S01–S05', ($) async {
        final fakes = _fakes(consent: const ConsentState())
          ..install = FakeInstallRepository.firstLaunch();
        final t = await _Tour.launch($, fakes);
        await t.shot('S01_launch', settle: false);
        final app = t.app;
        final l = t.l;
        await app.waitForScreen(ScreenId.s02);
        await t.shot('S02_welcome_1');
        final pages = find.byType(PageView);
        if ($.tester.any(pages)) {
          await $.tester.fling(pages.first, const Offset(-400, 0), 1000);
          await app.settle();
          await t.shot('S02_welcome_2');
          await $.tester.fling(pages.first, const Offset(-400, 0), 1000);
          await app.settle();
          await t.shot('S02_welcome_3');
        }
        await app.tapText(l.welcomeGetStarted);
        await app.waitForScreen(ScreenId.s03);
        await t.shot('S03_disclaimer');
        await t.scrollToEnd();
        await t.shot('S03_disclaimer_end');
        await app.tapText(l.disclaimerAcknowledge);
        await app.waitForScreen(ScreenId.s04);
        await t.shot('S04_ai_consent');
        await t.scrollToEnd();
        await t.shot('S04_ai_consent_end');
        await app.tapText(l.aiConsentAccept);
        await app.waitForScreen(ScreenId.s05);
        await t.shot('S05_home_first_run_coachmark');
      });

      taroFlow('[$_mode] main tour S05–S29, S33', ($) async {
        final fakes = _fakes();
        final t = await _Tour.launch($, fakes);
        final app = t.app;
        final l = t.l;
        await app.waitForScreen(ScreenId.s05);
        await t.shot('S05_home_empty');

        await app.tapButton(l.homeStartReading);
        await app.waitForScreen(ScreenId.s06);
        await t.shot('S06_spreads');
        await t.scrollToEnd();
        await t.shot('S06_spreads_end');
        await t.tapLabel(l.spread_three_ppf_name);
        await app.waitForScreen(ScreenId.s07);
        await t.shot('S07_question_empty');
        await app.enterQuestion(_question);
        await t.shot('S07_question_filled');
        await app.tapButton(l.questionBegin);
        await t.draw();
        await app.waitForScreen(ScreenId.s09);
        await app.waitUntil(() => fakes.readings.acked.isNotEmpty);
        await app.settle();
        await t.shot('S09_result_top');
        await t.tryShot('S09_result_mid', () async {
          await $.tester.drag(_vertical.first, const Offset(0, -700));
          await app.settle();
        });
        await t.tryShot('S09_result_footer', t.scrollToEnd);

        await t.tryShot('S09_menu', () async {
          await app.tapFinder(find.bySemanticsLabel(l.commonMore));
        });
        await t.tryShot('S33_report', () async {
          await app.tapText(l.reportReadingTitle);
          await app.waitForScreen(ScreenId.s33);
        });
        await t.tryShot('S33_report_selected', () async {
          await app.tapText(l.reportReasonHarmfulAdvice);
        });
        final id = fakes.journal.readings.values.single.id;

        await t.go(RoutePaths.home);
        await app.waitForScreen(ScreenId.s05);
        await t.shot('S05_home_with_reading');

        await t.tryShot('S13_daily', () => t.go(RoutePaths.daily));
        await t.tryShot('S13_daily_revealed', () async {
          await $.tester.tapAt($.tester.getCenter(t.app.screen(ScreenId.s13)));
          await app.settle(const Duration(seconds: 3));
        });
        await t.tryShot('S13_daily_end', t.scrollToEnd);

        await t.tryShot('S14_journal', () => t.go(RoutePaths.journal));
        await t.tryShot(
          'S15_entry',
          () => t.go(RoutePaths.journalEntry(id.value)),
        );
        await t.tryShot('S15_entry_end', t.scrollToEnd);

        await t.tryShot('S16_learn', () => t.go(RoutePaths.learn));
        await t.tryShot('S16_learn_end', t.scrollToEnd);
        await t.tryShot(
          'S17_card',
          () => t.go(RoutePaths.learnCard('major_17')),
        );
        await t.tryShot('S17_card_end', t.scrollToEnd);
        await t.tryShot(
          'S18_spreads_guide',
          () => t.go(RoutePaths.learnSpreads),
        );
        await t.tryShot(
          'S18_spread_celtic',
          () => t.go(RoutePaths.learnSpread('celtic_cross')),
        );
        await t.tryShot('S18_spread_celtic_end', t.scrollToEnd);
        await t.tryShot('S19_about', () => t.go(RoutePaths.learnAbout));
        await t.tryShot('S19_about_end', t.scrollToEnd);

        await t.tryShot('S20_settings', () => t.go(RoutePaths.settings));
        await t.tryShot('S20_settings_end', t.scrollToEnd);
        await t.tryShot(
          'S21_language',
          () => t.go(RoutePaths.settingsLanguage),
        );
        await t.tryShot(
          'S22_reminder',
          () => t.go(RoutePaths.settingsReminder),
        );
        await t.tryShot('S23_privacy', () => t.go(RoutePaths.settingsPrivacy));
        await t.tryShot('S23_privacy_end', t.scrollToEnd);
        await t.tryShot('S24_export', () => t.go(RoutePaths.settingsExport));
        await t.tryShot('S25_import', () => t.go(RoutePaths.settingsImport));
        await t.tryShot('S26_delete', () => t.go(RoutePaths.settingsDelete));
        await t.tryShot('S27_crisis', () => t.go(RoutePaths.helpCrisis));
        await t.tryShot('S27_crisis_end', t.scrollToEnd);
        await t.tryShot('S28_help', () => t.go(RoutePaths.help));
        await t.tryShot('S28_help_end', t.scrollToEnd);
        await t.tryShot(
          'S29_legal_disclaimer',
          () => t.go(RoutePaths.legal('disclaimer')),
        );
        await t.tryShot(
          'S29_legal_privacy',
          () => t.go(RoutePaths.legal('privacy')),
        );
        await t.tryShot(
          'S29_legal_terms',
          () => t.go(RoutePaths.legal('terms')),
        );
      });

      taroFlow('[$_mode] paywall S10–S12', ($) async {
        final exhausted = aCreditBalance().withFreeRemaining(0).build();
        final granted = aCreditBalance()
            .withFreeRemaining(0)
            .withBonus(1)
            .withRewarded(
              grantedToday: 1,
              cooldownEndsAt: kTestNow.add(const Duration(minutes: 5)),
            )
            .withLedgerVersion(3)
            .build();
        final fakes = _fakes()
          ..balance = FakeBalanceRepository(
            cached: exhausted,
            server: exhausted,
          )
          ..verifier = FakePurchaseVerifier(balance: exhausted)
          ..ads.autoResult = RewardedShowResult.earned;
        fakes.rewards
          ..autoGrant = true
          ..grantBalance = granted;
        fakes.readings.failNext(
          Failure.insufficientCredits(
            reason: InsufficientReason.noCredits,
            balance: exhausted,
          ),
          on: 'hold',
        );
        final t = await _Tour.launch($, fakes);
        final app = t.app;
        final l = t.l;
        await t.openQuestion(l.spread_three_ppf_name);
        await app.enterQuestion(kTestQuestion);
        await app.tapButton(l.questionBegin);
        await app.waitForScreen(ScreenId.s10);
        await t.shot('S10_out_of_readings');
        await app.tapText(l.outOfReadingsGetMore);
        await app.waitForScreen(ScreenId.s11);
        await t.shot('S11_store');
        await t.scrollToEnd();
        await t.shot('S11_store_end');
        await t.tryShot('S12_rewarded', () async {
          await t.tapLabel(l.rewardedOfferTitle(1));
          await app.waitForScreen(ScreenId.s12);
          await app.waitFor(find.text(l.rewardedGrantedTitle));
        });
        await t.tryShot('S11_store_balance_chip', () async {
          await t.go(RoutePaths.home);
          await app.waitForScreen(ScreenId.s05);
          await app.tapFinder(find.byType(BalanceChip));
          await app.waitForScreen(ScreenId.s11);
        });
      });

      taroFlow('[$_mode] paused S31 + classic S32', ($) async {
        final fakes = _fakes()
          ..config = FakeRemoteConfigRepository(
            aRemoteConfig().withReadingsEnabled(false).build(),
          );
        final t = await _Tour.launch($, fakes);
        final app = t.app;
        final l = t.l;
        await t.openQuestion(l.spread_three_ppf_name);
        await app.enterQuestion(kTestQuestion);
        await app.tapButton(l.questionBegin);
        await app.$(find.text(l.pausedTitle)).waitUntilExists();
        await $.tester.ensureVisible(find.text(l.pausedTitle));
        await t.shot('S31_paused');
        await app.tapButton(l.questionTryClassic);
        await t.draw(shots: false);
        await app.waitForScreen(ScreenId.s32);
        await t.shot('S32_classic_top');
        await t.tryShot('S32_classic_footer', t.scrollToEnd);
      });

      taroFlow('[$_mode] AI declined re-entry S04 + celtic cross', ($) async {
        final fakes = _fakes(consent: onboardedConsent(aiGranted: false));
        final t = await _Tour.launch($, fakes);
        final app = t.app;
        final l = t.l;
        await t.openQuestion(l.spread_celtic_cross_name);
        await t.shot('S07_celtic_question');
        await app.enterQuestion(kTestQuestion);
        await app.tapButton(l.questionBegin);
        await app.waitForScreen(ScreenId.s04);
        await t.shot('S04_reentry');
        await app.tapButton(l.aiConsentReentryBack);
        await app.waitForScreen(ScreenId.s07);
        await t.shot('S07_after_decline');
        await app.tapButton(l.questionTryClassic);
        await app.waitForScreen(ScreenId.s08);
        await app.tapButton(l.drawShuffleButton);
        await app.tapButton(l.drawShuffleReady);
        await app.tapButton(l.drawForMe);
        await t.shot('S08_celtic_picked');
        await app.tapButton(l.drawRevealAll);
        await app.waitForScreen(ScreenId.s32);
        await t.shot('S32_celtic_top');
      });

      taroFlow('[$_mode] refusal S07 (rephrase + refused)', ($) async {
        final fakes = _fakes();
        fakes.readings
          ..refuseNext(
            safety: const SafetyInfo(
              category: RefusalCategory.gambling,
              messageKey: 'safetyDeclinedGambling',
              canRephrase: true,
            ),
          )
          ..refuseNext(
            safety: const SafetyInfo(
              category: RefusalCategory.sexualMinors,
              messageKey: 'safetyDeclinedSexualMinors',
              canRephrase: false,
            ),
          );
        final t = await _Tour.launch($, fakes);
        final app = t.app;
        final l = t.l;
        await t.openQuestion(l.spread_three_ppf_name);
        await app.enterQuestion(_question);
        await app.tapButton(l.questionBegin);
        await t.draw(shots: false);
        await app.waitForScreen(ScreenId.s07);
        await app.settle(const Duration(seconds: 3));
        await t.shot('S07_refusal_rephrase');
        await t.tryShot('S07_refusal_rephrase_end', t.scrollToEnd);

        await t.go(RoutePaths.home);
        await t.openQuestion(l.spread_three_ppf_name);
        await app.enterQuestion(_question);
        await app.tapButton(l.questionBegin);
        await t.draw(shots: false);
        await app.waitForScreen(ScreenId.s07);
        await app.settle(const Duration(seconds: 3));
        await t.shot('S07_refusal_refused');
        await t.tryShot('S07_refusal_refused_end', t.scrollToEnd);
      });

      taroFlow('[$_mode] update required S30', ($) async {
        final fakes = _fakes()
          ..config = FakeRemoteConfigRepository(
            aRemoteConfig().build().copyWith(
              appMinVersionAndroid: '99.0.0',
              appMinVersionIos: '99.0.0',
            ),
          );
        final t = await _Tour.launch($, fakes);
        await t.app.waitForScreen(ScreenId.s30);
        await t.shot('S30_update_required');
      });
    },
    skip: _tourEnabled
        ? null
        : 'QA screenshot tour: pass --dart-define=QA_MODE=<mode> to run it',
  );
}
