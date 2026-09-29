import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  for (final kind in AttestationType.values) {
    group(kind.name, () {
      runAttestationServiceContract(() => FakeAttestationService(kind));
    });
  }

  test('device signals and failNext', () async {
    expect(
      (await FakeAttestationService().deviceSignal()).deviceCheckToken,
      isNotNull,
    );
    expect(
      (await FakeAttestationService(
        AttestationType.playIntegrity,
      ).deviceSignal()).deviceKey,
      isNotNull,
    );
    final attestation = FakeAttestationService()
      ..failNext(const Failure.attestation(kind: AttestationFailureKind.quota));
    const signal = DeviceSignal(deviceCheckToken: 'dc');
    expect(
      (await attestation.attest(
        challenge: 'c',
        installId: 'install-1',
        signal: signal,
      )).isErr,
      isTrue,
    );
    attestation.failNext(
      const Failure.attestation(kind: AttestationFailureKind.transient),
    );
    expect(
      (await attestation.assert_(clientDataHash: [1], keyId: 'key-1')).isErr,
      isTrue,
    );
    expect(attestation.challenges, ['c']);
    expect(attestation.attestedInstalls, [('install-1', signal)]);
    expect(attestation.assertionKeyIds, ['key-1']);
  });
}
