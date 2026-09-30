import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/install_dtos.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro/data/api/endpoints.dart';
import 'package:taro/data/api/interceptors/ai_consent_interceptor.dart';
import 'package:taro/data/api/interceptors/attestation_interceptor.dart';
import 'package:taro/data/api/interceptors/auth_interceptor.dart';
import 'package:taro/data/api/interceptors/error_interceptor.dart';
import 'package:taro/data/api/interceptors/headers_interceptor.dart';
import 'package:taro/data/api/interceptors/retry_interceptor.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro/data/api/server_clock.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro_core/taro_core.dart';

/// Static settings of the [WorkerClient] (02 §6.3, §15). No secrets.
final class WorkerClientConfig {
  /// Creates the settings.
  const WorkerClientConfig({
    required this.baseUrl,
    required this.platform,
    required this.appVersion,
    required this.locale,
    this.flavor,
    this.extraHeaders = const {},
  });

  /// Settings from the [AppInfo] port: `X-Taro-App-Version` is
  /// `version+buildNumber` (`1.2.0+34`). Pass [flavor] only for non-prod
  /// builds.
  ///
  /// [extraHeaders] is the debug attestation hook of dev and staging
  /// builds (`X-Taro-Debug-Attestation`, RC86): a prod build ([flavor]
  /// `null`) with extra headers is a wiring mistake and throws
  /// [StateError] (02 §15).
  factory WorkerClientConfig.fromAppInfo(
    AppInfo info, {
    required String baseUrl,
    required String Function() locale,
    String? flavor,
    Map<String, String> extraHeaders = const {},
  }) {
    if (flavor == null && extraHeaders.isNotEmpty) {
      throw StateError('A prod build must not send debug headers.');
    }
    return WorkerClientConfig(
      baseUrl: baseUrl,
      platform: info.platform,
      appVersion: '${info.version}+${info.buildNumber}',
      locale: locale,
      flavor: flavor,
      extraHeaders: extraHeaders,
    );
  }

  /// The Worker origin, e.g. `https://api.taro.vshyrochuk.com` (paths
  /// carry `/v1`).
  final String baseUrl;

  /// `X-Taro-Platform`.
  final AppPlatform platform;

  /// `X-Taro-App-Version`.
  final String appVersion;

  /// The current app locale (`X-Taro-Locale`), read per request.
  final String Function() locale;

  /// `X-Taro-Flavor` for dev/staging; `null` in prod.
  final String? flavor;

  /// Headers added to every request (dev/staging debug attestation only).
  final Map<String, String> extraHeaders;
}

