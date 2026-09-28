import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/crisis_resource.dart';
import 'package:taro_core/src/model/draw.dart';
import 'package:taro_core/src/model/drawn_card.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/model/reading_content.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/refusal_category.dart';

part 'reading.freezed.dart';

/// Thumbs rating of a reading (01 §10.4).
enum Rating {
  /// Thumbs up.
  up,

  /// Thumbs down.
  down,
}

/// Why a reading was rated down (backup `ratingReason`).
enum RatingReason {
  /// Wire `too_generic`.
  tooGeneric('too_generic'),

  /// Wire `mismatch`.
  mismatch('mismatch'),

  /// Wire `tone`.
  tone('tone'),

  /// Wire `other`.
  other('other');

  const RatingReason(this.wire);

  /// The snake_case value in backups.
  final String wire;

  /// Parses a wire value; `null` for unknown values.
  static RatingReason? fromWire(String wire) {
    for (final r in values) {
      if (r.wire == wire) return r;
    }
    return null;
  }
}

/// Why a reading was declined (02 §3): the wire `safety` object of a
/// `status: declined` response (03 §9.1).
@Freezed(fromJson: false, toJson: false)
abstract class SafetyInfo with _$SafetyInfo {
  /// Creates safety info.
  const factory SafetyInfo({
    /// The refusal category.
    required RefusalCategory category,

    /// ARB key of the message.
    required String messageKey,

    /// Whether the user may rephrase and try again.
    required bool canRephrase,

    /// Helplines to show (S27) for crisis categories.
    @Default(<CrisisResource>[]) List<CrisisResource> crisisResources,
  }) = _SafetyInfo;

  const SafetyInfo._();

  /// Parses the wire `safety` object; throws a [FormatException]. An
  /// unknown category maps to [RefusalCategory.other].
  factory SafetyInfo.fromJson(Map<String, Object?> json) {
    final category = RefusalCategory.fromWire(req<String>(json, 'category'));
    return SafetyInfo(
      category: category,
      messageKey: opt<String>(json, 'messageKey') ?? category.messageKey,
      canRephrase: req<bool>(json, 'canRephrase'),
      crisisResources: json['crisisResources'] == null
          ? const []
          : reqMaps(
              json,
              'crisisResources',
            ).map(CrisisResource.fromJson).toList(growable: false),
    );
  }

  /// The wire JSON (for the local `safety_json` column).
  Map<String, Object?> toJson() => {
    'category': category.wire,
    'messageKey': messageKey,
    'canRephrase': canRephrase,
    'crisisResources': [for (final r in crisisResources) r.toJson()],
  };
}

/// The local status of a reading (02 §4, 01 §10.4).
///
/// `pending` covers the Worker's `held` and `generating`; the wire
/// `completed` maps to [ReadingStatusComplete] and `declined` to
/// [ReadingStatusRefused]; `classic` means no Worker call (RC20).
@freezed
sealed class ReadingStatus with _$ReadingStatus {
  /// Persisted, not yet delivered.
  const factory ReadingStatus.pending() = ReadingStatusPending;

  /// Delivered and stored.
  const factory ReadingStatus.complete() = ReadingStatusComplete;

  /// Declined by the safety layer. [safety] is `null` for a reading
  /// imported from a backup, which does not carry it.
  const factory ReadingStatus.refused({SafetyInfo? safety}) =
      ReadingStatusRefused;

  /// Generation failed; [refunded] when the Worker refunded the hold.
  const factory ReadingStatus.failed(
    Failure failure, {
    @Default(false) bool refunded,
  }) = ReadingStatusFailed;

  /// A Classic reading: cards and static meanings, no AI (RC20).
  const factory ReadingStatus.classic() = ReadingStatusClassic;

  const ReadingStatus._();

  /// The stored / backup status name
  /// (`pending|complete|failed|refused|classic`).
  String get wire => switch (this) {
    ReadingStatusPending() => 'pending',
    ReadingStatusComplete() => 'complete',
    ReadingStatusRefused() => 'refused',
    ReadingStatusFailed() => 'failed',
    ReadingStatusClassic() => 'classic',
  };

  /// Whether a reading with this status is exported (01 §7.11): only
  /// `complete`, `refused` and `classic`.
  bool get isExportable => switch (this) {
    ReadingStatusComplete() ||
    ReadingStatusRefused() ||
    ReadingStatusClassic() => true,
    ReadingStatusPending() || ReadingStatusFailed() => false,
  };
}

