import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro_core/taro_core.dart';

/// A successful `POST /v1/installs` (03 §3.3), mapped. The session token
/// is already persisted by the `WorkerClient`.
final class Registration {
  /// Creates the result.
  const Registration({
    required this.token,
    required this.trust,
    required this.purchaseBinding,
    required this.balance,
    required this.config,
  });

  /// The install token. Never logged.
  final SessionToken token;

  /// The trust level.
  final Trust trust;

  /// The store-account binding (RC9).
  final PurchaseBinding purchaseBinding;

  /// The balance.
  final CreditBalance balance;

  /// The embedded public config.
  final RemoteConfig config;

  @override
  String toString() => 'Registration(<redacted>, $trust)';
}

/// A successful `POST /v1/installs/token` (03 §3.4), already persisted.
final class TokenGrant {
  /// Creates the grant.
  const TokenGrant({required this.token, required this.trust});

  /// The new install token. Never logged.
  final SessionToken token;

  /// The trust level.
  final Trust trust;

  @override
  String toString() => 'TokenGrant(<redacted>, $trust)';
}

/// The result of `GET /v1/config` with `If-None-Match` (03 §8.1).
sealed class ConfigFetch {
  const ConfigFetch();

  /// `304`: the cached document with the sent ETag is current.
  const factory ConfigFetch.notModified() = ConfigNotModified;

  /// `200`: a new document.
  const factory ConfigFetch.fetched({
    required RemoteConfig config,
    required JsonObject json,
    String? etag,
  }) = ConfigFetched;
}

/// `304 Not Modified`.
final class ConfigNotModified extends ConfigFetch {
  /// Creates the result.
  const ConfigNotModified();
}

/// `200` with a config document.
final class ConfigFetched extends ConfigFetch {
  /// Creates the result.
  const ConfigFetched({required this.config, required this.json, this.etag});

  /// The parsed, clamped config.
  final RemoteConfig config;

  /// The raw document (for the drift cache).
  final JsonObject json;

  /// The `ETag` to send next time.
  final String? etag;
}

/// The Worker's answer about one reading: `POST /v1/readings` (completed or
/// declined) or `GET /v1/readings/{clientReadingId}` (any state), mapped
/// (03 §9.1, RC30, RC27, RC51).
sealed class ReadingOutcome {
  const ReadingOutcome({required this.balance, this.attempt = 1});

  /// `completed`: the reading text (persist it, then ack, RC51).
  const factory ReadingOutcome.completed({
    required ReadingContent content,
    required CreditBalance balance,
    ChargeSource? chargeSource,
    String? promptVersion,
    String? workerReadingId,
    int attempt,
  }) = ReadingCompleted;

  /// `declined`: never charged; [safety] drives the refusal UI (RC27).
  const factory ReadingOutcome.declined({
    required SafetyInfo safety,
    required CreditBalance balance,
    int attempt,
  }) = ReadingDeclined;

  /// `held` / `generating`: still running; poll again.
  const factory ReadingOutcome.inProgress({
    required String workerStatus,
    required CreditBalance balance,
    int attempt,
  }) = ReadingInProgress;

  /// `failed` / `expired_hold` / `no_credit` / `expired_refunded`: nothing
  /// was charged; retry with the same cards (RC49).
  const factory ReadingOutcome.failed({
    required String workerStatus,
    required CreditBalance balance,
    int attempt,
  }) = ReadingAttemptFailed;

  /// The balance returned with the answer.
  final CreditBalance balance;

  /// `readings.attempt`.
  final int attempt;

  /// The local status this outcome leads to (02 §4): `completed` →
  /// `complete`, `declined` → `refused(safety)`, running → `pending`; a
  /// failed attempt → `failed(…, refunded: true)` except `no_credit`
  /// (never held, so nothing to refund; the draw waits for credits as on a
  /// `409 HOLD_CONFLICT`, RC48).
  ReadingStatus get status => switch (this) {
    ReadingCompleted() => const ReadingStatus.complete(),
    ReadingDeclined(:final safety) => ReadingStatus.refused(safety: safety),
    ReadingInProgress() => const ReadingStatus.pending(),
    ReadingAttemptFailed(workerStatus: 'no_credit') =>
      const ReadingStatus.failed(
        Failure.holdConflict(),
      ),
    ReadingAttemptFailed(workerStatus: 'expired_refunded', :final balance) =>
      ReadingStatus.failed(
        Failure.readingExpiredRefunded(balance: balance),
        refunded: true,
      ),
    ReadingAttemptFailed() => const ReadingStatus.failed(
      Failure.aiUnavailable(),
      refunded: true,
    ),
  };
}

