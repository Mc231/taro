import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runConsentStoreContract(FakeConsentStore.new);

  test('seed and failNext', () async {
    final store = FakeConsentStore()
      ..seed(const ConsentState(analyticsEnabled: true))
      ..failNext(const Failure.storage());
    expect(store.current.analyticsEnabled, isTrue);
    expect(
      expectErr(await store.update((s) => s.copyWith(analyticsEnabled: false))),
      const Failure.storage(),
    );
    expect(store.current.analyticsEnabled, isTrue);
  });
}
