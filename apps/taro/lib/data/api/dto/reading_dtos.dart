import 'package:json_annotation/json_annotation.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro_core/taro_core.dart';

part 'reading_dtos.g.dart';

/// `spread{id, version}` of holds and readings (03 §9.0, §9.1).
@JsonSerializable(createFactory: false)
final class SpreadRefDto {
  /// Creates the DTO.
  const SpreadRefDto({required this.id, required this.version});

  /// The spread ID.
  final String id;

  /// The spread content version.
  final int version;

  /// The wire JSON.
  JsonObject toJson() => _$SpreadRefDtoToJson(this);
}

/// `POST /v1/readings/holds` body (03 §9.0, RC50).
@JsonSerializable(createFactory: false, explicitToJson: true)
final class HoldRequestDto {
  /// Creates the DTO.
  const HoldRequestDto({
    required this.clientReadingId,
    required this.spread,
    required this.locale,
  });

  /// The body for a hold on [readingId] for [spread] in [locale].
  factory HoldRequestDto.fromDomain(
    ReadingId readingId,
    SpreadDefinition spread, {
    required String locale,
  }) => HoldRequestDto(
    clientReadingId: readingId.value,
    spread: SpreadRefDto(id: spread.id.value, version: spread.version),
    locale: locale,
  );

  /// = `Idempotency-Key` (RC42).
  final String clientReadingId;

  /// The spread.
  final SpreadRefDto spread;

  /// The reading locale.
  final String locale;

  /// The wire JSON.
  JsonObject toJson() => _$HoldRequestDtoToJson(this);
}

ChargeSource _chargeSource(String wire) =>
    wireEnum(ChargeSource.values.asNameMap(), wire, 'chargeSource');

/// `POST /v1/readings/holds` 201 response (03 §9.0); maps to
/// [ReadingHold].
@JsonSerializable(createToJson: false, checked: true)
final class HoldDto {
  /// Creates the DTO.
  const HoldDto({
    required this.clientReadingId,
    required this.chargeSource,
    required this.expiresAt,
    required this.balance,
  });

  /// Decodes the wire JSON.
  factory HoldDto.fromJson(JsonObject json) => _$HoldDtoFromJson(json);

  /// The reading the hold is for.
  final String clientReadingId;

  /// `free | bonus | paid`.
  final String chargeSource;

  /// When the hold lapses (server time).
  @UtcInstantConverter()
  final DateTime expiresAt;

  /// The balance after the hold.
  final BalanceDto balance;

  /// The domain hold, received at device time [syncedAt].
  ReadingHold toDomain({required DateTime syncedAt}) => ReadingHold(
    readingId: ReadingId(clientReadingId),
    chargeSource: _chargeSource(chargeSource),
    expiresAt: expiresAt,
    balance: balance.toDomain(syncedAt: syncedAt),
  );
}

/// One drawn card of the `POST /v1/readings` body.
@JsonSerializable(createFactory: false)
final class DrawnCardDto {
  /// Creates the DTO.
  const DrawnCardDto({
    required this.positionId,
    required this.cardId,
    required this.reversed,
  });

  /// The wire form of [card].
  factory DrawnCardDto.fromDomain(DrawnCard card) => DrawnCardDto(
    positionId: card.positionId.value,
    cardId: card.cardId.value,
    reversed: card.reversed,
  );

  /// The position.
  final String positionId;

  /// The RC1 card ID.
  final String cardId;

  /// Reversed?
  final bool reversed;

  /// The wire JSON.
  JsonObject toJson() => _$DrawnCardDtoToJson(this);
}

/// `POST /v1/readings` body (03 §9.1). The question is user text: never
/// logged.
@JsonSerializable(
  createFactory: false,
  explicitToJson: true,
  includeIfNull: false,
)
final class CreateReadingRequestDto {
  /// Creates the DTO.
  const CreateReadingRequestDto({
    required this.clientReadingId,
    required this.spread,
    required this.cards,
    required this.locale,
    required this.drawnAt,
    this.question,
  });

  /// The body of the persisted [pending] reading (same `clientReadingId`
  /// and cards on every retry, RC49).
  factory CreateReadingRequestDto.fromDomain(Reading pending) =>
      CreateReadingRequestDto(
        clientReadingId: pending.id.value,
        spread: SpreadRefDto(
          id: pending.draw.spreadId.value,
          version: pending.draw.spreadVersion,
        ),
        cards: [for (final c in pending.cards) DrawnCardDto.fromDomain(c)],
        question: pending.question,
        locale: pending.contentLocale,
        drawnAt: pending.draw.drawnAt,
      );

  /// = `Idempotency-Key` (RC42).
  final String clientReadingId;

  /// The spread.
  final SpreadRefDto spread;

  /// One card per position.
  final List<DrawnCardDto> cards;

  /// The user's question.
  final String? question;

  /// The reading locale.
  final String locale;

