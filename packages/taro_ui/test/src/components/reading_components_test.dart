import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

const _sections = [
  ReadingTextSection(
    body:
        'The cards move from shared joy toward patient, skilled work.\n\n'
        'The rebuilding may come from steady practice.',
  ),
  ReadingTextSection(
    heading: 'Present · The Star, reversed',
    subheading: 'Where you are now',
    body: 'Hope that feels far away right now.',
  ),
];

void main() {
  group('ReadingRatingControl', () {
    testWidgets('toggles up/down, clears on second tap, labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      ReadingRatingValue? rating;
      final log = <ReadingRatingValue?>[];
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => ReadingRatingControl(
                prompt: 'Was this reading helpful?',
                helpfulLabel: 'Helpful',
                notHelpfulLabel: 'Not helpful',
                value: rating,
                onChanged: (v) => setState(() {
                  log.add(v);
                  rating = v;
                }),
              ),
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.bySemanticsLabel('Helpful'));
      await tester.pump();
      expect(rating, ReadingRatingValue.up);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Helpful')),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true),
      );
      expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Not helpful'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Not helpful'));
      await tester.pump();
      expect(log, [
        ReadingRatingValue.up,
        ReadingRatingValue.down,
        null,
      ]);
      handle.dispose();
    });

    testWidgets('disabled control ignores taps', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const ReadingRatingControl(
          prompt: 'p',
          helpfulLabel: 'Helpful',
          notHelpfulLabel: 'Not helpful',
          value: ReadingRatingValue.down,
          onChanged: null,
        ),
      );
      expect(find.byType(Opacity), findsNWidgets(2));
      expect(find.byIcon(Icons.thumb_down_rounded), findsOneWidget);
    });
  });

  group('ReadingSectionHeader', () {
    testWidgets('is a header with a marker; small and plain variants', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const Column(
          children: [
            ReadingSectionHeader(
              title: 'Present · The Star, reversed',
              subtitle: 'Where you are now',
            ),
            ReadingSectionHeader(
              title: 'Upright meaning',
              small: true,
              marker: false,
            ),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.text('Present · The Star, reversed')),
        isSemantics(isHeader: true),
      );
      final dots = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color ==
                TaroColorTokens.light.accent.secondary,
      );
      expect(dots, findsOneWidget);
      handle.dispose();
    });
  });

  group('AiGeneratedLabel', () {
    testWidgets('ai pill and classic explanation', (tester) async {
      final handle = tester.ensureSemantics();
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          const Padding(
            padding: EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AiGeneratedLabel(label: 'AI-generated'),
                SizedBox(height: 16),
                AiGeneratedLabel.classic(
                  label: 'Classic reading',
                  explanation: 'No AI, free and works offline.',
                ),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      expect(find.text('AI-generated'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Classic reading')),
        isSemantics(label: 'Classic reading\nNo AI, free and works offline.'),
      );
      expect(
        const AiGeneratedLabel(label: 'x').variant,
        ReadingSourceVariant.ai,
      );
      handle.dispose();
    });
  });

  group('ReadingTextView', () {
    testWidgets('renders question, label, title, sections; selectable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const SingleChildScrollView(
          child: ReadingTextView(
            question: '“How can I rebuild after a hard year?”',
            sourceLabel: AiGeneratedLabel(label: 'AI-generated'),
            title: 'A season of rebuilding',
            sections: _sections,
            footer: Text('For entertainment and self-reflection.'),
          ),
        ),
        size: const Size(1032, 1376),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(
        find.text('The rebuilding may come from steady practice.'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('A season of rebuilding')),
        isSemantics(isHeader: true),
      );
      // Capped at layout.readingMaxWidth on a tablet.
      expect(
        tester.getSize(find.byType(SelectionArea)).width,
        TaroLayoutTokens.light.readingMaxWidth,
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('reveal staggers without reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: const Scaffold(
            body: ReadingTextView(
              title: 'A season of rebuilding',
              sections: _sections,
              reveal: true,
            ),
          ),
        ),
      );
      double opacityOf(String text) => tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text(text), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      expect(opacityOf('A season of rebuilding'), 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(opacityOf('A season of rebuilding'), greaterThan(0));
      expect(
        opacityOf('Hope that feels far away right now.'),
        lessThan(opacityOf('A season of rebuilding')),
      );
      await tester.pumpAndSettle();
      expect(opacityOf('Hope that feels far away right now.'), 1);
    });

    testWidgets('reveal is skipped under reduced motion', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const ReadingTextView(sections: _sections, reveal: true),
      );
      expect(
        find.ancestor(
          of: find.text('Hope that feels far away right now.'),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('loading shows skeletons with a label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const ReadingTextView.loading(loadingLabel: 'Loading your reading'),
      );
      expect(find.byType(SkeletonBlock), findsNWidgets(7));
      expect(find.bySemanticsLabel('Loading your reading'), findsOneWidget);
      handle.dispose();
    });
  });
}
