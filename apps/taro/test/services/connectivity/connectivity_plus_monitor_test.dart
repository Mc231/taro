import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/connectivity/always_online_monitor.dart';
import 'package:taro/services/connectivity/connectivity_plus_monitor.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

/// The plugin: [results] now, [changes] as the platform stream.
final class _Connectivity extends Fake implements Connectivity {
  List<ConnectivityResult> results = [ConnectivityResult.wifi];
  final StreamController<List<ConnectivityResult>> changes =
      StreamController.broadcast();
  Exception? checkError;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    if (checkError != null) throw checkError!;
    return results;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;

  void set(List<ConnectivityResult> next) {
    results = next;
    changes.add(next);
  }
}

final class _Harness implements ConnectivityMonitorHarness {
  final _Connectivity connectivity = _Connectivity();

  @override
  late final ConnectivityMonitor subject = ConnectivityPlusMonitor(
    logger: CapturingLogger(),
    connectivity: connectivity,
  );

  @override
  void setNetwork({required bool online}) => connectivity.set([
    if (online) ConnectivityResult.mobile else ConnectivityResult.none,
  ]);
}

void main() {
  late _Connectivity connectivity;
  late CapturingLogger logger;
  late ConnectivityPlusMonitor monitor;

  setUp(() {
    connectivity = _Connectivity();
    logger = CapturingLogger();
    monitor = ConnectivityPlusMonitor(
      logger: logger,
      connectivity: connectivity,
    );
  });

  group('ConnectivityPlusMonitor', () {
    runConnectivityMonitorContract(_Harness.new);

    test('any interface but none is online', () {
      expect(ConnectivityPlusMonitor.isOnlineResult([]), isFalse);
      expect(
        ConnectivityPlusMonitor.isOnlineResult([ConnectivityResult.none]),
        isFalse,
      );
      expect(
        ConnectivityPlusMonitor.isOnlineResult([
          ConnectivityResult.none,
          ConnectivityResult.vpn,
        ]),
        isTrue,
      );
    });

    test('a known state suppresses the same first event', () async {
      expect(await monitor.isOnline(), isTrue);
      final seen = <bool>[];
      final sub = monitor.online.listen(seen.add);
      connectivity
        ..set([ConnectivityResult.ethernet])
        ..set([ConnectivityResult.none]);
      await settle();
      await sub.cancel();
      expect(seen, [false]);
    });

    test('listens to the platform only while listened to', () async {
      final sub = monitor.online.listen((_) {});
      expect(connectivity.changes.hasListener, isTrue);
      await sub.cancel();
      expect(connectivity.changes.hasListener, isFalse);
      final again = monitor.online.listen((_) {});
      expect(connectivity.changes.hasListener, isTrue);
      await again.cancel();
    });

    test('a platform stream error is logged, not forwarded', () async {
      final errors = <Object>[];
      final sub = monitor.online.listen((_) {}, onError: errors.add);
      connectivity.changes.addError(PlatformException(code: 'x'));
      await settle();
      await sub.cancel();
      expect(errors, isEmpty);
      expect(logger.messages, ['connectivity stream error']);
    });

    test('a failed check answers the last hint, online at first', () async {
      connectivity.checkError = PlatformException(code: 'x');
      expect(await monitor.isOnline(), isTrue);
      connectivity
        ..checkError = null
        ..results = [ConnectivityResult.none];
      expect(await monitor.isOnline(), isFalse);
      connectivity.checkError = PlatformException(code: 'x');
      expect(await monitor.isOnline(), isFalse);
      expect(logger.messages, [
        'connectivity check failed',
        'connectivity check failed',
      ]);
    });

    test('defaults to the plugin singleton', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(
        ConnectivityPlusMonitor(logger: logger),
        isA<ConnectivityMonitor>(),
      );
    });
  });

  group('AlwaysOnlineMonitor', () {
    test('is always online and never changes', () async {
      // Not const, so the constructor line runs (coverage).
      // ignore: prefer_const_constructors
      final monitor = AlwaysOnlineMonitor();
      expect(await monitor.isOnline(), isTrue);
      expect(await monitor.online.isEmpty, isTrue);
    });
  });
}
