import 'dart:async';

/// A persisted value mirrored in memory for synchronous reads (`current`,
/// `cached`, `read()`), whose writes and reloads run one after another.
///
/// Repositories run every write through [serial] and reload from drift in
/// [follow] on the same queue, so a reload never lands between a write and
/// its in-memory update, and a change made outside the repository (backup
/// import, "Delete all data") still reaches [value] and [watch].
final class SerialValue<T> {
  /// Starts at [initial].
  SerialValue(T initial) : _value = initial;

  T _value;
  final StreamController<T> _changes = StreamController<T>.broadcast();
  Future<void> _tail = Future<void>.value();
  StreamSubscription<Object?>? _follow;

  /// The current value.
  T get value => _value;

  /// Replaces the value; emits only when it changed.
  void set(T next) {
    if (next == _value) return;
    _value = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  /// Emits the current value on listen, then every change.
  Stream<T> watch() {
    StreamSubscription<T>? source;
    late final StreamController<T> out;
    out = StreamController<T>(
      onListen: () {
        out.add(_value);
        source = _changes.stream.listen(out.add, onDone: out.close);
      },
      onCancel: () => source?.cancel(),
    );
    return out.stream;
  }

  /// Runs [task] after every task queued before it; a failed task does not
  /// block the queue.
  Future<R> serial<R>(Future<R> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// On every event of [changes] (a drift watch stream), queues a reload of
  /// the value through [load]. Failures go to [onError].
  void follow(
    Stream<Object?> changes,
    Future<T> Function() load, {
    required void Function(Object error, StackTrace stack) onError,
  }) {
    _follow = changes.listen(
      (_) => serial(() async {
        try {
          set(await load());
        } on Object catch (error, stack) {
          onError(error, stack);
        }
      }),
      onError: onError,
    );
  }

  /// Stops following and completes every [watch] stream.
  Future<void> close() async {
    await _follow?.cancel();
    await _tail;
    await _changes.close();
  }
}
