import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/links/platform_url_launcher.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  final logger = CapturingLogger();

  runUrlLauncherContract(
    () => PlatformUrlLauncher(
      logger: logger,
      launch: (_) async => true,
      launchInApp: (_) async => true,
      settings: () async => true,
    ),
  );

  test('passes allowed links to the platform', () async {
    final launched = <Uri>[];
    final inApp = <Uri>[];
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (uri) async {
        launched.add(uri);
        return true;
      },
      launchInApp: (uri) async {
        inApp.add(uri);
        return true;
      },
    );
    expectOk(await launcher.open(Uri.parse('tel:999')));
    expect(await launcher.open(Uri.parse('file:///etc')), isA<Err<void>>());
    expectOk(await launcher.openInApp(Uri.parse('https://a.example/t')));
    expect(
      await launcher.openInApp(Uri.parse('mailto:a@b.c')),
      isA<Err<void>>(),
    );
    expect(launched, [Uri.parse('tel:999')]);
    expect(inApp, [Uri.parse('https://a.example/t')]);
  });

  test('no handler is an Err', () async {
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (_) async => false,
      settings: () async => false,
    );
    expect(await launcher.open(Uri.parse('sms:1')), isA<Err<void>>());
    expect(await launcher.openAppSettings(), isA<Err<void>>());
  });

  test('a platform error is an Err, never a throw', () async {
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
      settings: () async => throw MissingPluginException(),
    );
    expect(
      await launcher.open(Uri.parse('https://findahelpline.com')),
      isA<Err<void>>(),
    );
    expect(await launcher.openAppSettings(), isA<Err<void>>());
  });

  testWidgets('the default launches go through url_launcher', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        calls.add(call);
        return true;
      },
    );
    final launcher = PlatformUrlLauncher(logger: logger, isIos: true);
    expect(await launcher.open(Uri.parse('tel:116123')), isA<Ok<void>>());
    expect(
      await launcher.openInApp(Uri.parse('https://a.example')),
      isA<Ok<void>>(),
    );
    expect(await launcher.openAppSettings(), isA<Ok<void>>());
    expect(calls, hasLength(3));
  });

  testWidgets('Android opens the app settings through the channel', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      PlatformUrlLauncher.appSettingsChannel,
      (call) async {
        calls.add(call);
        return true;
      },
    );
    final launcher = PlatformUrlLauncher(logger: logger);
    expect(await launcher.openAppSettings(), isA<Ok<void>>());
    expect(calls.single.method, 'open');
  });
}
