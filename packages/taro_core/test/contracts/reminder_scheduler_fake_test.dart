import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements ReminderSchedulerHarness {
  final FakeReminderScheduler reminders = FakeReminderScheduler();

  @override
  ReminderScheduler get subject => reminders;

  @override
  int get scheduledReminders => reminders.scheduled == null ? 0 : 1;
}

void main() {
  runReminderSchedulerContract(_Harness.new);

  test('permission answer and taps', () async {
    final reminders = FakeReminderScheduler(permission: false);
    expect(await reminders.requestPermission(), isFalse);
    expect(reminders.permissionRequests, 1);
    final taps = <String>[];
    final sub = reminders.taps.listen(taps.add);
    reminders.tap('/daily');
    await settle();
    await sub.cancel();
    expect(taps, ['/daily']);
  });
}
