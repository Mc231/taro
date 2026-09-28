import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeReadingRepository readings;
  late FakeClock clock;
  late StartClassicReading classic;

  setUp(() {
    // 22:30Z is already the next day in Kyiv.
    clock = FakeClock(DateTime.utc(2026, 9, 26, 22, 30));
    readings = FakeReadingRepository(clock: clock);
    classic = StartClassicReading(
      draws: DrawCards(
        content: FakeContentRepository(),
        settings: FakeSettingsRepository(),
        random: SeededRandomSource(),
        clock: clock,
      ),
      readings: readings,
      ids: SequentialIdGenerator(),
      clock: clock,
    );
  });

  test('draw uses the classic draw (no hold)', () async {
    final draw = expectOk(await classic.draw(aSpread('three_sao').build()));
    expect(draw.spreadId, const SpreadId('three_sao'));
    expect(draw.cards, hasLength(3));
    expect(readings.holds, isEmpty);
  });

  test('complete saves a Classic reading without the Worker', () async {
    final draw = aDraw();
    final reading = expectOk(
      await classic.complete(draw: draw, locale: 'uk', question: '  Why?  '),
    );
    expect(reading.status, const ReadingStatus.classic());
    expect(reading.id.value, '00000000-0000-4000-8000-000000000001');
    expect(reading.draw, draw);
    expect(reading.contentLocale, 'uk');
    expect(reading.question, 'Why?');
    expect(reading.localDate, '2026-09-27');
    expect(reading.createdAt, clock.now());
    expect(reading.content, isNull);
    expect(reading.chargeSource, isNull);
    // Nothing to acknowledge: the Worker never saw it.
    expect(reading.deliveryAcked, isTrue);
    expect(readings.journal.readings[reading.id], reading);
    expect(readings.submitted, isEmpty);
    expect(readings.acked, isEmpty);
  });

  test('an empty question is stored as none', () async {
    final reading = expectOk(
      await classic.complete(draw: aDraw(), locale: 'en', question: '   '),
    );
    expect(reading.question, isNull);
  });

  test('a storage failure is returned', () async {
    readings.failNext(const Failure.storage(), on: 'saveClassic');
    expect(
      expectErr(await classic.complete(draw: aDraw(), locale: 'en')),
      const Failure.storage(),
    );
  });
}
