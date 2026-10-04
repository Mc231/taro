import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro/data/install/install_repository_impl.dart';
import 'package:taro/data/install/proof_of_work.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../api/support/scripted_http_adapter.dart';
import '../api/support/worker_client_harness.dart' show fixture;
import 'support/install_harness.dart';

final class _ContractHarness implements InstallRepositoryHarness {
  _ContractHarness() {
    addTearDown(harness.close);
  }

  final InstallHarness harness = InstallHarness();

  @override
  InstallRepository get subject => harness.repo;

  @override
  void serverFailsNext(Failure failure) => switch (failure) {
    NetworkFailure() => harness.adapter.once(
      (request) => throw DioException(
        requestOptions: request.options,
        type: DioExceptionType.connectionError,
      ),
    ),
    TimezoneChangeRejectedFailure(:final allowedAfter) => harness.adapter.once(
      (_) => InstallHarness.error(
        409,
        'TIMEZONE_CHANGE_TOO_SOON',
        details: {'allowedAfter': allowedAfter.toIso8601String()},
      ),
    ),
    _ => throw UnsupportedError('$failure'),
  };
}

Map<String, dynamic> _body(RecordedRequest request) =>
    request.json! as Map<String, dynamic>;

void main() {
  runInstallRepositoryContract(_ContractHarness.new);

  late InstallHarness h;

  setUp(() => h = InstallHarness());
  tearDown(() => h.close());

  group('getOrCreate', () {
    test('writes the ID and a 32-byte secret before any request', () async {
      final identity = expectOk(await h.repo.getOrCreate());
      expect(identity.installId.value, h.ids.issued.single);
      expect(h.secure.values[SecureKeys.installId], identity.installId.value);
      final secret = h.secure.values[SecureKeys.installSecret]!;
      expect(base64Url.decode('$secret='), hasLength(32));
      expect(h.secure.calls.take(6), [
        'read',
        'read',
        'read',
        'read',
        'write',
        'write',
      ]);
      expect(h.adapter.requests, isEmpty);
      expect(identity.isRegistered, isFalse);
      expect(h.logger.logged('install identity created'), isTrue);
    });

    test('keeps a stored identity and reads storage once', () async {
      final first = expectOk(await h.repo.getOrCreate());
      final reads = h.secure.callCount('read');
      final again = expectOk(await h.repo.getOrCreate());
      expect(again, first);
      expect(h.secure.callCount('read'), reads);
    });

    test('concurrent first calls create one ID', () async {
      final results = await Future.wait([
        h.repo.getOrCreate(),
        h.repo.getOrCreate(),
      ]);
      expect(h.ids.issued, hasLength(1));
      expect(expectOk(results[0]), expectOk(results[1]));
    });

    test('a read failure is StorageFailure and creates nothing', () async {
      h.secure.failNext(const Failure.storage(), on: 'read');
      expect(expectErr(await h.repo.getOrCreate()), const Failure.storage());
      expect(h.ids.issued, isEmpty);
      expect(h.secure.values, isEmpty);
      // The next launch retries the read and succeeds.
      expectOk(await h.repo.getOrCreate());
      expect(h.ids.issued, hasLength(1));
    });

    test('a write failure is StorageFailure; the retry keeps the ID', () async {
      h.secure.failNext(const Failure.storage(), on: 'write');
      expect(expectErr(await h.repo.getOrCreate()), const Failure.storage());
      expect(h.secure.values, isEmpty);
      final identity = expectOk(await h.repo.getOrCreate());
      expect(h.secure.values[SecureKeys.installId], identity.installId.value);
    });

    test('a lost secret is replaced without a new ID', () async {
      final secure = InMemorySecureStore({SecureKeys.installId: 'kept-id'});
      final r = InstallHarness(secure: secure);
      addTearDown(r.close);
      final identity = expectOk(await r.repo.getOrCreate());
      expect(identity.installId.value, 'kept-id');
      expect(r.ids.issued, isEmpty);
      expect(secure.values[SecureKeys.installSecret], hasLength(43));
      expect(r.logger.logged('install secret was missing'), isTrue);
    });

    test('a database error reading the marker is StorageFailure', () async {
      await h.device.cacheDao.syncValue('open');
      await h.device.close();
      expect(expectErr(await h.repo.getOrCreate()), const Failure.storage());
      expect(h.logger.logged('install identity unreadable'), isTrue);
    });
  });

  group('ensureRegistered', () {
    test(
      'iOS: challenge → device signal → attest → POST /v1/installs',
      () async {
        final identity = expectOk(await h.repo.ensureRegistered());
        expect(h.adapter.requests.map((r) => r.route), [kChallenge, kRegister]);
        expect(h.attestation.calls, ['deviceSignal', 'attest']);
        expect(h.attestation.challenges, [
          fixture('installs.challenge.response')['challenge'],
        ]);
        // The proof binds the install ID and the device signal (03 §3.3).
        expect(h.attestation.attestedInstalls, [
          (
            identity.installId.value,
            const DeviceSignal(deviceCheckToken: 'devicecheck-token'),
          ),
        ]);
        final register = h.adapter.requests.last;
        final body = _body(register);
        expect(body, {
          'installId': identity.installId.value,
          'installSecret': h.secure.values[SecureKeys.installSecret],
          'platform': 'ios',
          'appVersion': '1.2.0+14',
          'locale': 'de',
          'timezone': 'Europe/Berlin',
          'deviceCheckToken': 'devicecheck-token',
          'attestation': {
            'type': 'app_attest',
            'challenge': fixture('installs.challenge.response')['challenge'],
            'keyId': 'key-1',
            'attestationObject': 'attestation-1',
          },
        });
        expect(
          register.header('idempotency-key'),
          allOf(isIn(h.ids.issued), isNot(register.header('x-request-id'))),
        );
        expect(register.header('authorization'), isNull);
        expect(identity.isRegistered, isTrue);
        expect(identity.registeredAt, kInstallNow);
        expect(identity.registeredTimezone, 'Europe/Berlin');
        expect(identity.trust, Trust.high);
        expect(identity.attestationKeyId, 'key-1');
        expect(
          identity.purchaseBinding?.appleAccountToken,
          (fixture('installs.register.response')['purchaseBinding']
              as Map)['appleAccountToken'],
        );
        expect(h.secure.values[SecureKeys.attestKeyId], 'key-1');
        expect(
          jsonDecode(h.secure.values[SecureKeys.purchaseBinding]!),
          fixture('installs.register.response')['purchaseBinding'],
        );
        final token = expectOk(await h.tokens.read())!;
        expect(
          token.token,
          fixture('installs.register.response')['installToken'],
        );
        expect(h.logger.logged('install registered (trust: high)'), isTrue);
      },
    );

    test('Android sends the device key and the integrity token', () async {
      final a = InstallHarness(
        attestationKind: AttestationType.playIntegrity,
        platform: AppPlatform.android,
      );
      addTearDown(a.close);
      final identity = expectOk(await a.repo.ensureRegistered());
      final body = _body(a.adapter.requests.last);
      expect(body['platform'], 'android');
      expect(body['deviceKey'], 'device-key');
      expect(body.containsKey('deviceCheckToken'), isFalse);
      expect(a.attestation.attestedInstalls, [
        (identity.installId.value, const DeviceSignal(deviceKey: 'device-key')),
      ]);
      expect(body['attestation'], {
        'type': 'play_integrity',
        'challenge': fixture('installs.challenge.response')['challenge'],
        'integrityToken': 'attestation-1',
      });
      expect(identity.attestationKeyId, isNull);
      expect(a.secure.values.containsKey(SecureKeys.attestKeyId), isFalse);
    });

    test('an unsupported device sends type none with a solved pow', () async {
      final n = InstallHarness(attestationKind: AttestationType.none);
      addTearDown(n.close);
      n.adapter.routes[kChallenge] = (_) => InstallHarness.ok({
        ...fixture('installs.challenge.response'),
        'powBits': 8,
      });
      final identity = expectOk(await n.repo.ensureRegistered());
      final attestation = _body(n.adapter.requests.last)['attestation'] as Map;
      expect(attestation['type'], 'none');
      expect(attestation['reason'], 'unsupported');
      expect(
        verifiesProofOfWork(
          challenge: attestation['challenge'] as String,
          installId: identity.installId.value,
          pow: attestation['pow'] as String,
          bits: 8,
        ),
        isTrue,
      );
      expect(n.powRuns.single.bits, 8);
      expect(n.attestation.calls, ['deviceSignal', 'attest']);
    });

    test('App Attest is used even before the warm-up settled isSupported '
        '(first launch)', () async {
      final w = InstallHarness(attestationSettlesOnFirstUse: true);
      addTearDown(w.close);
      expect(w.attestation.isSupported, isFalse);
      final identity = expectOk(await w.repo.ensureRegistered());
      final attestation = _body(w.adapter.requests.last)['attestation'] as Map;
      expect(attestation['type'], 'app_attest');
      expect(attestation['keyId'], 'key-1');
      expect(identity.attestationKeyId, 'key-1');
      expect(w.powRuns, isEmpty);
    });

    test('a platform reporting unsupported falls back to none', () async {
      h.adapter.routes[kChallenge] = (_) => InstallHarness.ok({
        ...fixture('installs.challenge.response'),
        'powBits': 4,
      });
      h.attestation.failNext(
        const Failure.attestation(kind: AttestationFailureKind.unsupported),
        on: 'attest',
      );
      expectOk(await h.repo.ensureRegistered());
      final attestation = _body(h.adapter.requests.last)['attestation'] as Map;
      expect(attestation['type'], 'none');
      expect(attestation['reason'], 'unsupported');
    });

    for (final kind in [
      AttestationFailureKind.transient,
      AttestationFailureKind.quota,
    ]) {
      test('a ${kind.name} attest error falls back to none/error', () async {
        h.adapter.routes[kChallenge] = (_) => InstallHarness.ok({
          ...fixture('installs.challenge.response'),
          'powBits': 4,
        });
        h.attestation.failNext(Failure.attestation(kind: kind), on: 'attest');
        final identity = expectOk(await h.repo.ensureRegistered());
        final attestation =
            _body(h.adapter.requests.last)['attestation'] as Map;
        expect(attestation['reason'], 'error');
        expect(attestation.containsKey('keyId'), isFalse);
        expect(identity.attestationKeyId, isNull);
        expect(h.logger.logged('platform attestation unavailable'), isTrue);
      });
    }

    group('a low-trust iOS install without an App Attest key', () {
      Future<InstallIdentity> registerLow(InstallHarness x) async {
        x.adapter.routes[kChallenge] = (_) => InstallHarness.ok({
          ...fixture('installs.challenge.response'),
          'powBits': 4,
        });
        x.adapter.routes[kRegister] = (_) => InstallHarness.ok({
          ...fixture('installs.register.response'),
          'trust': 'low',
        }, 201);
        x.attestation.failNext(
          const Failure.attestation(kind: AttestationFailureKind.transient),
          on: 'attest',
        );
        final low = expectOk(await x.repo.ensureRegistered());
        expect(low.trust, Trust.low);
        expect(low.attestationKeyId, isNull);
        x.adapter.routes[kRegister] = (_) =>
            InstallHarness.ok(fixture('installs.register.response'));
        return low;
      }

      test('re-registers with App Attest once per launch', () async {
        final low = await registerLow(h);
        final upgraded = expectOk(await h.repo.ensureRegistered());
        final registers = h.adapter.to(kRegister);
        expect(registers, hasLength(2));
        final body = _body(registers.last);
        expect(body['installId'], low.installId.value);
        expect(
          body['installSecret'],
          h.secure.values[SecureKeys.installSecret],
        );
        expect((body['attestation'] as Map)['type'], 'app_attest');
        expect(upgraded.trust, Trust.high);
        expect(upgraded.attestationKeyId, 'key-2');
        expect(h.secure.values[SecureKeys.attestKeyId], 'key-2');
        expectOk(await h.repo.ensureRegistered());
        expect(h.adapter.to(kRegister), hasLength(2));
      });

      test('keeps the low-trust registration without a platform '
          'attestation, and does not retry in this launch', () async {
        final low = await registerLow(h);
        h.attestation.failNext(
          const Failure.attestation(kind: AttestationFailureKind.transient),
          on: 'attest',
        );
        expect(expectOk(await h.repo.ensureRegistered()), low);
        expect(h.adapter.to(kRegister), hasLength(1));
        expect(h.logger.logged('low-trust install kept: '), isTrue);
        expect(expectOk(await h.repo.ensureRegistered()), low);
        expect(h.attestation.calls.where((c) => c == 'attest'), hasLength(2));
      });

      test('keeps it when the platform answers none or the Worker '
          'refuses', () async {
        final n = InstallHarness(attestationKind: AttestationType.none);
        addTearDown(n.close);
        n.adapter.routes[kChallenge] = (_) => InstallHarness.ok({
          ...fixture('installs.challenge.response'),
          'powBits': 4,
        });
        n.adapter.routes[kRegister] = (_) => InstallHarness.ok({
          ...fixture('installs.register.response'),
          'trust': 'low',
        }, 201);
        final low = expectOk(await n.repo.ensureRegistered());
        expect(expectOk(await n.repo.ensureRegistered()), low);
        expect(n.adapter.to(kRegister), hasLength(1));

        final r = InstallHarness();
        addTearDown(r.close);
        final rLow = await registerLow(r);
        r.adapter.routes[kRegister] = (_) =>
            InstallHarness.error(403, 'ATTESTATION_FAILED');
        expect(expectOk(await r.repo.ensureRegistered()), rLow);
        expect(r.adapter.to(kRegister), hasLength(2));
      });

      test('Android never upgrades this way', () async {
        final a = InstallHarness(
          attestationKind: AttestationType.playIntegrity,
          platform: AppPlatform.android,
        );
        addTearDown(a.close);
        await registerLow(a);
        expectOk(await a.repo.ensureRegistered());
        expect(a.adapter.to(kRegister), hasLength(1));
      });
    });

    test('a rejected attestation fails without POST /v1/installs', () async {
      h.attestation.failNext(
        const Failure.attestation(kind: AttestationFailureKind.rejected),
        on: 'attest',
      );
      expect(
        expectErr(await h.repo.ensureRegistered()),
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      );
      expect(h.adapter.requests.map((r) => r.route), [kChallenge]);
      expect(h.logger.logged('install registration failed: '), isTrue);
    });

    test('a 403 from the Worker leaves the install unregistered', () async {
      h.adapter.routes[kRegister] = (_) =>
          InstallHarness.error(403, 'ATTESTATION_FAILED');
      expect(
        expectErr(await h.repo.ensureRegistered()),
        isA<AttestationFailure>(),
      );
      expect(expectOk(await h.repo.getOrCreate()).isRegistered, isFalse);
      expect(expectOk(await h.tokens.read()), isNull);
    });

    test('each attempt has a fresh Idempotency-Key (RC55)', () async {
      h.adapter.once(
        (_) => InstallHarness.ok(fixture('installs.challenge.response')),
      );
      h.adapter.once((_) => InstallHarness.error(403, 'ATTESTATION_FAILED'));
      expectErr(await h.repo.ensureRegistered());
      expectOk(await h.repo.ensureRegistered());
      final keys = [
        for (final r in h.adapter.to(kRegister)) r.header('idempotency-key'),
      ];
      expect(keys, hasLength(2));
      expect(keys.toSet(), hasLength(2));
    });

    test('a network retry of one attempt reuses its key', () async {
      h.adapter.once(
        (_) => InstallHarness.ok(fixture('installs.challenge.response')),
      );
      h.adapter.once(
        (request) => throw DioException(
          requestOptions: request.options,
          type: DioExceptionType.connectionError,
        ),
      );
      expectOk(await h.repo.ensureRegistered());
      final registers = h.adapter.to(kRegister);
      expect(registers, hasLength(2));
      expect(
        registers[0].header('idempotency-key'),
        registers[1].header('idempotency-key'),
      );
    });

    test('concurrent calls share one registration', () async {
      final results = await Future.wait([
        h.repo.ensureRegistered(),
        h.repo.ensureRegistered(),
      ]);
      expect(h.adapter.to(kRegister), hasLength(1));
      expect(expectOk(results[0]), expectOk(results[1]));
    });

    test('a registered install makes no request', () async {
      expectOk(await h.repo.ensureRegistered());
      final count = h.adapter.requests.length;
      expectOk(await h.repo.ensureRegistered());
      expect(h.adapter.requests, hasLength(count));
    });

    test('a restart keeps the registration', () async {
      final first = expectOk(await h.repo.ensureRegistered());
      final restarted = InstallHarness(secure: h.secure, device: h.device);
      final identity = expectOk(await restarted.repo.getOrCreate());
      expect(identity, first);
      expectOk(await restarted.repo.ensureRegistered());
      expect(restarted.adapter.requests, isEmpty);
    });

    test('hands the registration to the listener', () async {
      final seen = <Registration>[];
      final l = InstallHarness(onRegistered: (r) async => seen.add(r));
      addTearDown(l.close);
      expectOk(await l.repo.ensureRegistered());
      expect(seen.single.balance.ledgerVersion, isNonNegative);
      expect(seen.single.trust, Trust.high);
    });

    test('a storage error saving the result is StorageFailure', () async {
      expectOk(await h.repo.getOrCreate());
      h.secure.failNext(const Failure.storage(), on: 'write');
      expect(
        expectErr(await h.repo.ensureRegistered()),
        const Failure.storage(),
      );
      expect(expectOk(await h.repo.getOrCreate()).isRegistered, isFalse);
    });

    test('a database error saving the marker is StorageFailure', () async {
      expectOk(await h.repo.getOrCreate());
      await h.device.close();
      expect(
        expectErr(await h.repo.ensureRegistered()),
        const Failure.storage(),
      );
      expect(h.logger.logged('registration marker write failed'), isTrue);
    });

    test('a marker of another install ID is ignored', () async {
      await h.device.cacheDao.putSyncValue(
        InstallRepositoryImpl.registrationKey,
        jsonEncode({
          'installId': 'someone-else',
          'registeredAt': '2026-09-20T00:00:00.000Z',
          'trust': 'high',
          'timezone': 'UTC',
        }),
      );
      expect(expectOk(await h.repo.getOrCreate()).isRegistered, isFalse);
    });

    test('an unreadable marker or binding counts as unregistered', () async {
      final secure = InMemorySecureStore({
        SecureKeys.installId: 'id-1',
        SecureKeys.installSecret: 'secret',
        SecureKeys.purchaseBinding: 'not json',
      });
      final r = InstallHarness(secure: secure);
      addTearDown(r.close);
      await r.device.cacheDao.putSyncValue(
        InstallRepositoryImpl.registrationKey,
        jsonEncode({
          'installId': 'id-1',
          'registeredAt': '2026-09-20T00:00:00.000Z',
          'trust': 'high',
          'timezone': 'UTC',
        }),
      );
      final identity = expectOk(await r.repo.getOrCreate());
      expect(identity.isRegistered, isTrue);
      expect(identity.purchaseBinding, isNull);
      expect(r.logger.logged('stored purchase binding unreadable'), isTrue);

      final broken = InstallHarness(secure: secure);
      addTearDown(broken.close);
      await broken.device.cacheDao.putSyncValue(
        InstallRepositoryImpl.registrationKey,
        '{',
      );
      expect(expectOk(await broken.repo.getOrCreate()).isRegistered, isFalse);
    });
  });

  group('refreshToken', () {
    test('stores the new token and trust', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.routes[kToken] = (_) => InstallHarness.ok({
        ...fixture('installs.token.response'),
        'trust': 'low',
      });
      expectOk(await h.repo.refreshToken());
      expect(
        expectOk(await h.tokens.read())!.token,
        fixture('installs.token.response')['installToken'],
      );
      expect(expectOk(await h.repo.getOrCreate()).trust, Trust.low);
      final restarted = InstallHarness(secure: h.secure, device: h.device);
      expect(expectOk(await restarted.repo.getOrCreate()).trust, Trust.low);
    });

    test('keyInvalidated re-registers with the same ID and secret', () async {
      final before = expectOk(await h.repo.ensureRegistered());
      final secret = h.secure.values[SecureKeys.installSecret];
      h.clock.advance(const Duration(days: 3));
      h.attestation.failNext(
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
        on: 'assert',
      );
      expectOk(await h.repo.refreshToken());
      final registers = h.adapter.to(kRegister);
      expect(registers, hasLength(2));
      final bodies = registers.map(_body).toList();
      expect(bodies[1]['installId'], before.installId.value);
      expect(bodies[1]['installSecret'], secret);
      // Within the 7-day key window, the re-registration has its own key.
      expect(
        registers[1].header('idempotency-key'),
        isNot(registers[0].header('idempotency-key')),
      );
      final after = expectOk(await h.repo.getOrCreate());
      expect(after.installId, before.installId);
      expect(after.registeredAt, kInstallNow.add(const Duration(days: 3)));
      expect(h.attestation.challenges, hasLength(2));
      expect(h.logger.logged('token refresh needs re-registration'), isTrue);
    });

    test('an expired session re-registers', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once((_) => InstallHarness.error(401, 'UNAUTHENTICATED'));
      expectOk(await h.repo.refreshToken());
      expect(h.adapter.to(kRegister), hasLength(2));
    });

    test('a failed re-registration is returned', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once((_) => InstallHarness.error(401, 'UNAUTHENTICATED'));
      h.adapter.once((_) => InstallHarness.error(503, 'SERVICE_UNAVAILABLE'));
      expect(expectErr(await h.repo.refreshToken()), isA<ServerFailure>());
      expect(expectOk(await h.repo.getOrCreate()).isRegistered, isFalse);
    });

    test('other failures pass through', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once((_) => InstallHarness.error(403, 'ATTESTATION_FAILED'));
      expect(
        expectErr(await h.repo.refreshToken()),
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      );
      expect(h.adapter.to(kRegister), hasLength(1));
    });

    test('without a token the session registers', () async {
      expectOk(await h.repo.refreshToken());
      expect(h.adapter.to(kToken), isEmpty);
      expect(expectOk(await h.repo.getOrCreate()).isRegistered, isTrue);
    });
  });

  group('reRegister', () {
    test('drops the key ID first, then registers again', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once((_) => InstallHarness.error(503, 'SERVICE_UNAVAILABLE'));
      expectErr(await h.repo.reRegister());
      expect(h.secure.values.containsKey(SecureKeys.attestKeyId), isFalse);
      final restarted = InstallHarness(secure: h.secure, device: h.device);
      expect(
        expectOk(await restarted.repo.getOrCreate()).isRegistered,
        isFalse,
      );
      expectOk(await h.repo.reRegister());
      // Each registration attests a new App Attest key.
      expect(h.secure.values[SecureKeys.attestKeyId], 'key-2');
    });

    test('joins a registration already running', () async {
      final results = await Future.wait([
        h.repo.ensureRegistered(),
        h.repo.reRegister(),
      ]);
      expect(h.adapter.to(kRegister), hasLength(1));
      expect(expectOk(results[1]).isRegistered, isTrue);
    });

    test('a storage error clearing the key ID is StorageFailure', () async {
      expectOk(await h.repo.ensureRegistered());
      h.secure.failNext(const Failure.storage(), on: 'delete');
      expect(expectErr(await h.repo.reRegister()), const Failure.storage());
    });

    test('a database error clearing the marker is StorageFailure', () async {
      expectOk(await h.repo.ensureRegistered());
      await h.device.close();
      expect(expectErr(await h.repo.reRegister()), const Failure.storage());
      expect(h.logger.logged('registration marker clear failed'), isTrue);
    });

    test('fails when the identity cannot be read', () async {
      h.secure.failNext(const Failure.storage(), on: 'read');
      expect(expectErr(await h.repo.reRegister()), const Failure.storage());
    });
  });

  group('updateTimezone', () {
    test('sends the zone with a fresh key and stores it', () async {
      expectOk(await h.repo.ensureRegistered());
      final a = expectOk(await h.repo.updateTimezone('Asia/Tokyo'));
      expectOk(await h.repo.updateTimezone('Asia/Tokyo'));
      expect(a.free.timezone, 'Asia/Tokyo');
      final puts = h.adapter.to(kTimezone);
      expect(_body(puts.first), {'timezone': 'Asia/Tokyo'});
      expect(
        puts[0].header('idempotency-key'),
        isNot(puts[1].header('idempotency-key')),
      );
      expect(
        expectOk(await h.repo.getOrCreate()).registeredTimezone,
        'Asia/Tokyo',
      );
      final restarted = InstallHarness(secure: h.secure, device: h.device);
      expect(
        expectOk(await restarted.repo.getOrCreate()).registeredTimezone,
        'Asia/Tokyo',
      );
    });

    test('409 keeps the server boundary and the stored zone', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once(
        (_) => InstallHarness.ok(
          fixture('errors.timezone_change_too_soon'),
          409,
        ),
      );
      expect(
        expectErr(await h.repo.updateTimezone('Asia/Tokyo')),
        Failure.timezoneChangeRejected(
          allowedAfter: DateTime.utc(2026, 9, 27, 10),
        ),
      );
      expect(
        expectOk(await h.repo.getOrCreate()).registeredTimezone,
        'Europe/Berlin',
      );
      expect(h.logger.logged('timezone change rejected until'), isTrue);
    });

    test('other failures pass through', () async {
      expectOk(await h.repo.ensureRegistered());
      h.adapter.once((_) => InstallHarness.error(400, 'INVALID_REQUEST'));
      expectErr(await h.repo.updateTimezone('Nowhere/Zone'));
      expect(
        expectOk(await h.repo.getOrCreate()).registeredTimezone,
        'Europe/Berlin',
      );
    });

    test('a failed marker write is logged, the balance returned', () async {
      expectOk(await h.repo.ensureRegistered());
      await h.device.close();
      expectOk(await h.repo.updateTimezone('Asia/Tokyo'));
      expect(h.logger.logged('registration marker update failed'), isTrue);
    });

    test('an install not registered here stores nothing', () async {
      await h.tokens.write(
        SessionToken(token: 'jwt', expiresAt: DateTime.utc(2026, 10)),
      );
      expectOk(await h.repo.updateTimezone('Asia/Tokyo'));
      expect(h.adapter.to(kTimezone), hasLength(1));
      expect(
        await h.device.cacheDao.syncValue(
          InstallRepositoryImpl.registrationKey,
        ),
        isNull,
      );
    });

    test('without a token the session has expired', () async {
      expect(
        expectErr(await h.repo.updateTimezone('Asia/Tokyo')),
        const Failure.sessionExpired(),
      );
    });
  });

  group('reinstall and deletion', () {
    test('iOS reinstall: Keychain survives, the app re-registers with the '
        'same ID and secret', () async {
      final before = expectOk(await h.repo.ensureRegistered());
      final secret = h.secure.values[SecureKeys.installSecret];
      // The Keychain survives the reinstall; taro_device.db does not.
      final reinstalled = InstallHarness(secure: h.secure);
      addTearDown(reinstalled.close);
      final identity = expectOk(await reinstalled.repo.getOrCreate());
      expect(identity.installId, before.installId);
      expect(identity.isRegistered, isFalse);
      expect(reinstalled.ids.issued, isEmpty);
      expectOk(await reinstalled.repo.ensureRegistered());
      final body = _body(reinstalled.adapter.to(kRegister).single);
      expect(body['installId'], before.installId.value);
      expect(body['installSecret'], secret);
      expect(reinstalled.attestation.calls, contains('attest'));
    });

    test('Delete all data (RC37) keeps the ID, secret, token and '
        'registration', () async {
      final before = expectOk(await h.repo.ensureRegistered());
      final kept = Map.of(h.secure.values);
      final deletion = FakeDataDeletionGateway();
      final outcome = await DeleteAllData(
        journal: FakeJournalRepository(),
        deletion: deletion,
        reminders: FakeReminderScheduler(),
        ids: h.ids,
        logger: h.logger,
      )();
      expectOk(outcome);
      expectOk(
        await h.client.deleteInstall(idempotencyKey: deletion.erased.single),
      );
      expect(h.secure.values, kept);
      final restarted = InstallHarness(secure: h.secure, device: h.device);
      expect(expectOk(await restarted.repo.getOrCreate()), before);
    });
  });

  group('the install secret', () {
    test('appears only in POST /v1/installs and never in a log', () async {
      expectOk(await h.repo.ensureRegistered());
      h.attestation.failNext(
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
        on: 'assert',
      );
      expectOk(await h.repo.refreshToken());
      expectOk(await h.repo.refreshToken());
      expectOk(await h.repo.updateTimezone('Asia/Tokyo'));
      h.adapter.once((_) => InstallHarness.error(400, 'INVALID_REQUEST'));
      expectErr(await h.repo.updateTimezone('x'));
      expectOk(await h.client.deleteInstall(idempotencyKey: 'k'));
      h.adapter.routes[kRegister] = (_) =>
          InstallHarness.error(500, 'INTERNAL');
      expectErr(await h.repo.reRegister());

      final secret = h.secure.values[SecureKeys.installSecret]!;
      final installId = h.secure.values[SecureKeys.installId]!;
      for (final request in h.adapter.requests) {
        final text =
            '${request.headers} ${utf8.decode(request.body)} '
            '${request.path} ${request.query}';
        expect(
          text.contains(secret),
          request.route == kRegister,
          reason: request.route,
        );
      }
      expect(h.adapter.to(kRegister), hasLength(3));
      for (final record in h.logger.records) {
        final text = '${record.message} ${record.error}';
        expect(text, isNot(contains(secret)));
        expect(text, isNot(contains(installId)));
        expect(
          text,
          isNot(
            contains(fixture('installs.register.response')['installToken']),
          ),
        );
      }
      expect(h.logger.records, isNotEmpty);
    });
  });
}
