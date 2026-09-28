import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `RemoteConfigRepository` contract needs besides the port.
abstract interface class RemoteConfigRepositoryHarness {
  /// The repository with nothing fetched or cached.
  RemoteConfigRepository get subject;

  /// `GET /v1/config` answers 200 with [config].
  void serverReturns(RemoteConfig config);

  /// `GET /v1/config` answers 304 Not Modified.
  void serverUnchanged();

  /// The next `GET /v1/config` fails with [failure].
  void serverFailsNext(Failure failure);
}

/// The `RemoteConfigRepository` contract (02 §9.4, RC8).
void runRemoteConfigRepositoryContract(
  RemoteConfigRepositoryHarness Function() create,
) {
  group('RemoteConfigRepository contract', () {
    late RemoteConfigRepositoryHarness harness;
    late RemoteConfigRepository config;
    final fetched = aRemoteConfig()
        .withVersion(7)
        .withRewardedEnabled(false)
        .build();

    setUp(() {
      harness = create();
      config = harness.subject;
    });

    test('starts with the compiled defaults', () {
      expect(config.current.version, RemoteConfig.defaults.version);
      expect(config.current.readingsEnabled, isTrue);
    });

    test('refresh adopts and emits the fetched config', () async {
      harness.serverReturns(fetched);
      final seen = <RemoteConfig>[];
      final sub = config.watch().listen(seen.add);
      await settle();
      final result = expectOk(await config.refresh());
      await settle();
      await sub.cancel();
      expect(result.version, 7);
      expect(result.rewardedEnabled, isFalse);
      expect(config.current.version, 7);
      expect(seen.last.version, 7);
    });

    test('304 keeps the current config', () async {
      harness.serverReturns(fetched);
      await config.refresh();
      harness.serverUnchanged();
      expect(expectOk(await config.refresh()).version, 7);
      expect(config.current.version, 7);
    });

    test('a failed refresh keeps the current config', () async {
      harness.serverReturns(fetched);
      await config.refresh();
      harness.serverFailsNext(const Failure.network());
      expect(expectErr(await config.refresh()), isA<NetworkFailure>());
      expect(config.current.version, 7);
    });
  });
}
