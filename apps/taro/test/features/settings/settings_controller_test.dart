import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/settings/controller/settings_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

void main() {
  late TaroFakes fakes;

  setUp(() {
    fakes = TaroFakes();
    fakes.balance.seed(aCreditBalance().withPaid(3).build());
  });

  (ProviderContainer, SettingsController, SettingsContent Function()) open() {
    final container = fakes.container(
      extra: [
        settingsStoreTimeoutsProvider.overrideWithValue((
          restore: const Duration(seconds: 5),
          transfer: const Duration(seconds: 5),
        )),
      ],
    )..listen(settingsScreenControllerProvider, (_, _) {});
    return (
      container,
      container.read(settingsScreenControllerProvider.notifier),
      () => container.read(settingsScreenControllerProvider) as SettingsContent,
    );
  }

  test('content: settings, balance, Remove Ads, AI row and the Support ID '
      '(RC43)', () async {
    final (_, _, read) = open();
    expect(read().view.support, isNull);
    await pumpEventQueue();
    final view = read().view;
    expect(view.settings, const UserSettings());
    expect(view.balance?.paid, 3);
    expect(view.adsRemoved, isFalse);
    expect(view.removeAdsOffered, isTrue);
    expect(view.aiConsentGranted, isFalse);
    expect(view.support?.supportId, supportIdOf(kTestInstallId));
    expect(view.support?.supportId, hasLength(8));
    expect(read().restore, const SettingsRestore.idle());
    expect(read().transfer, const SettingsTransfer.idle());
  });

  test('toggles persist and log setting_changed', () async {
    final (_, controller, read) = open();
    await controller.setReversals(enabled: false);
    await controller.setHaptics(enabled: false);
    await controller.setTheme(ThemeMode.dark);
    await pumpEventQueue();
    expect(
      read().view.settings,
      const UserSettings(
        reversalsEnabled: false,
        hapticsEnabled: false,
        themeMode: ThemeMode.dark,
      ),
    );
    expect(fakes.analytics.events.map((e) => e.parameters), [
      {'key': 'reversals', 'value': 'off'},
      {'key': 'haptics', 'value': 'off'},
      {'key': 'theme', 'value': 'dark'},
    ]);
  });

  test('a failed save logs nothing', () async {
    fakes.settings.failNext(const Failure.storage(), on: 'update');
    final (_, controller, _) = open();
    await controller.setHaptics(enabled: false);
    expect(fakes.analytics.events, isEmpty);
  });

  test('restore: inProgress → nothingFound', () async {
    final (_, controller, read) = open();
    final running = controller.restore();
    expect(read().restore, const SettingsRestore.inProgress());
    await controller.restore();
    await running;
    expect(
      read().restore,
      const SettingsRestore.success(RestoreFinding.nothingFound),
    );
    controller.acknowledge();
    expect(read().restore, const SettingsRestore.idle());
  });

  test('restore finds Remove Banner Ads', () async {
    fakes.iap.own(TaroProducts.removeAds.id);
    final (_, controller, read) = open();
    await controller.restore();
    await pumpEventQueue();
    expect(
      read().restore,
      const SettingsRestore.success(RestoreFinding.removeAdsRestored),
    );
    expect(read().view.adsRemoved, isTrue);
  });

  test('restore failure', () async {
    fakes.iap.failNext(const Failure.network(), on: 'restore');
    final (_, controller, read) = open();
    await controller.restore();
    expect(read().restore, const SettingsRestore.failed());
  });

  test(
    'move readings: a claimed purchase yields the transfer code (RC84)',
    () async {
      fakes
        ..iap.own(TaroProducts.readings10.id)
        ..verifier.failNext(
          const Failure.purchaseAlreadyClaimed(
            transferEligible: true,
            transferToken: 'tt1.payload.mac',
          ),
          on: 'verify',
        );
      final (_, controller, read) = open();
      final running = controller.moveReadings();
      expect(read().transfer, const SettingsTransfer.checking());
      await controller.moveReadings();
      await running;
      expect(read().transfer, const SettingsTransfer.code('tt1.payload.mac'));
      controller.acknowledge();
      expect(read().transfer, const SettingsTransfer.idle());
    },
  );

  test('move readings: claimed without proof is notEligible', () async {
    fakes
      ..iap.own(TaroProducts.readings10.id)
      ..verifier.failNext(
        const Failure.purchaseAlreadyClaimed(transferEligible: false),
        on: 'verify',
      );
    final (_, controller, read) = open();
    await controller.moveReadings();
    expect(read().transfer, const SettingsTransfer.notEligible());
  });

  test('move readings: nothing to move', () async {
    final (_, controller, read) = open();
    await controller.moveReadings();
    expect(read().transfer, const SettingsTransfer.nothingFound());
  });

  test(
    'move readings: a purchase of this install is nothing to move',
    () async {
      fakes.iap.own(TaroProducts.readings3.id);
      final (_, controller, read) = open();
      await controller.moveReadings();
      expect(read().transfer, const SettingsTransfer.nothingFound());
    },
  );

  test('move readings: a store failure', () async {
    fakes.iap.failNext(const Failure.network(), on: 'restore');
    final (_, controller, read) = open();
    await controller.moveReadings();
    expect(read().transfer, const SettingsTransfer.failed(ErrorKind.network));
  });

  test('state follows the entitlement and AI consent', () async {
    final (_, _, read) = open();
    await pumpEventQueue();
    fakes.consentStore.seed(
      ConsentState(
        onboardingStep: OnboardingStep.done,
        ai: AiConsent(
          decision: AiConsentDecision.granted,
          version: 2,
          at: fakes.clock.now(),
        ),
      ),
    );
    await pumpEventQueue();
    expect(read().view.aiConsentGranted, isTrue);
  });
}
