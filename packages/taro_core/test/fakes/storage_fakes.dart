import 'package:taro_core/taro_core.dart';

import 'fake_behaviour.dart';

/// An in-memory [SecureStore]. `failNext(Failure.storage())` simulates an
/// unusable Keychain / Keystore.
final class InMemorySecureStore with FakeBehaviour implements SecureStore {
  /// A store holding [initial].
  InMemorySecureStore([Map<String, String> initial = const {}])
    : values = {...initial};

  @override
  String get fakeName => 'SecureStore';

  /// The stored values.
  final Map<String, String> values;

  @override
  Future<Result<String?>> read(String key) async {
    record('read');
    final failure = takeFailure('read');
    if (failure != null) return Result.err(failure);
    return Result.ok(values[key]);
  }

  @override
  Future<Result<void>> write(String key, String value) async {
    record('write');
    final failure = takeFailure('write');
    if (failure != null) return Result.err(failure);
    values[key] = value;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    record('delete');
    final failure = takeFailure('delete');
    if (failure != null) return Result.err(failure);
    values.remove(key);
    return const Result.ok(null);
  }
}

/// The fake of the `SecureStore` port.
typedef FakeSecureStore = InMemorySecureStore;

/// An in-memory [SessionTokenStore].
final class FakeSessionTokenStore
    with FakeBehaviour
    implements SessionTokenStore {
  /// A store holding [token].
  FakeSessionTokenStore([this.token]);

  @override
  String get fakeName => 'SessionTokenStore';

  /// The stored token.
  SessionToken? token;

  @override
  Future<Result<SessionToken?>> read() async {
    record('read');
    final failure = takeFailure('read');
    if (failure != null) return Result.err(failure);
    return Result.ok(token);
  }

  @override
  Future<Result<void>> write(SessionToken token) async {
    record('write');
    final failure = takeFailure('write');
    if (failure != null) return Result.err(failure);
    this.token = token;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    record('clear');
    final failure = takeFailure('clear');
    if (failure != null) return Result.err(failure);
    token = null;
    return const Result.ok(null);
  }
}

/// An in-memory [ConsentStore] (`consent_state`).
final class FakeConsentStore with FakeBehaviour implements ConsentStore {
  /// A store holding [initial] (the first-launch state by default).
  FakeConsentStore([ConsentState initial = const ConsentState()])
    : _state = initial;

  @override
  String get fakeName => 'ConsentStore';

  ConsentState _state;
  final ChangeSignal _changes = ChangeSignal();

  @override
  ConsentState get current => _state;

  /// Replaces the state without recording a call.
  void seed(ConsentState state) {
    _state = state;
    _changes.notify();
  }

  @override
  Stream<ConsentState> watch() => watchValue(() => _state, _changes.stream);

  @override
  Future<Result<ConsentState>> update(
    ConsentState Function(ConsentState current) change,
  ) async {
    record('update');
    final failure = takeFailure('update');
    if (failure != null) return Result.err(failure);
    _state = change(_state);
    _changes.notify();
    return Result.ok(_state);
  }
}

/// An in-memory [EntitlementCache] (`entitlements`).
final class FakeEntitlementCache
    with FakeBehaviour
    implements EntitlementCache {
  /// A cache holding [entitlement].
  FakeEntitlementCache([this.entitlement = Entitlement.unknown]);

  @override
  String get fakeName => 'EntitlementCache';

  /// The cached entitlement.
  Entitlement entitlement;

  @override
  Entitlement read() {
    record('read');
    return entitlement;
  }

  @override
  Future<Result<void>> write(Entitlement entitlement) async {
    record('write');
    final failure = takeFailure('write');
    if (failure != null) return Result.err(failure);
    this.entitlement = entitlement;
    return const Result.ok(null);
  }
}

/// An in-memory [PurchaseOutbox] (`purchase_outbox`).
///
/// Unknown `txnKey`s fail with `Failure.storage()`.
final class FakePurchaseOutbox with FakeBehaviour implements PurchaseOutbox {
  @override
  String get fakeName => 'PurchaseOutbox';

  /// Rows by `txnKey`, in insertion order.
  final Map<String, OutboxEntry> rows = {};

  /// Inserts [entry] directly (no call recorded).
  void seed(OutboxEntry entry) => rows[entry.txnKey] = entry;

  @override
  Future<Result<OutboxEntry>> enqueue(
    StorePurchase purchase, {
    required String idempotencyKey,
    required DateTime now,
  }) async {
    record('enqueue');
    final failure = takeFailure('enqueue');
    if (failure != null) return Result.err(failure);
    final existing = rows[purchase.txnKey];
    if (existing != null) return Result.ok(existing);
    final entry = OutboxEntry(
      purchase: purchase,
      idempotencyKey: idempotencyKey,
      status: OutboxStatus.awaitingVerification,
      createdAt: now,
      updatedAt: now,
    );
    rows[purchase.txnKey] = entry;
    return Result.ok(entry);
  }

  @override
  Future<Result<List<OutboxEntry>>> pending() async {
    record('pending');
    final failure = takeFailure('pending');
    if (failure != null) return Result.err(failure);
    final open = [
      for (final r in rows.values)
        if (r.isOpen) r,
    ];
    // List.sort is not stable; break ties by insertion order.
    final order = rows.keys.toList();
    open.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0
          ? byTime
          : order.indexOf(a.txnKey).compareTo(order.indexOf(b.txnKey));
    });
    return Result.ok(open);
  }

  Future<Result<void>> _change(
    String method,
    String txnKey,
    OutboxEntry Function(OutboxEntry row) change,
  ) async {
    record(method);
    final failure = takeFailure(method);
    if (failure != null) return Result.err(failure);
    final row = rows[txnKey];
    if (row == null) return const Result.err(Failure.storage());
    rows[txnKey] = change(row);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> markGranted(String txnKey, {required DateTime now}) =>
      _change(
        'markGranted',
        txnKey,
        (r) => r.copyWith(status: OutboxStatus.granted, updatedAt: now),
      );

  @override
  Future<Result<void>> markFinished(String txnKey, {required DateTime now}) =>
      _change(
        'markFinished',
        txnKey,
        (r) => r.copyWith(status: OutboxStatus.finished, updatedAt: now),
      );

  @override
  Future<Result<void>> markRejected(String txnKey, {required DateTime now}) =>
      _change(
        'markRejected',
        txnKey,
        (r) => r.copyWith(status: OutboxStatus.rejected, updatedAt: now),
      );

  @override
  Future<Result<void>> recordAttempt(
    String txnKey, {
    required DateTime now,
    String? error,
  }) => _change(
    'recordAttempt',
    txnKey,
    (r) =>
        r.copyWith(attempts: r.attempts + 1, lastError: error, updatedAt: now),
  );
}
