@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/reading/controller/classic_reading_controller.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/controller/report_reading_controller.dart';
import 'package:taro/features/reading/view/classic_reading_screen.dart';
import 'package:taro/features/reading/view/reading_result_screen.dart';
import 'package:taro/features/reading/view/report_reading_sheet.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;
import 'package:taro_ui/taro_ui.dart';

import 'golden_app_support.dart';

/// The canvas sample (`docs/design/samples/readings/three_ppf.json`).
Map<String, Object?> _sample() =>
    jsonDecode(
          File(
            '../../docs/design/samples/readings/three_ppf.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

const Map<String, String> _names = {
  'cups_03': 'Three of Cups',
  'major_17': 'The Star',
  'pentacles_08': 'Eight of Pentacles',
  'wands_01': 'Ace of Wands',
  'swords_02': 'Two of Swords',
  'major_19': 'The Sun',
};

Draw _draw(List<(String, String, bool)> cards) => Draw(
  spreadId: const SpreadId('three_ppf'),
  spreadVersion: 1,
  drawnAt: DateTime.utc(2026, 9, 27, 18, 41),
  cards: [
    for (final (position, card, reversed) in cards)
      DrawnCard(
        positionId: PositionId(position),
        cardId: CardId(card),
        reversed: reversed,
      ),
  ],
);

CardText _text(CardId id) =>
    aCardText(id).copyWith(name: _names[id.value] ?? id.value);

void main() {
  final sample = _sample();
  final request = sample['request']! as Map<String, Object?>;
  final response = sample['response']! as Map<String, Object?>;
  final reading = aReading()
      .withId('r-golden')
      .onLocalDate('2026-09-27')
      .withDraw(
        _draw([
          ('past', 'cups_03', false),
          ('present', 'major_17', true),
          ('future', 'pentacles_08', false),
        ]),
      )
      .withQuestion(request['question']! as String)
      .withContent(
        ReadingContent.fromWire(response['reading']! as Map<String, Object?>),
      )
      .build();
  final view = ReadingResultView(
    reading: reading,
    cardTexts: {for (final c in reading.cards) c.cardId: _text(c.cardId)},
  );

  goldenMatrix(
    's09_reading_content',
    (_) => ReadingResultLayout(
      state: ReadingResultState.content(view),
      onDone: () {},
      onOpenDisclaimer: () {},
      onRate: (_, _) {},
      onToggleFavourite: () {},
      onReport: () {},
      onAddNote: () {},
      onWriteAbout: (_) {},
      onShare: (_, {required includeQuestion}) {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    extraLocales: const [Locale('de'), Locale('ja')],
    pump: pumpAppGolden(goldenFakes),
  );

  final classic = aReading()
      .withId('c-golden')
      .classic()
      .withQuestion(null)
      .withDraw(
        _draw([
          ('past', 'wands_01', false),
          ('present', 'swords_02', true),
          ('future', 'major_19', false),
        ]),
      )
      .build();
  final classicView = ClassicReadingView(
    reading: classic,
    positions: [
      for (final card in classic.cards)
        ClassicPosition(card: card, text: _text(card.cardId)),
    ],
  );

  goldenMatrix(
    's32_classic_content',
    (_) => ClassicReadingLayout(
      state: ClassicReadingState.content(classicView),
      onDone: () {},
      onOpenDisclaimer: () {},
      onAddNote: () {},
      onTryAi: (_) {},
    ),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );

  goldenMatrix(
    's33_report_editing',
    (_) => const _SheetFrame(
      child: _ReportEditing(),
    ),
    keyScreen: true,
    accessibility: true,
    pump: pumpAppGolden(goldenFakes),
  );
}

/// The S33 sheet over the `color.bg.scrim`, as `TaroSheet.show` presents
/// it.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ColoredBox(
      color: tokens.color.bg.scrim,
      child: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tokens.layout.maxContentWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.color.bg.surfaceRaised,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(tokens.radius.sheet),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ReportEditing extends StatefulWidget {
  const _ReportEditing();

  @override
  State<_ReportEditing> createState() => _ReportEditingState();
}

class _ReportEditingState extends State<_ReportEditing> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReportReadingLayout(
    state: const ReportReadingState.editing(ReportDraft()),
    note: _note,
    onReason: (_) {},
    onNote: (_) {},
    onSend: () {},
    onClose: () {},
  );
}
