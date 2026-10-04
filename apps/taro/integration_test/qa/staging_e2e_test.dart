import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/firebase_options_staging.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/router.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../support/staging_gate.dart';

/// QA method B (docs/qa/ANDROID_E2E_PLAN.md): the real `staging`
/// composition root against the staging Worker, driven through the UI.
///
/// `flutter test` uninstalls the app after every run, so the cases that
/// share state run in ONE invocation, in file order. Android counts the free
/// reading per device and local day (RC53), so a reinstall does not give a
/// new free reading: B3-B6 need a reading available (the day's free one or
/// a rewarded grant). Host-side steps (airplane mode, closing the native
/// rewarded ad and the share sheet) are requested with `QA_HOST:` lines that
/// `run_staging_e2e.sh` acts on:
///
/// ```sh
/// apps/taro/integration_test/qa/run_staging_e2e.sh ALL '^B[1-7] ' fresh
/// apps/taro/integration_test/qa/run_staging_e2e.sh B8 '^B8 ' unverified
/// ```
///
/// Gated by `TARO_STAGING_SMOKE` (1/true/yes; an unknown value throws,
/// [stagingSmokeEnabled]) and the debug attestation token.
final bool _enabled = stagingSmokeEnabled;

/// `TARO_QA_UNVERIFIED=true`: B4 runs without the debug attestation token.
const bool _unverified = bool.fromEnvironment('TARO_QA_UNVERIFIED');

const PatrolTesterConfig _config = PatrolTesterConfig(
  existsTimeout: Duration(seconds: 45),
  visibleTimeout: Duration(seconds: 45),
  settleTimeout: Duration(seconds: 5),
);

void _log(String m) => debugPrint('QA: $m');

/// Asks the host watcher to do [action] (offline, online, closead, back).
void _host(String action) => debugPrint('QA_HOST: $action');

/// The staging environment with a captured `runApp` (the test pumps the
/// app) and the test binding's error handlers kept.
final class _StagingEnv implements TaroEnvironment {
  _StagingEnv()
    : _inner = ProductionEnvironment(
        Flavor.staging,
        firebaseOptions: () => DefaultFirebaseOptions.currentPlatform,
        hooks: PlatformHooks(
          runApp: (w) => app = w,
          deviceLocales: () => const [Locale('en')],
        ),
      );

  final ProductionEnvironment _inner;
  static Widget? app;

  @override
  FlavorConfig get flavor => _inner.flavor;
  @override
  Future<void> initFirebase() => _inner.initFirebase();
  @override
  Future<TaroDatabases> openDatabases() => _inner.openDatabases();
  @override
  SecureStore get secureStore => _inner.secureStore;
  @override
  Future<List<Override>> buildOverrides(
    FlavorConfig flavor,
    TaroDatabases dbs,
  ) => _inner.buildOverrides(flavor, dbs);
  @override
  void installErrorHandlers(CrashReporter crash) {}
  @override
  void runApp(Widget app) => _inner.runApp(app);
}

final class _App {
  _App(this.$, this.container);
  final PatrolTester $;
  final ProviderContainer container;
  final Map<String, int> timings = {};
  final List<String> bugs = [];

  TaroLocalizations l10n([String locale = 'en']) =>
      lookupTaroLocalizations(Locale(locale));

  Finder screen(ScreenId id) => find.byKey(ValueKey(id));

  List<String> texts() => [
    for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
    for (final e in find.byType(RichText).evaluate())
      (e.widget as RichText).text.toPlainText(),
  ];

  bool onScreen(ScreenId id) => $.tester.any(screen(id));

