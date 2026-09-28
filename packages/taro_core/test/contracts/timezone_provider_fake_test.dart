import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  group('FakeTimezoneProvider', () {
    runTimezoneProviderContract(FakeTimezoneProvider.new);
  });
  group('FakeClock', () => runTimezoneProviderContract(FakeClock.utc));

  test('the zone can change', () async {
    final tz = FakeTimezoneProvider()..iana = 'Asia/Tokyo';
    expect(await tz.currentIana(), 'Asia/Tokyo');
  });
}
