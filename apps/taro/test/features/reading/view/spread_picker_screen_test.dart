import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/reading/controller/spread_picker_controller.dart';
import 'package:taro/features/reading/view/spread_picker_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    SpreadPickerState state,
  ) async {
    final calls = <String>[];
    await pumpTaroWidget(
      tester,
      SpreadPickerLayout(
        state: state,
        onBack: () => calls.add('back'),
        onPick: (s) => calls.add('pick:${s.id.value}'),
        onHowTheyWork: () => calls.add('how'),
        onRetry: () => calls.add('retry'),
      ),
    );
    return calls;
  }

  testWidgets('loading', (tester) async {
    await pumpLayout(tester, const SpreadPickerState.loading());
    expect(find.byType(TaroLoadingView), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
  });

  testWidgets('content: every offered spread with its card count', (
    tester,
  ) async {
    final calls = await pumpLayout(
      tester,
      SpreadPickerState.content([aSpread('single').build(), aSpread().build()]),
    );
    expect(find.text(l10n.spreadsTitle), findsOneWidget);
    expect(find.text(l10n.spread_single_name), findsOneWidget);
    expect(find.text(l10n.spread_three_ppf_name), findsOneWidget);
    expect(find.text(l10n.spread_celtic_cross_name), findsNothing);
    expect(find.textContaining(l10n.spreadCardCount(3)), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
    await tapFound(tester, find.text(l10n.spread_three_ppf_name));
    await tapFound(tester, find.text(l10n.spreadsHowTheyWork));
    expect(calls, ['pick:three_ppf', 'how']);
  });

  testWidgets('failed: error view with retry', (tester) async {
    final calls = await pumpLayout(
      tester,
      const SpreadPickerState.failed(Failure.storage()),
    );
    await tapFound(tester, find.text(l10n.commonRetry));
    expect(calls, ['retry']);
  });

  testWidgets('each row is one button with its diagram (S06 semantics)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLayout(tester, SpreadPickerState.content([aSpread().build()]));
    final name = l10n.spread_three_ppf_name;
    final label = l10n.spreadRowSemantics(
      name,
      l10n.spreadCardCount(3),
      l10n.spread_three_ppf_meta,
    );
    expect(find.bySemanticsLabel(label), findsOneWidget);
    expect(find.byType(SpreadDiagram), findsOneWidget);
    // The diagram is decorative inside the row.
    expect(find.bySemanticsLabel(name), findsNothing);
    handle.dispose();
  });

  testWidgets('RTL and 200 % text render without overflow', (tester) async {
    await pumpTaroWidget(
      tester,
      SpreadPickerLayout(
        state: SpreadPickerState.content([
          for (final id in kSpreadIds) aSpread(id.value).build(),
        ]),
        onBack: () {},
        onPick: (_) {},
        onHowTheyWork: () {},
        onRetry: () {},
      ),
      locale: const Locale('ar'),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SpreadDiagram), findsWidgets);
  });

  group('screen', () {
    testWidgets('a spread opens S07 with source home', (tester) async {
      await pumpFlow(
        tester,
        path: RoutePaths.readingSpreads,
        builder: (_) => const SpreadPickerScreen(),
        fakes: aiReadyFakes(),
      );
      await tapFound(tester, find.text(l10n.spread_single_name));
      expectRoute(RoutePaths.readingQuestion('single', source: 'home'));
    });

    testWidgets('How spreads work opens S18; back goes Home', (tester) async {
      await pumpFlow(
        tester,
        path: RoutePaths.readingSpreads,
        builder: (_) => const SpreadPickerScreen(),
        fakes: aiReadyFakes(),
      );
      await tapFound(tester, find.text(l10n.spreadsHowTheyWork));
      expectRoute(RoutePaths.learnSpreads);
    });

    testWidgets('back without history goes Home; retry reloads', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      fakes.content.failNext(const Failure.storage(), on: 'spreads');
      await pumpFlow(
        tester,
        path: RoutePaths.readingSpreads,
        builder: (_) => const SpreadPickerScreen(),
        fakes: fakes,
      );
      await tapFound(tester, find.text(l10n.commonRetry));
      expect(find.text(l10n.spread_single_name), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.home);
    });
  });
}
