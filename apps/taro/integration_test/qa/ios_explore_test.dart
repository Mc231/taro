import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/firebase_options_staging.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/router.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../support/staging_gate.dart';

/// QA round 2, iOS exploratory pass against the staging Worker (one
/// invocation, steps in order; a failing step is logged as `QA_FAIL` and
/// the pass goes on). Host steps (`QA_HOST: shot|openurl|grant|esc`) are
/// done by `run_ios_explore.sh`. Gated like `staging_e2e_test.dart`.
const PatrolTesterConfig _config = PatrolTesterConfig(
  existsTimeout: Duration(seconds: 45),
  visibleTimeout: Duration(seconds: 45),
  settleTimeout: Duration(seconds: 5),
);

/// Comma-separated step prefixes to run (e.g. `E0`); empty runs all.
const String _only = String.fromEnvironment('QA_ONLY');

void _log(String m) => debugPrint('QA: $m');
void _host(String a) => debugPrint('QA_HOST: $a');

final class _Env implements TaroEnvironment {
  _Env()
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
  Future<List<Override>> buildOverrides(FlavorConfig f, TaroDatabases d) =>
      _inner.buildOverrides(f, d);
  @override
  void installErrorHandlers(CrashReporter crash) {}
  @override
  void runApp(Widget app) => _inner.runApp(app);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final skip =
      !stagingSmokeEnabled || BuildDefines.debugAttestationToken.isEmpty;

  patrolWidgetTest('E ios exploratory', config: _config, skip: skip, (
    $,
  ) async {
    $.tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown($.tester.platformDispatcher.clearLocalesTestValue);
    final container = await bootstrap(_Env());
    addTearDown(container!.dispose);
    await $.tester.pumpWidget(_Env.app!);
    await $.pump();
    final t = $.tester;
    final fails = <String>[];
    var loc = 'en';
    TaroLocalizations l10n([String? c]) =>
        lookupTaroLocalizations(Locale(c ?? loc));
    Finder screen(ScreenId id) => find.byKey(ValueKey(id));
    bool on(ScreenId id) => t.any(screen(id));
    List<String> texts() => [
      for (final e in find.byType(Text).evaluate()) ?(e.widget as Text).data,
      for (final e in find.byType(RichText).evaluate())
        (e.widget as RichText).text.toPlainText(),
    ];
    Future<void> settle([int ms = 1500]) => t
        .pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          Duration(milliseconds: ms),
        )
        .catchError((Object _) => 0);
    // iOS-R2-01: Home must never say "unavailable" while a reading is free.
    final flashes = <String>[];
    final bad = {
      for (final c in ['en', 'uk']) ...[
        l10n(c).balanceUnavailable,
        l10n(c).errorDeviceUnverifiedTitle,
        l10n(c).questionDeviceUnverified,
      ],
    };
    void checkFlash() {
      final hit = texts().where(bad.contains).toList();
      if (hit.isEmpty) return;
      if (flashes.isEmpty) _host('shot FLASH_unavailable');
      flashes.add('${DateTime.timestamp().toIso8601String()} $hit');
    }

    Future<void> until(
      bool Function() c,
      String why, {
      int s = 60,
    }) async {
      final end = DateTime.timestamp().add(Duration(seconds: s));
      while (!c()) {
        if (DateTime.timestamp().isAfter(end)) {
          throw TestFailure(
            'timed out: $why; screen: ${texts().take(30).join(' | ')}',
          );
        }
        checkFlash();
        await t.pump(const Duration(milliseconds: 100));
      }
      await settle();
    }

    Future<void> wait(ScreenId id, {int s = 60}) =>
        until(() => on(id), '$id', s: s);
    Future<void> tap(Finder f) async {
      _log('tap ${f.toString(describeSelf: true)}');
      for (var i = 0; i < 50 && !t.any(f); i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      if (!t.any(f.hitTestable())) {
        try {
          await t.ensureVisible(f.first);
          await settle(500);
        } on Object catch (_) {}
      }
      if (!t.any(f.hitTestable())) await $(f).scrollTo();
      await $(f).tap();
      await settle();
    }

    Future<void> tapText(String s) => tap(find.text(s));
    // The Flutter layer only (no native overlays such as the UMP form or
    // the "Open in" prompt), pulled by run_ios_explore.sh from tmp/.
    Future<void> flutterShot(String name) async {
      try {
        final view = t.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        final size = view.flutterView.physicalSize;
        final image = await t.binding.runAsync(
          () => layer.toImage(Offset.zero & size, pixelRatio: 0.5),
        );
        final bytes = await t.binding.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        final dir = Directory('${Directory.systemTemp.path}/qa_shots/explore')
          ..createSync(recursive: true);
        File('${dir.path}/$name.png').writeAsBytesSync(
          bytes!.buffer.asUint8List(),
        );
      } on Object catch (e) {
        _log('flutter shot $name failed: $e');
      }
    }

    Future<void> shot(String name) async {
      _host('shot $name');
      await flutterShot(name);
      await t.pump(const Duration(milliseconds: 2500));
    }

    // A link as the engine delivers it (`pushRouteInformation`), for when
    // the host cannot accept iOS's "Open in" prompt.
    Future<void> injectLink(String url) async {
      _log('inject link $url');
      await t.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          MethodCall('pushRouteInformation', {'location': url, 'state': null}),
        ),
        (_) {},
      );
      await settle();
    }

