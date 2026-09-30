import 'package:taro_core/taro_core.dart';

/// A [ConnectivityMonitor] that always reports online (02 §5): tests and
/// platforms without `connectivity_plus`. Requests still fail with a
/// `NetworkFailure`, the authoritative offline signal.
final class AlwaysOnlineMonitor implements ConnectivityMonitor {
  /// Creates the monitor.
  const AlwaysOnlineMonitor();

  @override
  Stream<bool> get online => const Stream<bool>.empty();

  @override
  Future<bool> isOnline() async => true;
}
