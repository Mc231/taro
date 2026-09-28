import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// The value of [result], failing the test on an `Err`.
T expectOk<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('expected Ok, got Err($failure)'),
};

/// The failure of [result], failing the test on an `Ok`.
Failure expectErr<T>(Result<T> result) => switch (result) {
  Ok(:final value) => fail('expected Err, got Ok($value)'),
  Err(:final failure) => failure,
};

/// Waits for pending microtasks and stream events.
Future<void> settle() => Future<void>.delayed(Duration.zero);
