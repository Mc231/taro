@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/help/controller/crisis_resources_controller.dart';
import 'package:taro/features/help/view/crisis_resources_screen.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import 'golden_app_support.dart';

void main() {
  // The canvas sample (docs/design/screens/S27, `Crisis.dc.html`).
  final checked = DateTime.utc(2026, 9);
  final state = CrisisResourcesState.content(
    country: 'GB',
    hasLocalLines: true,
    countries: const ['GB', 'US'],
    resources: [
      CrisisResource(
        name: 'Samaritans',
        phone: '116 123',
        hours: 'free, 24/7',
        verifiedAt: checked,
      ),
      CrisisResource(
        name: 'Shout',
        sms: '85258',
        hours: '24/7',
        verifiedAt: checked,
      ),
      CrisisResource(
        name: 'Find A Helpline',
        url: 'https://findahelpline.com',
        verifiedAt: checked,
      ),
    ],
  );

  goldenMatrix(
    's27_crisis_content',
    (_) => CrisisResourcesLayout(
      state: state,
      onClose: () {},
      onRetry: () {},
      onChooseCountry: (_) {},
      onOpen: (_) {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );
}
