import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/settings/controller/delete_data_controller.dart';
import 'package:taro/features/settings/controller/language_controller.dart';
import 'package:taro/features/settings/controller/privacy_controller.dart';
import 'package:taro/features/settings/controller/reminder_settings_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = TaroFakes());

  group('LanguageController (S21)', () {
    test('select applies at once and logs; System clears it', () async {
      final container = fakes.container()
        ..listen(languageControllerProvider, (_, _) {});
      final controller = container.read(languageControllerProvider.notifier);
      expect(
        container.read(languageControllerProvider),
        const LanguageState.content(
          localeOverride: null,
          locales: kSupportedLocales,
        ),
      );
      await controller.select('ar');
      await pumpEventQueue();
      expect(
        (container.read(languageControllerProvider) as LanguageContent)
            .localeOverride,
        'ar',
      );
      await controller.select('ar');
      await controller.select('xx');
      await controller.select(null);
      await pumpEventQueue();
      expect(fakes.settings.current.localeOverride, isNull);
      expect(fakes.analytics.events.map((e) => e.parameters), [
        {'key': 'language', 'value': 'ar'},
        {'key': 'language', 'value': 'system'},
      ]);
    });

    test('a failed save logs nothing', () async {
      fakes.settings.failNext(const Failure.storage(), on: 'update');
      final container = fakes.container()
        ..listen(languageControllerProvider, (_, _) {});
      await container.read(languageControllerProvider.notifier).select('uk');
      expect(fakes.analytics.events, isEmpty);
    });
  });

  group('ReminderSettingsController (S22)', () {
    (ReminderSettingsController, ReminderSettingsState Function()) open() {
      final container = fakes.container()
        ..listen(reminderSettingsControllerProvider, (_, _) {});
      return (
        container.read(reminderSettingsControllerProvider.notifier),
        () => container.read(reminderSettingsControllerProvider),
      );
    }

    test(
      'on: permission, schedule in the app locale, events; time; off',
      () async {
        final (controller, read) = open();
        expect(read(), const ReminderSettingsState.content(ReminderSettings()));
        await controller.setEnabled(enabled: true);
        await pumpEventQueue();
        expect(
          read(),
          const ReminderSettingsState.content(ReminderSettings(enabled: true)),
        );
        expect(fakes.reminders.scheduled?.$2, 'en');
        await controller.setTime(hour: 7, minute: 5);
        await controller.setTime(hour: 24, minute: 0);
        await controller.setTime(hour: 7, minute: 60);
        await pumpEventQueue();
        expect(fakes.settings.current.reminder.time, '07:05');
        await controller.setEnabled(enabled: false);
        expect(fakes.reminders.scheduled, isNull);
        expect(fakes.analytics.events.map((e) => e.eventName), [
          'notification_permission_result',
          'reminder_changed',
          'reminder_changed',
          'reminder_changed',
        ]);
        expect(fakes.analytics.events[2].parameters, {
          'enabled': true,
          'hour': 7,
        });
      },
    );

    test('permissionDenied keeps it off; recheck after settings', () async {
      fakes.reminders.permission = false;
      final (controller, read) = open();
      await controller.setEnabled(enabled: true);
      expect(
        read(),
        const ReminderSettingsState.permissionDenied(ReminderSettings()),
      );
      expect(fakes.reminders.scheduled, isNull);
      fakes.reminders.permission = true;
      await controller.recheckPermission();
      await pumpEventQueue();
      expect(read(), isA<ReminderSettingsContent>());
      expect(fakes.reminders.scheduled, isNotNull);
    });

    test('a failed save schedules nothing', () async {
      fakes.settings.failNext(const Failure.storage(), on: 'update');
      final (controller, _) = open();
      await controller.setEnabled(enabled: true);
      expect(fakes.reminders.scheduled, isNull);
    });
  });

  group('PrivacyController (S23)', () {
    ProviderContainer open() {
      final container = fakes.container()
        ..listen(privacyControllerProvider, (_, _) {});
      return container;
    }

    PrivacyView viewOf(ProviderContainer c) =>
        (c.read(privacyControllerProvider) as PrivacyContent).view;

    test(
      'iOS: tracking status, UMP required, AI withdraw, analytics',
      () async {
        fakes
          ..tracking.current = TrackingStatus.denied
          ..consentStore.seed(
            ConsentState(
              onboardingStep: OnboardingStep.done,
              analyticsEnabled: true,
              ads: const AdsConsent(
                status: AdsConsentStatus.obtained,
                canRequestAds: true,
                privacyOptionsRequired: true,
              ),
              ai: AiConsent(
                decision: AiConsentDecision.granted,
                version: 2,
                at: fakes.clock.now(),
              ),
            ),
          );
        final container = open();
        await pumpEventQueue();
        expect(
          viewOf(container),
          const PrivacyView(
            aiGranted: true,
            adsPrivacyOptionsRequired: true,
            tracking: TrackingStatus.denied,
            analyticsEnabled: true,
          ),
        );
        final controller = container.read(privacyControllerProvider.notifier);
        await controller.reviewAdChoices();
        expect(fakes.consentService.privacyOptionsShown, 1);
        await controller.withdrawAi();
        await pumpEventQueue();
        expect(viewOf(container).aiGranted, isFalse);
        await controller.setAnalytics(enabled: false);
        await controller.setAnalytics(enabled: true);
        await pumpEventQueue();
        expect(viewOf(container).analyticsEnabled, isTrue);
        final names = fakes.analytics.eventNames;
        expect(names.where((n) => n == 'ai_consent_decided'), hasLength(1));
        expect(
          fakes.analytics.events
              .firstWhere((e) => e.eventName == 'ai_consent_decided')
              .parameters,
          {'granted': false, 'origin': 'settings', 'consent_version': 2},
        );
        expect(
          fakes.analytics.events
              .where((e) => e.eventName == 'analytics_toggled')
              .map((e) => e.parameters['enabled']),
          [false, true],
        );
      },
    );

    test(
      'Android: no tracking row; UMP not required hides ad choices',
      () async {
        fakes.appInfo = const FakeAppInfo(platform: AppPlatform.android);
        final container = open();
        await pumpEventQueue();
        expect(viewOf(container).tracking, isNull);
        expect(viewOf(container).adsPrivacyOptionsRequired, isFalse);
        final controller = container.read(privacyControllerProvider.notifier);
        await controller.reviewAdChoices();
        await controller.refreshTracking();
        expect(fakes.consentService.privacyOptionsShown, 0);
      },
    );

    test('a failed withdraw logs nothing', () async {
      fakes.consentStore.failNext(const Failure.storage(), on: 'update');
      final container = open();
      await container.read(privacyControllerProvider.notifier).withdrawAi();
      expect(fakes.analytics.eventNames, isNot(contains('ai_consent_decided')));
    });
  });

  group('DeleteDataController (S26, RC37)', () {
    (ProviderContainer, DeleteDataController, DeleteDataState Function())
    open() {
      final container = fakes.container()
        ..listen(deleteDataControllerProvider, (_, _) {});
      return (
        container,
        container.read(deleteDataControllerProvider.notifier),
        () => container.read(deleteDataControllerProvider),
      );
    }

    setUp(() {
      fakes.journal
        ..putReading(aReading().build())
        ..putDailyCard(aDailyCard().build());
      fakes.balance.seed(aCreditBalance().withPaid(2).withBonus(1).build());
      fakes.entitlements.entitlement = const Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.cache,
      );
    });

    test('confirm1 → confirm2 by the typed word → done; keeps credits and '
        'Remove Ads', () async {
      final (_, controller, read) = open();
      await pumpEventQueue();
      const summary = DeleteDataSummary(
        journalEntries: 2,
        readingsKept: 3,
        removeAdsKept: true,
      );
      expect(read(), const DeleteDataState.confirm1(summary));
      await controller.delete();
      expect(read(), const DeleteDataState.confirm1(summary));
      controller.updateTyped('delete ', word: 'DELETE');
      expect(read(), const DeleteDataState.confirm2(summary));
      controller.updateTyped('nope', word: 'DELETE');
      expect(read(), const DeleteDataState.confirm1(summary));
      controller.updateTyped('', word: '');
      expect(read(), const DeleteDataState.confirm1(summary));
      controller.updateTyped('DELETE', word: 'DELETE');
      final deleting = controller.delete();
      expect(read(), const DeleteDataState.deleting());
      await deleting;
      expect(read(), const DeleteDataState.done());
      expect(fakes.journal.readings, isEmpty);
      expect(fakes.deletion.erased, hasLength(1));
      expect(fakes.analytics.events.single.parameters, {'worker_ack': true});
      controller.updateTyped('DELETE', word: 'DELETE');
      expect(read(), const DeleteDataState.done());
    });

    test('partial when the Worker erasure is queued', () async {
      fakes.deletion.failNext(const Failure.network(), on: 'eraseServerData');
      final (_, controller, read) = open();
      controller.updateTyped('DELETE', word: 'DELETE');
      await controller.delete();
      expect(read(), const DeleteDataState.partial());
      expect(fakes.deletion.queuedKey, isNotNull);
      expect(fakes.analytics.events.single.parameters, {'worker_ack': false});
    });

    test('a local failure is failed; retry returns to confirm1', () async {
      fakes.journalRepository.failNext(
        const Failure.storage(),
        on: 'deleteAll',
      );
      final (_, controller, read) = open();
      await pumpEventQueue();
      controller.updateTyped('DELETE', word: 'DELETE');
      await controller.delete();
      expect(read(), const DeleteDataState.failed(ErrorKind.storage));
      controller.retry();
      expect(read(), isA<DeleteDataConfirm1>());
      controller.retry();
      expect(read(), isA<DeleteDataConfirm1>());
    });

    test(
      'no balance keeps 0 readings; a failed count keeps 0 entries',
      () async {
        fakes
          ..balance.seed(null)
          ..journalRepository.failNext(const Failure.storage(), on: 'snapshot');
        final (_, _, read) = open();
        await pumpEventQueue();
        expect(
          (read() as DeleteDataConfirm1).summary,
          const DeleteDataSummary(
            journalEntries: 0,
            readingsKept: 0,
            removeAdsKept: true,
          ),
        );
      },
    );

    test('closing while deleting drops the result', () async {
      final (container, controller, _) = open();
      controller.updateTyped('DELETE', word: 'DELETE');
      final deleting = controller.delete();
      container.dispose();
      await deleting;
      fakes.journalRepository.failNext(
        const Failure.storage(),
        on: 'deleteAll',
      );
      final (container2, controller2, _) = open();
      controller2.updateTyped('DELETE', word: 'DELETE');
      final failing = controller2.delete();
      container2.dispose();
      await failing;
    });
  });
}
