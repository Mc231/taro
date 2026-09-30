import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

final class _BrokenTimezone implements TimezoneProvider {
  @override
  Future<String> currentIana() async => throw StateError('no zone');
}

void main() {
  late TaroFakes fakes;
  late ProviderContainer container;
  late SyncCoordinator sync;

  setUp(() {
    fakes = TaroFakes();
    container = fakes.container();
    sync = container.read(syncCoordinatorProvider);
  });

  group('SyncCoordinator (06 §2.5 "Resume re-sync")', () {
    test('a launch pass runs every step and reports synced', () async {
      fakes.iap.owned.add(TaroProducts.removeAds.id);
      final status = await sync.run(SyncReason.launch);

      expect(status, SyncStatus.synced(at: fakes.clock.now()));
      expect(fakes.balance.requests, 1);
      expect(fakes.balance.syncReasons, [SyncReason.launch]);
      expect(fakes.install.calls, contains('ensureRegistered'));
      expect(fakes.config.calls, contains('refresh'));
      expect(fakes.outbox.calls, contains('pending'));
      expect(fakes.readings.calls, contains('flushPendingAcks'));
      expect(fakes.reminders.calls, contains('schedule'));
      expect(fakes.warmUps, 1);
      expect(fakes.entitlements.entitlement.removesAds, isTrue);
      expect(sync.current, status);
      expect(sync.runs, 1);
    });

    test('resume after advance(1 day) → exactly one balance sync', () async {
      await sync.run(SyncReason.launch);
      fakes.clock.advance(const Duration(days: 1));
      await sync.run(SyncReason.resume);
      expect(fakes.balance.requests, 2);
      expect(fakes.balance.syncReasons, [
        SyncReason.launch,
        SyncReason.resume,
      ]);
    });

    test('a same-day resume within the throttle is skipped', () async {
      await sync.run(SyncReason.launch);
      fakes.clock.advance(const Duration(seconds: 10));
      final status = await sync.run(SyncReason.resume);
      await sync.run(SyncReason.connectivityRegained);
      expect(fakes.balance.requests, 1);
      expect(sync.runs, 1);
      expect(status, isA<SyncStatusSynced>());
    });

    test('a resume after the throttle runs again', () async {
      await sync.run(SyncReason.launch);
      fakes.clock.advance(const Duration(seconds: 31));
      await sync.run(SyncReason.resume);
      expect(fakes.balance.requests, 2);
    });

    test(
      'launch, reset boundary and manual passes are never skipped',
      () async {
        await sync.run(SyncReason.launch);
        await sync.run(SyncReason.resetBoundary);
        await sync.run(SyncReason.manual);
        expect(fakes.balance.requests, 3);
      },
    );

    test('a resume during an in-flight sync joins it', () async {
      fakes.balance.pauseSync();
      final launch = sync.run(SyncReason.launch);
      final resume = sync.run(SyncReason.resume);
      expect(sync.isRunning, isTrue);
      await pumpEventQueue();
      fakes.balance.resumeSync();
      expect(await resume, await launch);
      expect(fakes.balance.requests, 1);
      expect(sync.runs, 1);
      expect(sync.isRunning, isFalse);
    });

    test('a time zone change triggers exactly one PUT', () async {
      await sync.run(SyncReason.launch);
      fakes.clock
        ..setTimeZone('America/New_York', utcOffset: const Duration(hours: -4))
        ..advance(const Duration(seconds: 5));
      await sync.run(SyncReason.resume);
      fakes.clock.advance(const Duration(seconds: 5));
      await sync.run(SyncReason.resume);
      expect(fakes.install.timezoneUpdates, ['America/New_York']);
      expect(fakes.balance.cached!.free.timezone, 'America/New_York');
    });

    test('a 409 keeps the server boundary', () async {
      await sync.run(SyncReason.launch);
      final before = fakes.balance.cached!;
      fakes.install.failNext(
        Failure.timezoneChangeRejected(allowedAfter: kTestNow),
        on: 'updateTimezone',
      );
      fakes.clock.setTimeZone(
        'Asia/Tokyo',
        utcOffset: const Duration(hours: 9),
      );
      await sync.run(SyncReason.resume);
      expect(fakes.install.timezoneUpdates, ['Asia/Tokyo']);
      expect(fakes.balance.cached!.free.timezone, before.free.timezone);
      expect(fakes.balance.cached!.free.resetsAt, before.free.resetsAt);
    });

    test('a stale balance response never overwrites a newer one (RC67)', () {
      final newer = aCreditBalance()
          .withLedgerVersion(5)
          .withServerTime(kTestNow)
          .withBonus(2)
          .build();
      fakes.balance
        ..seed(newer)
        ..server = aCreditBalance()
            .withLedgerVersion(4)
            .withServerTime(kTestNow.subtract(const Duration(minutes: 1)))
            .build();
      return expectLater(
        () async {
          await sync.run(SyncReason.manual);
          expect(container.read(balanceProvider), newer);
          fakes.balance.server = aCreditBalance()
              .withLedgerVersion(5)
              .withServerTime(kTestNow.subtract(const Duration(seconds: 1)))
              .build();
          await sync.run(SyncReason.manual);
          expect(container.read(balanceProvider), newer);
        }(),
        completes,
      );
    });

    test('a failed balance sync with a cache is stale', () async {
      fakes.balance.failNext(const Failure.network(), on: 'sync');
      final status = await sync.run(SyncReason.launch);
      expect(status, isA<SyncStatusStale>());
    });

    test('a failing extra step is logged and the pass continues', () async {
      final failing = TaroFakes()
        ..warmUp = () async => throw StateError('prepare failed');
      final c = failing.container();
      final status = await c
          .read(syncCoordinatorProvider)
          .run(
            SyncReason.launch,
          );
      expect(status, isA<SyncStatusSynced>());
      expect(failing.logger.logged('sync step failed'), isTrue);
    });

    test('an unreadable time zone falls back to the cached balance', () async {
      final broken = TaroFakes()..timezone = _BrokenTimezone();
      final c = broken.container();
      final status = await c
          .read(syncCoordinatorProvider)
          .run(
            SyncReason.launch,
          );
      expect(status, isA<SyncStatusStale>());
      expect(broken.logger.logged('time zone unreadable'), isTrue);
      expect(broken.logger.logged('sync pass failed'), isTrue);

      broken.balance.seed(null);
      final none = await c.read(syncCoordinatorProvider).run(SyncReason.launch);
      expect(none, isA<SyncStatusUnavailable>());
    });

    test('connectivity regained runs a pass', () async {
      fakes.connectivity.setOnline(online: false);
      await pumpEventQueue();
      expect(sync.runs, 0);
      fakes.connectivity.setOnline(online: true);
      await pumpEventQueue();
      expect(sync.runs, 1);
      expect(fakes.balance.syncReasons, [SyncReason.connectivityRegained]);
    });

    test('syncStatusProvider replays the current status, then changes', () {
      final seen = <SyncStatus>[];
      container.listen(
        syncStatusProvider,
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      return expectLater(
        () async {
          await pumpEventQueue();
          await sync.run(SyncReason.launch);
          await pumpEventQueue();
          expect(seen, [
            isA<SyncStatusStale>(),
            const SyncStatus.syncing(),
            isA<SyncStatusSynced>(),
          ]);
        }(),
        completes,
      );
    });

    test('dispose closes the status stream', () async {
      final done = Completer<void>();
      sync.status.listen(null, onDone: done.complete);
      container.dispose();
      await done.future;
    });
  });
}
