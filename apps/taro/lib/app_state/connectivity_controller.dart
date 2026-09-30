import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';

/// Whether the device looks online (a UI hint only; the authoritative
/// signal is a `NetworkFailure`, 02 §10). Optimistically `true` until the
/// first check answers.
final class ConnectivityController extends Notifier<bool> {
  @override
  bool build() {
    final monitor = ref.watch(connectivityMonitorProvider);
    final subscription = monitor.online.listen((online) => state = online);
    ref.onDispose(subscription.cancel);
    unawaited(
      monitor.isOnline().then((online) {
        if (ref.mounted) state = online;
      }),
    );
    return true;
  }
}

/// The app-wide connectivity hint (`connectivityProvider`, 02 §7).
final connectivityProvider = NotifierProvider<ConnectivityController, bool>(
  ConnectivityController.new,
);
