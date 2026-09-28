import 'package:test/test.dart';

import 'boundary_zones.dart';
import 'logic_support.dart';

void main() {
  final server = DateTime.utc(2026, 9, 26, 9, 12, 44);

  group('ServerClockOffset', () {
    test('fromSample: server ahead of the device is positive', () {
      final o = ServerClockOffset.fromSample(
        serverTime: server,
        receivedAt: server.subtract(const Duration(minutes: 7)),
      );
      expect(o.offset, const Duration(minutes: 7));
      expect(
        o.serverNow(server.subtract(const Duration(minutes: 6))),
        server.add(const Duration(minutes: 1)),
      );
      expect(o.toDevice(server), server.subtract(const Duration(minutes: 7)));
    });

    test('fromBalance uses serverTime and syncedAt', () {
      final b = aBalance(
        serverTime: server,
        syncedAt: server.add(const Duration(hours: 3)),
      );
      expect(
        ServerClockOffset.fromBalance(b),
        const ServerClockOffset(Duration(hours: -3)),
      );
    });

    test('remainingUntil never goes negative', () {
      const o = ServerClockOffset.zero;
      expect(
        o.remainingUntil(server, server.subtract(const Duration(seconds: 5))),
        const Duration(seconds: 5),
      );
      expect(
        o.remainingUntil(server, server.add(const Duration(hours: 1))),
        Duration.zero,
      );
    });

    test('countdown uses serverTime + monotonic elapsed (04 §5.3)', () {
      final target = server.add(const Duration(hours: 3));
      expect(
        ServerClockOffset.countdown(
          target: target,
          serverTime: server,
          elapsedSinceResponse: const Duration(minutes: 10),
        ),
        const Duration(hours: 2, minutes: 50),
      );
      expect(
        ServerClockOffset.countdown(
          target: target,
          serverTime: server,
          elapsedSinceResponse: const Duration(hours: 4),
        ),
        Duration.zero,
      );
    });

    test('a local device time is handled as its UTC instant', () {
      const o = ServerClockOffset(Duration(seconds: 30));
      final local = DateTime(2026, 9, 26, 12);
      expect(
        o.serverNow(local),
        local.toUtc().add(const Duration(seconds: 30)),
      );
      expect(o.serverNow(local).isUtc, isTrue);
    });

    test('value semantics', () {
      expect(
        const ServerClockOffset(Duration(seconds: 1)),
        const ServerClockOffset(Duration(seconds: 1)),
      );
      expect(
        const ServerClockOffset(Duration(seconds: 1)).hashCode,
        const Duration(seconds: 1).hashCode,
      );
      expect(
        ServerClockOffset.zero,
        isNot(const ServerClockOffset(Duration(seconds: 1))),
      );
      expect(
        ServerClockOffset.zero.toString(),
        'ServerClockOffset(0:00:00.000000)',
      );
    });
  });

  group('ResetSchedule over kBoundaryZones (06 §2.1)', () {
    const skews = [
      Duration.zero,
      Duration(minutes: 7),
      Duration(hours: -3),
    ];

    for (final zone in kBoundaryZones) {
      group(zone.name, () {
        for (final serverNow in kBoundaryInstants) {
          test('at $serverNow the sync fires at local midnight', () {
            final resetsAt = zone.nextMidnight(serverNow);
            expect(resetsAt.isAfter(serverNow), isTrue);
            expect(
              zone.localDate(resetsAt),
              LocalDates.addDays(zone.localDate(serverNow), 1),
            );
            expect(
              zone.localDate(resetsAt.subtract(const Duration(seconds: 1))),
              zone.localDate(serverNow),
            );
            for (final skew in skews) {
              // The device clock is `skew` behind the server.
              final deviceNow = serverNow.subtract(skew);
              final b = aBalance(
                resetsAt: resetsAt,
                serverTime: serverNow,
                syncedAt: deviceNow,
              );
              expect(
                ResetSchedule.nextSyncAt(b, deviceNow),
                resetsAt.subtract(skew),
              );
              expect(
                ResetSchedule.delayUntilSync(b, deviceNow),
                resetsAt.difference(serverNow),
              );
              expect(
                ResetSchedule.untilNextFree(b, deviceNow),
                resetsAt.difference(serverNow),
              );
              // Resume after the reset: due now.
              final later = resetsAt
                  .subtract(skew)
                  .add(const Duration(minutes: 1));
              expect(ResetSchedule.nextSyncAt(b, later), later);
              expect(ResetSchedule.delayUntilSync(b, later), Duration.zero);
              expect(ResetSchedule.untilNextFree(b, later), Duration.zero);
            }
          });
        }
      });
    }

    test('DST days are 23 h and 25 h long (America/New_York, Europe/Kyiv)', () {
      final ny = kBoundaryZones.firstWhere((z) => z.name == 'America/New_York');
      final kyiv = kBoundaryZones.firstWhere((z) => z.name == 'Europe/Kyiv');
      expect(
        ny.dayLength(DateTime.utc(2026, 3, 8, 12)),
        const Duration(hours: 23),
      );
      expect(
        ny.dayLength(DateTime.utc(2026, 11, 1, 12)),
        const Duration(hours: 25),
      );
      expect(
        ny.dayLength(DateTime.utc(2026, 6, 1, 12)),
        const Duration(hours: 24),
      );
      expect(
        kyiv.dayLength(DateTime.utc(2026, 3, 29, 12)),
        const Duration(hours: 23),
      );
      expect(
        kyiv.dayLength(DateTime.utc(2026, 10, 25, 12)),
        const Duration(hours: 25),
      );
      // The countdown from local midnight covers the whole short day.
      final start = DateTime.utc(2026, 3, 8, 5);
      final b = aBalance(
        resetsAt: ny.nextMidnight(start),
        serverTime: start,
        syncedAt: start,
      );
      expect(ResetSchedule.untilNextFree(b, start), const Duration(hours: 23));
    });

    test('an explicit offset overrides the balance skew', () {
      final b = aBalance(resetsAt: DateTime.utc(2026, 9, 26, 22));
      final now = DateTime.utc(2026, 9, 26, 21);
      expect(
        ResetSchedule.nextSyncAt(
          b,
          now,
          offset: const ServerClockOffset(Duration(minutes: 30)),
        ),
        DateTime.utc(2026, 9, 26, 21, 30),
      );
      expect(
        ResetSchedule.untilNextFree(
          b,
          now,
          offset: const ServerClockOffset(Duration(minutes: 30)),
        ),
        const Duration(minutes: 30),
      );
    });
  });
}
