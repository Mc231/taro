import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:taro_core/taro_core.dart';

/// Records calls across several fakes in order, for "A happens before B"
/// assertions (for example outbox write → verify → finish, rule 8).
///
/// Attach it with `fake.recorder = recorder`; each call is recorded as
/// `<fakeName>.<method>`.
final class CallRecorder {
  /// Every recorded call, oldest first.
  final List<String> calls = [];

  /// Records [call].
  void add(String call) => calls.add(call);

  /// Whether [first] was recorded before [second] (both must be present).
  bool isBefore(String first, String second) {
    final a = calls.indexOf(first);
    final b = calls.indexOf(second);
    return a >= 0 && b >= 0 && a < b;
  }
}

/// Shared test hooks of every fake: a call log and `failNext(Failure)`.
mixin FakeBehaviour {
  /// The name used in [CallRecorder] entries.
  String get fakeName;

  /// Every method called on this fake, oldest first.
  final List<String> calls = [];

  /// Optional cross-fake recorder.
  CallRecorder? recorder;

  final List<({String? method, Failure failure})> _failures = [];

  /// Makes the next call fail with [failure]: the next call of [on] (a
  /// method name such as `'sync'`), or the next failable call of any
  /// method when [on] is `null`. Queued failures are used in order.
  void failNext(Failure failure, {String? on}) =>
      _failures.add((method: on, failure: failure));

  /// Whether a failure is still queued.
  bool get hasQueuedFailure => _failures.isNotEmpty;

  /// How often [method] was called.
  int callCount(String method) => calls.where((c) => c == method).length;

  /// Records a call of [method].
  @protected
  void record(String method) {
    calls.add(method);
    recorder?.add('$fakeName.$method');
  }

  /// Takes the first queued failure for [method], if any.
  @protected
  Failure? takeFailure(String method) {
    final i = _failures.indexWhere(
      (f) => f.method == null || f.method == method,
    );
    if (i < 0) return null;
    return _failures.removeAt(i).failure;
  }
}

/// A stream that emits `read()` on listen and then after every [changes]
/// event whose value differs (by [equals]) from the last one emitted.
///
/// The current value is captured at listen time, so no change between the
/// call and the listen is lost.
Stream<T> watchValue<T>(
  T Function() read,
  Stream<void> changes, {
  bool Function(T a, T b)? equals,
}) {
  final same =
      equals ?? (T a, T b) => const DeepCollectionEquality().equals(a, b);
  late final StreamController<T> controller;
  StreamSubscription<void>? sub;
  controller = StreamController<T>(
    onListen: () {
      var last = read();
      controller.add(last);
      sub = changes.listen((_) {
        final next = read();
        if (!same(last, next)) {
          last = next;
          controller.add(next);
        }
      });
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
}

/// A broadcast "something changed" signal.
final class ChangeSignal {
  final StreamController<void> _controller = StreamController<void>.broadcast(
    sync: true,
  );

  /// The change events.
  Stream<void> get stream => _controller.stream;

  /// Signals a change.
  void notify() => _controller.add(null);
}
