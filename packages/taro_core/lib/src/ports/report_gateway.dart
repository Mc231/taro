import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/analytics/analytics_values.dart';
import 'package:taro_core/src/model/reading_content.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

part 'report_gateway.freezed.dart';

/// A `POST /v1/readings/{clientReadingId}/report` body (03 §9.7, CS7).
@freezed
abstract class ReadingReport with _$ReadingReport {
  /// Creates a report.
  const factory ReadingReport({
    /// The reported reading.
    required ReadingId readingId,

    /// The reason (`reason` wire value = `ReportReason.wire`).
    required ReportReason reason,

    /// The reading's content locale.
    required String locale,

    /// A fresh UUID per submission, reused on retry.
    required String idempotencyKey,

    /// The user's note (≤ 500 characters).
    String? note,

    /// The question as asked.
    String? question,

    /// The stored reading, sent back as the §9.1 wire object; absent for a
    /// declined reading.
    ReadingContent? reading,
  }) = _ReadingReport;
}

/// Reading reports (CS7, RC22, RC72). S33 discloses that the question and
/// reading are sent and kept for 90 days.
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class ReportGateway {
  /// Submits [report]. A repeat for the same reading returns the stored
  /// `201`; `RateLimitedFailure(reportLimit)` after 10 per local day.
  Future<Result<void>> submit(ReadingReport report);
}
