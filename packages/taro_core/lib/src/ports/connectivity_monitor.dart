/// A connectivity hint (02 §5, §10). The authoritative offline signal is a
/// `NetworkFailure` from a request.
abstract interface class ConnectivityMonitor {
  /// Emits whenever the online hint changes.
  Stream<bool> get online;

  /// The current online hint.
  Future<bool> isOnline();
}
