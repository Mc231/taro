/// Crash and non-fatal reporting (Crashlytics, 02 §5, §13).
abstract interface class CrashReporter {
  /// Records [error]; every `UnexpectedFailure` is reported non-fatal.
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    Map<String, Object> context = const {},
  });

  /// Adds a breadcrumb (already redacted).
  void log(String breadcrumb);

  /// Enables or disables collection (bound to the analytics toggle).
  Future<void> setCollectionEnabled({required bool enabled});
}
