import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements RewardGatewayHarness {
  final FakeRewardGateway gateway = FakeRewardGateway();

  @override
  RewardGateway get subject => gateway;

  @override
  void ssvVerifies(IntentId intentId) => gateway.grant(intentId);
}

void main() {
  runRewardGatewayContract(_Harness.new);

  group('FakeRewardGateway hooks', () {
    test('autoGrant grants on the first poll with the balance', () async {
      final balance = aCreditBalance().withBonus(1).build();
      final gateway = FakeRewardGateway(autoGrant: true, grantBalance: balance);
      final intent = expectOk(await gateway.createIntent(kTestAdUnitId));
      final status = expectOk(await gateway.status(intent.intentId));
      expect(status.state, RewardIntentState.granted);
      expect(status.balance, balance);
    });

    test('reject, expire, scripted statuses and unknown intents', () async {
      final gateway = FakeRewardGateway();
      final a = expectOk(await gateway.createIntent(kTestAdUnitId)).intentId;
      final b = expectOk(await gateway.createIntent(kTestAdUnitId)).intentId;
      gateway
        ..reject(a)
        ..expire(b);
      expect(
        expectOk(await gateway.status(a)).state,
        RewardIntentState.rejected,
      );
      expect(
        expectOk(await gateway.status(b)).state,
        RewardIntentState.expired,
      );
      gateway.scriptStatuses(a, const [
        RewardStatus(state: RewardIntentState.issued, amount: 1),
        RewardStatus(state: RewardIntentState.granted, amount: 1),
      ]);
      expect(expectOk(await gateway.status(a)).state, RewardIntentState.issued);
      expect(
        expectOk(await gateway.status(a)).state,
        RewardIntentState.granted,
      );
      expect(
        expectOk(await gateway.status(a)).state,
        RewardIntentState.granted,
      );
      expect(
        expectErr(await gateway.status(const IntentId('nope'))),
        const Failure.contract(wireCode: 'NOT_FOUND'),
      );
      await gateway.cancel(const IntentId('nope'));
      expect(gateway.cancelled, [const IntentId('nope')]);
      expect(gateway.adUnitIds, [kTestAdUnitId, kTestAdUnitId]);
    });

    test('failNext', () async {
      final gateway = FakeRewardGateway()
        ..failNext(const Failure.network(), on: 'createIntent')
        ..failNext(const Failure.network(), on: 'status');
      expect((await gateway.createIntent(kTestAdUnitId)).isErr, isTrue);
      expect((await gateway.status(const IntentId('x'))).isErr, isTrue);
    });
  });
}
