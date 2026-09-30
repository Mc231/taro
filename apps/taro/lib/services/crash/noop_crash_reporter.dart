import 'package:taro_core/taro_core.dart';

/// The `CrashReporter` that drops everything (dev flavor, where Crashlytics
/// is off; 02 §5, §15).
final class NoOpCrashReporter implements CrashReporter {
  /// Creates the no-op reporter.
  const NoOpCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    Map<String, Object> context = const {},
  }) async {}

  @override
  void log(String breadcrumb) {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}
