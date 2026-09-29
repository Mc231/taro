import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/error_envelope_dto.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Maps Worker responses and transport errors to [Failure]s (02 §3, §6.3;
/// GLOSSARY §5; RC5).
///
/// Every 03 §2.2 code has one mapping; an unknown code or an unparseable
/// body is a [ServerFailure]; `426` is always an [UpgradeRequiredFailure].
final class ApiErrorMapper {
  /// Creates a mapper; the clock stamps balances carried in error details.
  const ApiErrorMapper(this._clock);

  final Clock _clock;

  /// Every wire code this mapper knows (03 §2.2 plus the 202
  /// `PURCHASE_PENDING` status name).
  static const Set<String> knownCodes = {
    'VALIDATION_FAILED',
    'IDEMPOTENCY_KEY_REQUIRED',
    'UNAUTHENTICATED',
    'TOKEN_EXPIRED',
    'ATTESTATION_REQUIRED',
    'INSUFFICIENT_CREDITS',
    'ATTESTATION_FAILED',
    'REWARDED_DISABLED',
    'AI_UNAVAILABLE_REGION',
    'NOT_FOUND',
    'REQUEST_IN_PROGRESS',
    'HOLD_CONFLICT',
    'PURCHASE_ALREADY_CLAIMED',
    'REWARDED_DAILY_CAP',
    'TIMEZONE_CHANGE_TOO_SOON',
    'READING_EXPIRED_REFUNDED',
    'AI_CONSENT_REQUIRED',
    'IDEMPOTENCY_KEY_REUSED',
    'PURCHASE_INVALID',
    'PRODUCT_UNKNOWN',
    'SPREAD_INVALID',
    'UPGRADE_REQUIRED',
    'RATE_LIMITED',
    'PURCHASE_PENDING',
    'INTERNAL',
    'AI_UNAVAILABLE',
    'AI_BUDGET_EXHAUSTED',
    'READINGS_DISABLED',
  };

  /// The failure of a dio [error] (transport or HTTP status).
  Failure fromDioException(DioException error) {
    final carried = error.error;
    if (carried is Failure) return carried;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const Failure.timeout(),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel => const Failure.network(),
      DioExceptionType.badResponse => fromResponse(
        error.response!.statusCode ?? 0,
        error.response!.data,
        error.response!.headers,
      ),
      DioExceptionType.unknown =>
        carried is SocketException ||
                carried is HttpException ||
                carried is TlsException
            ? const Failure.network()
            : Failure.unexpected(
                error: carried ?? error,
                stack: error.stackTrace,
              ),
    };
  }

  /// Parses the 03 §2.2 envelope from a response [data] (a JSON string or
  /// an already decoded map); `null` when it is not one.
  static ApiErrorDto? parseEnvelope(Object? data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map<String, dynamic>) return null;
      return ErrorEnvelopeDto.fromJson(decoded).error;
    } on Exception {
      return null;
    }
  }

  /// The `Retry-After` of a response: the header (seconds) or the envelope's
  /// `retryAfterSec`.
  static Duration? retryAfter(Headers headers, ApiErrorDto? envelope) {
    final header = int.tryParse(headers.value(TaroHeaders.retryAfter) ?? '');
    final seconds = header ?? envelope?.retryAfterSec;
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  /// The failure of an HTTP [status] with body [data].
  Failure fromResponse(int status, Object? data, Headers headers) {
    final envelope = parseEnvelope(data);
    final requestId = envelope?.requestId ?? headers.value('x-request-id');
    if (status == 426) {
      return Failure.upgradeRequired(
        storeUrl: _string(envelope?.details, 'storeUrl'),
      );
    }
    if (envelope == null) {
      return Failure.server(status: status, requestId: requestId);
    }
    return fromCode(
      envelope,
      status: status,
      requestId: requestId,
      retryAfter: retryAfter(headers, envelope),
    );
  }

  /// The failure of a parsed [envelope] (GLOSSARY §5 table).
  Failure fromCode(
    ApiErrorDto envelope, {
    required int status,
    String? requestId,
    Duration? retryAfter,
  }) {
    final details = envelope.details;
    final code = envelope.code;
    return switch (code) {
      'VALIDATION_FAILED' ||
      'IDEMPOTENCY_KEY_REQUIRED' ||
      'NOT_FOUND' ||
      'IDEMPOTENCY_KEY_REUSED' ||
      'SPREAD_INVALID' => Failure.contract(wireCode: code),
      'UNAUTHENTICATED' || 'TOKEN_EXPIRED' => const Failure.sessionExpired(),
      'ATTESTATION_REQUIRED' ||
      'ATTESTATION_FAILED' => const Failure.attestation(
        kind: AttestationFailureKind.rejected,
      ),
      'INSUFFICIENT_CREDITS' => Failure.insufficientCredits(
        reason: _enum(
          InsufficientReason.values.asNameMap(),
          details,
          'reason',
          InsufficientReason.noCredits,
        ),
        balance: _balance(details),
        freeResetsAt: _instant(details, 'freeResetsAt'),
      ),
      'REWARDED_DISABLED' => const Failure.rewardUnavailable(
        reason: RewardUnavailableReason.disabled,
      ),
      'REWARDED_DAILY_CAP' => Failure.rewardUnavailable(
        reason: _string(details, 'reason') == 'cooldown'
            ? RewardUnavailableReason.cooldown
            : RewardUnavailableReason.cap,
        availableAt: _instant(details, 'availableAt'),
      ),
      'AI_UNAVAILABLE_REGION' => const Failure.aiUnavailableRegion(),
      'REQUEST_IN_PROGRESS' => const Failure.requestInProgress(),
      'HOLD_CONFLICT' => const Failure.holdConflict(),
      'PURCHASE_ALREADY_CLAIMED' => Failure.purchaseAlreadyClaimed(
        transferEligible: details['transferEligible'] == true,
        transferToken: _string(details, 'transferToken'),
      ),
      'TIMEZONE_CHANGE_TOO_SOON' => _timezone(details, status, requestId),
      'READING_EXPIRED_REFUNDED' => Failure.readingExpiredRefunded(
        balance: _balance(details),
      ),
      'AI_CONSENT_REQUIRED' => Failure.aiConsentRequired(
        requiredVersion: _int(details, 'requiredVersion'),
      ),
      'PURCHASE_INVALID' || 'PRODUCT_UNKNOWN' => Failure.purchase(
        wireCode: code,
        reason: _string(details, 'reason'),
      ),
      'PURCHASE_PENDING' => const Failure.purchasePending(),
      'UPGRADE_REQUIRED' => Failure.upgradeRequired(
        storeUrl: _string(details, 'storeUrl'),
      ),
      'RATE_LIMITED' => Failure.rateLimited(
        reason: _enum(
          RateLimitReason.values.asNameMap(),
          details,
          'reason',
          RateLimitReason.burst,
        ),
        retryAfter: retryAfter,
      ),
      'AI_UNAVAILABLE' => const Failure.aiUnavailable(),
      'AI_BUDGET_EXHAUSTED' => Failure.readingsPaused(
        reason: _string(details, 'tier') == 'freeStop'
            ? PausedReason.freeStop
            : PausedReason.budgetHard,
        retryAfter: retryAfter,
      ),
      'READINGS_DISABLED' => Failure.readingsPaused(
        reason: PausedReason.disabled,
        retryAfter: retryAfter,
      ),
      _ => Failure.server(status: status, wireCode: code, requestId: requestId),
    };
  }

  Failure _timezone(Map<String, dynamic> details, int status, String? id) {
    final allowedAfter = _instant(details, 'allowedAfter');
    return allowedAfter == null
        ? Failure.server(
            status: status,
            wireCode: 'TIMEZONE_CHANGE_TOO_SOON',
            requestId: id,
          )
        : Failure.timezoneChangeRejected(allowedAfter: allowedAfter);
  }

  CreditBalance? _balance(Map<String, dynamic> details) {
    final raw = details['balance'];
    if (raw is! Map<String, dynamic>) return null;
    try {
      return BalanceDto.fromJson(raw).toDomain(syncedAt: _clock.now());
    } on Exception {
      return null;
    }
  }

  static String? _string(Map<String, dynamic>? details, String key) {
    final value = details?[key];
    return value is String ? value : null;
  }

  static int? _int(Map<String, dynamic> details, String key) {
    final value = details[key];
    return value is int ? value : null;
  }

  static DateTime? _instant(Map<String, dynamic> details, String key) {
    final raw = _string(details, key);
    if (raw == null) return null;
    try {
      return parseUtcInstant(raw);
    } on FormatException {
      return null;
    }
  }

  static T _enum<T>(
    Map<String, T> values,
    Map<String, dynamic> details,
    String key,
    T fallback,
  ) => values[_string(details, key)] ?? fallback;
}
