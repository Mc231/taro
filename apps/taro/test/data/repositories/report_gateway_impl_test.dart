import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/repositories/report_gateway_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/fake_worker_server.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runReportGatewayContract(() {
    final h = RepositoryHarness();
    return ReportGatewayImpl(
      client: h.client,
      readings: FakeReadingRepository(),
    );
  });

  group('ReportGatewayImpl', () {
    late RepositoryHarness h;
    late FakeReadingRepository readings;
    late ReportGatewayImpl gateway;
    final reading = aReading().build();

    ReadingReport report({ReadingContent? content, String key = 'rk-1'}) =>
        ReadingReport(
          readingId: reading.id,
          reason: ReportReason.harmfulAdvice,
          locale: 'de',
          idempotencyKey: key,
          note: 'Bad advice',
          question: reading.question,
          reading: content,
        );

    setUp(() {
      h = RepositoryHarness();
      readings = FakeReadingRepository();
      gateway = ReportGatewayImpl(client: h.client, readings: readings);
    });
    tearDown(() => h.close());

    test('sends the stored reading with its cards (03 §9.7)', () async {
      readings.journal.putReading(reading);
      expectOk(await gateway.submit(report(content: reading.content)));
      final sent = h.server.sent('POST /v1/readings/').single;
      expect(sent.path, '/v1/readings/${reading.id.value}/report');
      expect(sent.header('Idempotency-Key'), 'rk-1');
      final body = sent.json! as Map<String, dynamic>;
      expect(body['reason'], 'harmful_advice');
      expect(body['locale'], 'de');
      final cards = (body['reading'] as Map<String, dynamic>)['cards'] as List;
      expect(
        [for (final c in cards.cast<Map<String, dynamic>>()) c['cardId']],
        [for (final c in reading.cards) c.cardId.value],
      );
    });

    test('a reading that is not stored is NOT_FOUND, nothing sent', () async {
      expect(
        expectErr(await gateway.submit(report(content: reading.content))),
        const Failure.contract(wireCode: 'NOT_FOUND'),
      );
      expect(h.server.requests, isEmpty);
    });

    test('a failed lookup is returned', () async {
      readings.failNext(const Failure.storage(), on: 'get');
      expect(
        expectErr(await gateway.submit(report(content: reading.content))),
        isA<StorageFailure>(),
      );
    });

    test('a transport failure is returned', () async {
      h.server.failNext(const Failure.network());
      expect(expectErr(await gateway.submit(report())), isA<NetworkFailure>());
    });
  });
}
