import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runReportGatewayContract(FakeReportGateway.new);

  test('failNext and stored reports', () async {
    final gateway = FakeReportGateway(dailyLimit: 1)
      ..failNext(const Failure.network());
    const report = ReadingReport(
      readingId: kTestReadingId,
      reason: ReportReason.other,
      locale: 'en',
      idempotencyKey: 'k',
    );
    expect((await gateway.submit(report)).isErr, isTrue);
    expectOk(await gateway.submit(report));
    expect(gateway.reports.keys, [kTestReadingId]);
  });
}
