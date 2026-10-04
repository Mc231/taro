@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/features/reading/controller/spread_picker_controller.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/reading/view/question_screen.dart';
import 'package:taro/features/reading/view/spread_picker_screen.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import '../../../../packages/taro_ui/test/helpers/golden/golden_sizes.dart';
import 'golden_app_support.dart';

/// Sprint 16.3 goldens: S06 `content`, S07 `editing` and
/// `refused(category)`, S08 `shuffling`, `picking`, `awaitingReading` and
/// the reduced-motion variant (★: phone + tablet widths, RC24).

const String _sample = 'How can I rebuild after a hard year at work?';

QuestionDraft _draft(String text) => QuestionDraft(
  spreadId: const SpreadId('three_ppf'),
  check: QuestionPrecheck.check(text, maxChars: 300),
  maxChars: 300,
  spread: aSpread().build(),
  text: text,
);

/// The declined question per golden locale.
const Map<String, String> _declinedQuestions = {
  'en': 'Will the kids get sick this winter?',
  'ar': 'هل سيمرض الأطفال هذا الشتاء؟',
  'uk': 'Чи захворіють діти цієї зими?',
};

QuestionState _declinedHealth(Locale locale) => QuestionState.rephrase(
  _draft(_declinedQuestions[locale.languageCode]!),
  safety: const SafetyInfo(
    category: RefusalCategory.health,
    messageKey: 'safetyDeclinedHealth',
    canRephrase: true,
  ),
  draw: aDraw(),
);

Widget _question(QuestionState state) => QuestionLayout(
  state: state,
  text: TextEditingController(text: state.draft.text),
  onChanged: (_) {},
  onSuggestion: (_) {},
  onBegin: () {},
  onRetry: () {},
  onDismiss: () {},
  onClassic: () {},
  onReflectWithoutQuestion: () {},
  onRephrase: () {},
  onAskDifferent: () {},
  onOpenConsent: () {},
  onOpenOptions: () {},
  onBack: () {},
  onDailyCard: () {},
  onLearn: () {},
  onChooseSpread: () {},
);

DrawView _view({int placed = 0, int revealed = 0, bool reduced = false}) =>
    DrawView(
      spread: aSpread().build(),
      draw: aDraw(),
      classic: false,
      placed: placed,
      revealed: revealed,
      reducedMotion: reduced,
      readingId: const ReadingId('r-1'),
      question: _sample,
    );

Widget _draw(DrawState state) => DrawLayout(
  state: state,
  onClose: () {},
  onShuffled: () {},
  onPick: () {},
  onDrawForMe: () {},
  onReveal: () {},
  onRevealAll: () {},
  onRetry: () {},
  onFinishLater: () {},
  onOpenOptions: () {},
);

void main() {
  final pump = pumpAppGolden(goldenFakes);

  goldenMatrix(
    's06_spread_picker_content',
    (_) => SpreadPickerLayout(
      state: SpreadPickerState.content([
        for (final id in kSpreadIds) aSpread(id.value).build(),
      ]),
      onBack: () {},
      onPick: (_) {},
      onHowTheyWork: () {},
      onRetry: () {},
    ),
    keyScreen: true,
    accessibility: true,
    pump: pump,
  );

  goldenMatrix(
    's07_question_editing',
    (_) => _question(QuestionState.editing(_draft(_sample))),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pump,
  );

  // The refusal state (S07 refusal spec): a declined `health` question
  // with a rewording hint, after the draw (the real-world case).
  goldenMatrix(
    's07_question_refused_health',
    (variant) => _question(_declinedHealth(variant.locale)),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    extraLocales: const [Locale('uk')],
    pump: pump,
  );
  // uk dark (the matrix covers uk light only).
  const ukDark = GoldenVariant(
    size: kPhoneLarge,
    themeMode: ThemeMode.dark,
    locale: Locale('uk'),
  );
  testWidgets('s07_question_refused_health ${ukDark.name}', (tester) async {
    await pump(tester, _question(_declinedHealth(ukDark.locale)), ukDark);
    await expectLater(
      find.byType(WidgetsApp),
      matchesGoldenFile(goldenPath('s07_question_refused_health', ukDark)),
    );
  }, tags: const ['golden']);

  goldenMatrix(
    's08_draw_shuffling',
    (_) => _draw(DrawState.shuffling(_view())),
    keyScreen: true,
    accessibility: true,
    pump: pump,
  );

  goldenMatrix(
    's08_draw_picking',
    (_) => _draw(DrawState.picking(_view(placed: 2))),
    keyScreen: true,
    accessibility: true,
    // BUG-03: at 200 % the deck fan scrolls after the slots.
    largeText: true,
    pump: pump,
  );

  // BUG-03, BUG-06, BUG-08: "Reveal all" scrolls at 200 %; "Tap to reveal"
  // and "Vergangenheit" stay whole in long locales.
  goldenMatrix(
    's08_draw_revealing',
    (_) => _draw(DrawState.revealing(_view(placed: 3))),
    keyScreen: true,
    largeText: true,
    extraLocales: const [Locale('de'), Locale('ja')],
    pump: pump,
  );

  goldenMatrix(
    's08_draw_awaiting_reading',
    (_) => _draw(DrawState.awaitingReading(_view(placed: 3, revealed: 3))),
    keyScreen: true,
    accessibility: true,
    pump: pump,
  );

  goldenMatrix(
    's08_draw_picking_reduced_motion',
    (_) => _draw(DrawState.picking(_view(placed: 2, reduced: true))),
    keyScreen: true,
    accessibility: true,
    pump: pump,
  );
}
