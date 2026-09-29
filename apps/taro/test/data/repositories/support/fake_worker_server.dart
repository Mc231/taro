import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../../api/support/scripted_http_adapter.dart';
import '../../api/support/worker_client_harness.dart';

/// A stateful in-memory Worker behind dio for the reading, report, store,
/// reward and erasure routes (03 §3.6, §6.2, §7, §9.0–§9.7).
///
/// Phase 8 has no contract fixtures for the reading routes yet: bodies
/// follow 03 §9 and are checked by the DTO decoders. [failNext] fails the
/// next call at transport level (not retried); [onNext] scripts one reply
/// for a route, taking precedence over the default behaviour.
final class FakeWorkerServer implements HttpClientAdapter {
  /// A Worker whose clock is [clock].
  FakeWorkerServer(this.clock);

  /// The server clock (`serverTime`, hold and intent expiry).
  final FakeClock clock;

  /// Every request, in order.
  final List<RecordedRequest> requests = [];

  /// Readings by `clientReadingId`: the request body and the Worker state.
  final Map<String, ({Map<String, dynamic> body, String status})> readings = {};

  /// Holds taken, by `clientReadingId`.
  final Map<String, int> holds = {};

  /// Acknowledged readings.
  final Set<String> acked = {};

  /// Reports by `clientReadingId`.
  final Map<String, Map<String, dynamic>> reports = {};

  /// Store transaction keys already granted.
  final Set<String> granted = {};

  /// Store transaction keys the store rejects (`PURCHASE_INVALID`).
  final Set<String> invalid = {};

  /// Reward intents by ID with their state.
  final Map<String, String> intents = {};

  /// Erasure idempotency keys received.
  final List<String> erasures = [];

  /// `paid` credits of the balance.
  int paid = 0;

  /// The ledger version of the balance.
  int ledgerVersion = 1;

  /// Hold TTL (03 §9.0 `readings.holdTtlSec`).
  Duration holdTtl = const Duration(minutes: 15);

  final List<Failure> _failures = [];
  final List<(String, Responder)> _scripted = [];

  /// The next request fails with [failure] (carried through dio, so the
  /// retry interceptor does not repeat it).
  void failNext(Failure failure) => _failures.add(failure);

  /// The next request whose `METHOD path` starts with [route] gets
  /// [responder].
  void onNext(String route, Responder responder) =>
      _scripted.add((route, responder));

  /// Requests whose route starts with [route].
  List<RecordedRequest> sent(String route) => [
    for (final r in requests)
      if (r.route.startsWith(route)) r,
  ];

