import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/app_locale.dart';
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/error_handlers.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/startup_assertions.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('assertStartup (02 §15)', () {
    final prod = testFlavorConfig(Flavor.prod);

    test('dev accepts the test doubles', () {
      assertStartup(
        flavor: testFlavorConfig(),
        random: SeededRandomSource(),
        attestation: FakeAttestationService(),
        taroEnv: BuildDefines.testEnv,
      );
    });

    test('prod needs the CSPRNG', () {
      expect(
        () => assertStartup(
          flavor: prod,
          random: SeededRandomSource(),
          attestation: FakeAttestationService(),
        ),
        throwsStateError,
      );
    });

    test('prod never uses the debug attestation', () {
      expect(
        () => assertStartup(
          flavor: prod,
          random: SecureRandomSource(),
          attestation: DebugAttestationService.forBuild(
            isProd: false,
            token: 't',
          )!,
        ),
        throwsStateError,
      );
    });

    test('prod never runs with TARO_ENV=test', () {
      expect(
        () => assertStartup(
          flavor: prod,
          random: SecureRandomSource(),
          attestation: FakeAttestationService(),
          taroEnv: BuildDefines.testEnv,
        ),
        throwsStateError,
      );
      assertStartup(
        flavor: prod,
        random: SecureRandomSource(),
        attestation: FakeAttestationService(),
      );
    });
  });

  group('resolveAppLocale (02 §11)', () {
    test('the override wins when it is an app locale', () {
      expect(
        resolveAppLocale(override: 'ar', deviceLocales: const [Locale('de')]),
        'ar',
      );
      expect(
        resolveAppLocale(override: 'xx', deviceLocales: const [Locale('de')]),
        'de',
      );
    });

    test('else the first supported device locale, else en', () {
      expect(
        resolveAppLocale(
          override: null,
          deviceLocales: const [Locale('pl'), Locale('pt', 'BR')],
        ),
        'pt',
      );
      expect(resolveAppLocale(override: null, deviceLocales: const []), 'en');
    });
  });

  group('installErrorHandlers', () {
    late FlutterExceptionHandler? previousFlutter;
    late bool Function(Object, StackTrace)? previousPlatform;

    setUp(() {
      previousFlutter = FlutterError.onError;
      previousPlatform = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousPlatform;
    });

    test('framework and platform errors reach the crash reporter', () async {
      final crash = FakeCrashReporter();
      final forwarded = <FlutterErrorDetails>[];
      FlutterError.onError = forwarded.add;
      installErrorHandlers(crash);

      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('build'), silent: true),
      );
      final handled = PlatformDispatcher.instance.onError!(
        StateError('zone'),
        StackTrace.current,
      );
      await pumpEventQueue();

      expect(handled, isTrue);
      expect(forwarded, hasLength(1));
      expect(crash.errors, hasLength(2));
      expect(crash.errors.first.fatal, isFalse);
      expect(crash.errors.last.fatal, isTrue);
    });
  });
}
