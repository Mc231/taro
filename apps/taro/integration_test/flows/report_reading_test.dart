import '../support/flow_harness.dart';

/// Report flow (Phase 19.3; 01 S33, 03 §9.7; CS7, RC22): a completed AI
/// reading → More → "Report this reading" → reason → Send → the report
/// reaches the Worker (`POST /v1/readings/{id}/report`, here the fake
/// gateway), the reading is marked reported, `reading_reported` is logged
/// (reason only, never text) and the menu shows "Reported".
void main() {
  taroFlow('report a reading end to end', ($) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.openQuestion();
    await app.begin();
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    await app.waitUntil(
      () => fakes.readings.acked.isNotEmpty,
      reason: 'delivery acknowledged',
    );
    final id = fakes.journal.readings.values.single.id;

    await app.tapFinder(find.bySemanticsLabel(l.commonMore));
    await app.tapText(l.reportReadingTitle);
    await app.waitForScreen(ScreenId.s33);
    await app.tapText(l.reportReasonHarmfulAdvice);
    await app.tapText(l.reportSend);
    await app.waitFor(find.text(l.reportSubmitted));

    final report = fakes.reports.reports[id];
    expect(report, isNotNull, reason: 'the report reached the Worker');
    expect(report!.reason, ReportReason.harmfulAdvice);
    expect(report.locale, 'en');
    await app.waitUntil(
      () => fakes.journal.readings[id]?.reported ?? false,
      reason: 'reading marked reported',
    );
    await app.waitUntil(
      () => fakes.analytics.eventNames.contains('reading_reported'),
      reason: 'reading_reported logged',
    );
    expect(
      fakes.analytics.events.toString(),
      isNot(contains(kTestQuestion)),
      reason: 'analytics never carry the question text (rule 18)',
    );

    await app.waitForScreen(ScreenId.s09);
    await app.tapFinder(find.bySemanticsLabel(l.commonMore));
    await app.waitFor(find.text(l.readingReported));
  });
}
