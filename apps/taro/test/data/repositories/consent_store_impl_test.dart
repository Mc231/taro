import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/consent_store_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../db/db_fixtures.dart';

void main() {
  late DeviceDatabase db;
  late CapturingLogger logger;
  late FakeClock clock;
  late ConsentStoreImpl store;

  Future<ConsentStoreImpl> open() async {
    final opened = await ConsentStoreImpl.open(
      cache: db.cacheDao,
      clock: clock,
      logger: logger,
    );
    addTearDown(opened.close);
    return opened;
  }

  setUp(() async {
    db = memoryDevice();
    logger = CapturingLogger();
    clock = FakeClock.utc(DateTime.utc(2026, 9, 26, 9));
    addTearDown(db.close);
    store = await open();
  });

  runConsentStoreContract(() => store);

  final full = ConsentState(
    ads: const AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
      privacyOptionsRequired: true,
    ),
    tracking: TrackingStatus.authorized,
    ai: AiConsent(
      decision: AiConsentDecision.granted,
      version: 2,
      at: DateTime.utc(2026, 9, 26, 9, 30, 1, 250),
    ),
    analyticsEnabled: true,
    onboardingStep: OnboardingStep.done,
  );

  test('the state survives a restart with its update time', () async {
    await store.update((_) => full);
    expect((await open()).current, full);
    expect((await db.cacheDao.consent())!.updatedAt, clock.now());
  });

  test('encode and decode round-trip; bad fields take defaults', () {
    expect(
      ConsentStoreImpl.decode(ConsentStoreImpl.encode(full)),
      full,
    );
    expect(ConsentStoreImpl.decode(null), const ConsentState());
    expect(
      ConsentStoreImpl.decode({
        'ads': {'status': 'maybe', 'canRequestAds': 'yes'},
        'tracking': 3,
        'ai': {'decision': 'granted', 'version': '2', 'at': 5},
        'analyticsEnabled': true,
        'onboardingStep': 'ump',
      }),
      const ConsentState(
        ai: AiConsent(decision: AiConsentDecision.granted),
        analyticsEnabled: true,
        onboardingStep: OnboardingStep.ump,
      ),
    );
  });

  test('an unreadable row reads as the first-launch state', () async {
    await db.cacheDao.putConsent(
      ConsentStatesCompanion.insert(json: '{', updatedAt: at(0)),
    );
    expect((await open()).current, const ConsentState());
    expect(logger.logged('consent row unreadable'), isTrue);
  });

  test('a row cleared by "Delete all data" resets the state', () async {
    await store.update((_) => full);
    await db.cacheDao.clearConsent();
    await pumpEventQueue();
    expect(store.current, const ConsentState());
  });

  test('a failed write returns a storage failure', () async {
    await db.customStatement('DROP TABLE consent_state');
    final result = await store.update(
      (s) => s.copyWith(analyticsEnabled: true),
    );
    expect(expectErr(result), isA<StorageFailure>());
    expect(store.current.analyticsEnabled, isFalse);
    expect(logger.logged('consent update failed'), isTrue);
  });

  test('a failed reload is logged', () async {
    await db.customStatement('DROP TABLE consent_state');
    db.notifyUpdates({const TableUpdate('consent_state')});
    await pumpEventQueue();
    expect(logger.logged('consent reload failed'), isTrue);
  });
}
