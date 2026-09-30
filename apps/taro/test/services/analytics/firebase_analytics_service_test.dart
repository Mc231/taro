import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/analytics/firebase_analytics_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'firebase_fakes.dart';

final class _Harness implements AnalyticsServiceHarness {
  _Harness() {
    analyticsPlatform.reset();
  }

  @override
  final AnalyticsService subject = FirebaseAnalyticsService(
    FirebaseAnalytics.instance,
    logger: CapturingLogger(),
  );

  @override
  List<String> get deliveredEventNames => analyticsPlatform.eventNames;
}

void main() {
  setUpAll(setUpFirebaseFakes);

  runAnalyticsServiceContract(_Harness.new);

  late CapturingLogger logger;
  late FirebaseAnalyticsService analytics;

  setUp(() async {
    await setUpFirebaseFakes();
    logger = CapturingLogger();
    analytics = FirebaseAnalyticsService(
      FirebaseAnalytics.instance,
      logger: logger,
    );
  });

  test('sends typed events with Firebase-typed parameters', () async {
    await analytics.log(
      const TaroAnalyticsEvent.onboardingCompleted(
        durationS: 42,
        aiConsent: true,
      ),
    );
    final event = analyticsPlatform.events.single;
    expect(event.name, 'onboarding_completed');
    expect(event.parameters, {'duration_s': 42, 'ai_consent': 'true'});
  });

  test('purchase_completed value goes from micros to currency units', () async {
    await analytics.log(
      const TaroAnalyticsEvent.purchaseCompleted(
        product: AnalyticsProduct.packM,
        valueMicros: 4990000,
        currency: AnalyticsCurrency.usd,
        credits: 10,
        isFirstPurchase: false,
      ),
    );
    expect(analyticsPlatform.events.single.parameters, {
      'product': 'pack_m',
      'value': 4.99,
      'currency': 'USD',
      'credits': 10,
      'is_first_purchase': 'false',
    });
  });

  test('screen_view events and screens use logScreenView', () async {
    await analytics.log(
      const TaroAnalyticsEvent.screenView(
        screen: ScreenId.s05,
        previous: ScreenId.s01,
      ),
    );
    await analytics.log(
      const TaroAnalyticsEvent.screenView(screen: ScreenId.s06),
    );
    await analytics.screen('S07');
    expect(analyticsPlatform.eventNames, everyElement('screen_view'));
    expect(analyticsPlatform.events[0].parameters, {
      'screen_name': 'S05',
      'previous': 'S01',
    });
    expect(analyticsPlatform.events[1].parameters, {'screen_name': 'S06'});
    expect(analyticsPlatform.events[2].parameters, {'screen_name': 'S07'});
  });

  test('maps consent mode purposes one to one', () async {
    await analytics.setConsent(AnalyticsConsent.allDenied());
    await analytics.setConsent(
      const AnalyticsConsent(
        analyticsStorage: true,
        adStorage: false,
        adUserData: true,
        adPersonalization: false,
      ),
    );
    expect(analyticsPlatform.consents, [
      [false, false, false, false],
      [true, false, true, false],
    ]);
  });

  test('the collection toggle reaches Firebase and gates events', () async {
    await analytics.setCollectionEnabled(enabled: false);
    expect(analytics.collectionEnabled, isFalse);
    await analytics.log(const TaroAnalyticsEvent.disclaimerAccepted());
    await analytics.screen('S05');
    expect(analyticsPlatform.events, isEmpty);
    await analytics.setCollectionEnabled(enabled: true);
    expect(analyticsPlatform.collection, [false, true]);
  });

  test('sets the 01 §15 user properties and never a user ID', () async {
    await analytics.setUserProperties(
      const AnalyticsUserProperties(
        appLocale: AnalyticsLocale.uk,
        theme: ThemeMode.dark,
        reversalsEnabled: true,
        adsRemoved: false,
        aiConsent: AiConsentProperty.declined,
        hasPurchased: true,
        journalSizeBucket: EntriesBucket.some,
      ),
    );
    expect(analyticsPlatform.userProperties, {
      'app_locale': 'uk',
      'theme': 'dark',
      'reversals_enabled': 'true',
      'ads_removed': 'false',
      'ai_consent': 'declined',
      'has_purchased': 'true',
      'journal_size_bucket': '11-50',
    });
    expect(analyticsPlatform.userIdSet, isFalse);
  });

  test('Firebase failures are logged, never thrown', () async {
    analyticsPlatform.failWith = StateError('platform down');
    await analytics.log(const TaroAnalyticsEvent.disclaimerAccepted());
    await analytics.screen('S05');
    await analytics.setConsent(AnalyticsConsent.allGranted());
    await analytics.setCollectionEnabled(enabled: true);
    await analytics.setUserProperties(
      const AnalyticsUserProperties(adsRemoved: true),
    );
    expect(logger.at(LogLevel.warning), hasLength(5));
    expect(logger.records.first.logger, 'taro.analytics');
    expect(logger.messages.first, 'firebase disclaimer_accepted failed');
  });
}
