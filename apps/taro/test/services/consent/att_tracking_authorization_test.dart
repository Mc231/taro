import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    as att;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/consent/att_tracking_authorization.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

/// The iOS side of `app_tracking_transparency`: `notDetermined` until the
/// first request, which answers [answer].
final class _AttPlatform {
  att.TrackingStatus answer = att.TrackingStatus.authorized;
  att.TrackingStatus current = att.TrackingStatus.notDetermined;
  final List<String> calls = [];

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'getTrackingAuthorizationStatus':
        return current.index;
      case 'requestTrackingAuthorization':
        if (current == att.TrackingStatus.notDetermined) current = answer;
        return current.index;
    }
    throw MissingPluginException(call.method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('app_tracking_transparency');
  late _AttPlatform platform;
  late CapturingLogger logger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    platform = _AttPlatform();
    logger = CapturingLogger();
    messenger.setMockMethodCallHandler(channel, platform.handle);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('AttTrackingAuthorization', () {
    runTrackingAuthorizationContract(
      () => AttTrackingAuthorization(logger: CapturingLogger()),
    );

    for (final answer in att.TrackingStatus.values.where(
      (s) => s != att.TrackingStatus.notDetermined,
    )) {
      test('maps the answer ${answer.name}', () async {
        platform.answer = answer;
        final subject = AttTrackingAuthorization(logger: logger);
        expect(await subject.status(), TrackingStatus.notDetermined);
        expect(
          await subject.request(),
          TrackingStatus.values.byName(answer.name),
        );
        expect(platform.calls, [
          'getTrackingAuthorizationStatus',
          'requestTrackingAuthorization',
        ]);
      });
    }

    test('mapAttStatus covers every plugin status by name', () {
      for (final status in att.TrackingStatus.values) {
        expect(mapAttStatus(status).name, status.name);
      }
    });

    test('a platform error answers denied and is logged', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'att'),
      );
      final subject = AttTrackingAuthorization(logger: logger);
      expect(await subject.status(), TrackingStatus.denied);
      expect(await subject.request(), TrackingStatus.denied);
      expect(logger.records, hasLength(2));
    });

    test('takes injected SDK calls', () async {
      final subject = AttTrackingAuthorization(
        logger: logger,
        readStatus: () async => att.TrackingStatus.restricted,
        requestAuthorization: () async => att.TrackingStatus.restricted,
      );
      expect(await subject.status(), TrackingStatus.restricted);
      expect(await subject.request(), TrackingStatus.restricted);
      expect(platform.calls, isEmpty);
    });
  });

  group('NotSupportedTrackingAuthorization', () {
    runTrackingAuthorizationContract(NotSupportedTrackingAuthorization.new);

    test('never prompts', () async {
      // Non-const: the constructor line must run (06 QA2 per-file floor).
      // ignore: prefer_const_constructors
      final subject = NotSupportedTrackingAuthorization();
      expect(await subject.status(), TrackingStatus.notSupported);
      expect(await subject.request(), TrackingStatus.notSupported);
      expect(platform.calls, isEmpty);
    });
  });
}
