import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runTrackingAuthorizationContract(FakeTrackingAuthorization.new);
  runTrackingAuthorizationContract(
    () => FakeTrackingAuthorization(current: TrackingStatus.notSupported),
  );

  test('prompts once with the scripted answer', () async {
    final att = FakeTrackingAuthorization(answer: TrackingStatus.denied);
    expect(await att.request(), TrackingStatus.denied);
    expect(await att.request(), TrackingStatus.denied);
    expect(att.prompts, 1);
  });
}
