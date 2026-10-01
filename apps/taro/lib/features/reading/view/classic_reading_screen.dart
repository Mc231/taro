import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/classic_reading_controller.dart';
import 'package:taro/features/reading/view/reading_mini_spread.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S32 Classic reading result (01 §8.3, §9.9; RC20, RC71): per position the
/// card, its orientation and the bundled meaning, under a "Classic
/// reading" label instead of "AI-generated". The `DisclaimerFooter` is in
/// every state; no banner, no report, no rating. "Try an AI reading" shows
/// only when the gate would allow one.
class ClassicReadingScreen extends ConsumerWidget {
  /// Creates the screen for the reading [id].
  const ClassicReadingScreen({required this.id, super.key});

  /// The Classic reading.
  final ReadingId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classicReadingControllerProvider(id));
    return ClassicReadingLayout(
      state: state,
      artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
      onDone: () => context.go(RoutePaths.home),
      onOpenDisclaimer: () => context.push(RoutePaths.legal('disclaimer')),
      onAddNote: () =>
          unawaited(context.push(RoutePaths.journalEntry(id.value))),
      onTryAi: (spread) => context.go(RoutePaths.readingQuestion(spread.value)),
    );
  }
}

/// The S32 layout for [state] (`docs/design/screens/S32/spec.md`): Close
/// and "Add note" (no report menu, no rating); the mini spread; the
/// "Classic reading" label and caption as the heading; per position the
/// heading, the position description with the short meaning, and the
/// authored meaning; "Try an AI reading" only when the gate allows one; the
/// `DisclaimerFooter` in every state. No banner (04 §8).
class ClassicReadingLayout extends StatelessWidget {
  /// Creates the view.
  const ClassicReadingLayout({
    required this.state,
    required this.onDone,
    required this.onOpenDisclaimer,
    required this.onAddNote,
    required this.onTryAi,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final ClassicReadingState state;

  /// The bundled art set of the card faces.
  final String artSet;

  /// "Done" / close (Home).
  final VoidCallback onDone;

  /// "Full disclaimer" (S29).
  final VoidCallback onOpenDisclaimer;

  /// "Add note" (the note editor).
  final VoidCallback onAddNote;

  /// "Try an AI reading" on the same spread (S07).
  final ValueChanged<SpreadId> onTryAi;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final footer = DisclaimerFooter(onOpenDisclaimer: onOpenDisclaimer);
    Widget framed(Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        footer,
      ],
    );
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.readingDone,
        onLeading: onDone,
        actions: [
          if (state is ClassicReadingContent)
            TaroButton.tertiary(
              label: l10n.commonAddNote,
              onPressed: onAddNote,
            ),
        ],
      ),
      body: switch (state) {
        ClassicReadingLoadingFromStorage() => ListView(
          padding: EdgeInsetsDirectional.only(top: tokens.space.s5),
          children: [
            ReadingTextView.loading(loadingLabel: l10n.commonLoading),
            footer,
          ],
        ),
        ClassicReadingNotFound() => framed(
          TaroEmptyView(
            title: l10n.readingNotFound,
            action: TaroButton.primary(
              label: l10n.commonBackToToday,
              onPressed: onDone,
            ),
          ),
        ),
        ClassicReadingFailed(:final failure) => framed(
          FailureView.of(failure),
        ),
        ClassicReadingContent(:final view) => ListView(
          padding: EdgeInsetsDirectional.only(
            top: tokens.space.s4,
            bottom: tokens.space.s7,
          ),
          children: [
            ReadingMiniSpread(
              spreadId: view.reading.spreadId,
              cards: [for (final p in view.positions) p.card],
              names: {
                for (final p in view.positions) p.card.cardId: p.text.name,
              },
              positions: [
                for (final p in view.positions) ?p.position,
              ],
              artSet: artSet,
            ),
            SizedBox(height: tokens.space.s6),
            _text(context, view),
            if (view.aiAvailable) ...[
              SizedBox(height: tokens.space.s7),
              TaroButton.secondary(
                label: l10n.classicTryAi,
                expand: true,
                onPressed: () => onTryAi(view.reading.spreadId),
              ),
            ],
            footer,
          ],
        ),
      },
    );
  }

  Widget _text(BuildContext context, ClassicReadingView view) {
    final l10n = TaroLocalizations.of(context);
    final reading = view.reading;
    final question = reading.question;
    return ReadingTextView(
      question: question == null ? null : l10n.readingQuestionQuoted(question),
      sourceLabel: AiGeneratedLabel.classic(
        label: l10n.classicLabel,
        explanation: l10n.classicCaption,
      ),
      sections: [
        for (final position in view.positions)
          ReadingTextSection(
            heading: l10n.readingPositionHeading(
              SpreadText.positionName(
                l10n,
                reading.spreadId,
                position.card.positionId,
              ),
              position.card.reversed
                  ? l10n.readingCardReversed(position.text.name)
                  : position.text.name,
            ),
            subheading: switch (SpreadText.positionDescription(
              l10n,
              reading.spreadId,
              position.card.positionId,
            )) {
              final String description => l10n.commonItemSeparator(
                description,
                position.short,
              ),
              null => position.short,
            },
            body: position.meaning,
          ),
      ],
    );
  }
}
