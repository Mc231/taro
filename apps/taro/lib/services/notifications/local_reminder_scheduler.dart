import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taro/services/notifications/reminder_copy.dart';
import 'package:taro_core/taro_core.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The deep link a reminder tap opens (01 §7.7, 02 §8.2).
const String kDailyReminderPayload = 'taro://daily';

/// The OS id of the one daily reminder.
const int kDailyReminderId = 1;

/// The Android notification channel of the daily reminder.
const String kDailyReminderChannelId = 'taro.daily_reminder';

/// The production [ReminderScheduler] over `flutter_local_notifications`
/// and `timezone` (02 §5, 01 §7.7).
///
/// - One daily reminder ([kDailyReminderId]) at the chosen local time,
///   repeating daily (`DateTimeComponents.time`) and scheduled with
///   [AndroidScheduleMode.inexactAllowWhileIdle]: the app never holds
///   `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`.
/// - The text rotates through the [ReminderCopy.variants] of the locale:
///   each (re)schedule picks the variant of the next fire date, and the app
///   reschedules on launch, resume and time-zone change.
/// - No badge on either platform.
/// - Initialising never asks for permission; [requestPermission] does, and
///   the app calls it only after "Yes, remind me".
/// - After a reboot the plugin's `ScheduledNotificationBootReceiver`
///   restores the reminder (Android manifest).
/// - [schedule] is idempotent: the same settings, locale, zone and variant
///   do not touch the OS again.
final class LocalReminderScheduler implements ReminderScheduler {
  /// A scheduler over [plugin] (default: the plugin singleton).
  ///
  /// [platform] picks the permission API (default: the running platform).
  LocalReminderScheduler({
    required Clock clock,
    required TimezoneProvider timezones,
    required ReminderCopyResolver copy,
    required Logger logger,
    FlutterLocalNotificationsPlugin? plugin,
    TargetPlatform? platform,
  }) : _clock = clock,
       _timezones = timezones,
       _copy = copy,
       _logger = logger.child('reminders'),
       _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _platform = platform ?? defaultTargetPlatform {
    _taps = StreamController<String>.broadcast(onListen: _flushTaps);
  }

  /// The Android small icon.
  static const String androidIcon = '@mipmap/ic_launcher';

  final Clock _clock;
  final TimezoneProvider _timezones;
  final ReminderCopyResolver _copy;
  final Logger _logger;
  final FlutterLocalNotificationsPlugin _plugin;
  final TargetPlatform _platform;

  late final StreamController<String> _taps;
  final List<String> _pendingTaps = [];

  Future<bool>? _ready;
  Future<void> _queue = Future<void>.value();
  _Scheduled? _current;

  static bool _tzLoaded = false;

  @override
  Stream<String> get taps {
    unawaited(_ensureReady());
    return _taps.stream;
  }

  @override
  Future<void> schedule(ReminderSettings settings, String locale) =>
      _serial(() => _schedule(settings, locale));

  @override
  Future<void> cancelAll() => _serial(() async {
    if (await _ensureReady()) await _cancel();
  });

  @override
  Future<bool> requestPermission() async {
    if (!await _ensureReady()) return false;
    try {
      final granted = switch (_platform) {
        TargetPlatform.android =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission(),
        TargetPlatform.iOS =>
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true),
        _ => null,
      };
      return granted ?? false;
    } on Object catch (error, stack) {
      _logger.warning('permission request failed', error: error, stack: stack);
      return false;
    }
  }

  Future<void> _schedule(ReminderSettings settings, String locale) async {
    if (!await _ensureReady()) return;
    if (!settings.enabled) return _cancel();
    final copy = _copy(locale);
    if (copy.variants.isEmpty) {
      _logger.warning('no reminder copy for $locale');
      return;
    }
    final location = _location(await _timezones.currentIana());
    final at = nextFire(settings, location, _clock.now());
    final variant = variantFor(at, copy.variants.length);
    final message = copy.variants[variant];
    final next = (
      time: settings.time,
      zone: location.name,
      message: message,
      channelName: copy.channelName,
    );
    if (next == _current) return;
    try {
      // The same id replaces the pending reminder.
      await _plugin.zonedSchedule(
        id: kDailyReminderId,
        scheduledDate: at,
        title: message.title,
        body: message.body,
        payload: kDailyReminderPayload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            kDailyReminderChannelId,
            copy.channelName,
            channelDescription: copy.channelDescription,
            channelShowBadge: false,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(presentBadge: false),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _current = next;
    } on Object catch (error, stack) {
      _current = null;
      _logger.warning('schedule failed', error: error, stack: stack);
    }
  }

  Future<void> _cancel() async {
    _current = null;
    try {
      await _plugin.cancel(id: kDailyReminderId);
    } on Object catch (error, stack) {
      _logger.warning('cancel failed', error: error, stack: stack);
    }
  }

  /// The next instant at [settings]' local time in [location], strictly
  /// after [now]. A wall time inside a DST gap resolves as `timezone` does.
  @visibleForTesting
  static tz.TZDateTime nextFire(
    ReminderSettings settings,
    tz.Location location,
    DateTime now,
  ) {
    final local = tz.TZDateTime.from(now, location);
    var at = tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day,
      settings.hour,
      settings.minute,
    );
    if (!at.isAfter(local)) {
      at = tz.TZDateTime(
        location,
        local.year,
        local.month,
        local.day + 1,
        settings.hour,
        settings.minute,
      );
    }
    return at;
  }

  /// The variant shown on the local date of [at]: consecutive days use
  /// consecutive variants.
  @visibleForTesting
  static int variantFor(tz.TZDateTime at, int count) {
    final day = DateTime.utc(at.year, at.month, at.day);
    return (day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) % count;
  }

  tz.Location _location(String iana) {
    if (!_tzLoaded) {
      tz_data.initializeTimeZones();
      _tzLoaded = true;
    }
    try {
      return tz.getLocation(iana);
    } on tz.LocationNotFoundException {
      _logger.warning('unknown time zone $iana; using UTC');
      return tz.UTC;
    }
  }

  Future<void> _serial(Future<void> Function() action) {
    final run = _queue.then((_) => action());
    _queue = run;
    return run;
  }

  Future<bool> _ensureReady() => _ready ??= _initialize();

  Future<bool> _initialize() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(androidIcon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
            defaultPresentBadge: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onResponse,
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch != null && launch.didNotificationLaunchApp) {
        final response = launch.notificationResponse;
        if (response != null) _onResponse(response);
      }
      return true;
    } on Object catch (error, stack) {
      _logger.warning('initialize failed', error: error, stack: stack);
      return false;
    }
  }

  void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (_taps.hasListener) {
      _taps.add(payload);
    } else {
      _pendingTaps.add(payload);
    }
  }

  void _flushTaps() {
    final pending = [..._pendingTaps];
    _pendingTaps.clear();
    pending.forEach(_taps.add);
  }
}

/// What is scheduled with the OS; equal values need no reschedule.
typedef _Scheduled = ({
  String time,
  String zone,
  ReminderMessage message,
  String channelName,
});
