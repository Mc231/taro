import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/reading/controller/report_reading_controller.dart';
import 'package:taro/features/reading/view/report_reading_sheet.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    ReportReadingState state,
  ) async {
    final calls = <String>[];
    final note = TextEditingController();
    addTearDown(note.dispose);
    await pumpTaroWidget(
      tester,
      ReportReadingLayout(
        state: state,
        note: note,
        onReason: (r) => calls.add('reason:${r.name}'),
        onNote: (n) => calls.add('note:$n'),
        onSend: () => calls.add('send'),
        onClose: () => calls.add('close'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BannerSlot), findsNothing);
    return calls;
  }

  TaroButton send(WidgetTester tester, String label) =>
      tester.widget<TaroButton>(
        find.byWidgetPredicate((w) => w is TaroButton && w.label == label),
      );

  testWidgets('editing: radios (none selected), note, disclosure; Send '
      'needs a reason', (tester) async {
    final calls = await pumpLayout(
      tester,
      const ReportReadingState.editing(ReportDraft()),
    );
    expect(find.text(l10n.reportReadingDisclosure), findsOneWidget);
    expect(find.text(l10n.reportChooseReason), findsOneWidget);
    final radios = tester.widgetList<TaroRadioTile<ReportReason>>(
      find.byType(TaroRadioTile<ReportReason>),
    );
    expect(radios, hasLength(ReportReason.values.length));
    for (final radio in radios) {
      expect(radio.groupValue, isNull);
    }
    expect(send(tester, l10n.reportSend).onPressed, isNull);
    await tapFound(tester, find.text(l10n.reportReasonHarmfulAdvice));
    await tester.enterText(find.byType(TextField), 'x');
    expect(calls, ['reason:harmfulAdvice', 'note:x']);
  });

  testWidgets('editing with a reason: Send enabled', (tester) async {
    final calls = await pumpLayout(
      tester,
      const ReportReadingState.editing(
        ReportDraft(reason: ReportReason.other),
      ),
    );
    expect(find.text(l10n.reportChooseReason), findsNothing);
    await tapFound(tester, find.text(l10n.reportSend));
    await tapFound(tester, find.text(l10n.commonCancel));
    expect(calls, ['send', 'close']);
  });

  testWidgets('submitting: busy, radios read-only', (tester) async {
    await pumpLayout(
      tester,
      const ReportReadingState.submitting(
        ReportDraft(reason: ReportReason.sexual),
      ),
    );
    expect(send(tester, l10n.reportSend).loading, isTrue);
    for (final radio in tester.widgetList<TaroRadioTile<ReportReason>>(
      find.byType(TaroRadioTile<ReportReason>),
    )) {
      expect(radio.onChanged, isNull);
    }
  });

  testWidgets('submitted / alreadyReported: confirmation + close', (
    tester,
  ) async {
    await pumpLayout(tester, const ReportReadingState.submitted());
    expect(find.text(l10n.reportSubmitted), findsOneWidget);
    await pumpLayout(tester, const ReportReadingState.alreadyReported());
    expect(find.text(l10n.readingReported), findsOneWidget);
  });

  testWidgets('failed: Retry', (tester) async {
    await pumpLayout(
      tester,
      const ReportReadingState.failed(
        ReportDraft(reason: ReportReason.hateful),
        failure: Failure.network(),
      ),
    );
    expect(find.text(l10n.reportFailed), findsOneWidget);
    expect(send(tester, l10n.commonRetry).onPressed, isNotNull);
  });

  testWidgets('offline: Send disabled with notice + disclosure', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      const ReportReadingState.offline(ReportDraft(reason: ReportReason.other)),
    );
    expect(find.text(l10n.reportOffline), findsOneWidget);
    expect(find.text(l10n.reportReadingDisclosure), findsOneWidget);
    expect(send(tester, l10n.reportSend).onPressed, isNull);
  });

  testWidgets('rateLimited: notice, Send disabled', (tester) async {
    await pumpLayout(
      tester,
      const ReportReadingState.rateLimited(
        ReportDraft(reason: ReportReason.offensive),
      ),
    );
    expect(find.text(l10n.reportRateLimited), findsOneWidget);
    expect(send(tester, l10n.reportSend).onPressed, isNull);
  });

  testWidgets('sheet: choose, write, send → closes with a thank-you toast', (
    tester,
  ) async {
    final fakes = aiReadyFakes();
    final reading = aReading().withId('r-1').build();
    fakes.journal.putReading(reading);
    await pumpTaro(
      tester,
      Builder(
        builder: (context) => TaroButton.primary(
          label: 'open',
          onPressed: () => TaroSheet.show<void>(
            context,
            builder: (_) => UncontrolledProviderScope(
              container: ProviderScope.containerOf(context),
              child: const ReportReadingSheet(id: ReadingId('r-1')),
            ),
          ),
        ),
      ),
      fakes: fakes,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tapFound(tester, find.text(l10n.reportReasonOffensive));
    await tester.enterText(find.byType(TextField), 'Rude');
    await tapFound(tester, find.text(l10n.reportSend));
    expect(find.byType(ReportReadingSheet), findsNothing);
    expect(find.text(l10n.reportSubmitted), findsOneWidget);
  });
}
