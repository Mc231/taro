import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:taro_core/taro_core.dart';

/// Reads the device IANA zone name from the platform.
typedef LocalTimezoneReader = Future<String> Function();

/// The production [TimezoneProvider] over `flutter_timezone` (02 §5).
///
/// The platform name is validated: UTC aliases (`GMT`, `Zulu`, …) become
/// `UTC`; anything else that is not an `Area/Location` name, or a platform
/// error, falls back to the last good answer (then `UTC`) with a warning,
/// so the Worker never receives a malformed zone.
final class FlutterTimezoneProvider implements TimezoneProvider {
  /// A provider over [read] (default: `FlutterTimezone.getLocalTimezone`).
  FlutterTimezoneProvider({required Logger logger, LocalTimezoneReader? read})
    : _logger = logger.child('timezone'),
      _read = read ?? readPlatformTimezone;

  final Logger _logger;
  final LocalTimezoneReader _read;
  String? _lastGood;

  static final RegExp _iana = RegExp(
    r'^(UTC|[A-Z][A-Za-z_]+(/[A-Za-z0-9_+-]+)+)$',
  );

  static const Set<String> _utcAliases = {
    'GMT',
    'GMT0',
    'GMT+0',
    'GMT-0',
    'Greenwich',
    'UCT',
    'Universal',
    'Zulu',
    'Z',
  };

  /// The zone name reported by the `flutter_timezone` plugin.
  static Future<String> readPlatformTimezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  /// [raw] as an IANA zone name the Worker accepts, or `null`.
  static String? normalize(String raw) {
    final name = raw.trim();
    if (_utcAliases.contains(name)) return 'UTC';
    return _iana.hasMatch(name) ? name : null;
  }

  @override
  Future<String> currentIana() async {
    try {
      final iana = normalize(await _read());
      if (iana != null) return _lastGood = iana;
      _logger.warning('unrecognised platform time zone');
    } on Object catch (error, stack) {
      _logger.warning('time zone lookup failed', error: error, stack: stack);
    }
    return _lastGood ?? 'UTC';
  }
}