/// A delivered reading.
final class ReadingCompleted extends ReadingOutcome {
  /// Creates the outcome.
  const ReadingCompleted({
    required this.content,
    required super.balance,
    this.chargeSource,
    this.promptVersion,
    this.workerReadingId,
    super.attempt,
  });

  /// The reading text.
  final ReadingContent content;

  /// Which bucket paid (`null` when the Worker did not say, e.g. on GET).
  final ChargeSource? chargeSource;

  /// The Worker prompt version (opaque, RC97).
  final String? promptVersion;

  /// The Worker `readingId`.
  final String? workerReadingId;
}

/// A declined reading.
final class ReadingDeclined extends ReadingOutcome {
  /// Creates the outcome.
  const ReadingDeclined({
    required this.safety,
    required super.balance,
    super.attempt,
  });

  /// Why.
  final SafetyInfo safety;
}

/// A reading still held or generating.
final class ReadingInProgress extends ReadingOutcome {
  /// Creates the outcome.
  const ReadingInProgress({
    required this.workerStatus,
    required super.balance,
    super.attempt,
  });

  /// `held | generating`.
  final String workerStatus;
}

/// A failed attempt (refunded or never charged).
final class ReadingAttemptFailed extends ReadingOutcome {
  /// Creates the outcome.
  const ReadingAttemptFailed({
    required this.workerStatus,
    required super.balance,
    super.attempt,
  });

  /// `failed | expired_hold | no_credit | expired_refunded`.
  final String workerStatus;
}

ChargeSource? _optChargeSource(String? wire) => wire == null || wire == 'none'
    ? null
    : wireEnum(ChargeSource.values.asNameMap(), wire, 'chargeSource');

/// `ReadingResponseDto` → [ReadingOutcome] (RC30, RC27).
extension ReadingResponseMapping on ReadingResponseDto {
  /// The outcome, received at device time [syncedAt]; throws a
  /// [FormatException] for an unknown status or a missing payload.
  ReadingOutcome toDomain({required DateTime syncedAt}) {
    final balance = this.balance.toDomain(syncedAt: syncedAt);
    return switch (status) {
      'completed' => ReadingOutcome.completed(
        content: _require(reading, 'reading').toDomain(),
        balance: balance,
        chargeSource: _optChargeSource(chargeSource),
        promptVersion: promptVersion,
        workerReadingId: readingId,
      ),
      'declined' => ReadingOutcome.declined(
        safety: _require(safety, 'safety').toDomain(),
        balance: balance,
      ),
      _ => throw FormatException('"status" has an unknown value', status),
    };
  }
}

/// `ReadingStateDto` → [ReadingOutcome].
extension ReadingStateMapping on ReadingStateDto {
  /// The outcome, received at device time [syncedAt]; throws a
  /// [FormatException] for an unknown status or a missing payload.
  ReadingOutcome toDomain({required DateTime syncedAt}) {
    final balance = this.balance.toDomain(syncedAt: syncedAt);
    return switch (status) {
      'completed' => ReadingOutcome.completed(
        content: _require(reading, 'reading').toDomain(),
        balance: balance,
        chargeSource: _optChargeSource(chargeSource),
        promptVersion: promptVersion,
        attempt: attempt,
      ),
      'declined' => ReadingOutcome.declined(
        safety: _require(safety, 'safety').toDomain(),
        balance: balance,
        attempt: attempt,
      ),
      'held' || 'generating' => ReadingOutcome.inProgress(
        workerStatus: status,
        balance: balance,
        attempt: attempt,
      ),
      'failed' ||
      'expired_hold' ||
      'no_credit' ||
      'expired_refunded' => ReadingOutcome.failed(
        workerStatus: status,
        balance: balance,
        attempt: attempt,
      ),
      _ => throw FormatException('"status" has an unknown value', status),
    };
  }
}

T _require<T>(T? value, String field) =>
    value ?? (throw FormatException('"$field" is required'));
