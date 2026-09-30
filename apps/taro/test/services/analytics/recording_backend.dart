import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro_core/taro_core.dart';

/// A `TaroAnalyticsBackend` that records every call as a readable string.
final class RecordingBackend implements TaroAnalyticsBackend {
  /// Every call, oldest first (`event <name>`, `screen <id>`, …).
  final List<String> calls = [];

  /// Every properties call, oldest first.
  final List<AnalyticsUserProperties> properties = [];

  /// Called after each call is recorded.
  void Function(String call)? onSend;

  /// When set, every call throws it after recording.
  Error? failWith;

  /// The delivered event names, oldest first.
  List<String> get eventNames => [
    for (final call in calls)
      if (call.startsWith('event ')) call.substring(6),
  ];

  Future<void> _record(String call) async {
    calls.add(call);
    onSend?.call(call);
    if (failWith case final error?) throw error;
  }

  @override
  Future<void> log(TaroAnalyticsEvent event) =>
      _record('event ${event.eventName}');

  @override
  Future<void> screen(String screenId) => _record('screen $screenId');

  @override
  Future<void> setCollectionEnabled({required bool enabled}) =>
      _record('collection $enabled');

  @override
  Future<void> setConsent(AnalyticsConsent consent) =>
      _record('consent $consent');

  @override
  Future<void> setUserProperties(AnalyticsUserProperties properties) {
    this.properties.add(properties);
    return _record('properties ${properties.toWire()}');
  }
}
