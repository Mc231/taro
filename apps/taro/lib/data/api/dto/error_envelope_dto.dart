import 'package:json_annotation/json_annotation.dart';
import 'package:taro/data/api/dto/json_support.dart';

part 'error_envelope_dto.g.dart';

/// The `error` object of the 03 §2.2 envelope.
@JsonSerializable(createToJson: false, checked: true)
final class ApiErrorDto {
  /// Creates the DTO.
  const ApiErrorDto({
    required this.code,
    this.message = '',
    this.requestId,
    this.retryable = false,
    this.retryAfterSec,
    this.details = const {},
  });

  /// Decodes the wire JSON.
  factory ApiErrorDto.fromJson(JsonObject json) => _$ApiErrorDtoFromJson(json);

  /// The UPPER_SNAKE code (03 §2.2, RC5).
  final String code;

  /// A developer message; never shown to users.
  final String message;

  /// The Worker request ID.
  final String? requestId;

  /// Whether the Worker marks the error retryable.
  final bool retryable;

  /// Seconds to wait before a retry.
  final int? retryAfterSec;

  /// Code-specific details (`reason`, `freeResetsAt`, `balance`, …).
  final Map<String, dynamic> details;
}

/// `{error: {code, message, requestId, retryable, retryAfterSec?,
/// details?}}` (03 §2.2).
@JsonSerializable(createToJson: false, checked: true)
final class ErrorEnvelopeDto {
  /// Creates the DTO.
  const ErrorEnvelopeDto({required this.error});

  /// Decodes the wire JSON.
  factory ErrorEnvelopeDto.fromJson(JsonObject json) =>
      _$ErrorEnvelopeDtoFromJson(json);

  /// The error.
  final ApiErrorDto error;
}
