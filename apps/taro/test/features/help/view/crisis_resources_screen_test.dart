import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/help/controller/crisis_resources_controller.dart';
import 'package:taro/features/help/view/crisis_resources_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<Uri>> pumpLayout(
    WidgetTester tester,
    CrisisResourcesState state, {
    double textScale = 1,
  }) async {
    final opened = <Uri>[];
    await pumpTaroWidget(
      tester,
      CrisisResourcesLayout(
        state: state,
        onClose: noop,
        onRetry: noop,
        onChooseCountry: noop1,
        onOpen: opened.add,
      ),
      textScale: textScale,
    );
    return opened;
  }

  // BUG-18: in ja the title broke as "…ありませ / ん"; it may break only
  // between the phrases "あなたは" and "ひとりではありません".
  testWidgets('ja title breaks only between phrases', (tester) async {
    const ja = Locale('ja');
    final title = lookupTaroLocalizations(ja).crisisTitle;
    final directory = aCrisisDirectory();
    for (final width in const <double>[320, 360, 375, 393, 411, 430]) {
      await pumpTaroWidget(
        tester,
        CrisisResourcesLayout(
          state: CrisisResourcesState.content(
            country: 'DE',
            resources: directory.select(country: 'DE'),
            hasLocalLines: true,
            countries: const ['DE'],
          ),
          onClose: noop,
          onRetry: noop,
          onChooseCountry: noop1,
          onOpen: (_) {},
        ),
        locale: ja,
        size: Size(width, 800),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final lastLine = paragraph.getPositionForOffset(
        Offset(0, paragraph.size.height - 1),
      );
      expect(lastLine.offset, isIn([0, title.indexOf('ひ')]), reason: '$width');
    }
  });

  // R2-03: bundled entries carry `verifiedAt: null` until the owner checks
  // them (Phase 18.4); S27 must not claim "Last checked January 1970".
  testWidgets('unverified entries: no "Last checked" line', (tester) async {
    await pumpLayout(
      tester,
      CrisisResourcesState.content(
        country: 'US',
        resources: [
          aCrisisResource(name: '988 Lifeline', phone: '988'),
          aCrisisResource(
            name: 'Find A Helpline',
            phone: null,
          ).copyWith(
            url: 'https://findahelpline.com',
            verifiedAt: CrisisResource.unverifiedAt,
          ),
        ],
        hasLocalLines: true,
        countries: const ['US'],
      ),
    );
    expect(find.textContaining('Last checked'), findsNothing);
    expect(find.textContaining('1970'), findsNothing);
  });

  // V2-07: the heading and the picker name the country, not its ISO code.
  testWidgets('country heading and picker use localized names', (
    tester,
  ) async {
    final directory = aCrisisDirectory();
    for (final (locale, heading) in const [
      (Locale('en'), 'Support: United States'),
      (Locale('de'), 'Hilfe: Vereinigte Staaten'),
      (Locale('uk'), 'Підтримка: США'),
      (Locale('ja'), 'アメリカ合衆国の相談窓口'),
    ]) {
      await pumpTaroWidget(
        tester,
        CrisisResourcesLayout(
          state: CrisisResourcesState.content(
            country: 'us',
            resources: directory.select(country: 'US'),
            hasLocalLines: true,
            countries: const ['DE', 'US'],
          ),
          onClose: noop,
          onRetry: noop,
          onChooseCountry: noop1,
          onOpen: (_) {},
        ),
        locale: locale,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.replaceAll('\u2060', '') == heading,
        ),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.textContaining(RegExp(r'\bUS\b')), findsNothing);
    }
    final ja = lookupTaroLocalizations(const Locale('ja'));
    expect(ja.crisisCountryName('JP').replaceAll('\u2060', ''), '日本');
    expect(l10n.crisisCountryName('GB'), 'United Kingdom');
    expect(l10n.crisisCountryName('ZZ'), 'ZZ');
  });

  // V2-08: in ar, "988 Lifeline" rendered as "Lifeline 988"; the name is a
  // first-strong isolate so a Latin name keeps its own order in RTL text.
  testWidgets('ar: resource names are bidi-isolated', (tester) async {
    await pumpTaroWidget(
      tester,
      CrisisResourcesLayout(
        state: CrisisResourcesState.content(
          country: 'US',
          resources: aCrisisDirectory().select(country: 'US'),
          hasLocalLines: true,
          countries: const ['US'],
        ),
        onClose: noop,
        onRetry: noop,
        onChooseCountry: noop1,
        onOpen: (_) {},
      ),
      locale: const Locale('ar'),
    );
    expect(find.text('\u2068988 Lifeline\u2069'), findsOneWidget);
  });

  testWidgets('loading', (tester) async {
    await pumpLayout(tester, const CrisisResourcesState.loading());
    expect(find.byType(TaroLoadingView), findsOneWidget);
  });

  testWidgets('storageError: error view with retry', (tester) async {
    await pumpLayout(tester, const CrisisResourcesState.storageError());
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });

  testWidgets('content: local lines with the country heading', (
    tester,
  ) async {
    final directory = aCrisisDirectory();
    await pumpLayout(
      tester,
      CrisisResourcesState.content(
        country: 'DE',
        resources: directory.select(country: 'DE'),
        hasLocalLines: true,
        countries: const ['DE', 'US'],
      ),
    );
    expect(find.text(l10n.crisisTitle), findsOneWidget);
    expect(find.text(l10n.crisisBody), findsOneWidget);
    expect(find.text('Support: Germany'), findsOneWidget);
    expect(find.text('\u2068Telefonseelsorge\u2069'), findsOneWidget);
    expect(find.textContaining('0800 111 0 111'), findsOneWidget);
    expect(find.textContaining('Last checked'), findsOneWidget);
  });

  testWidgets('content: Call, Text and Open actions with labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = await pumpLayout(
      tester,
      CrisisResourcesState.content(
        country: 'GB',
        resources: [
          aCrisisResource(name: 'Samaritans', phone: '116 123'),
          aCrisisResource(name: 'Shout', phone: null).copyWith(sms: '85258'),
          ...aCrisisDirectory().international,
        ],
        hasLocalLines: true,
        countries: const ['GB'],
      ),
    );
    expect(find.text(l10n.crisisInternationalName), findsOneWidget);
    expect(find.text(l10n.crisisInternationalBody), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel(l10n.crisisCallSemantics('Samaritans', '116 123')),
    );
    await tester.tap(
      find.bySemanticsLabel(l10n.crisisTextSemantics('Shout', '85258')),
    );
    await tester.tap(
      find.bySemanticsLabel(l10n.crisisOpenSemantics('findahelpline.com')),
    );
    expect(opened, [
      Uri.parse('tel:116123'),
      Uri.parse('sms:85258'),
      Uri.parse('https://findahelpline.com'),
    ]);
    handle.dispose();
  });

  testWidgets('content at text scale 2.0: no overflow', (tester) async {
    await pumpLayout(
      tester,
      CrisisResourcesState.content(
        country: 'DE',
        resources: aCrisisDirectory().select(country: 'DE'),
        hasLocalLines: true,
        countries: const ['DE'],
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('content without local lines: no country heading', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      CrisisResourcesState.content(
        country: 'FR',
        resources: [
          ...aCrisisDirectory().international,
          aCrisisResource(name: 'Night line', phone: '123').copyWith(
            hours: '24/7',
          ),
        ],
        hasLocalLines: false,
        countries: const [],
      ),
    );
    expect(find.text(l10n.crisisSupportIn('France')), findsNothing);
    expect(find.text(l10n.crisisInternationalName), findsOneWidget);
    expect(
      find.text(l10n.crisisHours('\u2066123\u2069', '24/7')),
      findsOneWidget,
    );
    final other = tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.crisisOtherCountry),
    );
    expect(other.onPressed, isNull);
  });

  test('fromQuery / location round-trip the origin', () {
    for (final origin in CrisisResourcesOrigin.values) {
      final uri = Uri.parse(CrisisResourcesScreen.location(origin));
      expect(uri.path, RoutePaths.helpCrisis);
      expect(
        CrisisResourcesScreen.fromQuery(uri.queryParameters).origin,
        origin,
      );
    }
    expect(
      CrisisResourcesScreen.fromQuery(const {}).origin,
      CrisisResourcesOrigin.help,
    );
  });

  testWidgets('screen: another country is picked from the sheet; close', (
    tester,
  ) async {
    final fakes = TaroFakes()
      ..crisis = FakeCrisisResourcesRepository(aCrisisDirectory());
    await pumpFlow(
      tester,
      path: RoutePaths.helpCrisis,
      builder: (state) =>
          CrisisResourcesScreen.fromQuery(state.uri.queryParameters),
      fakes: fakes,
      overrides: [crisisRegionProvider.overrideWithValue('DE')],
    );
    expect(find.text('\u2068Telefonseelsorge\u2069'), findsOneWidget);
    await tapText(tester, l10n.crisisOtherCountry);
    expect(find.text(l10n.crisisCountryPicker), findsOneWidget);
    await tapText(tester, 'United States');
    expect(find.text('\u2068988 Lifeline\u2069'), findsOneWidget);
    await tester.tap(find.text(l10n.crisisCall).first);
    await tester.pumpAndSettle();
    expect(fakes.links.opened, [Uri.parse('tel:988')]);
    await tester.tap(find.bySemanticsLabel(l10n.commonBack).first);
    await tester.pumpAndSettle();
    expectRoute(RoutePaths.home);
  });

  testWidgets('screen: a link that cannot open shows a toast', (
    tester,
  ) async {
    final fakes = TaroFakes()
      ..crisis = FakeCrisisResourcesRepository(aCrisisDirectory());
    fakes.links.failNext(const Failure.storage());
    await pumpFlow(
      tester,
      path: RoutePaths.helpCrisis,
      builder: (state) =>
          CrisisResourcesScreen.fromQuery(state.uri.queryParameters),
      fakes: fakes,
      overrides: [crisisRegionProvider.overrideWithValue('DE')],
    );
    await tester.tap(find.text(l10n.crisisCall).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.crisisOpenFailed), findsOneWidget);
  });

  testWidgets('screen from a reading: Back goes Home', (tester) async {
    await pumpFlow(
      tester,
      path: RoutePaths.helpCrisis,
      location: CrisisResourcesScreen.location(CrisisResourcesOrigin.reading),
      builder: (state) =>
          CrisisResourcesScreen.fromQuery(state.uri.queryParameters),
      fakes: TaroFakes(),
      pushed: true,
    );
    await tester.tap(find.bySemanticsLabel(l10n.commonBack).first);
    await tester.pumpAndSettle();
    expectRoute(RoutePaths.home);
  });

  testWidgets('screen: storage error retries', (tester) async {
    final fakes = TaroFakes();
    fakes.crisis.failNext(const Failure.storage(), on: 'directory');
    await pumpFlow(
      tester,
      path: RoutePaths.helpCrisis,
      builder: (_) => const CrisisResourcesScreen(),
      fakes: fakes,
    );
    expect(find.text(l10n.errorStorageTitle), findsOneWidget);
    await tapText(tester, l10n.commonRetry);
    expect(find.text(l10n.crisisTitle), findsOneWidget);
  });
}
