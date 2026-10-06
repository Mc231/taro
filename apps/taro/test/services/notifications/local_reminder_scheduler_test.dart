import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/notifications/local_reminder_scheduler.dart';
import 'package:taro/services/notifications/no_op_reminder_scheduler.dart';
import 'package:taro/services/notifications/reminder_copy.dart';
import 'package:taro_core/taro_core.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

/// One `zonedSchedule` call.
typedef ScheduleCall = ({
  int id,
  tz.TZDateTime at,
  String? title,
  String? body,
  String? payload,
  NotificationDetails details,
  AndroidScheduleMode mode,
  DateTimeComponents? match,
});

final class _Android extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  bool? answer = true;
  int requests = 0;

  @override
  Future<bool?> requestNotificationsPermission() async {
    requests++;
    return answer;
  }
}

final class _Ios extends Fake implements IOSFlutterLocalNotificationsPlugin {
  bool? answer = true;
  final List<Map<String, bool>> requests = [];

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requests.add({
      'sound': sound,
      'alert': alert,
      'badge': badge,
      'provisional': provisional,
    });
    return answer;
  }
}

/// The plugin as the OS sees it: pending ids, calls, a scriptable launch.
final class _Plugin extends Fake implements FlutterLocalNotificationsPlugin {
  final Set<int> pending = {};
  final List<ScheduleCall> scheduled = [];
  final List<int> cancelled = [];
  final _Android android = _Android();
  final _Ios ios = _Ios();
  InitializationSettings? settings;
  DidReceiveNotificationResponseCallback? onTap;
  NotificationAppLaunchDetails? launch;
  int initializations = 0;
  Exception? initError;
  Exception? scheduleError;
  Exception? cancelError;
  Exception? permissionError;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializations++;
    if (initError != null) throw initError!;
    this.settings = settings;
    onTap = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (scheduleError != null) throw scheduleError!;
    pending.add(id);
    scheduled.add((
      id: id,
      at: scheduledDate,
      title: title,
      body: body,
      payload: payload,
      details: notificationDetails,
      mode: androidScheduleMode,
      match: matchDateTimeComponents,
    ));
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    if (cancelError != null) throw cancelError!;
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (permissionError != null) throw permissionError!;
    if (T == AndroidFlutterLocalNotificationsPlugin) return android as T;
    if (T == IOSFlutterLocalNotificationsPlugin) return ios as T;
    return null;
  }
}

ReminderCopy _copy(String locale) => ReminderCopy(
  channelName: 'Daily reminder ($locale)',
  channelDescription: 'Your daily card',
  variants: [
    for (var i = 0; i < kReminderVariantCount; i++)
      ReminderMessage(title: '$locale title $i', body: '$locale body $i'),
  ],
);

final class _Harness implements ReminderSchedulerHarness {
  _Harness({TargetPlatform platform = TargetPlatform.android})
    : subject = LocalReminderScheduler(
        clock: FakeClock(),
        timezones: FakeTimezoneProvider(),
        copy: _copy,
        logger: CapturingLogger(),
        plugin: plugin,
        platform: platform,
      );

  static _Plugin plugin = _Plugin();

  @override
  final LocalReminderScheduler subject;

  @override
  int get scheduledReminders => plugin.pending.length;
}

