import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/timezone/fixed_timezone_provider.dart';
import 'package:taro/services/timezone/flutter_timezone_provider.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('flutter_timezone');
  late CapturingLogger logger;

  setUp(() {
    logger = CapturingLogger();
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getLocalTimezone');
      return 'Europe/Kyiv';
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('FlutterTimezoneProvider', () {
    runTimezoneProviderContract(
      () => FlutterTimezoneProvider(logger: CapturingLogger()),
    );

    test('reads the zone through the plugin channel', () async {
      expect(
        await FlutterTimezoneProvider(logger: logger).currentIana(),
        'Europe/Kyiv',
      );
      expect(logger.records, isEmpty);
    });

    test('keeps multi-part and Etc names', () async {
      for (final name in [
        'America/Argentina/Buenos_Aires',
        'Etc/GMT+3',
        'Etc/UTC',
        'UTC',
      ]) {
        expect(
          await FlutterTimezoneProvider(
            logger: logger,
            read: () async => name,
          ).currentIana(),
          name,
        );
      }
    });

    test('maps UTC aliases to UTC', () async {
      for (final alias in ['GMT', 'Zulu', 'UCT', ' GMT ']) {
        expect(
          await FlutterTimezoneProvider(
            logger: logger,
            read: () async => alias,
          ).currentIana(),
          'UTC',
        );
      }
    });

    test('a malformed name falls back to the last good zone', () async {
      var answer = 'Asia/Tokyo';
      final zones = FlutterTimezoneProvider(
        logger: logger,
        read: () async => answer,
      );
      expect(await zones.currentIana(), 'Asia/Tokyo');
      answer = 'EST5EDT';
      expect(await zones.currentIana(), 'Asia/Tokyo');
      expect(logger.messages, ['unrecognised platform time zone']);
    });

    test('a platform error falls back to UTC before any good answer', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'tz'),
      );
      expect(
        await FlutterTimezoneProvider(logger: logger).currentIana(),
        'UTC',
      );
      expect(logger.messages, ['time zone lookup failed']);
    });

    test('normalize', () {
      expect(FlutterTimezoneProvider.normalize('Europe/Kyiv'), 'Europe/Kyiv');
      expect(FlutterTimezoneProvider.normalize('Greenwich'), 'UTC');
      expect(FlutterTimezoneProvider.normalize(''), isNull);
      expect(FlutterTimezoneProvider.normalize('europe/kyiv'), isNull);
    });
  });

  group('FixedTimezoneProvider', () {
    runTimezoneProviderContract(FixedTimezoneProvider.new);

    test('reports its zone', () async {
      expect(await const FixedTimezoneProvider().currentIana(), 'UTC');
      expect(
        await const FixedTimezoneProvider('Europe/Berlin').currentIana(),
        'Europe/Berlin',
      );
    });
  });
}
