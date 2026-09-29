import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/repositories/serial_value.dart';

void main() {
  test('watch emits the value on listen, then only real changes', () async {
    final value = SerialValue(1);
    final seen = <int>[];
    final sub = value.watch().listen(seen.add);
    await pumpEventQueue();
    value
      ..set(1)
      ..set(2);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [1, 2]);
  });

  test('serial runs tasks in order; a failure does not block', () async {
    final value = SerialValue(0);
    final order = <String>[];
    final gate = Completer<void>();
    final first = value.serial(() async {
      await gate.future;
      order.add('first');
    });
    final failing = value.serial<void>(() async => throw StateError('x'));
    final last = value.serial(() async => order.add('last'));
    gate.complete();
    await first;
    await expectLater(failing, throwsStateError);
    await last;
    expect(order, ['first', 'last']);
  });

  test(
    'close completes watchers; later sets are kept but not emitted',
    () async {
      final value = SerialValue('a');
      final done = Completer<void>();
      value.watch().listen((_) {}, onDone: done.complete);
      await pumpEventQueue();
      await value.close();
      await done.future;
      value.set('b');
      expect(value.value, 'b');
    },
  );

  test('follow reloads on each event and reports failures', () async {
    final value = SerialValue(0);
    final source = StreamController<Object?>();
    final errors = <Object>[];
    var next = 1;
    value.follow(source.stream, () async {
      if (next < 0) throw StateError('load');
      return next;
    }, onError: (error, _) => errors.add(error));
    source.add(null);
    await pumpEventQueue();
    expect(value.value, 1);
    next = -1;
    source
      ..add(null)
      ..addError(ArgumentError('source'));
    await pumpEventQueue();
    expect(errors, [isA<ArgumentError>(), isA<StateError>()]);
    await value.close();
    await source.close();
  });
}