/// The dio client of the Worker API (02 §6.3; the RC4 route set).
///
/// Interceptor chain, in order: [HeadersInterceptor] → [AuthInterceptor] →
/// [AttestationInterceptor] → [AiConsentInterceptor] → [RetryInterceptor]
/// → [ErrorInterceptor]. Every call returns a [Result] and never throws;
/// response bodies are mapped to domain types by the DTO mappers. The
/// client knows nothing about which LLM provider generates a reading
/// (RC97): prompt versions and model IDs are opaque strings.
final class WorkerClient {
  /// Creates the client. [attestationKeyId] names the App Attest key of
  /// each assertion (see [AttestationInterceptor.storedKeyId]); [adapter]
  /// replaces dio's HTTP adapter (tests use a scripted one); [sleep]
  /// replaces the retry wait.
  WorkerClient({
    required WorkerClientConfig config,
    required SessionTokenStore tokens,
    required AttestationService attestation,
    required ConsentStore consent,
    required Clock clock,
    required IdGenerator ids,
    required RandomSource random,
    required Logger logger,
    ServerClockTracker? serverClock,
    AttestationKeyIdReader? attestationKeyId,
    HttpClientAdapter? adapter,
    Sleep sleep = realSleep,
    void Function()? onSessionExpired,
  }) : _tokens = tokens,
       _clock = clock,
       _logger = logger.child('api'),
       serverClock = serverClock ?? ServerClockTracker(),
       _mapper = ApiErrorMapper(clock),
       _dio = Dio(
         BaseOptions(
           baseUrl: config.baseUrl,
           connectTimeout: ApiTimeouts.connect,
           responseType: ResponseType.plain,
           validateStatus: _accepted,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.addAll([
      HeadersInterceptor(
        platform: config.platform,
        appVersion: config.appVersion,
        locale: config.locale,
        flavor: config.flavor,
        extraHeaders: config.extraHeaders,
        ids: ids,
        clock: clock,
        serverClock: this.serverClock,
      ),
      AuthInterceptor(
        dio: _dio,
        tokens: tokens,
        refresh: refreshSessionToken,
        onSessionExpired: onSessionExpired,
      ),
      AttestationInterceptor(attestation, keyId: attestationKeyId),
      AiConsentInterceptor(consent),
      RetryInterceptor(
        dio: _dio,
        random: random,
        sleep: sleep,
        logger: _logger,
      ),
      ErrorInterceptor(_mapper, logger: _logger),
    ]);
  }

  final SessionTokenStore _tokens;
  final Clock _clock;
  final Logger _logger;
  final ApiErrorMapper _mapper;
  final Dio _dio;
  Future<Result<TokenGrant>>? _refreshing;

  /// The Worker clock offset, updated from every `Date` header and every
  /// balance's `serverTime`.
  final ServerClockTracker serverClock;

  static bool _accepted(int? status) =>
      status != null && ((status >= 200 && status < 300) || status == 304);

  // Identity ----------------------------------------------------------------

  /// E03 `POST /v1/attest/challenge`.
  Future<Result<ChallengeDto>> challenge() => _send(
    Endpoints.challenge,
    decode: (json, _) => ChallengeDto.fromJson(
      _object(json),
    ),
  );

  /// E04 `POST /v1/installs` with a fresh [idempotencyKey] per registration
  /// attempt (RC55). The token is persisted before the result returns.
  Future<Result<Registration>> register(
    RegisterRequestDto body, {
    required String idempotencyKey,
  }) async {
    final result = await _send(
      Endpoints.register,
      body: body.toJson(),
      idempotencyKey: idempotencyKey,
      decode: (json, now) {
        final dto = RegistrationResponseDto.fromJson(_object(json));
        return Registration(
          token: dto.toSessionToken(),
          trust: dto.toTrust(),
          purchaseBinding: dto.purchaseBinding.toDomain(),
          balance: _balance(dto.balance, now),
          config: _config(dto.config, now),
        );
      },
    );
    return result.then(
      (reg) async => (await _tokens.write(reg.token)).map((_) => reg),
    );
  }

  /// E05 `POST /v1/installs/token` **attest**, single-flight: concurrent
  /// callers (and the auth interceptor) share one request. The new token is
  /// persisted before the result returns.
  Future<Result<TokenGrant>> refreshToken() =>
      _refreshing ??= _refreshOnce().whenComplete(() => _refreshing = null);

  /// [refreshToken] reduced to the token (the auth interceptor's
  /// [TokenRefresher]).
  Future<Result<SessionToken>> refreshSessionToken() async =>
      (await refreshToken()).map((grant) => grant.token);

  Future<Result<TokenGrant>> _refreshOnce() async {
    final result = await _send(
      Endpoints.refreshToken,
      decode: (json, _) {
        final dto = InstallTokenDto.fromJson(_object(json));
        return TokenGrant(token: dto.toSessionToken(), trust: dto.toTrust());
      },
    );
    return result.then(
      (grant) async => (await _tokens.write(grant.token)).map((_) => grant),
    );
  }

  /// E06 `PUT /v1/installs/me/timezone`; `409` →
  /// [TimezoneChangeRejectedFailure] (keep the server boundary).
  Future<Result<CreditBalance>> updateTimezone(
    String iana, {
    required String idempotencyKey,
  }) => _send(
    Endpoints.timezone,
    body: TimezoneRequestDto(timezone: iana).toJson(),
    idempotencyKey: idempotencyKey,
    decode: (json, now) => _balance(BalanceDto.fromJson(_object(json)), now),
  );

  /// E07 `DELETE /v1/installs/me` (`204`), a fresh key per user action.
  Future<Result<void>> deleteInstall({required String idempotencyKey}) =>
      _send<void>(
        Endpoints.deleteInstall,
        idempotencyKey: idempotencyKey,
        decode: (_, _) {},
      );

  // Config and balance ------------------------------------------------------

  /// E02 `GET /v1/config` with `If-None-Match: [etag]`.
  Future<Result<ConfigFetch>> fetchConfig({String? etag}) => _send(
    Endpoints.config,
    headers: {TaroHeaders.ifNoneMatch: ?etag},
    decodeResponse: (response, now) {
      if (response.statusCode == 304) return const ConfigFetch.notModified();
      final json = _object(_json(response));
      return ConfigFetch.fetched(
        config: _config(json, now),
        json: json,
        etag: response.headers.value(TaroHeaders.etag),
      );
    },
  );

  /// E08 `GET /v1/balance`.
  Future<Result<CreditBalance>> fetchBalance() => _send(
    Endpoints.balance,
    decode: (json, now) => _balance(BalanceDto.fromJson(_object(json)), now),
  );

  // Readings ----------------------------------------------------------------

  /// E09 `POST /v1/readings/holds` with `Idempotency-Key = clientReadingId`
  /// (RC42, RC50); the same call renews a live hold.
  Future<Result<ReadingHold>> createHold(HoldRequestDto body) => _send(
    Endpoints.hold,
    body: body.toJson(),
    idempotencyKey: body.clientReadingId,
    decode: (json, now) {
      final hold = HoldDto.fromJson(_object(json)).toDomain(syncedAt: now);
      _recordServerTime(hold.balance);
      return hold;
    },
  );

  /// E10 `POST /v1/readings` (60 s, RC31) with `Idempotency-Key =
  /// clientReadingId`. A timeout is a [TimeoutFailure] after one attempt:
  /// the caller then polls [fetchReading] per
  /// [ApiTimeouts.readingPollDelays] (02 §6.3).
  Future<Result<ReadingOutcome>> createReading(CreateReadingRequestDto body) =>
      _send(
        Endpoints.createReading,
        body: body.toJson(),
        idempotencyKey: body.clientReadingId,
        decode: (json, now) => _outcome(
          ReadingResponseDto.fromJson(_object(json)).toDomain(syncedAt: now),
        ),
      );

  /// E11 `GET /v1/readings/{clientReadingId}` (resume / poll); `410` →
  /// [ReadingExpiredRefundedFailure].
  Future<Result<ReadingOutcome>> fetchReading(ReadingId id) => _send(
    Endpoints.getReading,
    params: {'clientReadingId': id.value},
    decode: (json, now) => _outcome(
      ReadingStateDto.fromJson(_object(json)).toDomain(syncedAt: now),
    ),
  );

  /// E12 `POST /v1/readings/{clientReadingId}/ack` (no body), after the
  /// reading is persisted (RC51).
  Future<Result<void>> ackReading(ReadingId id) => _send<void>(
    Endpoints.ackReading,
    params: {'clientReadingId': id.value},
    decode: (_, _) {},
  );

  /// E13 `POST /v1/readings/{clientReadingId}/report`, a fresh key per
  /// submission reused on retry.
  Future<Result<ReportResponseDto>> reportReading(
    ReadingId id,
    ReportRequestDto body, {
    required String idempotencyKey,
  }) => _send(
    Endpoints.reportReading,
    params: {'clientReadingId': id.value},
    body: body.toJson(),
    idempotencyKey: idempotencyKey,
    decode: (json, _) => ReportResponseDto.fromJson(_object(json)),
  );

  // Store and rewards -------------------------------------------------------

  /// E14 `POST /v1/purchases/verify` with the outbox row's key; `202` →
  /// [GrantStatus.pending].
  Future<Result<GrantResult>> verifyPurchase(
    VerifyPurchaseRequestDto body, {
    required String idempotencyKey,
  }) => _send(
    Endpoints.verifyPurchase,
    body: body.toJson(),
    idempotencyKey: idempotencyKey,
    decode: (json, now) {
      final grant = VerifyPurchaseResponseDto.fromJson(
        _object(json),
      ).toDomain(syncedAt: now);
      final balance = grant.balance;
      if (balance != null) _recordServerTime(balance);
      return grant;
    },
  );

  /// E15 `POST /v1/rewards/intents`, a new key per tap.
  Future<Result<RewardIntent>> createRewardIntent(
    String adUnitId, {
    required String idempotencyKey,
  }) => _send(
    Endpoints.rewardIntent,
    body: RewardIntentRequestDto(adUnitId: adUnitId).toJson(),
    idempotencyKey: idempotencyKey,
    decode: (json, _) => RewardIntentDto.fromJson(_object(json)).toDomain(),
  );

  /// E16 `GET /v1/rewards/intents/{intentId}`.
  Future<Result<RewardStatus>> fetchRewardStatus(IntentId id) => _send(
    Endpoints.rewardStatus,
    params: {'intentId': id.value},
    decode: (json, now) {
      final status = RewardIntentStatusDto.fromJson(
        _object(json),
      ).toDomain(syncedAt: now);
      final balance = status.balance;
      if (balance != null) _recordServerTime(balance);
      return status;
    },
  );

  /// E17 `POST /v1/rewards/intents/{intentId}/cancel` (best effort).
  Future<Result<void>> cancelRewardIntent(IntentId id) => _send<void>(
    Endpoints.rewardCancel,
    params: {'intentId': id.value},
    decode: (_, _) {},
  );

  // Plumbing ----------------------------------------------------------------

  /// Sends one call and maps its response; never throws.
  ///
  /// The body is encoded here, once, to the exact bytes that are hashed
  /// for `X-Taro-Attestation` and sent.
  Future<Result<T>> _send<T>(
    Endpoint endpoint, {
    T Function(Object? json, DateTime receivedAt)? decode,
    T Function(Response<dynamic> response, DateTime receivedAt)? decodeResponse,
    Map<String, String> params = const {},
    Map<String, Object?>? body,
    String? idempotencyKey,
    Map<String, String> headers = const {},
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        endpoint.resolve(params),
        data: body == null
            ? null
            : Uint8List.fromList(utf8.encode(jsonEncode(body))),
        options: Options(
          method: endpoint.method,
          sendTimeout: endpoint.timeout,
          receiveTimeout: endpoint.timeout,
          headers: headers,
          extra: requestExtra(endpoint, idempotencyKey: idempotencyKey),
        ),
      );
    } on DioException catch (error) {
      return Result.err(_mapper.fromDioException(error));
    }
    final receivedAt = _clock.now();
    try {
      return Result.ok(
        decodeResponse != null
            ? decodeResponse(response, receivedAt)
            : decode!(_json(response), receivedAt),
      );
    } on Exception catch (error) {
      _logger.warning(
        '${endpoint.id} returned an unreadable ${response.statusCode} body',
        error: error is FormatException ? error.message : error.runtimeType,
      );
      return Result.err(
        Failure.server(
          status: response.statusCode ?? 0,
          requestId: response.headers.value('x-request-id'),
        ),
      );
    }
  }

  CreditBalance _balance(BalanceDto dto, DateTime now) =>
      _recordServerTime(dto.toDomain(syncedAt: now));

  CreditBalance _recordServerTime(CreditBalance balance) {
    serverClock.record(
      serverTime: balance.serverTime,
      receivedAt: balance.syncedAt,
    );
    return balance;
  }

  ReadingOutcome _outcome(ReadingOutcome outcome) {
    _recordServerTime(outcome.balance);
    return outcome;
  }

  RemoteConfig _config(JsonObject json, DateTime now) => RemoteConfig.fromJson(
    json,
    fetchedAt: now,
    onClamped: (key) => _logger.info('config_value_clamped $key'),
  );

  static Object? _json(Response<dynamic> response) {
    final data = response.data;
    if (data is! String || data.isEmpty) return null;
    return jsonDecode(data);
  }

  static JsonObject _object(Object? json) => json is Map<String, dynamic>
      ? json
      : throw const FormatException('Expected a JSON object');
}
