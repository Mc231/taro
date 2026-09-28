import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements RemoteConfigRepositoryHarness {
  final FakeRemoteConfigRepository repo = FakeRemoteConfigRepository();

  @override
  RemoteConfigRepository get subject => repo;

  @override
  void serverReturns(RemoteConfig config) => repo.server = config;

  @override
  void serverUnchanged() => repo.server = null;

  @override
  void serverFailsNext(Failure failure) => repo.failNext(failure);
}

void main() {
  runRemoteConfigRepositoryContract(_Harness.new);

  test('current can be set directly', () {
    final repo = FakeRemoteConfigRepository()
      ..current = aRemoteConfig().withAdsEnabled(false).build();
    expect(repo.current.adsEnabled, isFalse);
    expect(repo.calls, isEmpty);
  });
}