  /// When the cards were drawn.
  @UtcInstantConverter()
  final DateTime drawnAt;

  /// The wire JSON.
  JsonObject toJson() => _$CreateReadingRequestDtoToJson(this);

  @override
  String toString() => 'CreateReadingRequestDto($clientReadingId)';
}

/// One `reading.cards[]` entry (03 §9.1).
@JsonSerializable(checked: true)
final class ReadingCardWireDto {
  /// Creates the DTO.
  const ReadingCardWireDto({
    required this.positionId,
    required this.cardId,
    required this.reversed,
    required this.interpretation,
  });

  /// Decodes the wire JSON.
  factory ReadingCardWireDto.fromJson(JsonObject json) =>
      _$ReadingCardWireDtoFromJson(json);

  /// The position.
  final String positionId;

  /// The card.
  final String cardId;

  /// Reversed?
  final bool reversed;

  /// The interpretation (domain `PositionText.text`).
  final String interpretation;

  /// The wire JSON.
  JsonObject toJson() => _$ReadingCardWireDtoToJson(this);
}

/// The canonical wire reading (RC30):
/// `{title, overview, cards[], synthesis, reflectionPrompts}`.
@JsonSerializable(checked: true, explicitToJson: true)
final class ReadingWireDto {
  /// Creates the DTO.
  const ReadingWireDto({
    required this.title,
    required this.overview,
    required this.cards,
    required this.synthesis,
    required this.reflectionPrompts,
  });

  /// Decodes the wire JSON.
  factory ReadingWireDto.fromJson(JsonObject json) =>
      _$ReadingWireDtoFromJson(json);

  /// The wire object of stored [content] with the [cards] it interprets
  /// (the report body, 03 §9.7). Throws an [ArgumentError] when a position
  /// of [content] has no card in [cards].
  factory ReadingWireDto.fromDomain(
    ReadingContent content,
    List<DrawnCard> cards,
  ) {
    final byPosition = {for (final c in cards) c.positionId: c};
    return ReadingWireDto(
      title: content.title,
      overview: content.summary,
      cards: [
        for (final p in content.positions) _card(p, byPosition[p.positionId]),
      ],
      synthesis: content.synthesis,
      reflectionPrompts: content.reflectionPrompts,
    );
  }

  static ReadingCardWireDto _card(PositionText text, DrawnCard? card) {
    if (card == null) {
      throw ArgumentError.value(
        text.positionId.value,
        'cards',
        'no card for position',
      );
    }
    return ReadingCardWireDto(
      positionId: text.positionId.value,
      cardId: card.cardId.value,
      reversed: card.reversed,
      interpretation: text.text,
    );
  }

  /// Title.
  final String title;

  /// Overview (domain `summary`).
  final String overview;

  /// Interpretations per position.
  final List<ReadingCardWireDto> cards;

  /// Synthesis.
  final String synthesis;

  /// Reflection prompts.
  final List<String> reflectionPrompts;

  /// The wire JSON.
  JsonObject toJson() => _$ReadingWireDtoToJson(this);

  /// The domain content (RC30: `overview` → `summary`, `interpretation` →
  /// `text`).
  ReadingContent toDomain() => ReadingContent(
    title: title,
    summary: overview,
    positions: [
      for (final c in cards)
        PositionText(
          positionId: PositionId(c.positionId),
          text: c.interpretation,
        ),
    ],
    synthesis: synthesis,
    reflectionPrompts: reflectionPrompts,
  );
}

/// A crisis helpline in a declined response (RC81 canonical schema).
@JsonSerializable(createToJson: false, checked: true)
final class CrisisResourceDto {
  /// Creates the DTO.
  const CrisisResourceDto({
    required this.name,
    required this.verifiedAt,
    this.languages = const [],
    this.phone,
    this.sms,
    this.url,
    this.hours,
  });

  /// Decodes the wire JSON.
  factory CrisisResourceDto.fromJson(JsonObject json) =>
      _$CrisisResourceDtoFromJson(json);

  /// Display name.
  final String name;

  /// Phone number.
  final String? phone;

  /// SMS number.
  final String? sms;

  /// Web or chat URL.
  final String? url;

  /// Opening hours.
  final String? hours;

  /// Languages served.
  final List<String> languages;

  /// Last human verification.
  @UtcInstantConverter()
  final DateTime verifiedAt;

  /// The domain resource; throws a [FormatException] without a contact
  /// channel.
  CrisisResource toDomain() {
    final resource = CrisisResource(
      name: name,
      verifiedAt: verifiedAt,
      languages: languages,
      phone: phone,
      sms: sms,
      url: url,
      hours: hours,
    );
    if (!resource.hasContact) {
      throw FormatException('"$name" has no phone, sms or url');
    }
    return resource;
  }
}

/// The `safety` object of a declined reading (03 §9.1, RC27).
@JsonSerializable(createToJson: false, checked: true)
final class SafetyDto {
  /// Creates the DTO.
  const SafetyDto({
    required this.category,
    required this.canRephrase,
    this.messageKey,
    this.crisisResources = const [],
  });

