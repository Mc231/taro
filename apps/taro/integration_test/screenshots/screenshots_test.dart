// Store screenshots (05 §9.4, Phase 20.2): drives the real app on fakes
// (TARO_ENV=test) and writes the seven raw frames per locale, in order, to
// `<tmp>/store_shots/<capture>/<locale>/NN_name.png` at the device's
// physical resolution. `tools/screenshots/take_screenshots.sh` pulls them
// from the app container and `tools/screenshots/screenshots.py compose`
// frames them with the captions of `aso.yaml` `store_screenshots`.
//
// Runs only with STORE_SHOTS set (skipped otherwise):
//   flutter test integration_test/screenshots/screenshots_test.dart \
//     --flavor dev --dart-define-from-file=config/dev.json \
//     --dart-define=TARO_ENV=test --dart-define=STORE_SHOTS=iphone \
//     [--dart-define=STORE_LOCALES=en,ar] -d <device>
//
// The draw is fixed (`_StagedDraw`: the fixture's cards, upright), the AI
// reading is the fixture's text for the locale, Remove Ads is owned (no
// banners), frames 1–3 use the light theme and 4–7 the dark one. Every
// frame is checked for forbidden content first: no banner, paywall, price
// or countdown, and no Death, Devil or Tower in frames 1–3.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro/routing/router.dart';

import '../support/flow_harness.dart';
import 'store_readings.g.dart';

const bool _enabled = bool.hasEnvironment('STORE_SHOTS');

/// The capture set: iphone, ipad, phone or tablet.
const String _capture = String.fromEnvironment(
  'STORE_SHOTS',
  defaultValue: 'iphone',
);

const String _locales = String.fromEnvironment(
  'STORE_LOCALES',
  defaultValue: 'en,ar,de,es,fr,it,ja,ko,nl,pt,tr,uk',
);

/// Death, Devil, Tower: never in frames 1–3 (05 §9.4).
const Set<String> _forbiddenEarly = {'major_13', 'major_15', 'major_16'};

/// Cards kept out of view in the deck gallery (frame 6, 05 §9.4
/// "non-threatening cards only"): the above plus the darkest Swords
/// (Nine and Ten).
const Set<String> _threatening = {..._forbiddenEarly, 'swords_09', 'swords_10'};

/// The deck section frame 6 opens at: Cups on phones; Wands on tablets,
/// whose taller grid also shows Cups and the first row of Swords.
const String _deckAnchor = _capture == 'ipad' || _capture == 'tablet'
    ? 'anchor-wands'
    : 'anchor-cups';

/// One locale's fixture (`test/fixtures/store_readings/{locale}.json`).
final class StoreFixture {
  StoreFixture(this.json);

  factory StoreFixture.of(String locale) => StoreFixture(
    jsonDecode(kStoreReadingsJson[locale]!) as Map<String, Object?>,
  );

  final Map<String, Object?> json;

  String get locale => json['locale']! as String;
  String get question => json['question']! as String;
  String get spreadId => json['spreadId']! as String;
  String get dailyCardId => json['dailyCardId']! as String;
  String get learnCardId => json['learnCardId']! as String;

  List<DrawnCard> get cards => [
    for (final c in (json['cards']! as List).cast<Map<String, Object?>>())
      DrawnCard(
        positionId: PositionId(c['positionId']! as String),
        cardId: CardId(c['cardId']! as String),
        reversed: c['reversed']! as bool,
      ),
  ];

  /// The wire `reading` object as the client stores it (03 §9.1).
  ReadingContent get content =>
      ReadingContent.fromWire(json['reading']! as Map<String, Object?>);

  List<Map<String, Object?>> get journal =>
      (json['journal']! as List).cast<Map<String, Object?>>();

  /// Card IDs shown in frames 1–3: the draw and the daily card.
  Set<String> get earlyCardIds => {
    for (final c in cards) c.cardId.value,
    dailyCardId,
  };
}

/// A [RandomSource] whose next deck shuffle (`CardDrawer.shuffle`, a
/// Fisher–Yates over [deckSize] cards) puts the deck indexes [targets] in
/// the first positions; every card is upright. Other calls use [fallback].
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

final class _Shots {
  _Shots(this.app, this.fixture);

  final FlowApp app;
  final StoreFixture fixture;

  PatrolTester get $ => app.$;

  String get locale => fixture.locale;

  TaroLocalizations get l => app.l10n(locale);

  Future<void> go(String path) async {
    app.container.read(routerProvider).go(path);
    await app.settle(const Duration(seconds: 3));
  }

  /// Every text painted on screen (the `RichText` under each `Text`).
  List<String> get texts => [
    for (final e in find.byType(RichText).evaluate())
      (e.widget as RichText).text.toPlainText(),
  ];