    Future<void> openLink(String url, ScreenId expect) async {
      _host('openurl $url');
      final end = DateTime.timestamp().add(const Duration(seconds: 10));
      while (!on(expect) && DateTime.timestamp().isBefore(end)) {
        await t.pump(const Duration(milliseconds: 200));
      }
      if (on(expect)) {
        _log('native link $url opened');
      } else {
        await injectLink(url);
      }
    }

    final router = container.read(routerProvider);
    Future<void> home() async {
      router.go(RoutePaths.home);
      await wait(ScreenId.s05);
    }

    Future<void> step(String name, Future<void> Function() body) async {
      final id = name.split(' ').first;
      if (_only.isNotEmpty && !_only.split(',').contains(id)) return;
      _log('STEP $name');
      try {
        await body();
        _log('PASS $name');
      } on Object catch (e) {
        fails.add('$name: $e');
        _log('QA_FAIL $name: $e');
        await shot('FAIL_${name.split(' ').first}');
        try {
          await home();
        } on Object catch (_) {}
      }
    }

    CreditBalance? bal() => container.read(balanceRepositoryProvider).cached;
    Future<List<Reading>> readings() async =>
        (await container.read(journalRepositoryProvider).snapshot())
            .valueOrNull
            ?.readings ??
        const [];

    // E0 onboarding + registration.
    await step('E0 onboarding', () async {
      final l = l10n();
      await until(() => on(ScreenId.s02) || on(ScreenId.s05), 'S02/S05');
      if (on(ScreenId.s02)) {
        await tapText(l.welcomeGetStarted);
        await wait(ScreenId.s03);
        await tapText(l.disclaimerAcknowledge);
        await wait(ScreenId.s04);
        await tapText(l.aiConsentAccept);
        await wait(ScreenId.s05, s: 30);
      }
      await until(() => bal() != null, 'balance', s: 90);
      _log('balance: ${bal()}');
      await shot('E0_home_en');
      for (var i = 0; i < 150; i++) {
        checkFlash();
        await t.pump(const Duration(milliseconds: 100));
      }
      _log('E0 flashes: $flashes');
      expect(flashes, isEmpty, reason: 'Home said "unavailable" (iOS-R2-01)');
      expect(bal()!.canRead, isTrue, reason: 'fresh install has a reading');
    });

    Future<void> ensureCredit() async {
      if (bal()?.canRead ?? false) return;
      final id = await container.read(installRepositoryProvider).getOrCreate();
      _host('grant ${supportIdOf(id.valueOrNull!.installId)}');
      final repo = container.read(balanceRepositoryProvider);
      for (var i = 0; i < 30 && !(bal()?.canRead ?? false); i++) {
        await t.pump(const Duration(seconds: 4));
        await repo.sync(reason: SyncReason.manual);
      }
    }

