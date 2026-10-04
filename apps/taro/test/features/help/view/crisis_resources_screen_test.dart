import 'package:flutter/rendering.dart';
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
    expect(find.text(l10n.crisisSupportIn('DE')), findsOneWidget);
    expect(find.text('Telefonseelsorge'), findsOneWidget);
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
    expect(find.text(l10n.crisisSupportIn('FR')), findsNothing);
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
    expect(find.text('Telefonseelsorge'), findsOneWidget);
    await tapText(tester, l10n.crisisOtherCountry);
    expect(find.text(l10n.crisisCountryPicker), findsOneWidget);
    await tapText(tester, 'US');
    expect(find.text('988 Lifeline'), findsOneWidget);
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
