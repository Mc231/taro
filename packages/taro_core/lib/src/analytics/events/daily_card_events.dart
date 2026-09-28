part of '../taro_analytics_event.dart';

/// Daily card events (01 §15 `DailyCardEvent`).
sealed class DailyCardEvent extends TaroAnalyticsEvent {
  const DailyCardEvent._() : super._();
}

/// `daily_card_revealed`: today's card was revealed on S13.
final class DailyCardRevealedEvent extends DailyCardEvent {
  /// Creates the event.
  const DailyCardRevealedEvent({
    required this.reversed,
    required this.arcana,
    required this.streakDays,
  }) : super._();

  /// Whether the card is reversed.
  final bool reversed;

  /// Major or minor arcana.
  final Arcana arcana;

  /// Consecutive days with a revealed card (local, analytics only; 01 Q10).
  final int streakDays;

  @override
  String get eventName => 'daily_card_revealed';

  @override
  Map<String, Object> get parameters => {
    'reversed': reversed,
    'arcana': analyticsWire(arcana),
    'streak_days': streakDays,
  };
}

/// `daily_card_deeper_tapped`: "go deeper" was tapped on S13.
final class DailyCardDeeperTappedEvent extends DailyCardEvent {
  /// Creates the event.
  const DailyCardDeeperTappedEvent() : super._();

  @override
  String get eventName => 'daily_card_deeper_tapped';

  @override
  Map<String, Object> get parameters => const {};
}
