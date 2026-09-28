import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  group('FakeClock', () => runClockContract(FakeClock.new));
  group('FakeClock in UTC', () => runClockContract(FakeClock.utc));
  group('SystemClock', () => runClockContract(SystemClock.new));

  group('FakeClock hooks', () {
    test('advance, setNow and the local date', () {
      final clock = FakeClock();
      expect(clock.now(), kTestNow);
      expect(clock.localDate, kTestLocalDate);
      expect(clock.utcOffset, kTestUtcOffset);
      clock.advance(const Duration(hours: 12));
      expect(clock.localDate, '2026-09-27');
      clock.setNow(DateTime.utc(2026));
      expect(clock.now(), DateTime.utc(2026));
      expect(clock.reads, greaterThan(0));
    });

    test('setTimeZone moves the wall clock and the IANA name', () async {
      final clock = FakeClock.utc(DateTime.utc(2026, 9, 26, 23, 30));
      expect(clock.nowLocal().day, 26);
      clock.setTimeZone(
        'Asia/Kolkata',
        utcOffset: const Duration(hours: 5, minutes: 30),
      );
      expect(await clock.currentIana(), 'Asia/Kolkata');
      expect(clock.nowLocal().day, 27);
      expect(clock.nowLocal().hour, 5);
      clock.setTimeZone(
        'America/New_York',
        offsetAt: (utc) => utc.month < 11
            ? const Duration(hours: -4)
            : const Duration(hours: -5),
      );
      expect(clock.nowLocal().hour, 19);
    });

    test('delay advances instead of waiting', () async {
      final clock = FakeClock();
      await clock.delay(const Duration(minutes: 5));
      expect(clock.now(), kTestNow.add(const Duration(minutes: 5)));
    });
  });
}
