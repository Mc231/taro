import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/analytics/consent_aware_analytics.dart';
import 'package:taro/services/analytics/firebase_analytics_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'firebase_fakes.dart';
import 'recording_backend.dart';

const _disclaimer = TaroAnalyticsEvent.disclaimerAccepted();
const _reminder = TaroAnalyticsEvent.reminderOpened();

AnalyticsConsent _analyticsOnly({required bool granted}) => AnalyticsConsent(
  analyticsStorage: granted,
  adStorage: false,
  adUserData: false,
  adPersonalization: false,
);

final class _Harness implements AnalyticsServiceHarness {
  final RecordingBackend backend = RecordingBackend();

  @override
  late final AnalyticsService subject = ConsentAwareAnalytics(
    inner: backend,
    whenResolved: Future.value(AnalyticsConsent.allGranted()),
    logger: CapturingLogger(),
  );

  @override
  List<String> get deliveredEventNames => backend.eventNames;
}

void main() {
  runAnalyticsServiceContract(_Harness.new);

  late Completer<AnalyticsConsent> resolved;
  late RecordingBackend inner;
  late CapturingLogger logger;
  late ConsentAwareAnalytics analytics;

  setUp(() {
    resolved = Completer();
    inner = RecordingBackend();
    logger = CapturingLogger();
    analytics = ConsentAwareAnalytics(
      inner: inner,
      whenResolved: resolved.future,
      logger: logger,
    );
  });

  group('over the Firebase adapter', () {
    setUpAll(setUpFirebaseFakes);

    test('no event reaches Firebase before whenResolved', () async {
      await setUpFirebaseFakes();
      final gate = Completer<AnalyticsConsent>();
      final firebase = FirebaseAnalyticsService(
        FirebaseAnalytics.instance,
        logger: logger,
      );
      await firebase.setConsent(AnalyticsConsent.allDenied());
      final consentAware = ConsentAwareAnalytics(
        inner: firebase,
        whenResolved: gate.future,
        logger: logger,
      );
      await consentAware.log(
        const TaroAnalyticsEvent.onboardingStepViewed(
          step: AnalyticsOnboardingStep.welcome,
        ),
      );
      await consentAware.screen('S02');
      await consentAware.log(_disclaimer);
      await pumpEventQueue();
      expect(analyticsPlatform.events, isEmpty);
      expect(consentAware.bufferedCount, 3);

      gate.complete(AnalyticsConsent.allGranted());
      await consentAware.ready;
      expect(analyticsPlatform.eventNames, [
        'onboarding_step_viewed',
        'screen_view',
        'disclaimer_accepted',
      ]);
      expect(analyticsPlatform.consents, [
        [false, false, false, false],
        [true, true, true, true],
      ]);
    });

    test(
      'denied: the buffer is dropped and nothing reaches Firebase',
      () async {
        await setUpFirebaseFakes();
        final consentAware = ConsentAwareAnalytics(
          inner: FirebaseAnalyticsService(
            FirebaseAnalytics.instance,
            logger: logger,
          ),
          whenResolved: Future.value(AnalyticsConsent.allDenied()),
          logger: logger,
        );
        await consentAware.log(_disclaimer);
        await consentAware.ready;
        await consentAware.log(_reminder);
        expect(analyticsPlatform.events, isEmpty);
        expect(analyticsPlatform.consents, [
          [false, false, false, false],
        ]);
      },
    );
  });

  test('not required (all granted): the buffer is flushed in order', () async {
    await analytics.log(_disclaimer);
    await analytics.screen('S03');
    await analytics.log(_reminder);
    expect(inner.calls, isEmpty);
    expect(analytics.isResolved, isFalse);

    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(analytics.isResolved, isTrue);
    expect(inner.calls, [
      'consent ${AnalyticsConsent.allGranted()}',
      'event disclaimer_accepted',
      'screen S03',
      'event reminder_opened',
    ]);
    expect(analytics.bufferedCount, 0);
    expect(logger.logged('flushed 3'), isTrue);

    await analytics.log(_disclaimer);
    expect(inner.calls.last, 'event disclaimer_accepted');
  });

  test('analytics storage denied: buffer and later events dropped', () async {
    await analytics.log(_disclaimer);
    resolved.complete(_analyticsOnly(granted: false));
    await analytics.ready;
    await analytics.log(_reminder);
    expect(inner.eventNames, isEmpty);
    expect(logger.logged('dropped 1 buffered events'), isTrue);
  });

  test('keeps at most 50 events: the earliest ones', () async {
    for (var i = 0; i < 60; i++) {
      await analytics.log(i.isEven ? _disclaimer : _reminder);
    }
    expect(analytics.bufferedCount, kConsentBufferLimit);
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(inner.eventNames, hasLength(50));
    expect(logger.logged('flushed 50, overflowed 10'), isTrue);
  });

  test('dropping an overflowed buffer counts every dropped event', () async {
    for (var i = 0; i < 55; i++) {
      await analytics.log(_disclaimer);
    }
    resolved.complete(AnalyticsConsent.allDenied());
    await analytics.ready;
    expect(logger.logged('dropped 55 buffered events'), isTrue);
  });

  test('disabling collection drops the buffer and later events', () async {
    await analytics.log(_disclaimer);
    await analytics.setCollectionEnabled(enabled: false);
    expect(analytics.bufferedCount, 0);
    expect(logger.logged('collection disabled'), isTrue);
    await analytics.log(_reminder);
    expect(analytics.bufferedCount, 0);

    await analytics.setCollectionEnabled(enabled: true);
    await analytics.screen('S05');
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(inner.calls, [
      'collection false',
      'collection true',
      'consent ${AnalyticsConsent.allGranted()}',
      'screen S05',
    ]);

    await analytics.setCollectionEnabled(enabled: false);
    await analytics.log(_disclaimer);
    expect(inner.eventNames, isEmpty);
  });

  test('disabling collection with an empty buffer logs nothing', () async {
    await analytics.setCollectionEnabled(enabled: false);
    expect(logger.records, isEmpty);
  });

  test('a failed resolution counts as denied', () async {
    await analytics.log(_disclaimer);
    resolved.completeError(StateError('ump crashed'));
    await analytics.ready;
    expect(inner.eventNames, isEmpty);
    expect(inner.calls.single, 'consent ${AnalyticsConsent.allDenied()}');
    expect(logger.logged('treated as denied', level: LogLevel.warning), isTrue);
  });

  test('consent passes through; after resolution it gates events', () async {
    await analytics.setConsent(AnalyticsConsent.allDenied());
    expect(inner.calls, ['consent ${AnalyticsConsent.allDenied()}']);
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;

    await analytics.setConsent(_analyticsOnly(granted: false));
    await analytics.log(_disclaimer);
    expect(inner.eventNames, isEmpty);

    await analytics.setConsent(_analyticsOnly(granted: true));
    await analytics.log(_reminder);
    expect(inner.eventNames, ['reminder_opened']);
  });

  test('user properties wait for consent, merged', () async {
    await analytics.setUserProperties(
      const AnalyticsUserProperties(adsRemoved: true),
    );
    await analytics.setUserProperties(
      const AnalyticsUserProperties(hasPurchased: false),
    );
    expect(inner.properties, isEmpty);
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(inner.properties, [
      const AnalyticsUserProperties(adsRemoved: true, hasPurchased: false),
    ]);

    await analytics.setUserProperties(
      const AnalyticsUserProperties(theme: ThemeMode.light),
    );
    expect(inner.properties, hasLength(2));
  });

  test('user properties are dropped when consent is denied', () async {
    await analytics.setUserProperties(
      const AnalyticsUserProperties(adsRemoved: true),
    );
    resolved.complete(AnalyticsConsent.allDenied());
    await analytics.ready;
    await analytics.setUserProperties(
      const AnalyticsUserProperties(adsRemoved: false),
    );
    expect(inner.properties, isEmpty);
  });

  test('events made while flushing queue behind the buffer', () async {
    inner.onSend = (call) {
      if (call == 'event disclaimer_accepted') {
        unawaited(analytics.log(_reminder));
        unawaited(
          analytics.setUserProperties(
            const AnalyticsUserProperties(adsRemoved: true),
          ),
        );
      }
    };
    await analytics.log(_disclaimer);
    await analytics.screen('S05');
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(inner.calls.skip(1), [
      'event disclaimer_accepted',
      // Properties carry no order; they are applied before the next event.
      'properties {ads_removed: true}',
      'screen S05',
      'event reminder_opened',
    ]);
  });

  test('disabling collection mid-flush stops the flush', () async {
    inner.onSend = (call) {
      if (call == 'event disclaimer_accepted') {
        unawaited(analytics.setCollectionEnabled(enabled: false));
      }
    };
    await analytics.log(_disclaimer);
    await analytics.log(_reminder);
    resolved.complete(AnalyticsConsent.allGranted());
    await analytics.ready;
    expect(inner.eventNames, ['disclaimer_accepted']);
  });
}
