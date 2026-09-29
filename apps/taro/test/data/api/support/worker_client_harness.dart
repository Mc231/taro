import 'dart:convert';
import 'dart:io';

import 'package:taro/data/api/worker_client.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'scripted_http_adapter.dart';

/// A fixed jitter source: `nextInt(n)` returns [value] clamped below `n`.
/// With the default (the middle of 0..600) the backoff has no jitter.
final class FixedRandomSource implements RandomSource {
  FixedRandomSource([this.value = 300]);

  int value;

  @override
  int nextInt(int max) => value.clamp(0, max - 1);

  @override
  bool nextBool() => false;
}

/// The instant every harness starts at.
final DateTime kHarnessNow = DateTime.utc(2026, 9, 26, 10);

/// The token the harness starts with.
final SessionToken kHarnessToken = SessionToken(
  token: 'token-1',
  expiresAt: DateTime.utc(2026, 10, 3, 10),
);

/// A granted AI consent at version 1.
final ConsentState kConsentGranted = ConsentState(
  ai: AiConsent(
    decision: AiConsentDecision.granted,
    version: 1,
    at: DateTime.utc(2026, 9, 20),
  ),
);

/// A [WorkerClient] over a [ScriptedHttpAdapter] and the core fakes, on a
/// [FakeClock]; retry waits advance the clock instead of sleeping.
final class WorkerClientHarness {
  WorkerClientHarness({
    AttestationType attestationKind = AttestationType.appAttest,
    SessionToken? token,
    bool noToken = false,
    ConsentState? consent,
    String? flavor,
    AppPlatform platform = AppPlatform.ios,
  }) : tokens = FakeSessionTokenStore(noToken ? null : token ?? kHarnessToken),
       attestation = FakeAttestationService(attestationKind),
       consent = FakeConsentStore(consent ?? kConsentGranted) {
    client = WorkerClient(
      config: WorkerClientConfig.fromAppInfo(
        FakeAppInfo(version: '1.2.0', buildNumber: '14', platform: platform),
        baseUrl: 'https://api.test',
        locale: () => locale,
        flavor: flavor,
      ),
      tokens: tokens,
      attestation: attestation,
      consent: this.consent,
      clock: clock,
      ids: ids,
      random: random,
      logger: logger,
      adapter: adapter,
      sleep: (d) async {
        sleeps.add(d);
        clock.advance(d);
      },
      onSessionExpired: () => sessionExpiredCalls++,
    );
  }

  final ScriptedHttpAdapter adapter = ScriptedHttpAdapter();
  final FakeClock clock = FakeClock.utc(kHarnessNow);
  final SequentialIdGenerator ids = SequentialIdGenerator('rid-');
  final FixedRandomSource random = FixedRandomSource();
  final CapturingLogger logger = CapturingLogger();
  final FakeSessionTokenStore tokens;
  final FakeAttestationService attestation;
  final FakeConsentStore consent;
  final List<Duration> sleeps = [];
  late final WorkerClient client;

  /// `X-Taro-Locale`, read per request.
  String locale = 'de';

  /// How often the client reported an expired session.
  int sessionExpiredCalls = 0;

  /// The requests sent so far.
  List<RecordedRequest> get requests => adapter.requests;

  /// The last request.
  RecordedRequest get last => adapter.requests.last;
}

/// The contract fixtures (`melos run contract:sync`, QA15).
final Directory fixturesDir = Directory('test/contract/fixtures');

/// A contract fixture decoded as JSON.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('${fixturesDir.path}/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// A `BalanceDto` JSON with [ledgerVersion] and [serverTime].
Map<String, dynamic> balanceJson({
  int ledgerVersion = 7,
  String serverTime = '2026-09-26T10:00:00Z',
  int bonus = 0,
  int paid = 0,
}) => {
  ...fixture('balance.response'),
  'ledgerVersion': ledgerVersion,
  'serverTime': serverTime,
  'bonus': bonus,
  'paid': paid,
};

/// The wire reading of 03 §9.1 for a single-card spread.
Map<String, dynamic> wireReading() => {
  'title': 'The Tower',
  'overview': 'A sudden change.',
  'cards': [
    {
      'positionId': 'focus',
      'cardId': 'major_16',
      'reversed': false,
      'interpretation': 'Let the old structure fall.',
    },
  ],
  'synthesis': 'Change clears the ground.',
  'reflectionPrompts': ['What can you release?'],
};
