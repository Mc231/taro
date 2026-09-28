import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'reward_gateway.freezed.dart';

/// A rewarded-ad intent (`POST /v1/rewards/intents` 201, 03 §7.1).
@freezed
abstract class RewardIntent with _$RewardIntent {
  /// Creates an intent.
  const factory RewardIntent({
    /// The intent ID (also SSV `customData` and `userId`).
    required IntentId intentId,

    /// Bonus readings granted on a verified view.
    required int amount,

    /// When the intent lapses (UTC).
    required DateTime expiresAt,
  }) = _RewardIntent;
}

/// Reward intent `status` (GLOSSARY §5.1).
enum RewardIntentState {
  /// Created, not yet granted.
  issued,

  /// SSV verified; the bonus was granted.
  granted,

  /// Cancelled by the client.
  cancelled,

  /// Lapsed without a grant.
  expired,

  /// SSV rejected it.
  rejected,
}

/// A `GET /v1/rewards/intents/{intentId}` response (03 §7.3).
@freezed
abstract class RewardStatus with _$RewardStatus {
  /// Creates a status.
  const factory RewardStatus({
    /// The intent state.
    required RewardIntentState state,

    /// The intent amount.
    required int amount,

    /// The balance after a grant.
    CreditBalance? balance,
  }) = _RewardStatus;
}

/// Worker rewarded-ad intents (02 §5, 03 §7).
abstract interface class RewardGateway {
  /// `POST /v1/rewards/intents`. `RewardUnavailableFailure` on
  /// `403 REWARDED_DISABLED` / `409 REWARDED_DAILY_CAP`.
  Future<Result<RewardIntent>> createIntent(String adUnitId);

  /// `GET /v1/rewards/intents/{intentId}`.
  Future<Result<RewardStatus>> status(IntentId intentId);

  /// `POST /v1/rewards/intents/{intentId}/cancel`, best effort.
  Future<void> cancel(IntentId intentId);
}
