import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro_core/taro_core.dart';

/// [ReportGateway] over `POST /v1/readings/{clientReadingId}/report` (03
/// §9.7, CS7, RC22, RC72).
///
/// The wire `reading` carries each card's `cardId` and `reversed`, which the
/// [ReadingReport] does not hold: they come from the stored reading
/// ([ReadingRepository.get]). A repeat for the same reading is the Worker's
/// stored `201`; the eleventh report of a local day is
/// `RateLimitedFailure(reportLimit)`.
final class ReportGatewayImpl implements ReportGateway {
  /// Creates the gateway.
  ReportGatewayImpl({
    required WorkerClient client,
    required ReadingRepository readings,
  }) : _client = client,
       _readings = readings;

  final WorkerClient _client;
  final ReadingRepository _readings;

  @override
  Future<Result<void>> submit(ReadingReport report) async {
    var cards = const <DrawnCard>[];
    final content = report.reading;
    if (content != null) {
      final stored = await _readings.get(report.readingId);
      switch (stored) {
        case Err(:final failure):
          return Result.err(failure);
        case Ok(:final value):
          cards = value?.cards ?? const [];
      }
      final placed = {for (final c in cards) c.positionId};
      if (!content.positions.every((p) => placed.contains(p.positionId))) {
        // The stored draw does not cover the text: nothing valid to send.
        return const Result.err(Failure.contract(wireCode: 'NOT_FOUND'));
      }
    }
    final sent = await _client.reportReading(
      report.readingId,
      ReportRequestDto.fromDomain(report, cards: cards),
      idempotencyKey: report.idempotencyKey,
    );
    return sent.map((_) {});
  }
}
