import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements InstallRepositoryHarness {
  final FakeInstallRepository repo = FakeInstallRepository.firstLaunch();

  @override
  InstallRepository get subject => repo;

  @override
  void serverFailsNext(Failure failure) => repo.failNext(failure);
}

void main() {
  runInstallRepositoryContract(_Harness.new);

  test('defaults to a registered install; records zone updates', () async {
    final repo = FakeInstallRepository(
      timezoneBalance: aCreditBalance().withLedgerVersion(4).build(),
    );
    expect(expectOk(await repo.getOrCreate()).isRegistered, isTrue);
    final balance = expectOk(await repo.updateTimezone('Asia/Tokyo'));
    expect(balance.ledgerVersion, 5);
    expect(repo.timezoneUpdates, ['Asia/Tokyo']);
    expect(repo.identity?.registeredTimezone, 'Asia/Tokyo');
  });

  test('failNext on getOrCreate simulates unusable storage', () async {
    final repo = FakeInstallRepository()
      ..failNext(const Failure.storage(), on: 'getOrCreate')
      ..failNext(const Failure.network(), on: 'refreshToken');
    expect(expectErr(await repo.getOrCreate()), const Failure.storage());
    expect(expectErr(await repo.refreshToken()), const Failure.network());
  });
}