  /// 05 §9.4 forbidden content, then the capture.
  Future<void> shot(
    String frame, {
    Set<String> cardIds = const {},
    Set<String> hiddenNames = const {},
  }) async {
    await app.settle(const Duration(seconds: 3));
    final index = int.parse(frame.substring(0, 2));
    // A banner slot collapses to nothing unless an ad may show (Remove
    // Ads owned); the ad band itself must never be built.
    expect(find.byType(AdGapFrame), findsNothing, reason: '$frame: ads');
    for (final id in [ScreenId.s10, ScreenId.s11, ScreenId.s12]) {
      expect(app.screen(id), findsNothing, reason: '$frame: paywall $id');
    }
    final price = RegExp(r'[$€£¥₴₺₩]\s?\d|\d\s?[$€£¥₴₺₩]|\b(USD|EUR|UAH)\b');
    final countdowns = [
      _template(l.balanceNextFreeIn('\u0001')),
      _template(l.balanceNextFreeInAt('\u0001', '\u0001')),
      _template(l.rewardedCoolingDown('\u0001')),
      RegExp(RegExp.escape(l.balanceNextFreeTomorrow)),
    ];
    for (final text in texts) {
      expect(price.hasMatch(text), isFalse, reason: '$frame: price "$text"');
      for (final c in countdowns) {
        expect(c.hasMatch(text), isFalse, reason: '$frame: countdown "$text"');
      }
    }
    if (index <= 3) {
      expect(
        cardIds.intersection(_forbiddenEarly),
        isEmpty,
        reason: '$frame: no Death, Devil or Tower in frames 1–3',
      );
    }
    final shown = inView(hiddenNames);
    expect(
      shown,
      isEmpty,
      reason: '$frame: $shown in view (non-threatening cards only)',
    );
    await _write(frame);
  }

  /// The texts of [names] painted inside the screen.
  List<String> inView(Set<String> names) {
    final screen = Offset.zero & $.tester.view.physicalSize;
    final ratio = $.tester.view.devicePixelRatio;
    return [
      for (final e in find.byType(RichText).evaluate())
        if (names.contains((e.widget as RichText).text.toPlainText()))
          if ((e.renderObject! as RenderBox).localToGlobal(Offset.zero) *
                      ratio &
                  (e.renderObject! as RenderBox).size * ratio
              case final rect when rect.overlaps(screen))
            (e.widget as RichText).text.toPlainText(),
    ];
  }

  static RegExp _template(String message) => RegExp(
    message.split('\u0001').map(RegExp.escape).join('.+'),
  );

  Future<void> _write(String frame) async {
    final binding = $.tester.binding;
    final view = binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final physical = view.flutterView.physicalSize;
    final image = await binding.runAsync(
      () => layer.toImage(Offset.zero & physical),
    );
    final bytes = await binding.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    final dir = Directory(
      '${Directory.systemTemp.path}/store_shots/$_capture/$locale',
    )..createSync(recursive: true);
    final file = File('${dir.path}/$frame.png')
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    debugPrint('STORE_SHOT: ${file.path}');
  }
}

/// Fakes for [fixture] in [theme]: onboarded, Remove Ads owned, the
/// bundled content, the platform of the device.
TaroFakes _fakes(StoreFixture fixture, ThemeMode theme) {
  final f = flowFakes()
    ..appInfo = FakeAppInfo(
      platform: Platform.isAndroid ? AppPlatform.android : AppPlatform.ios,
    )
    ..locale = fixture.locale
    ..entitlements = FakeEntitlementCache(
      Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.store,
        verifiedAt: kTestNow,
      ),
    )
    ..contentPort = AssetContentRepository.fromBundle(rootBundle);
  // The store account owns Remove Ads, so the silent ownership query at
  // launch keeps the entitlement (no banner slot on the allow-listed tabs).
  f.iap.own(TaroProducts.removeAds.id);
  f.journal.settings = UserSettings(
    themeMode: theme,
    localeOverride: fixture.locale == 'en' ? null : fixture.locale,
  );
  return f;
}

Future<_Shots> _launch(
  PatrolTester $,
  StoreFixture fixture,
  TaroFakes fakes,
) async {
  // No DEBUG ribbon in store frames.
  WidgetsApp.debugAllowBannerOverride = false;
  addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
  $.tester.platformDispatcher.localesTestValue = [Locale(fixture.locale)];
  return _Shots(await FlowApp.launch($, fakes: fakes), fixture);
}

/// The deck order of the bundled deck (`CardDrawer` shuffles it).
Future<List<String>> _deckOrder() async {
  final deck = await AssetContentRepository.fromBundle(rootBundle).deck();
  return [for (final c in deck.valueOrNull!.cards) c.id.value];
}

