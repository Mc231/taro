import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `RewardGateway` contract needs besides the port.
abstract interface class RewardGatewayHarness {
  /// The gateway under test (rewarded enabled, under the cap).
  RewardGateway get subject;

  /// AdMob's SSV callback verifies [intentId].
  void ssvVerifies(IntentId intentId);
}

/// The `RewardGateway` contract (03 §7, RC56, RC57).
void runRewardGatewayContract(RewardGatewayHarness Function() create) {
  group('RewardGateway contract', () {
    late RewardGatewayHarness harness;
    late RewardGateway gateway;

    setUp(() {
      harness = create();
      gateway = harness.subject;
    });

    test('a new intent is issued with a positive amount', () async {
      final intent = expectOk(await gateway.createIntent(kTestAdUnitId));
      expect(intent.intentId.value, isNotEmpty);
      expect(intent.amount, greaterThan(0));
      final status = expectOk(await gateway.status(intent.intentId));
      expect(status.state, RewardIntentState.issued);
      expect(status.amount, intent.amount);
    });

    test('each intent has its own ID', () async {
      final a = expectOk(await gateway.createIntent(kTestAdUnitId));
      final b = expectOk(await gateway.createIntent(kTestAdUnitId));
      expect(a.intentId, isNot(b.intentId));
    });

    test('a verified view is granted', () async {
      final intent = expectOk(await gateway.createIntent(kTestAdUnitId));
      harness.ssvVerifies(intent.intentId);
      final status = expectOk(await gateway.status(intent.intentId));
      expect(status.state, RewardIntentState.granted);
    });

    test('cancel ends an issued intent without a grant', () async {
      final intent = expectOk(await gateway.createIntent(kTestAdUnitId));
      await gateway.cancel(intent.intentId);
      final status = expectOk(await gateway.status(intent.intentId));
      expect(status.state, RewardIntentState.cancelled);
    });

    test('cancel does not undo a grant', () async {
      final intent = expectOk(await gateway.createIntent(kTestAdUnitId));
      harness.ssvVerifies(intent.intentId);
      await gateway.cancel(intent.intentId);
      final status = expectOk(await gateway.status(intent.intentId));
      expect(status.state, RewardIntentState.granted);
    });
  });
}
