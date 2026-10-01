import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/links/platform_url_launcher.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  final logger = CapturingLogger();

  runUrlLauncherContract(
    () => PlatformUrlLauncher(logger: logger, launch: (_) async => true),
  );

  test('passes allowed links to the platform', () async {
    final launched = <Uri>[];
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (uri) async {
        launched.add(uri);
        return true;
      },
    );
    expectOk(await launcher.open(Uri.parse('tel:999')));
    expect(await launcher.open(Uri.parse('file:///etc')), isA<Err<void>>());
    expect(launched, [Uri.parse('tel:999')]);
  });

  test('no handler is an Err', () async {
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (_) async => false,
    );
    expect(await launcher.open(Uri.parse('sms:1')), isA<Err<void>>());
  });

  test('a platform error is an Err, never a throw', () async {
    final launcher = PlatformUrlLauncher(
      logger: logger,
      launch: (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'),
    );
    expect(
      await launcher.open(Uri.parse('https://findahelpline.com')),
      isA<Err<void>>(),
    );
  });

  testWidgets('the default launch goes through url_launcher', (
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
    final launcher = PlatformUrlLauncher(logger: logger);
    final opened = await launcher.open(Uri.parse('tel:116123'));
    expect(opened, isA<Ok<void>>());
    expect(calls, isNotEmpty);
  });
}
