import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/ports/sync_reason.dart';
import 'package:taro_core/src/result/result.dart';

/// The Worker credit balance and its display cache (02 §5, 04 §6.5).
///
/// The client never computes a balance (rule 7): it changes only through
/// [sync] or [apply] with a Worker response.
abstract interface class BalanceRepository {
  /// The latest balance (cached first, then every accepted update).
  Stream<CreditBalance?> watch();

  /// The latest accepted balance, if any.
  CreditBalance? get cached;

  /// `GET /v1/balance`. Concurrent calls share one request.
  Future<Result<CreditBalance>> sync({required SyncReason reason});

  /// Applies a balance returned by another Worker call (hold, purchase,
  /// reward, timezone) under the RC67 rule
  /// (`CreditBalance.isAcceptableOver` / `shouldReplace`). Returns the
  /// balance that is current afterwards.
  Future<CreditBalance> apply(CreditBalance balance);
}
