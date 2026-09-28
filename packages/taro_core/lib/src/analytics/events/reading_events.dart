part of '../taro_analytics_event.dart';

/// Reading events (01 §15 `ReadingEvent`).
sealed class ReadingEvent extends TaroAnalyticsEvent {
  const ReadingEvent._() : super._();
}

/// `reading_flow_started`: a reading flow was entered.
final class ReadingFlowStartedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingFlowStartedEvent({required this.source, required this.spread})
    : super._();

  /// Where the flow started.
  final ReadingFlowSource source;

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'reading_flow_started';

  @override
  Map<String, Object> get parameters => {
    'source': source.wire,
    'spread_id': spread.wire,
  };
}

/// `reading_gate_blocked`: `ReadingGate` did not allow a reading.
final class ReadingGateBlockedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingGateBlockedEvent({required this.reason, required this.spread})
    : super._();

  /// Why the gate blocked.
  final GateBlockReason reason;

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'reading_gate_blocked';

  @override
  Map<String, Object> get parameters => {
    'reason': reason.wire,
    'spread_id': spread.wire,
  };
}

/// `reading_hold_result`: `POST /v1/readings/holds` answered.
final class ReadingHoldResultEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingHoldResultEvent({required this.result, required this.spread})
    : super._();

  /// The hold outcome.
  final HoldResult result;

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'reading_hold_result';

  @override
  Map<String, Object> get parameters => {
    'result': result.wire,
    'spread_id': spread.wire,
  };
}

/// `question_submitted`: Begin was tapped on S07. Never the question text.
final class QuestionSubmittedEvent extends ReadingEvent {
  /// Creates the event.
  const QuestionSubmittedEvent({
    required this.spread,
    required this.hasQuestion,
    required this.questionLenBucket,
    required this.usedSuggestion,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Whether a question was typed.
  final bool hasQuestion;

  /// The question length bucket.
  final QuestionLengthBucket questionLenBucket;

  /// Whether a suggestion chip was used.
  final bool usedSuggestion;

  @override
  String get eventName => 'question_submitted';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'has_question': hasQuestion,
    'question_len_bucket': questionLenBucket.wire,
    'used_suggestion': usedSuggestion,
  };
}

/// `draw_completed`: every card of the spread was drawn.
final class DrawCompletedEvent extends ReadingEvent {
  /// Creates the event.
  const DrawCompletedEvent({
    required this.spread,
    required this.autoDraw,
    required this.reversedCount,
    required this.majorCount,
    required this.durationMs,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Whether "draw for me" was used.
  final bool autoDraw;

  /// Reversed cards drawn.
  final int reversedCount;

  /// Major arcana drawn.
  final int majorCount;

  /// Ritual duration.
  final int durationMs;

  @override
  String get eventName => 'draw_completed';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'auto_draw': autoDraw,
    'reversed_count': reversedCount,
    'major_count': majorCount,
    'duration_ms': durationMs,
  };
}

/// `reading_generated`: an AI reading was delivered.
final class ReadingGeneratedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingGeneratedEvent({
    required this.spread,
    required this.latencyMs,
    required this.promptVersion,
    required this.creditType,
    required this.locale,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Request-to-delivery latency.
  final int latencyMs;

  /// The `N` of prompt version `vN` (`ai.promptVersion`, BE11).
  final int promptVersion;

  /// The bucket the reading was paid from.
  final CreditType creditType;

  /// The reading language.
  final AnalyticsLocale locale;

  @override
  String get eventName => 'reading_generated';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'latency_ms': latencyMs,
    'prompt_version': promptVersion,
    'credit_type': creditType.wire,
    'locale': locale.wire,
  };
}

/// `reading_failed`: an AI reading failed.
final class ReadingFailedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingFailedEvent({
    required this.spread,
    required this.error,
    required this.refunded,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// What failed.
  final ReadingFailureKind error;

  /// Whether the credit was refunded.
  final bool refunded;

  @override
  String get eventName => 'reading_failed';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'error': error.wire,
    'refunded': refunded,
  };
}

/// `classic_reading_started`: a Classic (non-AI) reading began (RC20).
final class ClassicReadingStartedEvent extends ReadingEvent {
  /// Creates the event.
  const ClassicReadingStartedEvent({
    required this.spread,
    required this.reason,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Why Classic was offered.
  final ClassicReadingReason reason;

  @override
  String get eventName => 'classic_reading_started';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'reason': reason.wire,
  };
}

/// `classic_reading_completed`: a Classic reading result was shown (S32).
final class ClassicReadingCompletedEvent extends ReadingEvent {
  /// Creates the event.
  const ClassicReadingCompletedEvent({
    required this.spread,
    required this.reason,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Why Classic was offered.
  final ClassicReadingReason reason;

  @override
  String get eventName => 'classic_reading_completed';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'reason': reason.wire,
  };
}

/// `reading_reported`: a report was submitted from S33 (RC72).
final class ReadingReportedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingReportedEvent({required this.spread, required this.reason})
    : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// The report reason chip.
  final ReportReason reason;

  @override
  String get eventName => 'reading_reported';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'reason': reason.wire,
  };
}

/// `reading_refused`: the Worker declined the reading (03 §9.4, RC27).
final class ReadingRefusedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingRefusedEvent({
    required this.spread,
    required this.category,
    required this.canRephrase,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// The refusal category.
  final RefusalCategory category;

  /// Whether rephrasing is offered.
  final bool canRephrase;

  @override
  String get eventName => 'reading_refused';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'category': analyticsWire(category),
    'can_rephrase': canRephrase,
  };
}

/// `crisis_resources_viewed`: S27 was shown.
final class CrisisResourcesViewedEvent extends ReadingEvent {
  /// Creates the event.
  const CrisisResourcesViewedEvent({required this.origin}) : super._();

  /// Where S27 was opened from.
  final CrisisResourcesOrigin origin;

  @override
  String get eventName => 'crisis_resources_viewed';

  @override
  Map<String, Object> get parameters => {'origin': origin.wire};
}

/// `reading_viewed`: a reading result was opened.
final class ReadingViewedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingViewedEvent({required this.spread, required this.origin})
    : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Fresh or from the journal.
  final ReadingViewOrigin origin;

  @override
  String get eventName => 'reading_viewed';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'origin': origin.wire,
  };
}

/// `reading_rated`: thumbs up or down.
final class ReadingRatedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingRatedEvent({
    required this.spread,
    required this.rating,
    this.reason,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// The rating.
  final Rating rating;

  /// Why it was rated down, if given.
  final RatingReason? reason;

  @override
  String get eventName => 'reading_rated';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'rating': analyticsWire(rating),
    if (reason case final reason?) 'reason': analyticsWire(reason),
  };
}

/// `reading_shared`: the share image was shared.
final class ReadingSharedEvent extends ReadingEvent {
  /// Creates the event.
  const ReadingSharedEvent({
    required this.spread,
    required this.includeQuestion,
  }) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  /// Whether the question was included.
  final bool includeQuestion;

  @override
  String get eventName => 'reading_shared';

  @override
  Map<String, Object> get parameters => {
    'spread_id': spread.wire,
    'include_question': includeQuestion,
  };
}

/// `reflection_prompt_used`: a reflection prompt was tapped.
final class ReflectionPromptUsedEvent extends ReadingEvent {
  /// Creates the event.
  const ReflectionPromptUsedEvent({required this.spread}) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'reflection_prompt_used';

  @override
  Map<String, Object> get parameters => {'spread_id': spread.wire};
}
