import 'package:characters/characters.dart';
import 'package:taro_core/src/analytics/analytics_values.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/ports/id_generator.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/ports/report_gateway.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

/// Reports an AI reading from S33 (CS7, 02 §9.9, RC22, RC72).
///
/// Only AI readings the Worker delivered (`complete`, `refused`) can be
/// reported; Classic readings never reach the Worker (a
/// `ContractFailure(NOT_FOUND)`, like the Worker's own answer). A reading
/// already reported succeeds without a network call (`alreadyReported`).
final class ReportReading {
  /// Creates the use case.
  ReportReading({
    required ReadingRepository readings,
    required ReportGateway gateway,
    required IdGenerator ids,
  }) : _readings = readings,
       _gateway = gateway,
       _ids = ids;

  /// The note limit in grapheme clusters (03 §9.7).
  static const int noteMaxLength = 500;

  final ReadingRepository _readings;
  final ReportGateway _gateway;
  final IdGenerator _ids;

  /// Whether [reading] may be reported.
  static bool canReport(Reading reading) => switch (reading.status) {
    ReadingStatusComplete() || ReadingStatusRefused() => true,
    _ => false,
  };

  /// Sends the report and sets the local `reported` flag.
  Future<Result<void>> call(
    ReadingId id,
    ReportReason reason, {
    String? note,
  }) async {
    final stored = await _readings.get(id);
    return stored.then((reading) async {
      if (reading == null || !canReport(reading)) {
        return const Result.err(Failure.contract(wireCode: 'NOT_FOUND'));
      }
      if (reading.reported) return const Result.ok(null);
      final sent = await _gateway.submit(
        ReadingReport(
          readingId: id,
          reason: reason,
          locale: reading.contentLocale,
          idempotencyKey: _ids.uuidV4(),
          note: _clampNote(note),
          question: reading.question,
          reading: reading.content,
        ),
      );
      return sent.then((_) => _readings.markReported(id));
    });
  }

  static String? _clampNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final chars = trimmed.characters;
    return chars.length <= noteMaxLength
        ? trimmed
        : chars.take(noteMaxLength).toString();
  }
}
