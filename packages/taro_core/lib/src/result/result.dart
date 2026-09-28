import 'package:meta/meta.dart';
import 'package:taro_core/src/result/failure.dart';

/// The outcome of an operation that can fail without throwing (02 §3).
///
/// Repositories, gateways and use cases return `Result<T>` (or
/// `Future<Result<T>>`) and never throw across a boundary.
@immutable
sealed class Result<T> {
  const Result();

  /// A successful result carrying [value].
  const factory Result.ok(T value) = Ok<T>;

  /// A failed result carrying [failure].
  const factory Result.err(Failure failure) = Err<T>;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T>;

  /// The value of an [Ok], or `null` for an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure of an [Err], or `null` for an [Ok].
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Collapses the result: [onOk] for a value, [onErr] for a failure.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Transforms the value of an [Ok]; an [Err] passes through unchanged.
  Result<R> map<R>(R Function(T value) f) => switch (this) {
    Ok<T>(:final value) => Ok<R>(f(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// Chains an asynchronous step that runs only on [Ok].
  ///
  /// An [Err] short-circuits: [f] is not called and the failure is returned.
  Future<Result<R>> then<R>(Future<Result<R>> Function(T value) f) async =>
      switch (this) {
        Ok<T>(:final value) => f(value),
        Err<T>(:final failure) => Err<R>(failure),
      };
}

/// A successful [Result].
final class Ok<T> extends Result<T> {
  /// Wraps [value].
  const Ok(this.value);

  /// The successful value.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result].
final class Err<T> extends Result<T> {
  /// Wraps [failure].
  const Err(this.failure);

  /// Why the operation failed.
  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}
