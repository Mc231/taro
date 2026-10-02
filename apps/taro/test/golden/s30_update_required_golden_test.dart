@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro/features/update/view/update_required_screen.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import 'golden_app_support.dart';

void main() {
  // The canvas sample (docs/design/screens/S30, `UpdateRequired.dc.html`).
  goldenMatrix(
    's30_update_required_content',
    (_) => UpdateRequiredLayout(
      state: const UpdateRequiredState.content(
        platform: AppPlatform.ios,
        installedVersion: '1.0.0',
        minVersion: '1.1.0',
      ),
      onOpenStore: () {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );
}