  /// The current balance JSON.
  Map<String, dynamic> balance() => {
    ...fixture('balance.response'),
    'paid': paid,
    'ledgerVersion': ledgerVersion,
    'serverTime': clock.now().toIso8601String(),
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) await requestStream.forEach(bytes.addAll);
    final request = RecordedRequest(options, Uint8List.fromList(bytes));
    requests.add(request);
    if (_failures.isNotEmpty) {
      throw DioException(
        requestOptions: options,
        error: _failures.removeAt(0),
      );
    }
    final i = _scripted.indexWhere((s) => request.route.startsWith(s.$1));
    if (i >= 0) return _scripted.removeAt(i).$2(request);
    return _route(request);
  }

  ResponseBody _route(RecordedRequest r) {
    final segments = r.path.split('/');
    final body = (r.json as Map<String, dynamic>?) ?? const {};
    return switch ((r.method, segments)) {
      ('POST', ['', 'v1', 'readings', 'holds']) => _hold(body),
      ('POST', ['', 'v1', 'readings']) => _createReading(body),
      ('GET', ['', 'v1', 'readings', final id]) => _readingState(id),
      ('POST', ['', 'v1', 'readings', final id, 'ack']) => _ack(id),
      ('POST', ['', 'v1', 'readings', final id, 'report']) => _report(id, body),
      ('POST', ['', 'v1', 'purchases', 'verify']) => _verify(body),
      ('POST', ['', 'v1', 'rewards', 'intents']) => _createIntent(),
      ('GET', ['', 'v1', 'rewards', 'intents', final id]) => _intent(id),
      ('POST', ['', 'v1', 'rewards', 'intents', final id, 'cancel']) =>
        _cancelIntent(id),
      ('DELETE', ['', 'v1', 'installs', 'me']) => _erase(r),
      _ => throw StateError('FakeWorkerServer has no route ${r.route}'),
    };
  }

  ResponseBody _hold(Map<String, dynamic> body) {
    final id = body['clientReadingId'] as String;
    holds.update(id, (n) => n + 1, ifAbsent: () => 1);
    return _json(201, {
      'clientReadingId': id,
      'chargeSource': 'free',
      'expiresAt': clock.now().add(holdTtl).toIso8601String(),
      'balance': balance(),
    });
  }

  ResponseBody _createReading(Map<String, dynamic> body) {
    final id = body['clientReadingId'] as String;
    readings[id] = (body: body, status: 'completed');
    return _json(200, {
      'readingId': 'srv-$id',
      'status': 'completed',
      'chargeSource': 'free',
      'promptVersion': 'v1',
      'reading': wireReadingFor(body),
      'balance': balance(),
    });
  }

  ResponseBody _readingState(String id) {
    final stored = readings[id];
    if (stored == null) return _error(404, 'NOT_FOUND');
    return _json(200, {
      'status': stored.status,
      'attempt': 1,
      'promptVersion': 'v1',
      if (stored.status == 'completed') 'reading': wireReadingFor(stored.body),
      'balance': balance(),
    });
  }

  ResponseBody _ack(String id) {
    acked.add(id);
    return ScriptedHttpAdapter.response(204);
  }

  ResponseBody _report(String id, Map<String, dynamic> body) {
    if (!reports.containsKey(id)) {
      if (reports.length >= 10) {
        return _error(429, 'RATE_LIMITED', details: {'reason': 'reportLimit'});
      }
      reports[id] = body;
    }
    return _json(201, {'reportId': 'report-$id', 'status': 'received'});
  }

  ResponseBody _verify(Map<String, dynamic> body) {
    final key = (body['transactionId'] ?? body['purchaseToken']) as String;
    if (invalid.contains(key)) {
      return _error(422, 'PURCHASE_INVALID', details: {'reason': 'not_found'});
    }
    final replay = granted.contains(key);
    final first = granted.isEmpty;
    if (!replay) {
      granted.add(key);
      paid += 3;
      ledgerVersion++;
    }
    return _json(200, {
      'status': replay ? 'already_granted' : 'granted',
      'purchaseId': 'purchase-$key',
      'productId': body['productId'],
      'creditsGranted': 3,
      'isFirstPurchase': !replay && first,
      'balance': balance(),
    });
  }

  ResponseBody _createIntent() {
    final id = 'intent-${intents.length + 1}';
    intents[id] = 'issued';
    return _json(201, {
      'intentId': id,
      'customData': id,
      'userId': id,
      'amount': 1,
      'expiresAt': clock
          .now()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
    });
  }

  ResponseBody _intent(String id) {
    final state = intents[id];
    if (state == null) return _error(404, 'NOT_FOUND');
    return _json(200, {
      'status': state,
      'amount': 1,
      if (state == 'granted') 'balance': balance(),
    });
  }

  ResponseBody _cancelIntent(String id) {
    if (intents[id] == 'issued') intents[id] = 'cancelled';
    return ScriptedHttpAdapter.response(204);
  }

  ResponseBody _erase(RecordedRequest r) {
    erasures.add(r.header('Idempotency-Key')!);
    return ScriptedHttpAdapter.response(204);
  }

  static ResponseBody _json(int status, Object json) =>
      ScriptedHttpAdapter.response(status, json: json);

  static ResponseBody _error(
    int status,
    String code, {
    Map<String, Object?>? details,
  }) => ScriptedHttpAdapter.response(
    status,
    json: ScriptedHttpAdapter.envelope(code, details: details),
  );

  @override
  void close({bool force = false}) {}
}

/// The §9.1 wire reading for a `POST /v1/readings` [body]: one
/// interpretation per sent card.
Map<String, dynamic> wireReadingFor(Map<String, dynamic> body) => {
  'title': 'Scripted reading',
  'overview': 'An overview.',
  'cards': [
    for (final c in (body['cards'] as List).cast<Map<String, dynamic>>())
      {...c, 'interpretation': 'About ${c['cardId']}.'},
  ],
  'synthesis': 'A synthesis.',
  'reflectionPrompts': ['What now?'],
};

/// A [WorkerClient] over a [FakeWorkerServer], in-memory databases and the
/// core fakes, on a [FakeClock] (retry and poll waits advance it).
final class RepositoryHarness {
  RepositoryHarness() {
    server = FakeWorkerServer(clock);
    client = WorkerClient(
      config: WorkerClientConfig.fromAppInfo(
        const FakeAppInfo(version: '1.2.0', buildNumber: '14'),
        baseUrl: 'https://api.test',
        locale: () => 'en',
      ),
      tokens: FakeSessionTokenStore(kHarnessToken),
      attestation: FakeAttestationService(),
      consent: FakeConsentStore(kConsentGranted),
      clock: clock,
      ids: ids,
      random: FixedRandomSource(),
      logger: logger,
      adapter: server,
      sleep: sleep,
    );
  }

  final FakeClock clock = FakeClock.utc(kHarnessNow);
  final SequentialIdGenerator ids = SequentialIdGenerator();
  final CapturingLogger logger = CapturingLogger();
  final JournalDatabase journal = JournalDatabase(NativeDatabase.memory());
  final DeviceDatabase device = DeviceDatabase(NativeDatabase.memory());
  final FakeBalanceRepository balance = FakeBalanceRepository();
  late final FakeWorkerServer server;
  late final WorkerClient client;

  /// Every wait (retry backoff and reading polls), in order.
  final List<Duration> sleeps = [];

  /// Waits by advancing [clock].
  Future<void> sleep(Duration d) async {
    sleeps.add(d);
    clock.advance(d);
  }

  /// Closes both databases.
  Future<void> close() async {
    await journal.close();
    await device.close();
  }
}
