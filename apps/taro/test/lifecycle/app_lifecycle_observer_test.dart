import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/lifecycle/app_lifecycle_observer.dart';
import 'package:taro/lifecycle/reset_timer.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resumed syncs and re-arms; paused cancels the reset timer', () async {
    final fakes = TaroFakes();
    final container = fakes.container();
    final observer = container.read(appLifecycleObserverProvider);
    final timer = container.read(resetTimerProvider);
    final sync = container.read(syncCoordinatorProvider);
    expect(timer.isArmed, isTrue);

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(timer.isArmed, isFalse);
    observer
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(timer.isArmed, isTrue);
    await pumpEventQueue();
    expect(sync.runs, 1);
    expect(fakes.balance.syncReasons, [SyncReason.resume]);

    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      observer
        ..didChangeAppLifecycleState(AppLifecycleState.resumed)
        ..didChangeAppLifecycleState(state);
      expect(timer.isArmed, isFalse);
    }
  });

  test(
    'a new balance re-arms the timer; its fire runs a boundary sync',
    () async {
      final fakes = TaroFakes();
      final container = fakes.container();
      final timer = container.read(resetTimerProvider);
      fakes.balance.seed(null);
      await pumpEventQueue();
      expect(timer.isArmed, isFalse);
      fakes.clock.setNow(kTestResetsAt.add(const Duration(seconds: 1)));
      fakes.balance.seed(aCreditBalance().build());
      await pumpEventQueue();
      expect(timer.isArmed, isTrue);
      await Future<void>.delayed(ResetTimer.margin);
      await pumpEventQueue();
      expect(fakes.balance.syncReasons, [SyncReason.resetBoundary]);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('attach / detach register with the binding once', () {
    final fakes = TaroFakes();
    final container = fakes.container();
    final observer = container.read(appLifecycleObserverProvider)
      ..attach(WidgetsBinding.instance)
      ..attach(WidgetsBinding.instance);
    expect(
      WidgetsBinding.instance.removeObserver(observer),
      isTrue,
    );
    observer
      ..attach(WidgetsBinding.instance)
      ..detach();
    expect(WidgetsBinding.instance.removeObserver(observer), isFalse);
  });
}
