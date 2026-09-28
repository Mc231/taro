// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this, avoid_positional_boolean_parameters

import 'package:taro_core/taro_core.dart';

import 'defaults.dart';
import 'spread_builder.dart';

/// A fixed draw for [spreadId]: distinct cards, the second one reversed.
Draw aDraw({String spreadId = 'three_ppf', DateTime? drawnAt}) {
  final spread = aSpread(spreadId).build();
  return Draw(
    spreadId: spread.id,
    spreadVersion: spread.version,
    cards: [
      for (var i = 0; i < spread.positions.length; i++)
        DrawnCard(
          positionId: spread.positions[i].id,
          cardId: kCardIds[(i * 11) % kCardIds.length],
          reversed: i == 1,
        ),
    ],
    drawnAt: drawnAt ?? kTestNow,
  );
}

/// Reading content with one text per position of [draw].
ReadingContent aReadingContent({Draw? draw, String title = 'A turning point'}) {
  final d = draw ?? aDraw();
  return ReadingContent(
    title: title,
    summary: 'An overview of the spread.',
    positions: [
      for (final c in d.cards)
        PositionText(
          positionId: c.positionId,
          text: 'About ${c.cardId.value} in ${c.positionId.value}.',
        ),
    ],
    synthesis: 'How the cards fit together.',
    reflectionPrompts: const ['What is changing?', 'What stays?'],
  );
}

/// `aReading().withSpread('three_ppf').build()`: a delivered AI reading by
/// default.
ReadingBuilder aReading() => ReadingBuilder();

/// Builds a [Reading].
final class ReadingBuilder {
  ReadingId _id = kTestReadingId;
  DateTime _createdAt = kTestNow;
  DateTime? _updatedAt;
  String _localDate = kTestLocalDate;
  Draw? _draw;
  String _spreadId = 'three_ppf';
  ReadingStatus _status = const ReadingStatus.complete();
  String _locale = kTestLocale;
  String? _question = kTestQuestion;
  ReadingContent? _content;
  bool _contentSet = false;
  String? _promptVersion = 'v1';
  String? _modelId;
  ChargeSource? _chargeSource = ChargeSource.free;
  String? _note;
  bool _favourite = false;
  Rating? _rating;
  RatingReason? _ratingReason;
  bool _deliveryAcked = true;
  bool _reported = false;

  /// With reading ID [id].
  ReadingBuilder withId(String id) {
    _id = ReadingId(id);
    return this;
  }

  /// Created (and last updated) at [at], on local date [localDate].
  ReadingBuilder createdAt(DateTime at, {String? localDate}) {
    _createdAt = at;
    if (localDate != null) _localDate = localDate;
    return this;
  }

  /// Last updated at [at].
  ReadingBuilder updatedAt(DateTime at) {
    _updatedAt = at;
    return this;
  }

  /// On local date [localDate].
  ReadingBuilder onLocalDate(String localDate) {
    _localDate = localDate;
    return this;
  }

  /// A fixed draw of [spreadId].
  ReadingBuilder withSpread(String spreadId) {
    _spreadId = spreadId;
    _draw = null;
    return this;
  }

  /// With exactly [draw].
  ReadingBuilder withDraw(Draw draw) {
    _draw = draw;
    _spreadId = draw.spreadId.value;
    return this;
  }

  /// With status [status].
  ReadingBuilder withStatus(ReadingStatus status) {
    _status = status;
    return this;
  }

  /// Persisted and not yet delivered: no content, not acknowledged.
  ReadingBuilder pending() {
    _status = const ReadingStatus.pending();
    _deliveryAcked = false;
    return withContent(null);
  }

  /// Declined by the safety layer.
  ReadingBuilder refused({SafetyInfo? safety}) {
    _status = ReadingStatus.refused(safety: safety);
    return withContent(null);
  }

  /// Generation failed with [failure].
  ReadingBuilder failed(Failure failure, {bool refunded = false}) {
    _status = ReadingStatus.failed(failure, refunded: refunded);
    _deliveryAcked = false;
    return withContent(null);
  }

