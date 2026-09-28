import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements ConnectivityMonitorHarness {
  final FakeConnectivityMonitor monitor = FakeConnectivityMonitor();

  @override
  ConnectivityMonitor get subject => monitor;

  @override
  void setNetwork({required bool online}) => monitor.setOnline(online: online);
}

void main() {
  runConnectivityMonitorContract(_Harness.new);

  test('can start offline', () async {
    expect(await FakeConnectivityMonitor(online: false).isOnline(), isFalse);
  });
}
