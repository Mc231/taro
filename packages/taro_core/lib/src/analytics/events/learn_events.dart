part of '../taro_analytics_event.dart';

/// Learn events (01 §15 `LearnEvent`).
sealed class LearnEvent extends TaroAnalyticsEvent {
  const LearnEvent._() : super._();
}

/// `learn_card_viewed`: S17 card detail was shown.
final class LearnCardViewedEvent extends LearnEvent {
  /// Creates the event.
  const LearnCardViewedEvent({
    required this.card,
    required this.orientation,
    required this.origin,
  }) : super._();

  /// The card.
  final AnalyticsCardId card;

  /// The orientation shown.
  final CardOrientation orientation;

  /// Where the card was opened from.
  final LearnCardOrigin origin;

  @override
  String get eventName => 'learn_card_viewed';

  @override
  Map<String, Object> get parameters => {
    'card_id': card.wire,
    'orientation': orientation.wire,
    'origin': origin.wire,
  };
}

/// `learn_search`: a deck search was run (never the query text).
final class LearnSearchEvent extends LearnEvent {
  /// Creates the event.
  const LearnSearchEvent({required this.resultsBucket}) : super._();

  /// The result count bucket.
  final SearchResultsBucket resultsBucket;

  @override
  String get eventName => 'learn_search';

  @override
  Map<String, Object> get parameters => {
    'results_bucket': resultsBucket.wire,
  };
}

/// `learn_spread_viewed`: a spread detail was shown on S18.
final class LearnSpreadViewedEvent extends LearnEvent {
  /// Creates the event.
  const LearnSpreadViewedEvent({required this.spread}) : super._();

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'learn_spread_viewed';

  @override
  Map<String, Object> get parameters => {'spread_id': spread.wire};
}
