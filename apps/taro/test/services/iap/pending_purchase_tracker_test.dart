import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/iap/pending_purchase_tracker.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  late FakeClock clock;
  late int holdMinutes;
  late PendingPurchaseTracker tracker;
  final pack = TaroProducts.readings3.id;
  final other = TaroProducts.readings10.id;

  setUp(() {
    clock = FakeClock();
    holdMinutes = 30;
    tracker = PendingPurchaseTracker(
      clock: clock,
      holdMinutes: () => holdMinutes,
    );
  });

  test('nothing is pending at first', () {
    expect(tracker.isPending(pack), isFalse);
    expect(tracker.pending, isEmpty);
  });

  test('a pending mark holds for store.pendingHoldMinutes', () {
    tracker.markPending(pack);
    clock.advance(const Duration(minutes: 29, seconds: 59));
    expect(tracker.isPending(pack), isTrue);
    expect(tracker.isPending(other), isFalse, reason: 'other packs stay open');
    clock.advance(const Duration(seconds: 1));
    expect(tracker.isPending(pack), isFalse, reason: 'lapsed after 30 min');
    expect(tracker.pending, isEmpty);
  });

  test('settle clears the mark', () {
    tracker
      ..markPending(pack)
      ..markPending(other)
      ..settle(pack);
    expect(tracker.pending, {other});
  });

  test('a repeated mark restarts the hold', () {
    tracker.markPending(pack);
    clock.advance(const Duration(minutes: 20));
    tracker.markPending(pack);
    clock.advance(const Duration(minutes: 20));
    expect(tracker.isPending(pack), isTrue);
  });

  test('a config change applies on the next check', () {
    tracker.markPending(pack);
    clock.advance(const Duration(minutes: 6));
    holdMinutes = 5;
    expect(tracker.pending, isEmpty);
  });

  test('resume after the hold: the mark has lapsed', () {
    tracker.markPending(pack);
    // The app sat in the background past the hold.
    clock.advance(const Duration(hours: 5));
    expect(tracker.isPending(pack), isFalse);
  });
}
