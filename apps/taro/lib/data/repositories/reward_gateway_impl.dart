import 'package:taro/data/api/worker_client.dart';
import 'package:taro_core/taro_core.dart';

/// [RewardGateway] over the reward-intent routes (03 §7.1, §7.3; RC56,
/// RC57). `403 REWARDED_DISABLED` and `409 REWARDED_DAILY_CAP` map to
/// [RewardUnavailableFailure]. The caller applies a granted balance
/// (`EarnReward`).
final class RewardGatewayImpl implements RewardGateway {
  /// Creates the gateway; [ids] mints a fresh `Idempotency-Key` per tap.
  RewardGatewayImpl({
    required WorkerClient client,
    required IdGenerator ids,
    required Logger logger,
  }) : _client = client,
       _ids = ids,
       _logger = logger.child('rewards');

  final WorkerClient _client;
  final IdGenerator _ids;
  final Logger _logger;

  @override
  Future<Result<RewardIntent>> createIntent(String adUnitId) =>
      _client.createRewardIntent(adUnitId, idempotencyKey: _ids.uuidV4());

  @override
  Future<Result<RewardStatus>> status(IntentId intentId) =>
      _client.fetchRewardStatus(intentId);

  /// Best effort (RC57): a failure is logged by code and otherwise ignored;
  /// an uncancelled intent expires on the Worker after its TTL.
  @override
  Future<void> cancel(IntentId intentId) async {
    final result = await _client.cancelRewardIntent(intentId);
    if (result case Err(:final failure)) {
      _logger.info('reward intent cancel failed: ${failure.code}');
    }
  }
}
