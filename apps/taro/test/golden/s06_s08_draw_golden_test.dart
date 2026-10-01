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
import 'package:taro_core/taro_core.dart';

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

  goldenMatrix(
    's07_question_refused_health',
    (_) => _question(
      QuestionState.refused(
        _draft('How can I look after myself while I wait for my results?'),
        category: RefusalCategory.health,
        safety: const SafetyInfo(
          category: RefusalCategory.health,
          messageKey: 'safetyDeclinedHealth',
          canRephrase: false,
        ),
        draw: aDraw(),
      ),
    ),
    keyScreen: true,
    accessibility: true,
    pump: pump,
  );

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
