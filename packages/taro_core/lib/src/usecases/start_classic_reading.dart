import 'package:taro_core/src/logic/local_dates.dart';
import 'package:taro_core/src/model/draw.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/id_generator.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';
import 'package:taro_core/src/usecases/delivery_ack.dart';
import 'package:taro_core/src/usecases/draw_cards.dart';

/// A Classic reading (F8, 02 §9.8, RC20): the same CSPRNG ritual with no
/// hold, no Worker call, no network and no credit.
///
/// Offered after `needsAiConsent` ("Not now"), `aiUnavailableRegion` or
/// `readingsPaused`. Never counts toward the banner threshold or the review
/// prompt, and cannot be reported.
final class StartClassicReading {
  /// Creates the use case.
  StartClassicReading({
    required DrawCards draws,
    required ReadingRepository readings,
    required IdGenerator ids,
    required Clock clock,
  }) : _draws = draws,
       _readings = readings,
       _ids = ids,
       _clock = clock;

  final DrawCards _draws;
  final ReadingRepository _readings;
  final IdGenerator _ids;
  final Clock _clock;

  /// Draws the cards for [spread].
  Future<Result<Draw>> draw(SpreadDefinition spread) => _draws.classic(spread);

  /// Saves the reading (`status: classic`) once the last card is placed.
  Future<Result<Reading>> complete({
    required Draw draw,
    required String locale,
    String? question,
  }) {
    final now = _clock.now();
    return _readings.saveClassic(
      Reading(
        id: ReadingId(_ids.uuidV4()),
        createdAt: now,
        updatedAt: now,
        localDate: LocalDates.format(_clock.nowLocal()),
        draw: draw,
        status: const ReadingStatus.classic(),
        contentLocale: locale,
        question: normalizeQuestion(question),
        // Nothing to acknowledge: the Worker never saw it.
        deliveryAcked: true,
      ),
    );
  }
}
