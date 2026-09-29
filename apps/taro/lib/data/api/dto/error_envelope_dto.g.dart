// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiErrorDto _$ApiErrorDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApiErrorDto', json, ($checkedConvert) {
      final val = ApiErrorDto(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String? ?? ''),
        requestId: $checkedConvert('requestId', (v) => v as String?),
        retryable: $checkedConvert('retryable', (v) => v as bool? ?? false),
        retryAfterSec: $checkedConvert(
          'retryAfterSec',
          (v) => (v as num?)?.toInt(),
        ),
        details: $checkedConvert(
          'details',
          (v) => v as Map<String, dynamic>? ?? const {},
        ),
      );
      return val;
    });

ErrorEnvelopeDto _$ErrorEnvelopeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorEnvelopeDto', json, ($checkedConvert) {
      final val = ErrorEnvelopeDto(
        error: $checkedConvert(
          'error',
          (v) => ApiErrorDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
