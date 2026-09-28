import 'package:mocktail/mocktail.dart';
import 'package:taro_core/src/model/models.dart';
import 'package:taro_core/src/ports/ports.dart';
import 'package:taro_core/src/result/result_barrel.dart';
import 'package:taro_core/src/usecases/delivery_ack.dart';
import 'package:taro_core/src/usecases/usecases.dart';
import 'package:test/test.dart';

import '../model/model_fixtures.dart';

class _Readings extends Mock implements ReadingRepository {}

class _Logger extends Mock implements Logger {}

void main() {
  setUpAll(() => registerFallbackValue(const ReadingId('fallback')));

  group('normalizeQuestion', () {
    test('trims and drops empty questions', () {
      expect(normalizeQuestion(null), isNull);
      expect(normalizeQuestion('   '), isNull);
      expect(normalizeQuestion('  What now?  '), 'What now?');
    });
  });

  group('acknowledgeDelivery', () {
    late _Readings readings;
    late _Logger logger;

    setUp(() {
      readings = _Readings();
      logger = _Logger();
    });

    test('acks a delivered, unacknowledged reading', () async {
      when(() => readings.ack(any())).thenAnswer((_) async => const Ok(null));
      final reading = completeReading().copyWith(deliveryAcked: false);
      await acknowledgeDelivery(readings, logger, reading);
      verify(() => readings.ack(reading.id)).called(1);
      verifyZeroInteractions(logger);
    });

    test('logs a failed ack (queued by the adapter)', () async {
      when(
        () => readings.ack(any()),
      ).thenAnswer((_) async => const Err(Failure.network()));
      await acknowledgeDelivery(
        readings,
        logger,
        completeReading(
          status: const ReadingStatus.refused(),
        ).copyWith(deliveryAcked: false),
      );
      verify(() => logger.warning(any(that: contains('NETWORK')))).called(1);
    });

    test('skips acknowledged and undelivered readings', () async {
      await acknowledgeDelivery(readings, logger, completeReading());
      for (final status in const [
        ReadingStatus.pending(),
        ReadingStatus.classic(),
        ReadingStatus.failed(Failure.aiUnavailable()),
      ]) {
        await acknowledgeDelivery(
          readings,
          logger,
          completeReading(status: status).copyWith(deliveryAcked: false),
        );
      }
      verifyZeroInteractions(readings);
    });
  });

  group('ReportReading.canReport', () {
    test('only delivered AI readings', () {
      expect(
        {
          for (final status in const [
            ReadingStatus.pending(),
            ReadingStatus.complete(),
            ReadingStatus.refused(),
            ReadingStatus.failed(Failure.aiUnavailable()),
            ReadingStatus.classic(),
          ])
            status.wire: ReportReading.canReport(
              completeReading(status: status),
            ),
        },
        {
          'pending': false,
          'complete': true,
          'refused': true,
          'failed': false,
          'classic': false,
        },
      );
    });
  });

  group('SyncAccount.shouldSkip', () {
    const config = RemoteConfig.defaults; // 30 s throttle
    final cached = balance(); // resetsAt 2026-09-26T22:00:00Z
    final last = DateTime.utc(2026, 9, 26, 10);

    bool skip({
      SyncReason reason = SyncReason.resume,
      Duration since = const Duration(seconds: 10),
      String localDate = '2026-09-26',
      DateTime? lastSuccessAt,
      CreditBalance? balance,
      bool noBalance = false,
    }) => SyncAccount.shouldSkip(
      reason: reason,
      now: (lastSuccessAt ?? last).add(since),
      localDate: localDate,
      config: config,
      lastSuccessAt: lastSuccessAt ?? last,
      lastSuccessLocalDate: '2026-09-26',
      balance: noBalance ? null : (balance ?? cached),
    );

    test('skips a recent resume on the same day before the reset', () {
      expect(skip(), isTrue);
      expect(skip(reason: SyncReason.connectivityRegained), isTrue);
    });

    test('runs once the throttle has passed', () {
      expect(skip(since: const Duration(seconds: 30)), isFalse);
    });

    test('runs when the local date changed', () {
      expect(skip(localDate: '2026-09-27'), isFalse);
    });

    test('runs at or after free.resetsAt', () {
      expect(
        skip(lastSuccessAt: DateTime.utc(2026, 9, 26, 21, 59, 55)),
        isFalse,
      );
    });

    test('never skips other reasons, a first sync or no balance', () {
      for (final reason in [
        SyncReason.launch,
        SyncReason.resetBoundary,
        SyncReason.manual,
        SyncReason.preReading,
      ]) {
        expect(skip(reason: reason), isFalse, reason: reason.name);
      }
      expect(skip(noBalance: true), isFalse);
      expect(
        SyncAccount.shouldSkip(
          reason: SyncReason.resume,
          now: last,
          localDate: '2026-09-26',
          config: config,
          lastSuccessAt: null,
          lastSuccessLocalDate: null,
          balance: cached,
        ),
        isFalse,
      );
    });
  });

  group('value types', () {
    test('ImportPreview counts the file entries', () {
      final preview = ImportPreview(
        BackupV1(
          exportedAt: DateTime.utc(2026, 9, 26),
          appVersion: '1.0.0+1',
          data: BackupData(
            settings: const UserSettings(),
            readings: [completeReading()],
            dailyCards: [dailyCard(), dailyCard()],
          ),
          checksum: '0' * 64,
        ),
      );
      expect(preview.readings, 1);
      expect(preview.dailyCards, 2);
    });

    test('RewardOutcome exposes a factory per case', () {
      const outcomes = <RewardOutcome>[
        RewardOutcome.granted(amount: 1),
        RewardOutcome.delayed(),
        RewardOutcome.dismissed(),
        RewardOutcome.notGranted(RewardIntentState.expired),
      ];
      expect(outcomes.toSet(), hasLength(4));
    });

    test('constants', () {
      expect(EarnReward.pollInterval, const Duration(milliseconds: 1500));
      expect(ExportBackup.mimeType, 'application/json');
      expect(ReportReading.noteMaxLength, 500);
      expect(DataDeletionOutcome.values, hasLength(2));
    });
  });
}