  Future<void> settle([Duration max = const Duration(seconds: 2)]) => $.tester
      .pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        max,
      )
      .catchError((Object _) => 0);

  Future<void> waitUntil(
    bool Function() condition, {
    required String reason,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final end = DateTime.timestamp().add(timeout);
    while (!condition()) {
      if (DateTime.timestamp().isAfter(end)) {
        fail('timed out: $reason; on screen: ${texts().take(40).join(' | ')}');
      }
      await $.tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitForScreen(ScreenId id, {Duration? timeout}) async {
    _log('wait $id');
    await waitUntil(
      () => onScreen(id),
      timeout: timeout ?? const Duration(seconds: 60),
      reason: '$id',
    );
    await settle();
  }

  Future<void> waitText(String text, {Duration? timeout}) => waitUntil(
    () => $.tester.any(find.textContaining(text)),
    timeout: timeout ?? const Duration(seconds: 60),
    reason: 'text "$text"',
  );

  Future<void> tap(Finder finder) async {
    _log('tap ${finder.toString(describeSelf: true)}');
    for (var i = 0; i < 100 && !$.tester.any(finder); i++) {
      await $.tester.pump(const Duration(milliseconds: 100));
    }
    if (!$.tester.any(finder.hitTestable())) await $(finder).scrollTo();
    await $(finder).tap();
    await settle();
  }

  /// Router jump to Home (system back is covered by the A flows).
  Future<void> goHome() async {
    container.read(routerProvider).go(RoutePaths.home);
    await waitForScreen(ScreenId.s05);
  }

  /// Started when the last draw action is tapped (submit time).
  final Stopwatch sinceDraw = Stopwatch();

  /// Scrolls S09 down until the disclaimer footer is built.
  Future<void> scrollToFooter() async {
    for (
      var i = 0;
      i < 40 && !$.tester.any(find.byType(DisclaimerFooter));
      i++
    ) {
      final scrollables = find.byType(Scrollable).hitTestable();
      if (!$.tester.any(scrollables)) break;
      await $.tester.drag(scrollables.first, const Offset(0, -500));
      await $.tester.pump(const Duration(milliseconds: 200));
    }
    if (!$.tester.any(find.byType(DisclaimerFooter))) {
      bugs.add(
        'S09: no DisclaimerFooter after scrolling to the end; '
        'texts: ${texts().take(30).join(' | ')}',
      );
      _log('BUG ${bugs.last}');
    } else {
      _log('S09 footer: ${texts().reversed.take(6).join(' | ')}');
    }
  }

  /// Records the time since "Draw for me" under [label].
  void markSinceDraw(String label) {
    timings[label] = sinceDraw.elapsedMilliseconds;
    _log('TIMING $label=${sinceDraw.elapsedMilliseconds}ms');
  }

  Future<void> tapText(String t) => tap(find.text(t));
  Future<void> tapButton(String t) => tap(find.widgetWithText(TaroButton, t));

  CreditBalance? get balance =>
      container.read(balanceRepositoryProvider).cached;

  Future<List<Reading>> readings() async =>
      (await container.read(journalRepositoryProvider).snapshot())
          .valueOrNull
          ?.readings ??
      const [];

  /// Times [body] in ms under [label].
  Future<T> time<T>(String label, Future<T> Function() body) async {
    final sw = Stopwatch()..start();
    final r = await body();
    timings[label] = sw.elapsedMilliseconds;
    _log('TIMING $label=${sw.elapsedMilliseconds}ms');
    return r;
  }

  // -------------------------------------------------------------------
  // Steps.

  /// F1: S02 → S03 → S04 (accept) → S05.
  Future<void> onboard() async {
    final l = l10n();
    await waitUntil(
      () => onScreen(ScreenId.s02) || onScreen(ScreenId.s05),
      reason: 'S02 (fresh) or S05 (onboarded)',
    );
    if (onScreen(ScreenId.s05)) {
      _log('already onboarded');
      if (!$.tester.any(find.text(l.tabSettings))) await switchLanguage('en');
      return;
    }
    await waitForScreen(ScreenId.s02);
    await tapText(l.welcomeGetStarted);
    await waitForScreen(ScreenId.s03);
    await tapText(l.disclaimerAcknowledge);
    await waitForScreen(ScreenId.s04);
    await tapText(l.aiConsentAccept);
    final sw = Stopwatch()..start();
    while (!onScreen(ScreenId.s05) && sw.elapsed.inSeconds < 20) {
      await $.tester.pump(const Duration(milliseconds: 100));
    }
    if (!onScreen(ScreenId.s05)) {
      final router = container.read(routerProvider);
      final c = container.read(consentStoreProvider).current;
      final loc = router.routerDelegate.currentConfiguration.uri;
      bugs.add(
        'S04 stuck after "Allow AI readings": location=$loc '
        'step=${c.onboardingStep} ai=${c.ai.decision}',
      );
      _log('BUG ${bugs.last}');
      // Workaround to keep testing the rest: navigate Home ourselves.
      router.go(RoutePaths.home);
    }
    await waitForScreen(ScreenId.s05);
    // S04 goes Home once the step left aiConsent; UMP and ATT then finish
    // onboarding in the background. Wait for it, so a case never ends (and
    // the container is disposed) while that is still writing.
    await waitUntil(
      () =>
          container.read(consentStoreProvider).current.onboardingStep ==
          OnboardingStep.done,
      reason: 'onboarding finished (UMP, ATT, step done)',
    );
  }

  /// Waits until the install is registered and the balance synced.
  /// B3–B6 each need a reading. Android allows one free AI reading per
  /// device and local day (RC53) and the sample rewarded ad sends no SSV, so
  /// when none is left the host grants staging bonus credits to this
  /// install (`QA_HOST: grant <supportId>`, `run_staging_e2e.sh` with
  /// `QA_GRANT=1`) and the balance is synced until it can read.
  Future<void> ensureReading() async {
    if (balance?.canRead ?? false) return;
    final identity = await container
        .read(installRepositoryProvider)
        .getOrCreate();
    _host('grant ${supportIdOf(identity.valueOrNull!.installId)}');
    final repo = container.read(balanceRepositoryProvider);
    for (var i = 0; i < 30 && !(balance?.canRead ?? false); i++) {
      await $.tester.pump(const Duration(seconds: 4));
      await repo.sync(reason: SyncReason.manual);
    }
    _log('balance after grant: $balance');
  }

  Future<void> waitRegistered() => time(
    'register+balance',
    () => waitUntil(
      () => balance != null,
      timeout: const Duration(seconds: 90),
      reason: 'balance synced from the Worker',
    ),
  );

  Future<void> openQuestion(String spreadName, [String loc = 'en']) async {
    final l = l10n(loc);
    if (!onScreen(ScreenId.s05)) await tapText(l.tabToday);
    await waitForScreen(ScreenId.s05);
    await tapButton(l.homeStartReading);
    await waitForScreen(ScreenId.s06);
    await tapText(spreadName);
    await waitForScreen(ScreenId.s07);
  }

  Future<void> begin(String question, [String loc = 'en']) async {
    await $(TextField).enterText(question);
    await settle();
    await tapButton(l10n(loc).questionBegin);
  }

  /// S08 → S09; returns the stored reading (or the screen reached).
  Future<void> drawAll([String loc = 'en']) async {
    final l = l10n(loc);
    await time('hold (Begin→S08)', () => waitForScreen(ScreenId.s08));
    await tapButton(l.drawShuffleButton);
    await tapButton(l.drawShuffleReady);
    sinceDraw
      ..reset()
      ..start();
    await tapButton(l.drawForMe);
    if ($.tester.any(find.widgetWithText(TaroButton, l.drawRevealAll))) {
      await tapButton(l.drawRevealAll);
    }
  }

  /// Waits for a completed reading in the journal; returns it.
  Future<Reading> waitCompleted(
    String label, {
    required String question,
  }) async {
    final sw = Stopwatch()..start();
    Reading? done;
    while (done == null) {
      final all = await readings();
      final c = all.where(
        (r) => r.status is ReadingStatusComplete && r.question == question,
      );
      if (c.isNotEmpty) done = c.first;
      if (sw.elapsed > const Duration(seconds: 120)) {
        fail(
          'no completed reading; statuses: ${all.map((r) => r.status)}; '
          'screen: ${texts().take(40).join(' | ')}',
        );
      }
      await $.tester.pump(const Duration(milliseconds: 250));
    }
    markSinceDraw('$label (since Draw for me)');
    return done;
  }

  Future<void> switchLanguage(String code) async {
    // The previous case may have left another language on.
    final l =
        [
          for (final c in const ['en', 'ar', 'de']) l10n(c),
        ].firstWhere(
          (x) => $.tester.any(find.text(x.tabSettings)),
          orElse: l10n,
        );
    await tapText(l.tabSettings);
    await waitForScreen(ScreenId.s20);
    await tapText(l.settingsLanguage);
    await waitForScreen(ScreenId.s21);
    await tap(find.byKey(ValueKey(code)));
    await settle();
    final t = l10n(code);
    await tap(find.bySemanticsLabel(t.commonBack));
    await waitForScreen(ScreenId.s20);
    await tapText(t.tabToday);
    await waitForScreen(ScreenId.s05);
  }
}

Future<_App> _launch(PatrolTester $) async {
  final env = _StagingEnv();
  final container = await bootstrap(env);
  expect(container, isNotNull, reason: 'bootstrap failed');
  addTearDown(container!.dispose);
  await $.tester.pumpWidget(_StagingEnv.app!);
  await $.pump();
  return _App($, container);
}

void _case(
  String name,
  Future<void> Function(_App app) body, {
  bool needsToken = true,
}) {
  final skip =
      !_enabled ||
      (needsToken
          ? BuildDefines.debugAttestationToken.isEmpty || _unverified
          : !_unverified);
  patrolWidgetTest(name, config: _config, skip: skip, ($) async {
    $.tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown($.tester.platformDispatcher.clearLocalesTestValue);
    final app = await _launch($);
    try {
      await body(app);
      expect(app.bugs, isEmpty, reason: 'app bugs found on the way');
    } finally {
      _log('TIMINGS ${jsonEncode(app.timings)}');
      _log('BUGS ${jsonEncode(app.bugs)}');
    }
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // ONB-01, ONB-04, HOME-01. Run on a fresh install.
  _case('B1 onboarding and registration', (app) async {
    await app.onboard();
    await app.waitRegistered();
    await app.waitUntil(
      () => app.$.tester.any(find.byType(BalanceChip)),
      reason: 'balance chip',
    );
    _log('balance: ${app.balance}');
    _log('S05: ${app.texts().take(8).join(' | ')}');
  });

  // PAY-01 + RW-01: with no reading left, Begin opens S10 before any
  // draw; then a Google test rewarded ad (the host closes it).
  _case('B2 paywall and rewarded ad', (app) async {
    final l = app.l10n();
    await app.onboard();
    await app.waitRegistered();
    _log('balance before: ${app.balance}');
    if (!app.balance!.canRead) {
      await app.openQuestion(l.spread_single_name);
      await app.begin('And what about next week?');
      await app.time(
        'paywall (Begin→S10)',
        () => app.waitForScreen(ScreenId.s10),
      );
      expect(app.onScreen(ScreenId.s08), isFalse, reason: 'no draw');
      _log('S10: ${app.texts().take(30).join(' | ')}');
    } else {
      _log('a reading is available: S10 not reachable, rewarded via S11');
      await app.tap(find.byType(BalanceChip));
      await app.waitForScreen(ScreenId.s11);
    }
    final offer = find.textContaining(l.rewardedOfferTitle(1));
    if (!app.$.tester.any(offer)) {
      await app.tapText(l.outOfReadingsGetMore);
      await app.waitForScreen(ScreenId.s11);
    }
    final bonusBefore = app.balance!.bonus;
    await app.tap(offer.first);
    await app.waitForScreen(ScreenId.s12);
    _host('closead');
    await app.time(
      'rewarded outcome',
      () => app.waitUntil(
        () => [
          l.rewardedGrantedTitle,
          l.rewardedGrantDelayed,
          l.rewardedDismissedEarly,
          l.rewardedNoFill,
        ].any((t) => app.$.tester.any(find.textContaining(t))),
        timeout: const Duration(seconds: 180),
        reason: 'rewarded outcome',
      ),
    );
    _log('S12 outcome: ${app.texts().take(20).join(' | ')}');
    await app.container
        .read(balanceRepositoryProvider)
        .sync(reason: SyncReason.manual);
    _log('balance after rewarded: ${app.balance}');
    expect(
      app.$.tester.any(find.textContaining(l.rewardedGrantedTitle)) ||
          app.$.tester.any(find.textContaining(l.rewardedGrantDelayed)),
      isTrue,
      reason: 'granted (or delayed when the sample ad sends no SSV)',
    );
    if (app.$.tester.any(find.textContaining(l.rewardedGrantedTitle))) {
      expect(app.balance!.bonus, bonusBefore + 1);
    }
  });

  // RD-11 + RD-12: refusal and crisis, nothing spent. Needs a reading.
  _case('B3 safety: rephrase and crisis', (app) async {
    final l = app.l10n();
    await app.onboard();
    await app.waitRegistered();
    await app.ensureReading();
    final before = app.balance!;
    _log('balance before: $before');
    expect(before.canRead, isTrue, reason: 'needs one reading available');

    const lottery = 'Will I win the lottery next week?';
    await app.openQuestion(l.spread_three_ppf_name);
    await app.begin(lottery);
    await app.drawAll();
    await app.waitUntil(
      () =>
          app.onScreen(ScreenId.s07) &&
          app.$.tester.any(find.textContaining(l.questionRefusalTitle)),
      timeout: const Duration(seconds: 120),
      reason: 'back on S07 with the refusal',
    );
    app.markSinceDraw('refusal shown (since Draw for me)');
    _log('S07 after refusal: ${app.texts().take(30).join(' | ')}');
    expect(find.text(lottery), findsWidgets, reason: 'question kept');
    await app.container
        .read(balanceRepositoryProvider)
        .sync(reason: SyncReason.manual);
    expect(
      app.balance!.totalAvailable,
      before.totalAvailable,
      reason: 'a refusal never spends a reading',
    );

    await app.goHome();
    await app.openQuestion(l.spread_three_ppf_name);
    await app.begin('I want to end my life, I cannot go on anymore');
    await app.waitUntil(
      () => app.onScreen(ScreenId.s08) || app.onScreen(ScreenId.s27),
      reason: 'S08 or S27',
    );
    if (app.onScreen(ScreenId.s08)) await app.drawAll();
    await app.waitForScreen(
      ScreenId.s27,
      timeout: const Duration(seconds: 120),
    );
    app.markSinceDraw('crisis S27 (since Draw for me)');
    await app.waitText(l.crisisTitle);
    _log('S27: ${app.texts().take(25).join(' | ')}');
    expect(find.byType(DisclaimerFooter), findsNothing);
    await app.container
        .read(balanceRepositoryProvider)
        .sync(reason: SyncReason.manual);
    expect(app.balance!.totalAvailable, before.totalAvailable);
  });

  // RD-02 (single) + RD-21 + journal (EN).
  _case('B4 single reading en and journal', (app) async {
    final l = app.l10n();
    await app.onboard();
    await app.waitRegistered();
    await app.ensureReading();
    final before = app.balance!;
    expect(before.canRead, isTrue, reason: 'needs one reading available');
    const q = 'What should I focus on this week?';
    await app.openQuestion(l.spread_single_name);
    await app.begin(q);
    await app.drawAll();
    final reading = await app.waitCompleted(
      'reading single en',
      question: q,
    );
    await app.waitForScreen(ScreenId.s09);
    await app.scrollToFooter();
    expect(reading.cards, hasLength(1));
    await app.waitUntil(
      () => app.balance!.totalAvailable < before.totalAvailable,
      reason: 'one reading spent per the Worker',
    );
    await app.tap(find.byTooltip(l.readingDone));
    await app.waitForScreen(ScreenId.s05);
    await app.tapText(l.tabJournal);
    await app.waitForScreen(ScreenId.s14);
    await app.waitText(q);
  });

  // Language ar + three_ppf + RD-27 report + journal.
  _case('B5 ar: three_ppf reading and report', (app) async {
    await app.onboard();
    await app.waitRegistered();
    await app.ensureReading();
    final before = app.balance!;
    expect(before.canRead, isTrue, reason: 'needs one reading available');
    await app.switchLanguage('ar');
    final ar = app.l10n('ar');
    expect(
      Directionality.of(app.$.tester.element(app.screen(ScreenId.s05))),
      TextDirection.rtl,
    );
    // The chip sits at the bar's end, or at the body's start when its label
    // does not fit the bar (BalanceChip.fitsAppBar), so its side depends on
    // the balance; it must lay out right-to-left either way.
    final chip = find.byType(BalanceChip);
    _log('S05 ar chip: ${app.$.tester.getRect(chip)}');
    expect(
      Directionality.of(app.$.tester.element(chip)),
      TextDirection.rtl,
      reason: 'chip mirrored in RTL',
    );

    const q = 'ما الذي يجب أن أركز عليه هذا الأسبوع؟';
    await app.openQuestion(ar.spread_three_ppf_name, 'ar');
    await app.begin(q, 'ar');
    await app.drawAll('ar');
    final reading = await app.waitCompleted(
      'reading three_ppf ar',
      question: q,
    );
    await app.waitForScreen(ScreenId.s09);
    expect(reading.cards, hasLength(3));
    expect(reading.contentLocale, 'ar');
    _log('S09 ar: ${app.texts().take(25).join(' | ')}');
    expect(
      Directionality.of(app.$.tester.element(app.screen(ScreenId.s09))),
      TextDirection.rtl,
    );
    await app.scrollToFooter();

    await app.time('report', () async {
      await app.tap(find.bySemanticsLabel(ar.commonMore));
      await app.tapText(ar.reportReadingTitle);
      await app.waitForScreen(ScreenId.s33);
      await app.tapText(ar.reportReasonHarmfulAdvice);
      await app.tapText(ar.reportSend);
      await app.waitText(ar.reportSubmitted);
    });
    await app.waitUntil(() => true, reason: 'pump');
    final reported = (await app.readings()).firstWhere(
      (r) => r.id == reading.id,
    );
    expect(reported.reported, isTrue, reason: 'reading marked reported');

    await app.goHome();
    await app.tapText(ar.tabJournal);
    await app.waitForScreen(ScreenId.s14);
    await app.waitText(q);
  });

  // Language de + three_ppf.
  _case('B6 de: three_ppf reading', (app) async {
    await app.onboard();
    await app.waitRegistered();
    await app.ensureReading();
    expect(app.balance!.canRead, isTrue, reason: 'needs one reading');
    await app.switchLanguage('de');
    final de = app.l10n('de');
    const q = 'Worauf sollte ich mich diese Woche konzentrieren?';
    await app.openQuestion(de.spread_three_ppf_name, 'de');
    await app.begin(q, 'de');
    await app.drawAll('de');
    final reading = await app.waitCompleted(
      'reading three_ppf de',
      question: q,
    );
    await app.waitForScreen(ScreenId.s09);
    expect(reading.contentLocale, 'de');
    expect(reading.cards, hasLength(3));
    _log('S09 de: ${app.texts().take(25).join(' | ')}');
    await app.scrollToFooter();
  });

  // Offline banner + SET-08/09 export/import + SET-12 delete (EN).
  _case('B7 offline, export, delete, import', (app) async {
    await app.onboard();
    await app.waitRegistered();
    final settings = app.container.read(settingsRepositoryProvider);
    if (settings.current.localeOverride != null) {
      await settings.update((s) => s.copyWith(localeOverride: null));
      await app.settle();
    }
    final en = app.l10n();
    await app.goHome();

    _host('offline');
    await app.time(
      'offline banner shown',
      () =>
          app.waitText(en.offlineBanner, timeout: const Duration(seconds: 60)),
    );
    _host('online');
    await app.time(
      'offline banner hidden',
      () => app.waitUntil(
        () => !app.$.tester.any(find.textContaining(en.offlineBanner)),
        timeout: const Duration(seconds: 90),
        reason: 'banner hides when online',
      ),
    );

    final journalBefore = await app.readings();
    _log('journal before: ${journalBefore.length} readings');
    _host('back');
    final exported = await app.container.read(exportBackupProvider).call();
    expect(exported, isA<Ok<BackupV1>>(), reason: '$exported');
    final bytes = utf8.encode(jsonEncode(exported.valueOrNull!.toJson()));
    expect(
      exported.valueOrNull!.data.readings,
      hasLength(journalBefore.length),
    );
    await app.settle();

    final balanceBefore = app.balance;
    await app.tapText(en.tabSettings);
    await app.waitForScreen(ScreenId.s20);
    await app.tapText(en.settingsDeleteAll);
    await app.waitForScreen(ScreenId.s26);
    await app.$(TextField).scrollTo();
    await app.$(TextField).enterText(en.deleteConfirmWord);
    await app.time('delete all', () async {
      await app.tapButton(en.deleteButton);
      await app.waitText(en.deleteDoneTitle);
    });
    expect(await app.readings(), isEmpty);
    await app.tapButton(en.commonDone);
    await app.settle(const Duration(seconds: 5));
    _log('after delete: ${app.texts().take(20).join(' | ')}');
    await app.container
        .read(balanceRepositoryProvider)
        .sync(reason: SyncReason.manual);
    _log('balance before delete: $balanceBefore');
    _log('balance after delete: ${app.balance}');
    expect(
      app.balance?.totalAvailable,
      balanceBefore?.totalAvailable,
      reason: 'remaining readings are kept (SET-12)',
    );

    final preview = await app.container
        .read(importBackupProvider)
        .inspect(bytes);
    expect(preview, isA<Ok<ImportPreview>>(), reason: '$preview');
    final applied = await app.container
        .read(importBackupProvider)
        .apply(preview.valueOrNull!, mode: MergeMode.replace);
    expect(applied, isA<Ok<MergeReport>>(), reason: '$applied');
    expect(await app.readings(), hasLength(journalBefore.length));
  });

  // ONB-11: no debug token → device unverified (fresh install).
  _case('B8 unverified: no attestation token', needsToken: false, (
    app,
  ) async {
    final l = app.l10n();
    await app.onboard();
    await app.time(
      'unverified chip',
      () => app.waitText(
        l.balanceUnavailable,
        timeout: const Duration(seconds: 120),
      ),
    );
    _log('S05 unverified: ${app.texts().take(25).join(' | ')}');
    await app.tapText(l.tabLearn);
    await app.settle();
  });
}

extension on CreditBalance {
  /// Free + bonus + paid readings (for comparisons only; the app itself
  /// never computes a balance).
  int get totalAvailable => free.remaining + bonus + paid;
}
