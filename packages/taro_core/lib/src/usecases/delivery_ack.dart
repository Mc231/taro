import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/result/result.dart';

/// Acknowledges delivery of a stored terminal AI reading (RC51).
///
/// A failed ack is not a failure of the reading: the adapter queues it in
/// `pending_acks` and `SyncAccount` retries it. Internal to the use cases.
Future<void> acknowledgeDelivery(
  ReadingRepository readings,
  Logger logger,
  Reading reading,
) async {
  final delivered = switch (reading.status) {
    ReadingStatusComplete() || ReadingStatusRefused() => true,
    _ => false,
  };
  if (!delivered || reading.deliveryAcked) return;
  final ack = await readings.ack(reading.id);
  if (ack case Err(:final failure)) {
    logger.warning('delivery ack queued: ${failure.code}');
  }
}

/// A question as stored: trimmed, and `null` when empty.
String? normalizeQuestion(String? question) {
  final trimmed = question?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