/// A reading in the journal (01 §10.4, 02 §4). Persisted locally before the
/// network call.
@freezed
abstract class Reading with _$Reading {
  /// Creates a reading.
  const factory Reading({
    /// UUIDv4 = `clientReadingId` = `Idempotency-Key` (RC42).
    required ReadingId id,

    /// Creation time (UTC).
    required DateTime createdAt,

    /// Last change (UTC); the newer one wins a backup merge.
    required DateTime updatedAt,

    /// Local calendar date `YYYY-MM-DD` of creation.
    required String localDate,

    /// The drawn cards.
    required Draw draw,

    /// Local status.
    required ReadingStatus status,

    /// Locale the content was generated in.
    required String contentLocale,

    /// The user's question.
    String? question,

    /// The AI text; `null` until delivered and for Classic readings.
    ReadingContent? content,

    /// Worker prompt version; `null` for Classic readings.
    String? promptVersion,

    /// Model ID (device-local, never exported).
    String? modelId,

    /// Which bucket paid (device-local, never exported).
    ChargeSource? chargeSource,

    /// The user's note.
    String? note,

    /// Favourite flag.
    @Default(false) bool favourite,

    /// Thumbs rating.
    Rating? rating,

    /// Reason for a thumbs-down.
    RatingReason? ratingReason,

    /// Whether the delivery ack reached the Worker (device-local).
    @Default(false) bool deliveryAcked,

    /// Whether the user reported this reading.
    @Default(false) bool reported,
  }) = _Reading;

  const Reading._();

  /// Parses a backup `reading` (throws a [FormatException]).
  ///
  /// The backup has no spread version or draw time: the draw gets
  /// [spreadVersion] (default 1) and `drawnAt = createdAt`. Device-local
  /// fields get their "already delivered" values.
  factory Reading.fromBackupJson(
    Map<String, Object?> json, {
    int spreadVersion = 1,
  }) {
    final createdAt = reqInstant(json, 'createdAt');
    final statusWire = req<String>(json, 'status');
    final status = switch (statusWire) {
      'complete' => const ReadingStatus.complete(),
      'refused' => const ReadingStatus.refused(),
      'classic' => const ReadingStatus.classic(),
      _ => throw FormatException('"status" is not exportable', statusWire),
    };
    final content = optMap(json, 'content');
    final ratingWire = opt<String>(json, 'rating');
    final reasonWire = opt<String>(json, 'ratingReason');
    return Reading(
      id: ReadingId(req<String>(json, 'id')),
      createdAt: createdAt,
      updatedAt: reqInstant(json, 'updatedAt'),
      localDate: reqLocalDate(json, 'localDate'),
      draw: Draw(
        spreadId: SpreadId(req<String>(json, 'spreadId')),
        spreadVersion: spreadVersion,
        cards: reqMaps(
          json,
          'cards',
        ).map(DrawnCard.fromJson).toList(growable: false),
        drawnAt: createdAt,
      ),
      status: status,
      contentLocale: req<String>(json, 'contentLocale'),
      question: opt<String>(json, 'question'),
      content: content == null ? null : ReadingContent.fromJson(content),
      promptVersion: opt<String>(json, 'promptVersion'),
      note: opt<String>(json, 'note'),
      favourite: req<bool>(json, 'favourite'),
      rating: ratingWire == null
          ? null
          : Rating.values.asNameMap()[ratingWire] ??
                (throw FormatException('"rating" is unknown', ratingWire)),
      ratingReason: reasonWire == null
          ? null
          : RatingReason.fromWire(reasonWire) ??
                (throw FormatException(
                  '"ratingReason" is unknown',
                  reasonWire,
                )),
      deliveryAcked: true,
    );
  }

  /// The spread of the draw.
  SpreadId get spreadId => draw.spreadId;

  /// The drawn cards.
  List<DrawnCard> get cards => draw.cards;

  /// Whether this reading goes into a backup (01 §7.11).
  bool get isExportable => status.isExportable;

  /// The backup JSON of this reading (`backup_schema_v1.json` `reading`).
  ///
  /// Throws a [StateError] for a pending or failed reading, which is never
  /// exported.
  Map<String, Object?> toBackupJson() {
    if (!isExportable) {
      throw StateError('A ${status.wire} reading is not exportable');
    }
    return {
      'id': id.value,
      'createdAt': formatInstant(createdAt),
      'updatedAt': formatInstant(updatedAt),
      'localDate': localDate,
      'spreadId': spreadId.value,
      'question': question,
      'cards': [for (final c in cards) c.toJson()],
      'status': status.wire,
      'content': content?.toJson(),
      'contentLocale': contentLocale,
      'promptVersion': promptVersion,
      'note': note,
      'favourite': favourite,
      'rating': rating?.name,
      'ratingReason': ratingReason?.wire,
    };
  }
}
