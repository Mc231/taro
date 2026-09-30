import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taro_core/taro_core.dart';

/// The production [ConnectivityMonitor] over `connectivity_plus` (02 §5,
/// §10). It is a hint only: any interface other than `none` counts as
/// online, and the authoritative offline signal is a `NetworkFailure`.
///
/// [online] is a broadcast stream that emits only real changes; it listens
/// to the platform while it has listeners.
final class ConnectivityPlusMonitor implements ConnectivityMonitor {
  /// A monitor over [connectivity] (default: the plugin singleton).
  ConnectivityPlusMonitor({required Logger logger, Connectivity? connectivity})
    : _logger = logger.child('connectivity'),
      _connectivity = connectivity ?? Connectivity() {
    _changes = StreamController<bool>.broadcast(
      onListen: _listen,
      onCancel: _stop,
    );
  }

  final Logger _logger;
  final Connectivity _connectivity;
  late final StreamController<bool> _changes;
  StreamSubscription<List<ConnectivityResult>>? _platform;
  bool? _last;

  /// Whether [results] mean some network interface is up.
  static bool isOnlineResult(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get online => _changes.stream;

  @override
  Future<bool> isOnline() async {
    try {
      final online = isOnlineResult(await _connectivity.checkConnectivity());
      _last = online;
      return online;
    } on Object catch (error, stack) {
      _logger.warning('connectivity check failed', error: error, stack: stack);
      return _last ?? true;
    }
  }

  void _listen() {
    _platform = _connectivity.onConnectivityChanged.listen(
      (results) {
        final online = isOnlineResult(results);
        if (online == _last) return;
        _last = online;
        _changes.add(online);
      },
      onError: (Object error, StackTrace stack) => _logger.warning(
        'connectivity stream error',
        error: error,
        stack: stack,
      ),
    );
  }

  Future<void> _stop() async {
    await _platform?.cancel();
    _platform = null;
  }
}
