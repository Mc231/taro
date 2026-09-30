import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/consent/controller/att_preprompt_controller.dart';
import 'package:taro/features/consent/view/att_preprompt_view.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  testWidgets('hidden: only the app; visible: the neutral pre-prompt with '
      'one Continue that completes the request', (tester) async {
    final fakes = TaroFakes();
    await pumpTaro(
      tester,
      const AttPrePromptHost(child: Text('app')),
      fakes: fakes,
    );
    expect(find.text('app'), findsOneWidget);
    expect(find.byType(AttPrePromptLayout), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.text('app')),
    );
    var done = false;
    unawaited(
      container
          .read(attPrePromptProvider.notifier)
          .request()
          .then((_) => done = true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AttPrePromptLayout), findsOneWidget);
    expect(find.text(l10n.attPrepromptTitle), findsOneWidget);
    expect(find.text(l10n.attPrepromptAllowTitle), findsOneWidget);
    expect(find.text(l10n.attPrepromptDenyTitle), findsOneWidget);
    expect(find.text(l10n.attPrepromptEitherTitle), findsOneWidget);
    // One action only: no fake "Allow", no Skip.
    expect(find.byType(TaroButton), findsOneWidget);

    await tapText(tester, l10n.attPrepromptContinue);
    expect(done, isTrue);
    expect(
      container.read(attPrePromptProvider),
      const AttPrePromptState.hidden(),
    );
    expect(find.byType(AttPrePromptLayout), findsNothing);
  });
}