    // A three-card reading from Home; returns on S09.
    Future<Reading> doReading(String question, String tag) async {
      await ensureCredit();
      _log('balance before $tag reading: ${bal()}');
      final l = l10n();
      await tap(find.widgetWithText(TaroButton, l.homeStartReading));
      await wait(ScreenId.s06);
      await shot('${tag}_spreads');
      await tapText(l.spread_three_ppf_name);
      await wait(ScreenId.s07);
      await $(TextField).enterText(question);
      await settle();
      await tap(find.widgetWithText(TaroButton, l.questionBegin));
      await wait(ScreenId.s08);
      await tap(find.widgetWithText(TaroButton, l.drawShuffleButton));
      await tap(find.widgetWithText(TaroButton, l.drawShuffleReady));
      final sw = Stopwatch()..start();
      await tap(find.widgetWithText(TaroButton, l.drawForMe));
      if (t.any(find.widgetWithText(TaroButton, l.drawRevealAll))) {
        await tap(find.widgetWithText(TaroButton, l.drawRevealAll));
      }
      Reading? done;
      while (done == null && sw.elapsed.inSeconds < 120) {
        final c = (await readings()).where(
          (r) => r.status is ReadingStatusComplete && r.question == question,
        );
        if (c.isNotEmpty) done = c.first;
        await t.pump(const Duration(milliseconds: 250));
      }
      if (done == null) {
        throw TestFailure('no completed $tag reading: ${texts().take(30)}');
      }
      _log('TIMING $tag reading=${sw.elapsedMilliseconds}ms');
      await wait(ScreenId.s09);
      return done;
    }

    // iOS edge swipe back (Cupertino back gesture) from the left edge.
    Future<void> edgeSwipe() async {
      final size = t.view.physicalSize / t.view.devicePixelRatio;
      _log('edge swipe on ${router.routerDelegate.currentConfiguration.uri}');
      await t.timedDragFrom(
        Offset(4, size.height / 2),
        Offset(size.width * 0.7, 0),
        const Duration(milliseconds: 350),
      );
      await settle();
    }

    String curLoc() =>
        router.routerDelegate.currentConfiguration.uri.toString();

    // E1a/b/c reading in en, swipe back S09 → Home, S15 → S09 → back.
    const qEn = 'What should I focus on this week?';
    await step('E1a reading en', () async {
      final r = await doReading(qEn, 'E1a_en');
      expect(r.contentLocale, 'en');
      await shot('E1a_result_en');
    });
    await step('E1b S09 swipe back home', () async {
      expect(on(ScreenId.s09), isTrue, reason: 'on S09 after E1a');
      await edgeSwipe();
      await wait(ScreenId.s05, s: 10);
      _log('after S09 swipe: ${curLoc()}');
      expect(on(ScreenId.s09), isFalse);
      expect(on(ScreenId.s08), isFalse, reason: 'never back into the draw');
      await shot('E1b_home_after_swipe');
    });
    await step('E1c journal S15 S09 back', () async {
      final l = l10n();
      await tapText(l.tabJournal);
      await wait(ScreenId.s14);
      await until(() => t.any(find.textContaining(qEn)), 'en reading listed');
      await tap(find.textContaining(qEn).first);
      await wait(ScreenId.s15);
      await shot('E1c_S15');
      await tapText(l.entryFullReading);
      await wait(ScreenId.s09);
      await shot('E1c_S09_from_S15');
      await tap(find.byTooltip(l.readingDone));
      await wait(ScreenId.s15, s: 10);
      expect(on(ScreenId.s09), isFalse);
      _log('S09 Done -> ${curLoc()}');
      await shot('E1c_S15_after_done');
      await tapText(l.entryFullReading);
      await wait(ScreenId.s09);
      await edgeSwipe();
      await wait(ScreenId.s15, s: 10);
      expect(on(ScreenId.s09), isFalse);
      _log('S09 swipe -> ${curLoc()}');
      await shot('E1c_S15_after_swipe');
      await edgeSwipe();
      await wait(ScreenId.s14, s: 10);
      _log('S15 swipe -> ${curLoc()}');
      await shot('E1c_S14_after_swipe');
      await home();
    });

