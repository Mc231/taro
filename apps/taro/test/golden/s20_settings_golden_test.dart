@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart' show SupportInfo;
import 'package:taro/features/settings/controller/settings_controller.dart';
import 'package:taro/features/settings/view/settings_screen.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import 'golden_app_support.dart';

void main() {
  // The canvas sample (docs/design/screens/S20, `Settings.dc.html`).
  final state = SettingsScreenState.content(
    view: SettingsView(
      settings: const UserSettings(
        reminder: ReminderSettings(enabled: true, time: '20:00'),
      ),
      balance: aCreditBalance().withPaid(3).withFreeRemaining(1).build(),
      adsRemoved: false,
      removeAdsOffered: true,
      aiConsentGranted: true,
      support: const SupportInfo(
        email: 'support@example.com',
        supportId: '3f9a1c07',
        appVersion: '1.0.0',
        buildNumber: '12',
        platform: AppPlatform.ios,
        osVersion: '18.0',
        locale: 'en',
      ),
    ),
    restore: const SettingsRestore.idle(),
    transfer: const SettingsTransfer.idle(),
  );

  goldenMatrix(
    's20_settings_content',
    (_) => SettingsLayout(
      state: state,
      onNavigate: (_) {},
      onStore: () {},
      onReversals: (_) {},
      onHaptics: (_) {},
      onTheme: (_) {},
      onRestore: () {},
      onMoveReadings: () {},
      onAcknowledge: () {},
      onCopy: (_) {},
      onRate: () {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );
}
