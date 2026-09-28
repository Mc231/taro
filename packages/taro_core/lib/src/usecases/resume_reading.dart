import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';
import 'package:taro_core/src/usecases/delivery_ack.dart';

/// Resumes readings left `pending` (app killed, connection lost) via
/// `GET /v1/readings/{clientReadingId}` (02 §9.2, §10, RC51).
final class ResumeReading {
  /// Creates the use case.
  ResumeReading({
    required ReadingRepository readings,
    required Logger logger,
  }) : _readings = readings,
       _logger = logger;

  final ReadingRepository _readings;
  final Logger _logger;

  /// Resumes one reading and acknowledges it once delivered.
  Future<Result<Reading>> call(ReadingId id) async {
    final result = await _readings.resume(id);
    if (result case Ok(:final value)) {
      await acknowledgeDelivery(_readings, _logger, value);
    }
    return result;
  }

  /// Resumes every pending reading; each one is independent. Returns how
  /// many were resumed without a failure.
  Future<Result<int>> resumeAll() async {
    final pending = await _readings.pending();
    return pending.then((readings) async {
      var resumed = 0;
      for (final reading in readings) {
        final result = await call(reading.id);
        switch (result) {
          case Ok():
            resumed++;
          case Err(:final failure):
            _logger.info('resume deferred: ${failure.code}');
        }
      }
      return Result.ok(resumed);
    });
  }
}
