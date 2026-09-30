import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

const _token = 'dev-debug-attestation-token-0001';

FlavorConfig _config(Flavor flavor) =>
    FlavorConfig.fromDefines(flavor, defines: const {});

void main() {
  group('contract', () {
    runAttestationServiceContract(
      () => DebugAttestationService.forBuild(isProd: false, token: _token)!,
    );
  });

  group('a prod build never reaches it (02 §15, RC86)', () {
    final prod = _config(Flavor.prod);

    test('the prod flavor config is prod', () => expect(prod.isProd, isTrue));

    test('forBuild refuses prod, whatever the token', () {
      for (final token in [_token, 'x', '']) {
        expect(
          DebugAttestationService.forBuild(isProd: prod.isProd, token: token),
          isNull,
        );
      }
    });

    test('select returns the platform service in prod', () {
      final platform = FakeAttestationService();
      final selected = DebugAttestationService.select(
        isProd: prod.isProd,
        debugToken: _token,
        platform: platform,
      );
      expect(selected, same(platform));
      expect(selected, isNot(isA<DebugAttestationService>()));
    });
  });

  group('non-prod builds', () {
    for (final flavor in [Flavor.dev, Flavor.staging]) {
      test('${flavor.name} with a token selects the debug service', () {
        final selected = DebugAttestationService.select(
          isProd: _config(flavor).isProd,
          debugToken: _token,
          platform: FakeAttestationService(),
        );
        expect(selected, isA<DebugAttestationService>());
      });

      test('${flavor.name} without a token keeps the platform service', () {
        final platform = FakeAttestationService();
        for (final token in ['', '   ']) {
          expect(
            DebugAttestationService.select(
              isProd: _config(flavor).isProd,
              debugToken: token,
              platform: platform,
            ),
            same(platform),
          );
        }
      });
    }
  });

  group('the debug service', () {
    final platform = FakeAttestationService(AttestationType.playIntegrity);
    final debug = DebugAttestationService.forBuild(
      isProd: false,
      token: '  $_token ',
      signals: platform,
    )!;

    test('sends the trimmed token in X-Taro-Debug-Attestation', () {
      expect(DebugAttestationService.headerName, 'X-Taro-Debug-Attestation');
      expect(debug.headers, {'X-Taro-Debug-Attestation': _token});
    });

    test('attests and asserts as none (no platform attestation)', () async {
      expect(debug.isSupported, isFalse);
      final blob = (await debug.attest(
        challenge: 'c',
        installId: 'i',
        signal: const DeviceSignal(),
      )).valueOrNull;
      expect(
        blob,
        const AttestationBlob(type: AttestationType.none, challenge: 'c'),
      );
      expect(
        (await debug.assert_(clientDataHash: [1])).valueOrNull,
        const AssertionBlob(header: 'none'),
      );
    });

    test('takes the device signal from the platform service', () async {
      expect(
        await debug.deviceSignal(),
        const DeviceSignal(deviceKey: 'device-key'),
      );
      expect(
        await DebugAttestationService.forBuild(
          isProd: false,
          token: _token,
        )!.deviceSignal(),
        const DeviceSignal(),
      );
    });

    test('never prints the token', () {
      expect(debug.toString(), isNot(contains(_token)));
      expect(debug.toString(), contains('<redacted>'));
    });
  });
}
