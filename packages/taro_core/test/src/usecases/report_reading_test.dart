import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeReadingRepository readings;
  late FakeReportGateway gateway;
  late ReportReading report;

  final delivered = aReading().withNote('private').build();

  setUp(() {
    readings = FakeReadingRepository()..journal.putReading(delivered);
    gateway = FakeReportGateway();
    report = ReportReading(
      readings: readings,
      gateway: gateway,
      ids: SequentialIdGenerator('report-'),
    );
  });

  test('sends the reading and question, then marks it reported', () async {
    expectOk(
      await report(
        delivered.id,
        ReportReason.harmfulAdvice,
        note: '  Please check this.  ',
      ),
    );
    final sent = gateway.reports[delivered.id]!;
    expect(sent.reason, ReportReason.harmfulAdvice);
    expect(sent.locale, delivered.contentLocale);
    expect(sent.idempotencyKey, 'report-1');
    expect(sent.note, 'Please check this.');
    expect(sent.question, delivered.question);
    expect(sent.reading, delivered.content);
    expect(readings.journal.readings[delivered.id]!.reported, isTrue);
  });

  test('a declined reading can be reported without content', () async {
    final refused = aReading()
        .withId('66666666-6666-4666-8666-666666666666')
        .refused()
        .build();
    readings.journal.putReading(refused);
    expectOk(await report(refused.id, ReportReason.offensive));
    expect(gateway.reports[refused.id]!.reading, isNull);
    expect(gateway.reports[refused.id]!.note, isNull);
  });

  test('a blank note is dropped; a long one is cut to 500', () async {
    expectOk(await report(delivered.id, ReportReason.other, note: '   '));
    expect(gateway.reports[delivered.id]!.note, isNull);

    final other = aReading()
        .withId('77777777-7777-4777-8777-777777777777')
        .build();
    readings.journal.putReading(other);
    // 600 graphemes, each two code units.
    expectOk(await report(other.id, ReportReason.other, note: '🌙' * 600));
    final note = gateway.reports[other.id]!.note!;
    expect(note, '🌙' * ReportReading.noteMaxLength);
  });

  test('an already reported reading is not sent again', () async {
    readings.journal.putReading(delivered.copyWith(reported: true));
    expectOk(await report(delivered.id, ReportReason.other));
    expect(gateway.calls, isEmpty);
  });

  test('Classic and unknown readings cannot be reported', () async {
    final classic = aReading()
        .withId('88888888-8888-4888-8888-888888888888')
        .classic()
        .build();
    readings.journal.putReading(classic);
    for (final id in [classic.id, const ReadingId('unknown')]) {
      expect(
        expectErr(await report(id, ReportReason.other)),
        const Failure.contract(wireCode: 'NOT_FOUND'),
      );
    }
    expect(gateway.calls, isEmpty);
  });

  test('a storage failure is returned', () async {
    readings.failNext(const Failure.storage(), on: 'get');
    expect(
      expectErr(await report(delivered.id, ReportReason.other)),
      const Failure.storage(),
    );
  });

  test('a rejected report is not marked', () async {
    gateway.failNext(
      const Failure.rateLimited(reason: RateLimitReason.reportLimit),
    );
    expect(
      expectErr(await report(delivered.id, ReportReason.other)),
      const Failure.rateLimited(reason: RateLimitReason.reportLimit),
    );
    expect(readings.journal.readings[delivered.id]!.reported, isFalse);
  });
}
