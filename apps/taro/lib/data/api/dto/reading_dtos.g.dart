// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$SpreadRefDtoToJson(SpreadRefDto instance) =>
    <String, dynamic>{'id': instance.id, 'version': instance.version};

Map<String, dynamic> _$HoldRequestDtoToJson(HoldRequestDto instance) =>
    <String, dynamic>{
      'clientReadingId': instance.clientReadingId,
      'spread': instance.spread.toJson(),
      'locale': instance.locale,
    };

HoldDto _$HoldDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HoldDto', json, ($checkedConvert) {
      final val = HoldDto(
        clientReadingId: $checkedConvert('clientReadingId', (v) => v as String),
        chargeSource: $checkedConvert('chargeSource', (v) => v as String),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        balance: $checkedConvert(
          'balance',
          (v) => BalanceDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DrawnCardDtoToJson(DrawnCardDto instance) =>
    <String, dynamic>{
      'positionId': instance.positionId,
      'cardId': instance.cardId,
      'reversed': instance.reversed,
    };

Map<String, dynamic> _$CreateReadingRequestDtoToJson(
  CreateReadingRequestDto instance,
) => <String, dynamic>{
  'clientReadingId': instance.clientReadingId,
  'spread': instance.spread.toJson(),
  'cards': instance.cards.map((e) => e.toJson()).toList(),
  'question': ?instance.question,
  'locale': instance.locale,
  'drawnAt': const UtcInstantConverter().toJson(instance.drawnAt),
};

ReadingCardWireDto _$ReadingCardWireDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingCardWireDto', json, ($checkedConvert) {
      final val = ReadingCardWireDto(
        positionId: $checkedConvert('positionId', (v) => v as String),
        cardId: $checkedConvert('cardId', (v) => v as String),
        reversed: $checkedConvert('reversed', (v) => v as bool),
        interpretation: $checkedConvert('interpretation', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReadingCardWireDtoToJson(ReadingCardWireDto instance) =>
    <String, dynamic>{
      'positionId': instance.positionId,
      'cardId': instance.cardId,
      'reversed': instance.reversed,
      'interpretation': instance.interpretation,
    };

ReadingWireDto _$ReadingWireDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingWireDto', json, ($checkedConvert) {
      final val = ReadingWireDto(
        title: $checkedConvert('title', (v) => v as String),
        overview: $checkedConvert('overview', (v) => v as String),
        cards: $checkedConvert(
          'cards',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ReadingCardWireDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        synthesis: $checkedConvert('synthesis', (v) => v as String),
        reflectionPrompts: $checkedConvert(
          'reflectionPrompts',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReadingWireDtoToJson(ReadingWireDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'overview': instance.overview,
      'cards': instance.cards.map((e) => e.toJson()).toList(),
      'synthesis': instance.synthesis,
      'reflectionPrompts': instance.reflectionPrompts,
    };

CrisisResourceDto _$CrisisResourceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CrisisResourceDto', json, ($checkedConvert) {
      final val = CrisisResourceDto(
        name: $checkedConvert('name', (v) => v as String),
        verifiedAt: $checkedConvert(
          'verifiedAt',
          (v) => const UtcInstantConverter().fromJson(v as String),
        ),
        languages: $checkedConvert(
          'languages',
          (v) =>
              (v as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
        ),
        phone: $checkedConvert('phone', (v) => v as String?),
        sms: $checkedConvert('sms', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
        hours: $checkedConvert('hours', (v) => v as String?),
      );
      return val;
    });

SafetyDto _$SafetyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SafetyDto', json, ($checkedConvert) {
      final val = SafetyDto(
        category: $checkedConvert('category', (v) => v as String),
        canRephrase: $checkedConvert('canRephrase', (v) => v as bool),
        messageKey: $checkedConvert('messageKey', (v) => v as String?),
        crisisResources: $checkedConvert(
          'crisisResources',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) =>
                        CrisisResourceDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              const [],
        ),
      );
      return val;
    });

ReadingResponseDto _$ReadingResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingResponseDto', json, ($checkedConvert) {
      final val = ReadingResponseDto(
        status: $checkedConvert('status', (v) => v as String),
        balance: $checkedConvert(
          'balance',
          (v) => BalanceDto.fromJson(v as Map<String, dynamic>),
        ),
        readingId: $checkedConvert('readingId', (v) => v as String?),
        chargeSource: $checkedConvert('chargeSource', (v) => v as String?),
        promptVersion: $checkedConvert('promptVersion', (v) => v as String?),
        reading: $checkedConvert(
          'reading',
          (v) => v == null
              ? null
              : ReadingWireDto.fromJson(v as Map<String, dynamic>),
        ),
        safety: $checkedConvert(
          'safety',
          (v) =>
              v == null ? null : SafetyDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

ReadingStateDto _$ReadingStateDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingStateDto', json, ($checkedConvert) {
      final val = ReadingStateDto(
        status: $checkedConvert('status', (v) => v as String),
        balance: $checkedConvert(
          'balance',
          (v) => BalanceDto.fromJson(v as Map<String, dynamic>),
        ),
        attempt: $checkedConvert('attempt', (v) => (v as num?)?.toInt() ?? 1),
        chargeSource: $checkedConvert('chargeSource', (v) => v as String?),
        promptVersion: $checkedConvert('promptVersion', (v) => v as String?),
        reading: $checkedConvert(
          'reading',
          (v) => v == null
              ? null
              : ReadingWireDto.fromJson(v as Map<String, dynamic>),
        ),
        safety: $checkedConvert(
          'safety',
          (v) =>
              v == null ? null : SafetyDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReportRequestDtoToJson(ReportRequestDto instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'note': ?instance.note,
      'question': ?instance.question,
      'reading': ?instance.reading?.toJson(),
      'locale': instance.locale,
    };

ReportResponseDto _$ReportResponseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReportResponseDto', json, ($checkedConvert) {
      final val = ReportResponseDto(
        reportId: $checkedConvert('reportId', (v) => v as String),
        status: $checkedConvert('status', (v) => v as String),
      );
      return val;
    });
