import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `ReportGateway` contract (03 §9.7, CS7, RC72). [create] returns a
/// gateway with no reports sent today.
void runReportGatewayContract(ReportGateway Function() create) {
  group('ReportGateway contract', () {
    late ReportGateway gateway;

    setUp(() => gateway = create());

    ReadingReport report(int n) => ReadingReport(
      readingId: ReadingId(
        '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}',
      ),
      reason: ReportReason.harmfulAdvice,
      locale: 'en',
      idempotencyKey: 'report-key-$n',
      note: 'It told me to stop my medication.',
      question: 'Should I change my treatment?',
    );

    test('accepts a report', () async {
      expectOk(await gateway.submit(report(1)));
    });

    test('a repeat for the same reading succeeds', () async {
      expectOk(await gateway.submit(report(1)));
      expectOk(await gateway.submit(report(1)));
    });

    test('the eleventh report of a day is rate limited', () async {
      for (var n = 1; n <= 10; n++) {
        expectOk(await gateway.submit(report(n)));
      }
      expect(
        expectErr(await gateway.submit(report(11))),
        const Failure.rateLimited(reason: RateLimitReason.reportLimit),
      );
      // A repeat of an accepted report still succeeds.
      expectOk(await gateway.submit(report(3)));
    });
  });
}
