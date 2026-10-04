import 'package:taro_core/src/logic/reading_gate.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/ports/balance_repository.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/connectivity_monitor.dart';
import 'package:taro_core/src/ports/consent_store.dart';
import 'package:taro_core/src/ports/install_repository.dart';
import 'package:taro_core/src/ports/remote_config_repository.dart';
import 'package:taro_core/src/ports/sync_reason.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/result.dart';

/// Gathers the gate inputs and runs `ReadingGate.evaluate` on S07 **Begin**
/// (02 §9.3, RC44). Nothing is drawn here.
///
/// A stale or missing balance is synced first; a `NetworkFailure` from that
/// sync is the authoritative offline signal (02 §10).
final class ResolveReadingGate {
  /// Creates the use case.
  ResolveReadingGate({
    required InstallRepository install,
    required BalanceRepository balance,
    required RemoteConfigRepository config,
    required ConsentStore consent,
    required ConnectivityMonitor connectivity,
    required Clock clock,
  }) : _install = install,
       _balance = balance,
       _config = config,
       _consent = consent,
       _connectivity = connectivity,
       _clock = clock;

  final InstallRepository _install;
  final BalanceRepository _balance;
  final RemoteConfigRepository _config;
  final ConsentStore _consent;
  final ConnectivityMonitor _connectivity;
  final Clock _clock;

  /// Evaluates the gate for [spread]; an unregistered install registers
  /// first when online. Fails only when the install identity cannot be read
  /// (S01 `storageError`).
  Future<Result<GateDecision>> call(SpreadDefinition spread) async {
    final install = await _install.getOrCreate();
    if (install case Err(:final failure)) return Result.err(failure);
    var identity = install.valueOrNull!;
    final config = _config.current;
    var online = await _connectivity.isOnline();
    // Self-healing (02 §6.4): an install that is not registered (a failed
    // or interrupted registration, a repair the Worker refused) registers
    // now instead of showing "couldn't verify this device" until the next
    // sync pass.
    if (!identity.isRegistered && online) {
      final registered = await _install.ensureRegistered();
      if (registered case Ok(:final value)) identity = value;
    }
    var balance = _balance.cached;
    final now = _clock.now();
    if (online &&
        (balance == null || balance.isStaleAt(now, config.balanceStaleAfter))) {
      final synced = await _balance.sync(reason: SyncReason.preReading);
      switch (synced) {
        case Ok(:final value):
          balance = value;
        case Err(failure: NetworkFailure()):
          online = false;
        case Err():
          balance = _balance.cached;
      }
    }
    return Result.ok(
      ReadingGate.evaluate(
        install: identity,
        balance: balance,
        config: config,
        consent: _consent.current,
        online: online,
        spread: spread,
        now: _clock.now(),
      ),
    );
  }
}