  /// Decodes the wire JSON.
  factory SafetyDto.fromJson(JsonObject json) => _$SafetyDtoFromJson(json);

  /// The snake_case category; unknown values map to `other`.
  final String category;

  /// The ARB key of the message.
  final String? messageKey;

  /// Whether the user may rephrase.
  final bool canRephrase;

  /// Helplines (crisis categories).
  final List<CrisisResourceDto> crisisResources;

  /// The domain value.
  SafetyInfo toDomain() {
    final refusal = RefusalCategory.fromWire(category);
    return SafetyInfo(
      category: refusal,
      messageKey: messageKey ?? refusal.messageKey,
      canRephrase: canRephrase,
      crisisResources: [for (final r in crisisResources) r.toDomain()],
    );
  }
}

/// `POST /v1/readings` 200 response (03 §9.1, RC30); `status` is
/// `completed` or `declined`.
@JsonSerializable(createToJson: false, checked: true)
final class ReadingResponseDto {
  /// Creates the DTO.
  const ReadingResponseDto({
    required this.status,
    required this.balance,
    this.readingId,
    this.chargeSource,
    this.promptVersion,
    this.reading,
    this.safety,
  });

  /// Decodes the wire JSON.
  factory ReadingResponseDto.fromJson(JsonObject json) =>
      _$ReadingResponseDtoFromJson(json);

  /// The Worker reading row ID.
  final String? readingId;

  /// `completed | declined`.
  final String status;

  /// `free | bonus | paid`, or `none` for a declined reading.
  final String? chargeSource;

  /// The Worker prompt version (opaque; provider-neutral, RC97).
  final String? promptVersion;

  /// The reading (completed).
  final ReadingWireDto? reading;

  /// Why it was declined.
  final SafetyDto? safety;

  /// The balance after the call.
  final BalanceDto balance;
}

/// `GET /v1/readings/{clientReadingId}` response (03 §9.1): `status` is a
/// `readings.status` value (GLOSSARY §6).
@JsonSerializable(createToJson: false, checked: true)
final class ReadingStateDto {
  /// Creates the DTO.
  const ReadingStateDto({
    required this.status,
    required this.balance,
    this.attempt = 1,
    this.chargeSource,
    this.promptVersion,
    this.reading,
    this.safety,
  });

  /// Decodes the wire JSON.
  factory ReadingStateDto.fromJson(JsonObject json) =>
      _$ReadingStateDtoFromJson(json);

  /// `held | generating | completed | declined | failed | no_credit |
  /// expired_hold | expired_refunded`.
  final String status;

  /// `readings.attempt`.
  final int attempt;

  /// Charge source, when the Worker sends it.
  final String? chargeSource;

  /// Prompt version, when the Worker sends it.
  final String? promptVersion;

  /// The reading while a completed body exists.
  final ReadingWireDto? reading;

  /// The safety object of a declined reading.
  final SafetyDto? safety;

  /// The balance.
  final BalanceDto balance;
}

/// `POST /v1/readings/{clientReadingId}/report` body (03 §9.7).
@JsonSerializable(
  createFactory: false,
  explicitToJson: true,
  includeIfNull: false,
)
final class ReportRequestDto {
  /// Creates the DTO.
  const ReportRequestDto({
    required this.reason,
    required this.locale,
    this.note,
    this.question,
    this.reading,
  });

  /// The body of [report]; [cards] are the reading's drawn cards (the wire
  /// reading carries `cardId` and `reversed`).
  factory ReportRequestDto.fromDomain(
    ReadingReport report, {
    List<DrawnCard> cards = const [],
  }) => ReportRequestDto(
    reason: report.reason.wire,
    locale: report.locale,
    note: report.note,
    question: report.question,
    reading: report.reading == null
        ? null
        : ReadingWireDto.fromDomain(report.reading!, cards),
  );

  /// `offensive | harmful_advice | sexual | hateful | other`.
  final String reason;

  /// Optional note (≤ 500 characters).
  final String? note;

  /// The question as asked.
  final String? question;

  /// The stored reading.
  final ReadingWireDto? reading;

  /// The reading locale.
  final String locale;

  /// The wire JSON.
  JsonObject toJson() => _$ReportRequestDtoToJson(this);

  @override
  String toString() => 'ReportRequestDto($reason)';
}

/// `POST /v1/readings/{clientReadingId}/report` 201 response.
@JsonSerializable(createToJson: false, checked: true)
final class ReportResponseDto {
  /// Creates the DTO.
  const ReportResponseDto({required this.reportId, required this.status});

  /// Decodes the wire JSON.
  factory ReportResponseDto.fromJson(JsonObject json) =>
      _$ReportResponseDtoFromJson(json);

  /// The report ID.
  final String reportId;

  /// `received`.
  final String status;
}
