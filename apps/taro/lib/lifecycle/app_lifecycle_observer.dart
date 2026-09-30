import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/lifecycle/reset_timer.dart';
import 'package:taro_core/taro_core.dart';

/// Resume handling (02 §9.2, rule 6): `resumed` runs a resume sync and
/// re-arms the [ResetTimer]; `paused` / `hidden` cancel the timer. It lives
/// outside the widget tree on the bootstrap container (AR3).
final class AppLifecycleObserver with WidgetsBindingObserver {
  /// An observer driving [sync] and [resetTimer].
  AppLifecycleObserver({
    required SyncCoordinator sync,
    required ResetTimer resetTimer,
  }) : _sync = sync,
       _resetTimer = resetTimer;

  final SyncCoordinator _sync;
  final ResetTimer _resetTimer;
  WidgetsBinding? _binding;

  /// Starts observing [binding].
  void attach(WidgetsBinding binding) {
    if (_binding != null) return;
    _binding = binding..addObserver(this);
  }

  /// Stops observing.
  void detach() {
    _binding?.removeObserver(this);
    _binding = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resetTimer.resume();
        unawaited(_sync.run(SyncReason.resume));
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _resetTimer.pause();
      case AppLifecycleState.inactive:
        break;
    }
  }
}

/// The [ResetTimer], re-armed on every balance change.
final resetTimerProvider = Provider<ResetTimer>((ref) {
  final sync = ref.watch(syncCoordinatorProvider);
  final repository = ref.watch(balanceRepositoryProvider);
  final timer = ResetTimer(
    clock: ref.watch(clockProvider),
    onFire: () => unawaited(sync.run(SyncReason.resetBoundary)),
  )..arm(repository.cached);
  final subscription = repository.watch().listen(timer.arm);
  ref.onDispose(() async {
    timer.dispose();
    await subscription.cancel();
  });
  return timer;
});

/// The [AppLifecycleObserver] of the container (attached at bootstrap).
final appLifecycleObserverProvider = Provider<AppLifecycleObserver>((ref) {
  final observer = AppLifecycleObserver(
    sync: ref.watch(syncCoordinatorProvider),
    resetTimer: ref.watch(resetTimerProvider),
  );
  ref.onDispose(observer.detach);
  return observer;
});