void main() {
  const on = ReminderSettings(enabled: true, time: '08:30');
  late _Plugin plugin;
  late FakeClock clock;
  late FakeTimezoneProvider zones;
  late CapturingLogger logger;

  setUpAll(tz_data.initializeTimeZones);

  setUp(() {
    plugin = _Harness.plugin = _Plugin();
    // 2026-09-26 09:00 UTC = 12:00 in Kyiv (UTC+3).
    clock = FakeClock();
    zones = FakeTimezoneProvider();
    logger = CapturingLogger();
  });

  LocalReminderScheduler scheduler({
    TargetPlatform platform = TargetPlatform.android,
    ReminderCopyResolver copy = _copy,
  }) => LocalReminderScheduler(
    clock: clock,
    timezones: zones,
    copy: copy,
    logger: logger,
    plugin: plugin,
    platform: platform,
  );

  runReminderSchedulerContract(_Harness.new);

  group('initialisation', () {
    test('never asks for permission and never sets a badge', () async {
      await scheduler().schedule(on, 'en');
      final settings = plugin.settings!;
      expect(settings.android!.defaultIcon, LocalReminderScheduler.androidIcon);
      final darwin = settings.iOS!;
      expect(darwin.requestAlertPermission, isFalse);
      expect(darwin.requestSoundPermission, isFalse);
      expect(darwin.requestBadgePermission, isFalse);
      expect(darwin.defaultPresentBadge, isFalse);
      expect(plugin.android.requests, 0);
      expect(plugin.ios.requests, isEmpty);
    });

    test('initialises once', () async {
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      await reminders.cancelAll();
      await reminders.requestPermission();
      expect(plugin.initializations, 1);
    });

    test('a failed initialisation disables the scheduler', () async {
      plugin.initError = PlatformException(code: 'init');
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      await reminders.cancelAll();
      expect(await reminders.requestPermission(), isFalse);
      expect(plugin.scheduled, isEmpty);
      expect(plugin.cancelled, isEmpty);
      expect(logger.records.single.message, 'initialize failed');
    });
  });

  group('schedule', () {
    test(
      'a daily, inexact, badge-free reminder opening taro://daily',
      () async {
        await scheduler().schedule(on, 'en');
        final call = plugin.scheduled.single;
        expect(call.id, kDailyReminderId);
        expect(call.mode, AndroidScheduleMode.inexactAllowWhileIdle);
        expect(call.match, DateTimeComponents.time);
        expect(call.payload, kDailyReminderPayload);
        final android = call.details.android!;
        expect(android.channelId, kDailyReminderChannelId);
        expect(android.channelName, 'Daily reminder (en)');
        expect(android.channelDescription, 'Your daily card');
        expect(android.channelShowBadge, isFalse);
        expect(call.details.iOS!.presentBadge, isFalse);
        expect(call.details.iOS!.badgeNumber, isNull);
      },
    );

    test(
      'a time already past today fires tomorrow in the device zone',
      () async {
        await scheduler().schedule(on, 'en');
        final at = plugin.scheduled.single.at;
        expect(at.location.name, 'Europe/Kyiv');
        expect(
          [at.year, at.month, at.day, at.hour, at.minute],
          [
            2026,
            9,
            27,
            8,
            30,
          ],
        );
        expect(at.toUtc(), DateTime.utc(2026, 9, 27, 5, 30));
      },
    );

    test('a later time fires today', () async {
      await scheduler().schedule(on.copyWith(time: '21:00'), 'en');
      final at = plugin.scheduled.single.at;
      expect([at.day, at.hour, at.minute], [26, 21, 0]);
    });

    test('the current minute counts as past', () async {
      await scheduler().schedule(on.copyWith(time: '12:00'), 'en');
      expect(plugin.scheduled.single.at.day, 27);
    });

    test('uses the locale copy of the fire date', () async {
      await scheduler().schedule(on, 'uk');
      final call = plugin.scheduled.single;
      final variant = LocalReminderScheduler.variantFor(
        call.at,
        kReminderVariantCount,
      );
      expect(call.title, 'uk title $variant');
      expect(call.body, 'uk body $variant');
      expect(call.details.android!.channelName, 'Daily reminder (uk)');
    });

    test('rotates through the six variants on consecutive days', () async {
      final reminders = scheduler();
      final titles = <String?>[];
      for (var day = 0; day < 7; day++) {
        await reminders.schedule(on, 'en');
        titles.add(plugin.scheduled.last.title);
        clock.advance(const Duration(days: 1));
      }
      expect(titles.take(6).toSet(), hasLength(6));
      expect(titles[6], titles[0]);
    });

    test('is idempotent: the same reminder does not touch the OS', () async {
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      await reminders.schedule(on, 'en');
      clock.advance(const Duration(minutes: 30));
      await reminders.schedule(on, 'en');
      expect(plugin.scheduled, hasLength(1));
      expect(plugin.pending, {kDailyReminderId});
    });

    test('concurrent launch and resume calls schedule once', () async {
      final reminders = scheduler();
      await Future.wait([
        reminders.schedule(on, 'en'),
        reminders.schedule(on, 'en'),
      ]);
      expect(plugin.scheduled, hasLength(1));
    });

    test('a new time, locale or zone reschedules under the same id', () async {
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      await reminders.schedule(on.copyWith(time: '07:00'), 'en');
      await reminders.schedule(on.copyWith(time: '07:00'), 'de');
      zones.iana = 'America/New_York';
      await reminders.schedule(on.copyWith(time: '07:00'), 'de');
      expect(plugin.scheduled, hasLength(4));
      expect(plugin.scheduled.map((c) => c.id).toSet(), {kDailyReminderId});
      expect(plugin.scheduled.last.at.location.name, 'America/New_York');
      expect(plugin.pending, hasLength(1));
    });

    test(
      'disabled settings cancel even a reminder from an earlier launch',
      () async {
        plugin.pending.add(kDailyReminderId);
        await scheduler().schedule(const ReminderSettings(), 'en');
        expect(plugin.cancelled, [kDailyReminderId]);
        expect(plugin.pending, isEmpty);
      },
    );

    test('after a cancel the same reminder is scheduled again', () async {
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      await reminders.cancelAll();
      await reminders.schedule(on, 'en');
      expect(plugin.scheduled, hasLength(2));
      expect(plugin.pending, {kDailyReminderId});
    });

    // Android still reports legacy IANA links (Ukraine is `Europe/Kiev`,
    // India `Asia/Calcutta`). setUpAll loads only the canonical `latest`
    // data, so this passes only when the scheduler loads the full database
    // itself (round 4: reminders fired at 09:00 UTC instead of local time).
    for (final (legacy, offset) in [
      ('Europe/Kiev', 3),
      ('Asia/Calcutta', 5),
      ('America/Buenos_Aires', -3),
    ]) {
      test('a legacy zone name $legacy fires in local time', () async {
        zones.iana = legacy;
        await scheduler().schedule(on, 'en');
        final at = plugin.scheduled.single.at;
        expect(at.location.name, legacy);
        expect(at.timeZoneOffset.inHours, offset);
        expect([at.hour, at.minute], [8, 30]);
        expect(logger.records, isEmpty);
      });
    }

    test('an unknown zone falls back to UTC', () async {
      zones.iana = 'Mars/Olympus_Mons';
      await scheduler().schedule(on, 'en');
      final at = plugin.scheduled.single.at;
      expect(at.location.name, endsWith('UTC'));
      expect(at.timeZoneOffset, Duration.zero);
      expect(logger.records.single.level, LogLevel.warning);
    });

    test('missing copy schedules nothing', () async {
      await scheduler(
        copy: (_) => const ReminderCopy(
          channelName: 'x',
          channelDescription: 'y',
          variants: [],
        ),
      ).schedule(on, 'en');
      expect(plugin.scheduled, isEmpty);
      expect(logger.records.single.message, 'no reminder copy for en');
    });

    test('an OS error is logged and the next call retries', () async {
      plugin.scheduleError = PlatformException(code: 'alarm');
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      expect(plugin.pending, isEmpty);
      expect(logger.records.single.message, 'schedule failed');
      plugin.scheduleError = null;
      await reminders.schedule(on, 'en');
      expect(plugin.pending, {kDailyReminderId});
    });

    test('a failed cancel is logged, never thrown', () async {
      plugin.cancelError = PlatformException(code: 'cancel');
      final reminders = scheduler();
      await reminders.cancelAll();
      await reminders.schedule(const ReminderSettings(), 'en');
      expect(logger.records.map((r) => r.message), [
        'cancel failed',
        'cancel failed',
      ]);
    });
  });

  group('nextFire', () {
    test('handles the autumn DST change in the zone', () {
      final kyiv = tz.getLocation('Europe/Kyiv');
      // 2026-10-25 04:00 local (after clocks went back at 04:00 EEST).
      final at = LocalReminderScheduler.nextFire(
        on,
        kyiv,
        DateTime.utc(2026, 10, 24, 18),
      );
      expect([at.day, at.hour, at.minute], [25, 8, 30]);
      expect(at.toUtc(), DateTime.utc(2026, 10, 25, 6, 30));
    });

    test('crosses month ends', () {
      final at = LocalReminderScheduler.nextFire(
        on,
        tz.UTC,
        DateTime.utc(2026, 9, 30, 23),
      );
      expect([at.month, at.day], [10, 1]);
    });
  });

  group('requestPermission', () {
    test('asks POST_NOTIFICATIONS on Android', () async {
      final reminders = scheduler();
      expect(await reminders.requestPermission(), isTrue);
      expect(plugin.android.requests, 1);
      plugin.android.answer = null;
      expect(await reminders.requestPermission(), isFalse);
    });

    test('asks alert and sound, never badge, on iOS', () async {
      final reminders = scheduler(platform: TargetPlatform.iOS);
      expect(await reminders.requestPermission(), isTrue);
      expect(plugin.ios.requests.single, {
        'sound': true,
        'alert': true,
        'badge': false,
        'provisional': false,
      });
      plugin.ios.answer = false;
      expect(await reminders.requestPermission(), isFalse);
    });

    test('other platforms are never granted', () async {
      expect(
        await scheduler(platform: TargetPlatform.linux).requestPermission(),
        isFalse,
      );
    });

    test('a platform error answers false', () async {
      plugin.permissionError = PlatformException(code: 'denied');
      expect(await scheduler().requestPermission(), isFalse);
      expect(logger.records.single.message, 'permission request failed');
    });
  });

  group('taps', () {
    NotificationResponse response(String? payload) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: payload,
    );

    test('a tap emits its route', () async {
      final reminders = scheduler();
      final taps = <String>[];
      final sub = reminders.taps.listen(taps.add);
      await reminders.schedule(on, 'en');
      plugin.onTap!(response(kDailyReminderPayload));
      await settle();
      await sub.cancel();
      expect(taps, [kDailyReminderPayload]);
    });

    test('a tap that launched the app reaches the first listener', () async {
      plugin.launch = NotificationAppLaunchDetails(
        true,
        notificationResponse: response(kDailyReminderPayload),
      );
      final reminders = scheduler();
      await reminders.schedule(on, 'en');
      final taps = <String>[];
      final sub = reminders.taps.listen(taps.add);
      await settle();
      await sub.cancel();
      expect(taps, [kDailyReminderPayload]);
    });

    test('listening initialises the plugin', () async {
      final reminders = scheduler();
      final sub = reminders.taps.listen((_) {});
      await settle();
      await sub.cancel();
      expect(plugin.initializations, 1);
    });

    test('ignores empty payloads and non-notification launches', () async {
      plugin.launch = const NotificationAppLaunchDetails(false);
      final reminders = scheduler();
      final taps = <String>[];
      final sub = reminders.taps.listen(taps.add);
      await settle();
      plugin.onTap!(response(null));
      plugin.onTap!(response(''));
      await settle();
      await sub.cancel();
      expect(taps, isEmpty);
    });

    test('a launch without a response emits nothing', () async {
      plugin.launch = const NotificationAppLaunchDetails(true);
      final reminders = scheduler();
      final taps = <String>[];
      final sub = reminders.taps.listen(taps.add);
      await settle();
      await sub.cancel();
      expect(taps, isEmpty);
    });
  });

  group('variantFor', () {
    test('consecutive local dates use consecutive variants', () {
      final kyiv = tz.getLocation('Europe/Kyiv');
      final a = tz.TZDateTime(kyiv, 2026, 9, 27, 8, 30);
      final b = tz.TZDateTime(kyiv, 2026, 9, 28, 0, 1);
      expect(
        LocalReminderScheduler.variantFor(b, 6),
        (LocalReminderScheduler.variantFor(a, 6) + 1) % 6,
      );
    });
  });

  group('NoOpReminderScheduler', () {
    test('schedules nothing, is never granted and never taps', () async {
      // Not const, so the constructor line runs (coverage).
      // ignore: prefer_const_constructors
      final reminders = NoOpReminderScheduler();
      await reminders.schedule(on, 'en');
      await reminders.cancelAll();
      expect(await reminders.requestPermission(), isFalse);
      expect(await reminders.taps.isEmpty, isTrue);
    });
  });

  test('ReminderMessage compares by value', () {
    const a = ReminderMessage(title: 't', body: 'b');
    expect(a, const ReminderMessage(title: 't', body: 'b'));
    expect(a.hashCode, const ReminderMessage(title: 't', body: 'b').hashCode);
    expect(a, isNot(const ReminderMessage(title: 't', body: 'c')));
  });

  test('default plugin and platform', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(
      LocalReminderScheduler(
        clock: clock,
        timezones: zones,
        copy: _copy,
        logger: logger,
      ),
      isA<ReminderScheduler>(),
    );
  });
}
