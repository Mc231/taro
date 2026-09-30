import '../support/flow_harness.dart';

/// A time zone change (01 §7.1, 02 §9.2, 03 §3.5; 06 §2.5): the device
/// moves → the next resume sends exactly one `PUT /v1/installs/me/timezone`
/// → the reset boundary follows the new zone. A second move too soon is
/// refused (`409 TIMEZONE_CHANGE_TOO_SOON`): the server boundary is kept
/// and the app stays usable.
void main() {
  taroFlow('time zone change: one PUT, then a 409 keeps the boundary', (
    $,
  ) async {
    final fakes = flowFakes();
    final app = await FlowApp.launch($, fakes: fakes);
    await app.waitForScreen(ScreenId.s05);
    await app.waitUntil(() => fakes.balance.syncReasons.isNotEmpty);
    expect(fakes.install.timezoneUpdates, isEmpty);

    // Kyiv → New York: accepted; the Worker moves the reset boundary.
    const newYork = 'America/New_York';
    final nyResets = DateTime.utc(2026, 9, 27, 4);
    final moved = aCreditBalance()
        .withTimezone(newYork)
        .withResetsAt(nyResets)
        .withLedgerVersion(2)
        .build();
    fakes.install.timezoneBalance = moved;
    app.control.serverBalance = moved;
    await app.backgroundAndResume(
      whileAway: () {
        app.control
          ..setTimeZone(newYork, utcOffset: const Duration(hours: -4))
          ..advance(const Duration(minutes: 1));
      },
    );
    await app.waitUntil(() => fakes.balance.cached?.free.timezone == newYork);
    expect(fakes.install.timezoneUpdates, [newYork]);
    expect(fakes.balance.cached?.free.resetsAt, nyResets);

    // New York → Tokyo an hour later: too soon, 409; the NY boundary stays.
    const tokyo = 'Asia/Tokyo';
    app.control.failNextTimezoneUpdate(
      Failure.timezoneChangeRejected(
        allowedAfter: kTestNow.add(const Duration(days: 1)),
      ),
    );
    await app.backgroundAndResume(
      whileAway: () {
        app.control
          ..setTimeZone(tokyo, utcOffset: const Duration(hours: 9))
          ..advance(const Duration(hours: 1));
      },
    );
    await app.waitUntil(() => fakes.install.timezoneUpdates.length == 2);
    await app.settle();
    expect(fakes.install.timezoneUpdates, [newYork, tokyo]);
    expect(fakes.balance.cached?.free.timezone, newYork);
    expect(fakes.balance.cached?.free.resetsAt, nyResets);

    // Still usable (the pre-reading sync gets a fresh balance).
    final now = fakes.clock.now();
    app.control.serverBalance = fakes.balance.cached!.copyWith(
      ledgerVersion: 3,
      serverTime: now,
      syncedAt: now,
    );
    await app.openQuestion();
    await app.begin();
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
  });
}
