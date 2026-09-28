import 'package:meta/meta.dart';

/// Base of every event. { braces in comments are ignored }
sealed class TaroAnalyticsEvent {
  const TaroAnalyticsEvent();
  String get eventName;
  Map<String, Object> get parameters;
}

final class ReadingGenerated extends TaroAnalyticsEvent {
  const ReadingGenerated({required this.spreadId, required this.latencyMs, this.error});

  @AnalyticsEnum(['single', 'three_ppf'])
  final String spreadId;
  final int latencyMs;
  @AnalyticsEnum(['network', 'timeout'])
  final String? error;

  @override
  String get eventName => 'reading_generated';

  @override
  Map<String, Object> get parameters => {
        'spread_id': spreadId,
        'latency_ms': latencyMs,
        if (error != null) 'error': error!,
      };
}

final class ClassicReadingStarted extends TaroAnalyticsEvent {
  const ClassicReadingStarted(this.spreadId, this.reason);
  final SpreadId spreadId;
  final ClassicReason reason;
  @override
  final eventName = 'classic_reading_started';
  @override
  Map<String, Object> get parameters {
    final label = reason.name;
    return {'spread_id': spreadId.wire, 'reason': label};
  }
}

final class ClassicReadingCompleted extends TaroAnalyticsEvent {
  const ClassicReadingCompleted(this.spreadId, this.reason);
  final SpreadId spreadId;
  final ClassicReason reason;
  @override
  String get eventName => "classic_reading_completed";
  @override
  Map<String, Object> get parameters => {'spread_id': spreadId.wire, 'reason': reason.name};
}

class RatePromptShown extends TaroAnalyticsEvent {
  const RatePromptShown();
  @override
  String get eventName => 'rate_prompt_shown';
  @override
  Map<String, Object> get parameters => const {};
}

class NotAnEvent {
  final String label = 'x';
}
