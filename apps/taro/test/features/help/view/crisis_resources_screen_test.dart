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

  Future<void> pumpLayout(WidgetTester tester, CrisisResourcesState state) =>
      pumpTaroWidget(
        tester,
        CrisisResourcesLayout(
          state: state,
          onClose: noop,
          onRetry: noop,
          onChooseCountry: noop1,
        ),
      );

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
    expect(find.text('Find A Helpline'), findsOneWidget);
    expect(find.text(l10n.crisisHours('123', '24/7')), findsOneWidget);
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
    await tester.tap(find.bySemanticsLabel(l10n.commonClose).first);
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
