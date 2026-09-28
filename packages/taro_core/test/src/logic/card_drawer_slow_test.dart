@Tags(['slow'])
library;

import 'package:test/test.dart';

import 'logic_support.dart';

/// χ² uniformity of the draw (01 §17.3, 02 §4.1), in the non-CI `slow`
/// suite.
///
/// 100,000 seeded three-card draws. For every position the 78 card counts
/// are tested against the uniform expectation (df = 77); the critical value
/// at p = 0.001 is 122.1 (df = 77). The seed is fixed, so the result is
/// reproducible; the tolerance documents what a failure would mean. The
/// reversal share is checked within ±1 % of 0.5 (≈ 5.5 σ for 300,000 flips).
void main() {
  const draws = 100000;
  const critical = 122.1;

  test('positions are uniform over the 78 cards (χ², p > 0.001)', () {
    final drawer = CardDrawer(SeededRandomSource(20260926));
    final spread = spreadOf(3);
    final counts = [for (var p = 0; p < 3; p++) <CardId, int>{}];
    var reversed = 0;
    final now = DateTime.utc(2026, 9, 26);
    for (var i = 0; i < draws; i++) {
      final draw = drawer.draw(deck, spread, reversalsEnabled: true, now: now);
      for (var p = 0; p < 3; p++) {
        final card = draw.cards[p];
        counts[p][card.cardId] = (counts[p][card.cardId] ?? 0) + 1;
        if (card.reversed) reversed++;
      }
    }
    const expected = draws / 78;
    for (var p = 0; p < 3; p++) {
      expect(counts[p].length, 78);
      var chi2 = 0.0;
      for (final id in kCardIds) {
        final d = counts[p][id]! - expected;
        chi2 += d * d / expected;
      }
      expect(chi2, lessThan(critical), reason: 'position $p: χ² = $chi2');
    }
    expect(reversed / (draws * 3), closeTo(0.5, 0.01));
  });
}
