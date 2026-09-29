import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/repositories/reward_gateway_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../api/support/scripted_http_adapter.dart';
import 'support/fake_worker_server.dart';

final class _Harness implements RewardGatewayHarness {
  _Harness() : h = RepositoryHarness() {
    subject = RewardGatewayImpl(client: h.client, ids: h.ids, logger: h.logger);
  }

  final RepositoryHarness h;

  @override
  late final RewardGatewayImpl subject;

  @override
  void ssvVerifies(IntentId intentId) =>
      h.server.intents[intentId.value] = 'granted';
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runRewardGatewayContract(_Harness.new);

  group('RewardGatewayImpl', () {
    late _Harness harness;
    late FakeWorkerServer server;

    setUp(() {
      harness = _Harness();
      server = harness.h.server;
    });
    tearDown(() => harness.h.close());

    test('each tap sends a fresh idempotency key and the ad unit', () async {
      await harness.subject.createIntent(kTestAdUnitId);
      await harness.subject.createIntent(kTestAdUnitId);
      final sent = server.sent('POST /v1/rewards/intents');
      expect(sent.first.json, {'adUnitId': kTestAdUnitId});
      expect(
        sent.map((r) => r.header('Idempotency-Key')).toSet(),
        hasLength(2),
      );
    });

    test('a granted status carries the balance', () async {
      final intent = expectOk(await harness.subject.createIntent('unit'));
      harness.ssvVerifies(intent.intentId);
      final status = expectOk(await harness.subject.status(intent.intentId));
      expect(status.balance, isNotNull);
    });

    test('409 REWARDED_DAILY_CAP is RewardUnavailableFailure', () async {
      server.onNext(
        'POST /v1/rewards/intents',
        (_) => ScriptedHttpAdapter.response(
          409,
          json: ScriptedHttpAdapter.envelope(
            'REWARDED_DAILY_CAP',
            details: {'reason': 'cap'},
          ),
        ),
      );
      expect(
        expectErr(await harness.subject.createIntent('unit')),
        isA<RewardUnavailableFailure>(),
      );
    });

    test('a failed cancel is logged and swallowed', () async {
      server.failNext(const Failure.network());
      await harness.subject.cancel(const IntentId('intent-9'));
      expect(
        harness.h.logger.records.map((r) => r.message),
        contains('reward intent cancel failed: NETWORK'),
      );
    });
  });
}