void main() {
  final locales = _locales.split(',').where((l) => l.isNotEmpty).toList();
  group(
    'store screenshots [$_capture]',
    () {
      // Time for the host to pull the last frames before the app goes.
      tearDownAll(() => Future<void>.delayed(const Duration(seconds: 15)));
      for (final locale in locales) {
        taroFlow('[$locale] frames 1–3 (light)', ($) async {
          final fixture = StoreFixture.of(locale);
          expect(fixture.earlyCardIds.intersection(_forbiddenEarly), isEmpty);
          final fakes = _fakes(fixture, ThemeMode.light);
          final order = await _deckOrder();
          fakes.random = _StagedDraw([
            for (final c in fixture.cards) order.indexOf(c.cardId.value),
          ], order.length);
          fakes.readings.completeNextWith(fixture.content);
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
          final s = await _launch($, fixture, fakes);
          final app = s.app;
          final l = s.l;

          // Frame 1: the draw ritual: the spread on the table with real art,
          // two cards turned, the question and the disclaimer in view.
          await app.waitForScreen(ScreenId.s05);
          await app.tapButton(l.homeStartReading);
          await app.waitForScreen(ScreenId.s06);
          await app.tapText(l.spread_three_ppf_name);
          await app.waitForScreen(ScreenId.s07);
          await app.enterQuestion(fixture.question);
          await app.tapButton(l.questionBegin);
          await app.waitForScreen(ScreenId.s08);
          await app.tapButton(l.drawShuffleButton);
          await app.tapButton(l.drawShuffleReady);
          await app.tapButton(l.drawForMe);
          await app.tapFinder(find.byKey(const ValueKey('flip-0')));
          await app.tapFinder(find.byKey(const ValueKey('flip-1')));
          await s.shot(
            '01_spread',
            cardIds: {for (final c in fixture.cards) c.cardId.value},
          );
          final drawn = fakes.readings.submitted.single.draw;
          expect(
            [for (final c in drawn.cards) c.cardId.value],
            [for (final c in fixture.cards) c.cardId.value],
            reason: 'the staged draw',
          );

          // Frame 2: the reading: the spread, the question, the AI title and
          // the first position section.
          await app.tapFinder(find.byKey(const ValueKey('flip-2')));
          await app.waitForScreen(ScreenId.s09);
          await app.waitUntil(() => fakes.readings.acked.isNotEmpty);
          await s.shot(
            '02_reading',
            cardIds: {for (final c in fixture.cards) c.cardId.value},
          );

          // Frame 3: the daily card.
          await s.go(RoutePaths.daily);
          await app.waitForScreen(ScreenId.s13);
          await s.shot('03_daily', cardIds: {fixture.dailyCardId});
        });

        taroFlow('[$locale] frames 4–7 (dark)', ($) async {
          final fixture = StoreFixture.of(locale);
          final fakes = _fakes(fixture, ThemeMode.dark);
          _seedJournal(fakes, fixture);
          final s = await _launch($, fixture, fakes);
          final app = s.app;
          await app.waitForScreen(ScreenId.s05);

          await s.go(RoutePaths.journal);
          await app.waitForScreen(ScreenId.s14);
          await s.shot('04_journal');

          await s.go(RoutePaths.learnCard(fixture.learnCardId));
          await app.waitForScreen(ScreenId.s17);
          await s.shot('05_learn');

          await s.go(RoutePaths.learn);
          await app.waitForScreen(ScreenId.s16);
          await app.tapFinder(find.byKey(const ValueKey(_deckAnchor)));
          await app.settle(const Duration(seconds: 3));
          final content = fakes.contentPort!;
          final hidden = {
            for (final id in _threatening)
              (await content.cardText(CardId(id), locale)).valueOrNull!.name,
          };
          await s.shot('06_deck', hiddenNames: hidden);

          await s.go(RoutePaths.settingsExport);
          await app.waitForScreen(ScreenId.s24);
          await s.shot('07_private');
        });
      }
    },
    skip: _enabled
        ? null
        : 'store screenshots: pass --dart-define=STORE_SHOTS=<capture>',
  );
}

/// The journal of frames 4–7: the fixture reading, two earlier readings
/// and today's daily card.
void _seedJournal(TaroFakes fakes, StoreFixture fixture) {
  final main = Draw(
    spreadId: SpreadId(fixture.spreadId),
    spreadVersion: 1,
    cards: fixture.cards,
    drawnAt: kTestNow,
  );
  fakes.journal.putReading(
    aReading()
        .withId('store-0')
        .withDraw(main)
        .withLocale(fixture.locale)
        .withQuestion(fixture.question)
        .withContent(fixture.content)
        .build(),
  );
  for (final (i, entry) in fixture.journal.indexed) {
    final at = kTestNow.subtract(
      Duration(days: (entry['daysAgo']! as num).toInt()),
    );
    final spread = entry['spreadId']! as String;
    final ids = (entry['cards']! as List).cast<String>();
    final positions = aSpread(spread).build().positionsInOrder;
    final draw = Draw(
      spreadId: SpreadId(spread),
      spreadVersion: 1,
      cards: [
        for (final (k, id) in ids.indexed)
          DrawnCard(
            positionId: positions[k].id,
            cardId: CardId(id),
            reversed: false,
          ),
      ],
      drawnAt: at,
    );
    final title = entry['title']! as String;
    final overview = entry['overview']! as String;
    fakes.journal.putReading(
      aReading()
          .withId('store-${i + 1}')
          .withDraw(draw)
          .createdAt(at, localDate: at.toIso8601String().substring(0, 10))
          .withLocale(fixture.locale)
          .withQuestion(entry['question']! as String)
          .withContent(
            ReadingContent(
              title: title,
              summary: overview,
              positions: [
                for (final c in draw.cards)
                  PositionText(positionId: c.positionId, text: overview),
              ],
              synthesis: overview,
              reflectionPrompts: const [],
            ),
          )
          .build(),
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
}
