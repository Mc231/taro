import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/install/install_repository_impl.dart';
import 'package:taro/data/install/proof_of_work.dart';
import 'package:taro/data/secure/secure_session_token_store.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../../api/support/scripted_http_adapter.dart';
import '../../api/support/worker_client_harness.dart' show balanceJson, fixture;
import '../../db/db_fixtures.dart';

/// A Worker fake by route: `METHOD /path` → reply, with queued one-off
/// replies ([once]) taking precedence for the next request.
final class RoutedHttpAdapter implements HttpClientAdapter {
  /// Every request received, oldest first.
  final List<RecordedRequest> requests = [];

  /// The standing replies by route.
  final Map<String, Responder> routes = {};

  final List<Responder> _once = [];

  /// Queues [responder] for the next request only.
  void once(Responder responder) => _once.add(responder);

  /// Requests to [route], oldest first.
  List<RecordedRequest> to(String route) => [
    for (final r in requests)
      if (r.route == route) r,
  ];

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
    if (_once.isNotEmpty) return _once.removeAt(0)(request);
    final route = routes[request.route];
    if (route == null) throw StateError('No route for ${request.route}');
    return route(request);
  }

  @override
  void close({bool force = false}) {}
}

/// Routes.
const String kChallenge = 'POST /v1/attest/challenge';
const String kRegister = 'POST /v1/installs';
const String kToken = 'POST /v1/installs/token';
const String kTimezone = 'PUT /v1/installs/me/timezone';
const String kDelete = 'DELETE /v1/installs/me';

/// The harness start instant.
final DateTime kInstallNow = DateTime.utc(2026, 9, 26, 10);

/// An [InstallRepositoryImpl] over an in-memory secure store, an in-memory
/// `taro_device.db`, the core fakes and a [RoutedHttpAdapter] Worker.
///
/// [secure] and [device] may be passed to model a restart or a reinstall
/// (what survives is what the caller hands over).
final class InstallHarness {
  InstallHarness({
    InMemorySecureStore? secure,
    DeviceDatabase? device,
    AttestationType attestationKind = AttestationType.appAttest,
    AppPlatform platform = AppPlatform.ios,
    SequentialIdGenerator? ids,
    FakeClock? clock,
    this.onRegistered,
  }) : secure = secure ?? InMemorySecureStore(),
       device = device ?? memoryDevice(),
       attestation = FakeAttestationService(attestationKind),
       ids = ids ?? SequentialIdGenerator(),
       clock = clock ?? FakeClock.utc(kInstallNow) {
    tokens = SecureSessionTokenStore(this.secure, logger: logger);
    config = WorkerClientConfig(
      baseUrl: 'https://api.test',
      platform: platform,
      appVersion: '1.2.0+14',
      locale: () => 'de',
    );
    client = WorkerClient(
      config: config,
      tokens: tokens,
      attestation: attestation,
      consent: FakeConsentStore(),
      clock: this.clock,
      ids: this.ids,
      random: random,
      logger: logger,
      adapter: adapter,
      sleep: (d) async => this.clock.advance(d),
    );
    repo = InstallRepositoryImpl(
      client: client,
      config: config,
      secure: this.secure,
      cache: this.device.cacheDao,
      attestation: attestation,
      timezone: timezone,
      clock: this.clock,
      ids: this.ids,
      random: random,
      logger: logger,
      solveProofOfWork: _solve,
      onRegistered: onRegistered,
    );
    adapter.routes.addAll({
      kChallenge: (_) => ok(fixture('installs.challenge.response')),
      kRegister: (_) => ok(fixture('installs.register.response'), 201),
      kToken: (_) => ok(fixture('installs.token.response')),
      kTimezone: (request) {
        final zone = (request.json! as Map)['timezone'] as String;
        final balance = balanceJson();
        return ok({
          ...balance,
          'free': {
            ...balance['free'] as Map<String, dynamic>,
            'timezone': zone,
          },
        });
      },
      kDelete: (_) => ScriptedHttpAdapter.response(204),
    });
  }

  final InMemorySecureStore secure;
  final DeviceDatabase device;
  final FakeAttestationService attestation;
  final SequentialIdGenerator ids;
  final FakeClock clock;
  final RegistrationListener? onRegistered;
  final RoutedHttpAdapter adapter = RoutedHttpAdapter();
  final SeededRandomSource random = SeededRandomSource(7);
  final CapturingLogger logger = CapturingLogger();
  final FakeTimezoneProvider timezone = FakeTimezoneProvider('Europe/Berlin');
  late final SecureSessionTokenStore tokens;
  late final WorkerClientConfig config;
  late final WorkerClient client;
  late final InstallRepositoryImpl repo;

  /// Arguments of every proof-of-work run.
  final List<({String challenge, String installId, int bits})> powRuns = [];

  Future<String> _solve({
    required String challenge,
    required String installId,
    required int bits,
  }) async {
    powRuns.add((challenge: challenge, installId: installId, bits: bits));
    return solveProofOfWork(
      challenge: challenge,
      installId: installId,
      bits: bits,
    );
  }

  /// A JSON reply.
  static ResponseBody ok(Object json, [int status = 200]) =>
      ScriptedHttpAdapter.response(status, json: json);

  /// A Worker error envelope reply.
  static ResponseBody error(
    int status,
    String code, {
    Map<String, Object?>? details,
  }) => ScriptedHttpAdapter.response(
    status,
    json: ScriptedHttpAdapter.envelope(code, details: details),
  );

  /// Closes the database.
  Future<void> close() => device.close();
}