    // E1 language → uk, then a reading in uk.
    await step('E1 language uk', () async {
      final l = l10n();
      await tapText(l.tabSettings);
      await wait(ScreenId.s20);
      await tapText(l.settingsLanguage);
      await wait(ScreenId.s21);
      await shot('E1_language_picker');
      await tap(find.byKey(const ValueKey('uk')));
      loc = 'uk';
      await settle();
      await tap(find.bySemanticsLabel(l10n().commonBack));
      await wait(ScreenId.s20);
      await shot('E1_settings_uk');
      await tapText(l10n().tabToday);
      await wait(ScreenId.s05);
      await shot('E1_home_uk');
    });

    const q = 'На чому мені варто зосередитися цього тижня?';
    await step('E2 reading uk', () async {
      final l = l10n();
      final done = await doReading(q, 'E2_uk');
      expect(done.contentLocale, 'uk');
      expect(done.cards, hasLength(3));
      await wait(ScreenId.s09);
      await shot('E2_result_uk_top');
      _log('S09 uk: ${texts().take(25).join(' | ')}');
      final latin = texts()
          .where((s) => RegExp('[A-Za-z]{5,}').hasMatch(s))
          .take(10)
          .toList();
      _log('S09 uk latin strings: $latin');
      for (var i = 0; i < 6; i++) {
        await t.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -600),
        );
        await t.pump(const Duration(milliseconds: 300));
      }
      await shot('E2_result_uk_bottom');
      await tap(find.byTooltip(l.readingDone));
      await wait(ScreenId.s05);
    });

    // E3 journal search + filters (uk).
    await step('E3 journal search filter', () async {
      final l = l10n();
      await tapText(l.tabJournal);
      await wait(ScreenId.s14);
      await until(() => t.any(find.textContaining(q)), 'reading in journal');
      await shot('E3_journal_uk');
      await t.enterText(find.byType(TextField).first, 'зосередитися');
      await t.pump(const Duration(seconds: 1));
      await settle();
      expect(find.textContaining(q), findsWidgets, reason: 'search hit');
      await shot('E3_search_hit');
      await t.enterText(find.byType(TextField).first, 'qqzzxx');
      await t.pump(const Duration(seconds: 1));
      await settle();
      expect(
        find.textContaining(l.journalSearchEmpty('qqzzxx')),
        findsOneWidget,
      );
      await shot('E3_search_empty');
      await t.enterText(find.byType(TextField).first, '');
      await t.pump(const Duration(seconds: 1));
      await settle();
      await tapText(l.journalFilterDailyCards);
      await shot('E3_filter_daily');
      _log('filter daily: ${texts().take(20).join(' | ')}');
      await tapText(l.journalFilterReadings);
      expect(find.textContaining(q), findsWidgets);
      await tapText(l.journalFilterFavourites);
      await shot('E3_filter_fav');
      await tapText(l.journalFilterAll);
      await tapText(l.journalFilterMore);
      await shot('E3_filter_more_sheet');
      _log('more sheet: ${texts().take(30).join(' | ')}');
      if (t.any(find.text(l.journalFilterApply))) {
        await tapText(l.journalFilterApply);
      }
      await settle();
      await tap(find.textContaining(q).first);
      await wait(ScreenId.s15);
      await shot('E3_entry_uk');
      await home();
    });

    // E4 Learn → card detail → zoom → close; reversed toggle.
    await step('E4 learn card zoom', () async {
      final l = l10n();
      await tapText(l.tabLearn);
      await wait(ScreenId.s16);
      await shot('E4_learn_uk');
      await t.enterText(find.byType(TextField).first, 'zzzz');
      await settle();
      await shot('E4_learn_search_empty');
      await t.enterText(find.byType(TextField).first, '');
      await settle();
      await tap(find.byKey(const ValueKey('major_01')));
      await wait(ScreenId.s17);
      await shot('E4_card_detail');
      await tapText(l.commonReversed);
      await shot('E4_card_reversed');
      await tap(find.byType(TaroCardFace).first);
      await until(
        () => t.any(find.bySemanticsLabel(l.cardZoomSemantics)),
        'zoomed',
      );
      await shot('E4_card_zoomed');
      await tap(find.bySemanticsLabel(l.commonClose));
      await until(
        () => !t.any(find.bySemanticsLabel(l.cardZoomSemantics)),
        'zoom closed',
      );
      await tap(find.bySemanticsLabel(l.cardNextAction));
      await settle();
      await shot('E4_card_next');
      await home();
    });

    // E5 FAQ search + legal tabs (uk).
    await step('E5 faq legal', () async {
      final l = l10n();
      await tapText(l.tabSettings);
      await wait(ScreenId.s20);
      await tapText(l.settingsHelpFaq);
      await wait(ScreenId.s28);
      await shot('E5_faq');
      await t.enterText(find.byType(TextField).first, 'реклам');
      await t.pump(const Duration(seconds: 1));
      await settle();
      _log('faq search: ${texts().take(20).join(' | ')}');
      await shot('E5_faq_search_hit');
      await t.enterText(find.byType(TextField).first, 'qqzzxx');
      await t.pump(const Duration(seconds: 1));
      await settle();
      expect(find.textContaining(l.helpSearchEmpty('qqzzxx')), findsWidgets);
      await shot('E5_faq_search_empty');
      router.go(RoutePaths.settings);
      await wait(ScreenId.s20);
      await tapText(l.settingsLegal);
      await wait(ScreenId.s29);
      for (final (name, label) in [
        ('terms', l.legalTerms),
        ('privacy', l.legalPrivacy),
        ('licences', l.legalLicences),
        ('disclaimer', l.legalDisclaimer),
      ]) {
        await tap(find.text(label).first);
        await shot('E5_legal_$name');
        _log('legal $name: ${texts().take(12).join(' | ')}');
      }
      await home();
    });

    // E6 deep links (host openurl) while running.
    await step('E6 deep link learn card', () async {
      await home();
      await openLink('taro://learn/card/major_00', ScreenId.s17);
      await wait(ScreenId.s17, s: 30);
      _log('deep link at ${router.routerDelegate.currentConfiguration.uri}');
      await shot('E6_deeplink_major_00');
      await openLink('taro://learn/card/major_99', ScreenId.s05);
      await wait(ScreenId.s05, s: 30);
      _log('bad link at ${router.routerDelegate.currentConfiguration.uri}');
      await shot('E6_deeplink_bad');
      await openLink('taro://journal/2020-01-01', ScreenId.s15);
      await t.pump(const Duration(seconds: 2));
      await settle();
      _log('journal link at ${router.routerDelegate.currentConfiguration.uri}');
      await shot('E6_deeplink_journal_missing');
      await home();
    });

    // E7 import screen + export (share sheet last, it stays on top).
    await step('E7 import export', () async {
      final l = l10n();
      final before = await readings();
      final exported = await container.read(exportBackupProvider).call();
      expect(exported, isA<Ok<BackupV1>>());
      final bytes = utf8.encode(jsonEncode(exported.valueOrNull!.toJson()));
      _log('export bytes=${bytes.length} readings=${before.length}');
      await tapText(l.tabSettings);
      await wait(ScreenId.s20);
      await tapText(l.settingsImport);
      await wait(ScreenId.s25);
      await shot('E7_import_screen');
      final preview = await container.read(importBackupProvider).inspect(bytes);
      expect(preview, isA<Ok<ImportPreview>>(), reason: '$preview');
      final merged = await container
          .read(importBackupProvider)
          .apply(preview.valueOrNull!);
      expect(merged, isA<Ok<MergeReport>>(), reason: '$merged');
      _log('merge report: ${merged.valueOrNull}');
      expect(await readings(), hasLength(before.length), reason: 'no dupes');
      router.go(RoutePaths.settings);
      await wait(ScreenId.s20);
      await tapText(l.settingsExport);
      await wait(ScreenId.s24);
      await shot('E7_export_screen');
      await tap(find.widgetWithText(TaroButton, l.exportButton));
      await t.pump(const Duration(seconds: 4));
      await shot('E7_export_share_sheet');
      _host('esc');
      await t.pump(const Duration(seconds: 4));
      await settle();
      await shot('E7_export_after');
      _log('export after: ${texts().take(15).join(' | ')}');
    });

    _log('FLASHES ${jsonEncode(flashes)}');
    _log('FAILS ${jsonEncode(fails)}');
    await t.pump(const Duration(seconds: 3));
    expect(fails, isEmpty);
  });
}
