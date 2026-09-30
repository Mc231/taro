import 'package:taro_core/taro_core.dart';

/// A [ReminderScheduler] that schedules nothing (02 §5): tests, and builds
/// or platforms without local notifications. Permission is never granted
/// and no tap is ever emitted.
final class NoOpReminderScheduler implements ReminderScheduler {
  /// Creates the no-op scheduler.
  const NoOpReminderScheduler();

  @override
  Future<void> schedule(ReminderSettings settings, String locale) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Stream<String> get taps => const Stream<String>.empty();
}
