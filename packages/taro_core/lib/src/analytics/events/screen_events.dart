part of '../taro_analytics_event.dart';

/// Screen events (01 §15 `ScreenEvent`).
sealed class ScreenEvent extends TaroAnalyticsEvent {
  const ScreenEvent._() : super._();
}

/// `screen_view`: a screen became visible.
final class ScreenViewEvent extends ScreenEvent {
  /// Creates the event.
  const ScreenViewEvent({required this.screen, this.previous}) : super._();

  /// The screen shown.
  final ScreenId screen;

  /// The screen shown before it.
  final ScreenId? previous;

  @override
  String get eventName => 'screen_view';

  @override
  Map<String, Object> get parameters => {
    'screen': screen.wire,
    'previous': ?previous?.wire,
  };
}