  /// A Classic reading (no AI, no Worker, RC20).
  ReadingBuilder classic() {
    _status = const ReadingStatus.classic();
    _promptVersion = null;
    _chargeSource = null;
    return withContent(null);
  }

  /// With content [content] (`null` for none).
  ReadingBuilder withContent(ReadingContent? content) {
    _content = content;
    _contentSet = true;
    return this;
  }

  /// With content locale [locale].
  ReadingBuilder withLocale(String locale) {
    _locale = locale;
    return this;
  }

  /// With question [question].
  ReadingBuilder withQuestion(String? question) {
    _question = question;
    return this;
  }

  /// With note [note].
  ReadingBuilder withNote(String? note) {
    _note = note;
    return this;
  }

  /// Marked favourite.
  ReadingBuilder favourite([bool favourite = true]) {
    _favourite = favourite;
    return this;
  }

  /// Rated [rating] with an optional [reason].
  ReadingBuilder withRating(Rating? rating, [RatingReason? reason]) {
    _rating = rating;
    _ratingReason = reason;
    return this;
  }

  /// Paid from [source].
  ReadingBuilder withChargeSource(ChargeSource? source) {
    _chargeSource = source;
    return this;
  }

  /// With model ID [modelId].
  ReadingBuilder withModelId(String? modelId) {
    _modelId = modelId;
    return this;
  }

  /// With delivery acknowledged or not.
  ReadingBuilder acked({bool acked = true}) {
    _deliveryAcked = acked;
    return this;
  }

  /// Already reported.
  ReadingBuilder reported([bool reported = true]) {
    _reported = reported;
    return this;
  }

  /// The reading.
  Reading build() {
    final draw = _draw ?? aDraw(spreadId: _spreadId, drawnAt: _createdAt);
    return Reading(
      id: _id,
      createdAt: _createdAt,
      updatedAt: _updatedAt ?? _createdAt,
      localDate: _localDate,
      draw: draw,
      status: _status,
      contentLocale: _locale,
      question: _question,
      content: _contentSet ? _content : aReadingContent(draw: draw),
      promptVersion: _promptVersion,
      modelId: _modelId,
      chargeSource: _chargeSource,
      note: _note,
      favourite: _favourite,
      rating: _rating,
      ratingReason: _ratingReason,
      deliveryAcked: _deliveryAcked,
      reported: _reported,
    );
  }
}

/// `aDailyCard().on('2026-09-25').build()`.
DailyCardBuilder aDailyCard() => DailyCardBuilder();

/// Builds a [DailyCard].
final class DailyCardBuilder {
  String _localDate = kTestLocalDate;
  CardId _cardId = const CardId('major_17');
  bool _reversed = false;
  DateTime _drawnAt = kTestNow;
  DateTime? _updatedAt;
  String? _note;
  bool _favourite = false;

  /// For local date [localDate].
  DailyCardBuilder on(String localDate) {
    _localDate = localDate;
    return this;
  }

  /// Card [id].
  DailyCardBuilder withCard(String id) {
    _cardId = CardId.parse(id);
    return this;
  }

  /// Reversed.
  DailyCardBuilder reversed([bool reversed = true]) {
    _reversed = reversed;
    return this;
  }

  /// Drawn (and created) at [at].
  DailyCardBuilder drawnAt(DateTime at) {
    _drawnAt = at;
    return this;
  }

  /// Last updated at [at].
  DailyCardBuilder updatedAt(DateTime at) {
    _updatedAt = at;
    return this;
  }

  /// With note [note].
  DailyCardBuilder withNote(String? note) {
    _note = note;
    return this;
  }

  /// Marked favourite.
  DailyCardBuilder favourite([bool favourite = true]) {
    _favourite = favourite;
    return this;
  }

  /// The daily card.
  DailyCard build() => DailyCard(
    localDate: _localDate,
    cardId: _cardId,
    reversed: _reversed,
    drawnAt: _drawnAt,
    createdAt: _drawnAt,
    updatedAt: _updatedAt ?? _drawnAt,
    note: _note,
    favourite: _favourite,
  );
}
