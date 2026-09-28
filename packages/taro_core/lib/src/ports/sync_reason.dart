/// Why a sync runs (02 §9.1, §9.2).
enum SyncReason {
  /// App launch (bootstrap step 6).
  launch,

  /// `AppLifecycleState.resumed`.
  resume,

  /// The `ResetTimer` fired at `free.resetsAt + 5 s`.
  resetBoundary,

  /// Connectivity came back.
  connectivityRegained,

  /// The user asked (pull to refresh, retry button).
  manual,

  /// Before the reading gate when the cached balance is stale (02 §9.3).
  preReading,
}
