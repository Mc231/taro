part of '../taro_analytics_event.dart';

/// Backup and data events (01 §15 `DataEvent`). Counts only, as buckets.
sealed class DataEvent extends TaroAnalyticsEvent {
  const DataEvent._() : super._();
}

/// `export_completed`: a backup file was exported (S24).
final class ExportCompletedEvent extends DataEvent {
  /// Creates the event.
  const ExportCompletedEvent({required this.entriesBucket}) : super._();

  /// The number of journal entries, bucketed.
  final EntriesBucket entriesBucket;

  @override
  String get eventName => 'export_completed';

  @override
  Map<String, Object> get parameters => {
    'entries_bucket': entriesBucket.wire,
  };
}

/// `export_failed`: exporting a backup failed.
final class ExportFailedEvent extends DataEvent {
  /// Creates the event.
  const ExportFailedEvent({required this.entriesBucket, this.error})
    : super._();

  /// The number of journal entries, bucketed.
  final EntriesBucket entriesBucket;

  /// What failed, if known.
  final ExportError? error;

  @override
  String get eventName => 'export_failed';

  @override
  Map<String, Object> get parameters => {
    'entries_bucket': entriesBucket.wire,
    'error': ?error?.wire,
  };
}

/// `import_completed`: a backup was imported (S25).
final class ImportCompletedEvent extends DataEvent {
  /// Creates the event.
  const ImportCompletedEvent({
    required this.mode,
    required this.entriesBucket,
    required this.schemaVersion,
  }) : super._();

  /// Merge or replace.
  final ImportMode mode;

  /// The number of imported entries, bucketed.
  final EntriesBucket entriesBucket;

  /// The backup schema version.
  final int schemaVersion;

  @override
  String get eventName => 'import_completed';

  @override
  Map<String, Object> get parameters => {
    'mode': mode.wire,
    'entries_bucket': entriesBucket.wire,
    'schema_version': schemaVersion,
  };
}

/// `import_failed`: a backup could not be imported.
final class ImportFailedEvent extends DataEvent {
  /// Creates the event.
  const ImportFailedEvent({required this.reason}) : super._();

  /// Why it failed.
  final ImportFailureReason reason;

  @override
  String get eventName => 'import_failed';

  @override
  Map<String, Object> get parameters => {'reason': reason.wire};
}

/// `data_deleted`: all data was deleted (S26).
final class DataDeletedEvent extends DataEvent {
  /// Creates the event.
  const DataDeletedEvent({required this.workerAck}) : super._();

  /// Whether the Worker acknowledged the deletion.
  final bool workerAck;

  @override
  String get eventName => 'data_deleted';

  @override
  Map<String, Object> get parameters => {'worker_ack': workerAck};
}
