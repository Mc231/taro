@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/consent/view/att_preprompt_view.dart';
import 'package:taro/features/onboarding/controller/ai_consent_controller.dart';
import 'package:taro/features/onboarding/view/ai_consent_screen.dart';
import 'package:taro/features/onboarding/view/disclaimer_screen.dart';
import 'package:taro/features/onboarding/view/welcome_screen.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_matrix.dart';
import '../helpers/pump_taro_widget.dart';

void _noop() {}

/// Phase 16 Sprint 16.1 goldens (06 §3, RC24): S02 `content`, S03
/// `content` and S04 `undecided` are ★ (also at `kTabletIpad13` and
/// `kTabletAndroid`); the ATT pre-prompt in light/dark × en/ar. S02 also
/// at text scale 2.0 (the hero shrinks to one card).
void main() {
  goldenMatrix(
    's02_welcome_content',
    (_) => const WelcomeLayout(onGetStarted: _noop, heroCardName: 'The Star'),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpTaroGolden,
  );
  goldenMatrix(
    's03_disclaimer_content',
    (_) => const DisclaimerLayout(
      acknowledged: false,
      onAcknowledge: _noop,
      onReadFull: _noop,
    ),
    keyScreen: true,
    accessibility: true,
    pump: pumpTaroGolden,
  );
  goldenMatrix(
    's04_ai_consent_undecided',
    (_) => const AiConsentLayout(
      state: AiConsentState.undecided(
        origin: AiConsentOrigin.onboarding,
        version: 2,
      ),
      onAllow: _noop,
      onNotNow: _noop,
      onBack: _noop,
      onPrivacy: _noop,
    ),
    keyScreen: true,
    accessibility: true,
    pump: pumpTaroGolden,
  );
  goldenMatrix(
    'att_preprompt',
    (_) => const AttPrePromptLayout(onContinue: _noop),
    pump: pumpTaroGolden,
  );
}
