part of '../taro_analytics_event.dart';

/// Error events (01 §15 `ErrorEvent`).
sealed class ErrorEvent extends TaroAnalyticsEvent {
  const ErrorEvent._() : super._();
}

/// `error_shown`: `TaroErrorView` was shown.
final class ErrorShownEvent extends ErrorEvent {
  /// Creates the event.
  const ErrorShownEvent({required this.kind, required this.screen}) : super._();

  /// The error kind.
  final ErrorKind kind;

  /// The screen showing it.
  final ScreenId screen;

  @override
  String get eventName => 'error_shown';

  @override
  Map<String, Object> get parameters => {
    'kind': analyticsWire(kind),
    'screen': screen.wire,
  };
}
