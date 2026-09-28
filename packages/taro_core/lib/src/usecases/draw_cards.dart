import 'package:taro_core/src/logic/card_drawer.dart';
import 'package:taro_core/src/model/draw.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/content_repository.dart';
import 'package:taro_core/src/ports/random_source.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/ports/settings_repository.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/result.dart';

/// Draws the cards for a spread with the CSPRNG (02 §4.1, §9.3, PR7).
///
/// An AI draw needs a live [ReadingHold] (rule 10, RC50): there is no way
/// to draw for an AI reading before the Worker reserved the credit.
final class DrawCards {
  /// Creates the use case.
  DrawCards({
    required ContentRepository content,
    required SettingsRepository settings,
    required RandomSource random,
    required Clock clock,
  }) : _content = content,
       _settings = settings,
       _drawer = CardDrawer(random),
       _clock = clock;

  final ContentRepository _content;
  final SettingsRepository _settings;
  final CardDrawer _drawer;
  final Clock _clock;

  /// Draws for an AI reading under [hold]. A lapsed hold fails with
  /// `HoldConflictFailure` (S08 `holdLost`), and nothing is drawn.
  Future<Result<Draw>> call(
    SpreadDefinition spread, {
    required ReadingHold hold,
  }) async {
    final now = _clock.now();
    if (hold.isExpiredAt(now)) return const Result.err(Failure.holdConflict());
    return _draw(spread, now);
  }

  /// Draws for a Classic reading: no hold, no network (RC20).
  Future<Result<Draw>> classic(SpreadDefinition spread) =>
      _draw(spread, _clock.now());

  Future<Result<Draw>> _draw(SpreadDefinition spread, DateTime now) async {
    final deck = await _content.deck();
    return deck.map(
      (d) => _drawer.draw(
        d,
        spread,
        reversalsEnabled: _settings.current.reversalsEnabled,
        now: now,
      ),
    );
  }
}
