import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/endpoints.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro/data/api/server_clock.dart';
import 'package:taro_core/taro_core.dart';

void main() {
  group('Endpoints (RC4, GLOSSARY §4)', () {
    test('the client route set is E02–E17', () {
      expect(
        {for (final e in Endpoints.all) e.id: e.route},
        {
          'E02': 'GET /v1/config',
          'E03': 'POST /v1/attest/challenge',
          'E04': 'POST /v1/installs',
          'E05': 'POST /v1/installs/token',
          'E06': 'PUT /v1/installs/me/timezone',
          'E07': 'DELETE /v1/installs/me',
          'E08': 'GET /v1/balance',
          'E09': 'POST /v1/readings/holds',
          'E10': 'POST /v1/readings',
          'E11': 'GET /v1/readings/{clientReadingId}',
          'E12': 'POST /v1/readings/{clientReadingId}/ack',
          'E13': 'POST /v1/readings/{clientReadingId}/report',
          'E14': 'POST /v1/purchases/verify',
          'E15': 'POST /v1/rewards/intents',
          'E16': 'GET /v1/rewards/intents/{intentId}',
          'E17': 'POST /v1/rewards/intents/{intentId}/cancel',
        },
      );
    });

    test('flags follow RC11/RC50 (attest), [idem] and RC28 (consent)', () {
      Set<String> ids(bool Function(Endpoint) f) => {
        for (final e in Endpoints.all)
          if (f(e)) e.id,
      };
      expect(ids((e) => e.attested), {'E05', 'E09', 'E10', 'E15'});
      expect(ids((e) => e.idempotent), {
        'E04',
        'E06',
        'E07',
        'E09',
        'E10',
        'E13',
        'E14',
        'E15',
      });
      expect(ids((e) => e.aiConsent), {'E09', 'E10'});
      expect(ids((e) => e.pollOnTimeout), {'E10'});
      expect(ids((e) => e.auth == EndpointAuth.public), {'E02', 'E03', 'E04'});
      expect(ids((e) => e.auth == EndpointAuth.tokenMayBeExpired), {'E05'});
    });

    test('timeouts per 02 §6.3 (reading 60 s, RC31)', () {
      expect(Endpoints.createReading.timeout, const Duration(seconds: 60));
      expect(Endpoints.verifyPurchase.timeout, const Duration(seconds: 20));
      expect(Endpoints.register.timeout, const Duration(seconds: 15));
      expect(Endpoints.hold.timeout, const Duration(seconds: 15));
      expect(Endpoints.balance.timeout, const Duration(seconds: 10));
      expect(
        ApiTimeouts.readingPollDelays.fold(Duration.zero, (a, b) => a + b),
        lessThanOrEqualTo(ApiTimeouts.readingPollBudget),
      );
    });

    test('the reading poll schedule is 1, 2, 4, 8 s within 30 s', () {
      expect(
        [
          for (var i = 0; i < 5; i++)
            ApiTimeouts.readingPollDelay(i, Duration.zero),
        ],
        [
          const Duration(seconds: 1),
          const Duration(seconds: 2),
          const Duration(seconds: 4),
          const Duration(seconds: 8),
          null,
        ],
      );
      expect(ApiTimeouts.readingPollDelay(-1, Duration.zero), isNull);
      expect(
        ApiTimeouts.readingPollDelay(3, const Duration(seconds: 23)),
        isNull,
      );
      expect(
        ApiTimeouts.readingPollDelay(3, const Duration(seconds: 22)),
        const Duration(seconds: 8),
      );
    });

    test('resolve encodes parameters and rejects a missing one', () {
      expect(
        Endpoints.getReading.resolve({'clientReadingId': 'a b/c'}),
        '/v1/readings/a%20b%2Fc',
      );
      expect(Endpoints.balance.resolve(), '/v1/balance');
      expect(() => Endpoints.rewardStatus.resolve(), throwsArgumentError);
      expect(Endpoints.hold.toString(), 'E09 POST /v1/readings/holds');
    });

    test('requestExtra carries the endpoint and key', () {
      final extra = requestExtra(Endpoints.hold, idempotencyKey: 'k');
      expect(extra.values, containsAll([Endpoints.hold, 'k']));
    });
  });

  group('ServerClockTracker', () {
    test('records samples and emits only changes', () async {
      final tracker = ServerClockTracker();
      final seen = <ServerClockOffset>[];
      tracker.changes.listen(seen.add);
      final now = DateTime.utc(2026, 9, 26, 10);
      tracker
        ..record(
          serverTime: now.add(const Duration(seconds: 5)),
          receivedAt: now,
        )
        ..record(
          serverTime: now.add(const Duration(seconds: 5)),
          receivedAt: now,
        )
        ..recordDateHeader(null, receivedAt: now)
        ..recordDateHeader('garbage', receivedAt: now)
        ..recordDateHeader('Sat, 26 Sep 2026 09:59:50 GMT', receivedAt: now);
      expect(seen.map((o) => o.offset), [
        const Duration(seconds: 5),
        const Duration(seconds: -10),
      ]);
      expect(tracker.current.offset, const Duration(seconds: -10));
      await tracker.dispose();
    });
  });
}
