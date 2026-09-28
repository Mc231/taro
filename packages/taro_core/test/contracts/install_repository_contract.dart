import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// What the `InstallRepository` contract needs besides the port.
abstract interface class InstallRepositoryHarness {
  /// The repository of a fresh install (nothing in secure storage).
  InstallRepository get subject;

  /// The next Worker call fails with [failure].
  void serverFailsNext(Failure failure);
}

/// The `InstallRepository` contract (02 §6.2, §6.4, 03 §3).
void runInstallRepositoryContract(InstallRepositoryHarness Function() create) {
  group('InstallRepository contract', () {
    late InstallRepositoryHarness harness;
    late InstallRepository install;

    setUp(() {
      harness = create();
      install = harness.subject;
    });

    test('getOrCreate creates one install ID and keeps it', () async {
      final first = expectOk(await install.getOrCreate());
      final again = expectOk(await install.getOrCreate());
      expect(first.installId.value, isNotEmpty);
      expect(again.installId, first.installId);
      expect(first.isRegistered, isFalse);
    });

    test('ensureRegistered registers the same install once', () async {
      final created = expectOk(await install.getOrCreate());
      final registered = expectOk(await install.ensureRegistered());
      expect(registered.installId, created.installId);
      expect(registered.isRegistered, isTrue);
      expect(registered.trust, isNotNull);
      final again = expectOk(await install.ensureRegistered());
      expect(again.registeredAt, registered.registeredAt);
      expect(expectOk(await install.getOrCreate()).isRegistered, isTrue);
    });

    test('a failed registration leaves the install unregistered', () async {
      harness.serverFailsNext(const Failure.network());
      expect(
        expectErr(await install.ensureRegistered()),
        isA<NetworkFailure>(),
      );
      expect(expectOk(await install.getOrCreate()).isRegistered, isFalse);
    });

    test('refreshToken succeeds for a registered install', () async {
      await install.ensureRegistered();
      expectOk(await install.refreshToken());
    });

    test('updateTimezone returns the balance on the new zone', () async {
      await install.ensureRegistered();
      final balance = expectOk(await install.updateTimezone('Asia/Tokyo'));
      expect(balance.free.timezone, 'Asia/Tokyo');
    });

    test('a rejected zone change is a failure', () async {
      await install.ensureRegistered();
      final allowedAfter = DateTime.utc(2026, 9, 27);
      harness.serverFailsNext(
        Failure.timezoneChangeRejected(allowedAfter: allowedAfter),
      );
      expect(
        expectErr(await install.updateTimezone('Asia/Tokyo')),
        Failure.timezoneChangeRejected(allowedAfter: allowedAfter),
      );
    });
  });
}
